import 'package:http/http.dart' as http;

/// TODO(docs)
class SimpleHttpClientException implements Exception {
  const SimpleHttpClientException._();
}

/// TODO(docs)
class SimpleTimeoutException extends SimpleHttpClientException {
  /// The (frozen) request.
  final http.BaseRequest request;

  /// TODO(docs)
  SimpleTimeoutException(this.request) : super._();

  @override
  String toString() => 'SimpleTimeoutException{request: $request}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleTimeoutException &&
          runtimeType == other.runtimeType &&
          request == other.request;

  @override
  int get hashCode => request.hashCode;
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleErrorResponseException &&
          runtimeType == other.runtimeType &&
          response == other.response;

  @override
  int get hashCode => response.hashCode;

  @override
  String toString() => 'SimpleErrorResponseException{response: $response}';
}

/// TODO(docs)
class SimpleCancellationException extends SimpleHttpClientException {
  /// TODO(docs)
  const SimpleCancellationException() : super._();

  @override
  String toString() => 'SimpleCancellationException{}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleCancellationException && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;
}
