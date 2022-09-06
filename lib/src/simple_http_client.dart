import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cancellation_token_hoc081098/cancellation_token_hoc081098.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'exception.dart';

import 'dart:typed_data';

/// TODO(docs)
typedef RequestInterceptor = FutureOr<http.BaseRequest> Function(
    http.BaseRequest request);

/// TODO(docs)
typedef ResponseInterceptor = FutureOr<void> Function(
    http.BaseRequest request, http.Response response);

/// TODO(docs)
typedef JsonDecoderFunction = dynamic Function(String source);

/// TODO(docs)
typedef JsonEncoderFunction = String Function(Object object);

/// TODO(docs)
@sealed
abstract class SimpleHttpClient {
  /// TODO(docs)
  factory SimpleHttpClient({
    required http.Client client,
    Duration? timeout,
    List<RequestInterceptor> requestInterceptors = const <RequestInterceptor>[],
    List<ResponseInterceptor> responseInterceptors =
        const <ResponseInterceptor>[],
    JsonDecoderFunction jsonDecoder = jsonDecode,
    JsonEncoderFunction jsonEncoder = jsonEncode,
  }) =>
      _DefaultSimpleHttpClient(
        client: client,
        timeout: timeout,
        requestInterceptors: requestInterceptors,
        responseInterceptors: responseInterceptors,
        jsonDecoder: jsonDecoder,
        jsonEncoder: jsonEncoder,
      );

  /// Sends an HTTP request and asynchronously returns the response.
  Future<http.StreamedResponse> send(
    http.BaseRequest request,
    CancellationToken? cancelToken,
  );

  /// Sends an HTTP GET request with the given headers to the given URL.
  /// Returns the resulting JSON object.
  ///
  /// Can throw [SimpleHttpClientException].
  Future<dynamic> getJson(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  });

  /// TODO(docs)
  Future<dynamic> postMultipart(
    Uri url,
    List<http.MultipartFile> files, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    CancellationToken? cancelToken,
  });

  /// TODO(docs)
  Future<dynamic> postJson(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    CancellationToken? cancelToken,
  });

  /// TODO(docs)
  Future<dynamic> putJson(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    CancellationToken? cancelToken,
  });

  /// TODO(docs)
  Future<dynamic> deleteJson(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  });

  /// Closes the client and cleans up any resources associated with it.
  ///
  /// It's important to close each client when it's done being used; failing to
  /// do so can cause the Dart process to hang.
  void close();
}

/// TODO(docs)
class _DefaultSimpleHttpClient implements SimpleHttpClient {
  /// JSON content type.
  static const jsonContentType = 'application/json; charset=utf-8';

  final http.Client _client;
  final Duration? _timeout;

  final List<RequestInterceptor> _requestInterceptors;
  final List<ResponseInterceptor> _responseInterceptors;

  final JsonDecoderFunction _jsonDecoder;
  final JsonEncoderFunction _jsonEncoder;

  /// TODO(docs)
  _DefaultSimpleHttpClient({
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
        cancelToken,
        headers: {
          ...?headers,
          HttpHeaders.contentTypeHeader: jsonContentType,
        },
      ).then<dynamic>(interceptAndParseJson(cancelToken));

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
        HttpHeaders.contentTypeHeader: 'multipart/form-data',
      });

    return send(request, cancelToken)
        .then((res) => http.Response.fromStream(res))
        .then<dynamic>(interceptAndParseJson(cancelToken));
  }

  @override
  Future<dynamic> postJson(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    CancellationToken? cancelToken,
  }) =>
      post(
        url,
        cancelToken,
        headers: {
          ...?headers,
          HttpHeaders.contentTypeHeader: jsonContentType,
        },
        body: bodyToString(body),
      ).then<dynamic>(interceptAndParseJson(cancelToken));

  @override
  Future<dynamic> putJson(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    CancellationToken? cancelToken,
  }) {
    return put(
      url,
      cancelToken,
      headers: {
        ...?headers,
        HttpHeaders.contentTypeHeader: jsonContentType,
      },
      body: bodyToString(body),
    ).then<dynamic>(interceptAndParseJson(cancelToken));
  }

  @override
  Future<dynamic> deleteJson(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  }) =>
      delete(url, cancelToken, headers: headers)
          .then<dynamic>(interceptAndParseJson(cancelToken));

  @override
  void close() => _client.close();

  //
  //
  //

  @override
  Future<http.StreamedResponse> send(
    http.BaseRequest request,
    CancellationToken? cancelToken,
  ) async {
    final interceptedRequest = _requestInterceptors.isEmpty
        ? request
        : await _requestInterceptors.fold<Future<http.BaseRequest>>(
            requestFuture(request, cancelToken),
            (acc, interceptor) {
              return acc.then((req) {
                cancelToken?.guard();
                return interceptor(req);
              });
            },
          );

    cancelToken?.guard();

    final responseFuture = _client.send(interceptedRequest);

    cancelToken?.guard();

    final response = _timeout != null
        ? await responseFuture.timeout(
            _timeout!,
            onTimeout: () {
              cancelToken?.guard();
              throw SimpleTimeoutException(interceptedRequest);
            },
          )
        : await responseFuture;

    cancelToken?.guard();

    return response;
  }

  //
  //
  //

  FutureOr<dynamic> Function(http.Response) interceptAndParseJson(
    CancellationToken? cancelToken,
  ) =>
      (response) {
        /// TODO: https://github.com/dart-lang/http/issues/782: cupertino_http: BaseResponse.request is null
        final request = response.request;

        return _responseInterceptors.isNotEmpty && request != null
            ? _responseInterceptors
                .fold<Future<void>>(
                requestFuture(request, cancelToken),
                (acc, interceptor) => acc.then((_) {
                  cancelToken?.guard();
                  return interceptor(request, response);
                }),
              )
                .then<dynamic>((_) {
                cancelToken?.guard();
                return parseJsonOrThrow(response);
              })
            : parseJsonOrThrow(response);
      };

  dynamic parseJsonOrThrow(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (HttpStatus.ok <= statusCode &&
        statusCode <= HttpStatus.multipleChoices) {
      return _jsonDecoder(body);
    }

    throw SimpleErrorResponseException(response);
  }

  String? bodyToString(Object? body) =>
      body != null ? _jsonEncoder(body) : null;

  static Future<http.BaseRequest> requestFuture(
      http.BaseRequest request, CancellationToken? cancelToken) {
    cancelToken?.guard();
    return Future.value(request);
  }

  //
  //
  //

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

  /// Sends a non-streaming [Request] and returns a non-streaming [Response].
  Future<http.Response> _sendUnstreamed(
    String method,
    Uri url,
    Map<String, String>? headers,
    CancellationToken? cancelToken, {
    Object? body,
    Encoding? encoding,
  }) =>
      cancelToken == null
          ? Future.sync(
                  () => _buildRequest(method, url, headers, encoding, body))
              .then((request) => send(request, null))
              .then(http.Response.fromStream)
          : cancelToken.guardFuture(() async {
              final request =
                  _buildRequest(method, url, headers, encoding, body);

              cancelToken.guard();

              final streamedResponse = await send(request, cancelToken);

              cancelToken.guard();

              final response = await _fromStream(streamedResponse, cancelToken);

              cancelToken.guard();

              return response;
            });

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
