import 'package:http/http.dart';

/// TODO(docs)
class SimpleHttpClientTimeoutException implements Exception {
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
class SimpleHttpClientException implements Exception {
  /// TODO(docs)
  final String errorResponseBody;

  /// TODO(docs)
  final BaseRequest? baseRequest;

  /// TODO(docs)
  final int statusCode;

  /// The URL to which the request will be sent.
  Uri? get url => baseRequest?.url;

  /// TODO(docs)
  SimpleHttpClientException(
      this.errorResponseBody, this.baseRequest, this.statusCode);

  @override
  String toString() =>
      'SimpleHttpClientException{errorResponseBody: $errorResponseBody, baseRequest: $baseRequest, statusCode: $statusCode}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleHttpClientException &&
          runtimeType == other.runtimeType &&
          errorResponseBody == other.errorResponseBody &&
          baseRequest == other.baseRequest &&
          statusCode == other.statusCode;

  @override
  int get hashCode =>
      errorResponseBody.hashCode ^ baseRequest.hashCode ^ statusCode.hashCode;
}
