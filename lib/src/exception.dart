import 'package:http/http.dart' as http;

import 'interface.dart';

/// Exception thrown by [SimpleHttpClient].
class SimpleHttpClientException implements Exception {
  const SimpleHttpClientException._();
}

/// TODO(docs)
class SimpleTimeoutException extends SimpleHttpClientException {
  /// The (frozen) request.
  final http.BaseRequest request;

  /// The URL to which the request will be sent.
  Uri? get url => request.url;

  /// TODO(docs)
  SimpleTimeoutException(this.request) : super._();

  @override
  String toString() => 'SimpleTimeoutException{request: $request}';
}

/// TODO(docs)
class SimpleErrorResponseException extends SimpleHttpClientException {
  /// The error response.
  final http.Response response;

  /// The (frozen) request that triggered [response].
  http.BaseRequest? get request => response.request;

  /// The HTTP status code for [response].
  int get statusCode => response.statusCode;

  /// The URL to which the request will be sent.
  Uri? get url => request?.url;

  /// The error response body
  String get errorResponseBody => response.body;

  /// TODO(docs)
  SimpleErrorResponseException(this.response) : super._();

  @override
  String toString() => 'SimpleErrorResponseException{response: $response}';
}
