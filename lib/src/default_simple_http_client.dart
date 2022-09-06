import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cancellation_token_hoc081098/cancellation_token_hoc081098.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'exception.dart';

import 'dart:typed_data';

import 'interface.dart';

/// Default implementation of [SimpleHttpClient].
@internal
class DefaultSimpleHttpClient implements SimpleHttpClient {
  final http.Client _client;
  final Duration? _timeout;

  final List<RequestInterceptor> _requestInterceptors;
  final List<ResponseInterceptor> _responseInterceptors;

  final JsonDecoderFunction _jsonDecoder;
  final JsonEncoderFunction _jsonEncoder;

  /// TODO(docs)
  DefaultSimpleHttpClient({
    required http.Client client,
    required Duration? timeout,
    required List<RequestInterceptor> requestInterceptors,
    required List<ResponseInterceptor> responseInterceptors,
    required JsonDecoderFunction jsonDecoder,
    required JsonEncoderFunction jsonEncoder,
  })  : _client = client,
        _timeout = timeout,
        _requestInterceptors = List.unmodifiable(requestInterceptors),
        _responseInterceptors = List.unmodifiable(responseInterceptors),
        _jsonDecoder = jsonDecoder,
        _jsonEncoder = jsonEncoder;

  @override
  Future<dynamic> getJson(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  }) =>
      get(
        url,
        cancelToken: cancelToken,
        headers: {
          ...?headers,
          HttpHeaders.contentTypeHeader: SimpleHttpClient.jsonUtf8ContentType,
        },
      ).then<dynamic>(_parseJsonOrThrow);

  @override
  Future<dynamic> postMultipart(
    Uri url,
    List<http.MultipartFile> files, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    CancellationToken? cancelToken,
  }) {
    final request = http.MultipartRequest('POST', url)
      ..fields.addAll(fields ?? const <String, String>{})
      ..files.addAll(files)
      ..headers.addAll(<String, String>{
        ...?headers,
        HttpHeaders.contentTypeHeader: SimpleHttpClient.multipartContentType,
      });

    return send(request, cancelToken).then<dynamic>(_parseJsonOrThrow);
  }

  @override
  Future<dynamic> postJson(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    CancellationToken? cancelToken,
  }) =>
      post(
        url,
        cancelToken: cancelToken,
        headers: {
          ...?headers,
          HttpHeaders.contentTypeHeader: SimpleHttpClient.jsonUtf8ContentType,
        },
        body: _bodyToString(body),
      ).then<dynamic>(_parseJsonOrThrow);

  @override
  Future<dynamic> putJson(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    CancellationToken? cancelToken,
  }) =>
      put(
        url,
        cancelToken: cancelToken,
        headers: {
          ...?headers,
          HttpHeaders.contentTypeHeader: SimpleHttpClient.jsonUtf8ContentType,
        },
        body: _bodyToString(body),
      ).then<dynamic>(_parseJsonOrThrow);

  @override
  Future<dynamic> deleteJson(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  }) =>
      delete(url, cancelToken: cancelToken, headers: headers)
          .then<dynamic>(_parseJsonOrThrow);

  @override
  void close() => _client.close();

  @override
  Future<http.Response> send(
    http.BaseRequest request,
    CancellationToken? cancelToken,
  ) =>
      cancelToken == null
          ? _sendInternal(request, null)
          : cancelToken.guardFuture(() => _sendInternal(request, cancelToken));

  @override
  Future<http.Response> head(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  }) =>
      _sendUnstreamed('HEAD', url, headers, cancelToken);

  @override
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  }) =>
      _sendUnstreamed('GET', url, headers, cancelToken);

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancellationToken? cancelToken,
  }) =>
      _sendUnstreamed(
        'POST',
        url,
        headers,
        cancelToken,
        body: body,
        encoding: encoding,
      );

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancellationToken? cancelToken,
  }) =>
      _sendUnstreamed(
        'PUT',
        url,
        headers,
        cancelToken,
        body: body,
        encoding: encoding,
      );

  @override
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancellationToken? cancelToken,
  }) =>
      _sendUnstreamed(
        'PATCH',
        url,
        headers,
        cancelToken,
        body: body,
        encoding: encoding,
      );

  @override
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancellationToken? cancelToken,
  }) =>
      _sendUnstreamed(
        'DELETE',
        url,
        headers,
        cancelToken,
        body: body,
        encoding: encoding,
      );

  @override
  Future<String> read(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  }) async {
    final response = await get(url, cancelToken: cancelToken, headers: headers);
    _checkResponseSuccess(url, response);
    return response.body;
  }

  @override
  Future<Uint8List> readBytes(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  }) async {
    final response = await get(url, cancelToken: cancelToken, headers: headers);
    _checkResponseSuccess(url, response);
    return response.bodyBytes;
  }

  //
  // internal implementation
  //

  Future<http.Response> _sendInternal(
    http.BaseRequest request,
    CancellationToken? cancelToken,
  ) async {
    // intercept the request
    final interceptedRequest = _requestInterceptors.isEmpty
        ? request
        : await _requestInterceptors.fold<Future<http.BaseRequest>>(
            _value(request, cancelToken),
            (acc, interceptor) => acc.then((req) {
              cancelToken?.guard();
              return interceptor(req);
            }),
          );

    cancelToken?.guard();

    // send the request
    final responseFuture = _client.send(interceptedRequest);

    // await the response
    final streamedResponse = _timeout != null
        ? await responseFuture.timeout(
            _timeout!,
            onTimeout: () {
              cancelToken?.guard();
              throw SimpleTimeoutException(interceptedRequest);
            },
          )
        : await responseFuture;

    cancelToken?.guard();

    // convert http.StreamedResponse to http.Response
    final response = cancelToken == null
        ? await http.Response.fromStream(streamedResponse)
        : await _fromStream(streamedResponse, cancelToken);

    cancelToken?.guard();

    // intercept the response
    if (_responseInterceptors.isNotEmpty) {
      /// TODO: https://github.com/dart-lang/http/issues/782: cupertino_http: BaseResponse.request is null
      final request = interceptedRequest;

      final interceptedResponse =
          await _responseInterceptors.fold<Future<http.Response>>(
        _value(response, cancelToken),
        (acc, interceptor) => acc.then((res) {
          cancelToken?.guard();
          return interceptor(request, res);
        }),
      );

      cancelToken?.guard();
      return interceptedResponse;
    } else {
      return response;
    }
  }

  /// Sends a non-streaming [Request] and returns a non-streaming [Response].
  Future<http.Response> _sendUnstreamed(
    String method,
    Uri url,
    Map<String, String>? headers,
    CancellationToken? cancelToken, {
    Object? body,
    Encoding? encoding,
  }) {
    Future<http.Response> block() => _sendInternal(
          _buildRequest(method, url, headers, encoding, body),
          cancelToken,
        );

    return cancelToken == null
        ? Future.sync(block)
        : cancelToken.guardFuture(block);
  }

  dynamic _parseJsonOrThrow(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (HttpStatus.ok <= statusCode &&
        statusCode <= HttpStatus.multipleChoices) {
      return _jsonDecoder(body);
    }

    throw SimpleErrorResponseException(response);
  }

  String? _bodyToString(Object? body) =>
      body != null ? _jsonEncoder(body) : null;

  static Future<T> _value<T>(T request, CancellationToken? cancelToken) {
    cancelToken?.guard();
    return Future.value(request);
  }

  static http.Request _buildRequest(
    String method,
    Uri url,
    Map<String, String>? headers,
    Encoding? encoding,
    Object? body,
  ) {
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

    return request;
  }

  /// Throws an error if [response] is not successful.
  static void _checkResponseSuccess(Uri url, http.Response response) {
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
  cancelToken.guard();

  final body = await _toBytes(response.stream, cancelToken);

  cancelToken.guard();

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

  stream.guardedBy(cancelToken).listen(
        sink.add,
        onError: completer.completeError,
        onDone: sink.close,
        cancelOnError: true,
      );

  return completer.future;
}
