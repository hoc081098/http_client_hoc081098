import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../http_client_hoc081098.dart';
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
typedef JsonEncoderFunction = String Function(Object? object);

/// TODO(docs)
@sealed
abstract class SimpleHttpClient extends http.BaseClient {
  SimpleHttpClient._();

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

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request);

  /// Sends an HTTP GET request with the given headers to the given URL.
  /// Returns the resulting JSON object.
  ///
  /// Can throw [SimpleHttpClientException].
  Future<dynamic> getJson(
    Uri url, {
    Map<String, String>? headers,
  });

  /// TODO(docs)
  Future<dynamic> postMultipart(
    Uri url,
    List<http.MultipartFile> files, {
    Map<String, String>? headers,
    Map<String, String>? fields,
  });

  /// TODO(docs)
  Future<dynamic> postJson(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  });

  /// TODO(docs)
  Future<dynamic> putJson(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  });

  /// TODO(docs)
  Future<dynamic> deleteJson(Uri url, {Map<String, String>? headers});
}

/// TODO(docs)
class _DefaultSimpleHttpClient extends SimpleHttpClient {
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
        _jsonEncoder = jsonEncoder,
        super._();

  @override
  Future<dynamic> getJson(Uri url, {Map<String, String>? headers}) => super.get(
        url,
        headers: {
          ...?headers,
          HttpHeaders.contentTypeHeader: jsonContentType,
        },
      ).then<dynamic>(interceptAndParseJson);

  @override
  Future<dynamic> postMultipart(
    Uri url,
    List<http.MultipartFile> files, {
    Map<String, String>? headers,
    Map<String, String>? fields,
  }) {
    final request = http.MultipartRequest('POST', url)
      ..fields.addAll(fields ?? const <String, String>{})
      ..files.addAll(files)
      ..headers.addAll(<String, String>{
        ...?headers,
        HttpHeaders.contentTypeHeader: 'multipart/form-data',
      });

    return send(request)
        .then((res) => http.Response.fromStream(res))
        .then<dynamic>(interceptAndParseJson);
  }

  @override
  Future<dynamic> postJson(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) =>
      super
          .post(
            url,
            headers: {
              ...?headers,
              HttpHeaders.contentTypeHeader: jsonContentType,
            },
            body: bodyToString(body),
          )
          .then<dynamic>(interceptAndParseJson);

  @override
  Future<dynamic> putJson(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) {
    return super
        .put(
          url,
          headers: {
            ...?headers,
            HttpHeaders.contentTypeHeader: jsonContentType,
          },
          body: bodyToString(body),
        )
        .then<dynamic>(interceptAndParseJson);
  }

  @override
  Future<dynamic> deleteJson(Uri url, {Map<String, String>? headers}) =>
      super.delete(url, headers: headers).then<dynamic>(interceptAndParseJson);

  //
  //
  //

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final interceptedRequest = _requestInterceptors.isEmpty
        ? request
        : await _requestInterceptors.fold<Future<http.BaseRequest>>(
            Future.value(request),
            (acc, interceptor) => acc.then((req) => interceptor(req)),
          );

    final responseFuture = _client.send(interceptedRequest);
    final response = _timeout != null
        ? await responseFuture.timeout(
            _timeout!,
            onTimeout: () =>
                throw SimpleHttpClientTimeoutException(interceptedRequest),
          )
        : await responseFuture;

    return response;
  }

  //
  //
  //

  FutureOr<dynamic> interceptAndParseJson(http.Response response) {
    /// TODO: https://github.com/dart-lang/http/issues/782: cupertino_http: BaseResponse.request is null
    final request = response.request;

    return _responseInterceptors.isNotEmpty && request != null
        ? _responseInterceptors
            .fold<Future<void>>(
              Future.value(null),
              (acc, interceptor) =>
                  acc.then((_) => interceptor(request, response)),
            )
            .then<dynamic>((_) => parseJsonOrThrow(response))
        : parseJsonOrThrow(response);
  }

  dynamic parseJsonOrThrow(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (HttpStatus.ok <= statusCode &&
        statusCode <= HttpStatus.multipleChoices) {
      return _jsonDecoder(body);
    }

    throw SimpleHttpClientErrorResponseException(response);
  }

  String? bodyToString(Object? body) =>
      body != null ? _jsonEncoder(body) : null;
}
