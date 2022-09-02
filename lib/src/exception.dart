import 'package:http/http.dart' as http;

/// TODO(docs)
class SimpleHttpClientException implements Exception {
  const SimpleHttpClientException._();
}

/// TODO(docs)
class SimpleHttpClientTimeoutException extends SimpleHttpClientException {
  /// The (frozen) request.
  final http.BaseRequest request;

  /// TODO(docs)
  SimpleHttpClientTimeoutException(this.request) : super._();

  @override
  String toString() => 'SimpleHttpClientTimeoutException{request: $request}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleHttpClientTimeoutException &&
          runtimeType == other.runtimeType &&
          request == other.request;

  @override
  int get hashCode => request.hashCode;
}

/// TODO(docs)
class SimpleHttpClientErrorResponseException extends SimpleHttpClientException {
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
  SimpleHttpClientErrorResponseException(this.response) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleHttpClientErrorResponseException &&
          runtimeType == other.runtimeType &&
          response == other.response;

  @override
  int get hashCode => response.hashCode;

  @override
  String toString() =>
      'SimpleHttpClientErrorResponseException{response: $response}';
}

/// TODO(docs)
class SimpleHttpClientCancellationException extends SimpleHttpClientException {
  final StackTrace stackTrace;

  /// TODO(docs)
  SimpleHttpClientCancellationException(this.stackTrace) : super._();

  @override
  String toString() =>
      'SimpleHttpClientCancellationException{stackTrace: $stackTrace}';
}
