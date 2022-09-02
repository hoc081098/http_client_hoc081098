import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

import 'cancellation_token.dart';

/// The abstract base class for an HTTP client.
///
/// This is a mixin-style class; subclasses only need to implement [send] and
/// maybe [close], and then they get various convenience methods for free.
@internal
abstract class BaseClient {
  /// @internal
  Future<http.Response> head(
    Uri url,
    CancellationToken? cancelToken, {
    Map<String, String>? headers,
  }) =>
      _sendUnstreamed('HEAD', url, headers, cancelToken);

  /// @internal
  Future<http.Response> get(
    Uri url,
    CancellationToken? cancelToken, {
    Map<String, String>? headers,
  }) =>
      _sendUnstreamed('GET', url, headers, cancelToken);

  /// @internal
  Future<http.Response> post(
    Uri url,
    CancellationToken? cancelToken, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      _sendUnstreamed(
        'POST',
        url,
        headers,
        cancelToken,
        body: body,
        encoding: encoding,
      );

  /// @internal
  Future<http.Response> put(
    Uri url,
    CancellationToken? cancelToken, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      _sendUnstreamed(
        'PUT',
        url,
        headers,
        cancelToken,
        body: body,
        encoding: encoding,
      );

  /// @internal
  Future<http.Response> patch(
    Uri url,
    CancellationToken? cancelToken, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      _sendUnstreamed(
        'PATCH',
        url,
        headers,
        cancelToken,
        body: body,
        encoding: encoding,
      );

  /// @internal
  Future<http.Response> delete(
    Uri url,
    CancellationToken? cancelToken, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      _sendUnstreamed(
        'DELETE',
        url,
        headers,
        cancelToken,
        body: body,
        encoding: encoding,
      );

  /// @internal
  Future<String> read(
    Uri url,
    CancellationToken? cancelToken, {
    Map<String, String>? headers,
  }) async {
    final response = await get(url, cancelToken, headers: headers);
    _checkResponseSuccess(url, response);
    return response.body;
  }

  /// @internal
  Future<Uint8List> readBytes(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  }) async {
    final response = await get(url, cancelToken, headers: headers);
    _checkResponseSuccess(url, response);
    return response.bodyBytes;
  }

  /// Sends an HTTP request and asynchronously returns the response.
  ///
  /// Implementers should call [BaseRequest.finalize] to get the body of the
  /// request as a [ByteStream]. They shouldn't make any assumptions about the
  /// state of the stream; it could have data written to it asynchronously at a
  /// later point, or it could already be closed when it's returned. Any
  /// internal HTTP errors should be wrapped as [ClientException]s.
  Future<http.StreamedResponse> send(
    http.BaseRequest request,
    CancellationToken? cancelToken,
  );

  /// Sends a non-streaming [Request] and returns a non-streaming [Response].
  Future<http.Response> _sendUnstreamed(
    String method,
    Uri url,
    Map<String, String>? headers,
    CancellationToken? cancelToken, {
    Object? body,
    Encoding? encoding,
  }) =>
      cancellationGuard(
        cancelToken,
        () async {
          final request = http.Request(method, url);

          if (headers != null) request.headers.addAll(headers);
          if (encoding != null) request.encoding = encoding;
          if (body != null) {
            if (body is String) {
              request.body = body;
            } else if (body is List) {
              request.bodyBytes = body.cast<int>();
            } else if (body is Map) {
              request.bodyFields = body.cast<String, String>();
            } else {
              throw ArgumentError('Invalid request body "$body".');
            }
          }

          if (cancelToken == null) {
            return send(request, null).then(http.Response.fromStream);
          }

          cancelToken.guard(StackTrace.current);

          final streamedResponse = await send(request, cancelToken);

          cancelToken.guard(StackTrace.current);

          final response = await _fromStream(streamedResponse, cancelToken);

          cancelToken.guard(StackTrace.current);

          return response;
        },
      );

  /// Throws an error if [response] is not successful.
  void _checkResponseSuccess(Uri url, http.Response response) {
    if (response.statusCode < 400) return;
    var message = 'Request to $url failed with status ${response.statusCode}';
    if (response.reasonPhrase != null) {
      message = '$message: ${response.reasonPhrase}';
    }
    throw http.ClientException('$message.', url);
  }
}

/// Creates a new HTTP response by waiting for the full body to become
/// available from a [StreamedResponse].
Future<http.Response> _fromStream(
  http.StreamedResponse response,
  CancellationToken cancelToken,
) async {
  cancelToken.guard(StackTrace.current);

  final body = await _toBytes(response.stream, cancelToken);

  cancelToken.guard(StackTrace.current);

  return http.Response.bytes(body, response.statusCode,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase);
}

/// Collects the data of this stream in a [Uint8List].
Future<Uint8List> _toBytes(
  http.ByteStream stream,
  CancellationToken cancelToken,
) {
  final completer = Completer<Uint8List>();
  final sink = ByteConversionSink.withCallback(
      (bytes) => completer.complete(Uint8List.fromList(bytes)));

  stream.takeUntil(onCancel(cancelToken)).listen(
        sink.add,
        onError: completer.completeError,
        onDone: sink.close,
        cancelOnError: true,
      );

  return completer.future;
}
