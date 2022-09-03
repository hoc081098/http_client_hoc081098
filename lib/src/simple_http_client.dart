import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cancellation_token_hoc081098/cancellation_token_hoc081098.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'base.dart';
import 'exception.dart';

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

  /// TODO(docs)
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
class _DefaultSimpleHttpClient extends BaseClient implements SimpleHttpClient {
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
      super.get(
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
      super
          .post(
            url,
            cancelToken,
            headers: {
              ...?headers,
              HttpHeaders.contentTypeHeader: jsonContentType,
            },
            body: bodyToString(body),
          )
          .then<dynamic>(interceptAndParseJson(cancelToken));

  @override
  Future<dynamic> putJson(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    CancellationToken? cancelToken,
  }) {
    return super
        .put(
          url,
          cancelToken,
          headers: {
            ...?headers,
            HttpHeaders.contentTypeHeader: jsonContentType,
          },
          body: bodyToString(body),
        )
        .then<dynamic>(interceptAndParseJson(cancelToken));
  }

  @override
  Future<dynamic> deleteJson(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  }) =>
      super
          .delete(url, cancelToken, headers: headers)
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
}
