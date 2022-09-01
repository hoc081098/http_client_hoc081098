import 'package:http/http.dart';

/// TODO(docs)
class SimpleHttpClientException implements Exception {}

/// TODO(docs)
class SimpleHttpClientTimeoutException extends SimpleHttpClientException {
  /// TODO(docs)
  final BaseRequest request;

  /// TODO(docs)
  SimpleHttpClientTimeoutException(this.request);

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
  /// TODO(docs)
  final String errorResponseBody;

  /// TODO(docs)
  final BaseRequest? baseRequest;

  /// TODO(docs)
  final int statusCode;

  /// The URL to which the request will be sent.
  Uri? get url => baseRequest?.url;

  /// TODO(docs)
  SimpleHttpClientErrorResponseException(
      this.errorResponseBody, this.baseRequest, this.statusCode);

  @override
  String toString() =>
      'SimpleHttpClientErrorResponseException{errorResponseBody: $errorResponseBody,'
      ' baseRequest: $baseRequest, statusCode: $statusCode}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleHttpClientErrorResponseException &&
          runtimeType == other.runtimeType &&
          errorResponseBody == other.errorResponseBody &&
          baseRequest == other.baseRequest &&
          statusCode == other.statusCode;

  @override
  int get hashCode =>
      errorResponseBody.hashCode ^ baseRequest.hashCode ^ statusCode.hashCode;
}
