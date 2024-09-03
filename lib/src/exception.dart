import 'dart:io';

import 'package:http/http.dart' as http;

import 'interface.dart';

/// Exception thrown by [SimpleHttpClient].
abstract base class SimpleHttpClientException implements Exception {
  /// The (frozen) request.
  http.BaseRequest? get request;

  const SimpleHttpClientException._();
}

/// The exception thrown by [SimpleHttpClient] when the sending of a request
/// and receiving of a response time-out.
final class SimpleTimeoutException extends SimpleHttpClientException {
  @override
  final http.BaseRequest request;

  /// The URL to which the request will be sent.
  Uri? get url => request.url;

  /// Construct a [SimpleTimeoutException] with a [request].
  SimpleTimeoutException(this.request) : super._();

  @override
  String toString() => 'SimpleTimeoutException{request: $request}';
}

/// The exception thrown by [SimpleHttpClient] when the response status code
/// is not in the 2xx range.
///
/// This exception is thrown by:
/// * [SimpleHttpClient.getJson]
/// * [SimpleHttpClient.postMultipart]
/// * [SimpleHttpClient.postJson]
/// * [SimpleHttpClient.putJson]
/// * [SimpleHttpClient.deleteJson]
final class SimpleErrorResponseException extends SimpleHttpClientException {
  /// The error response.
  final http.Response response;

  /// The (frozen) request that triggered [response].
  @override
  http.BaseRequest? get request => response.request;

  /// The HTTP status code for [response].
  int get statusCode => response.statusCode;

  /// The URL to which the request will be sent.
  Uri? get url => request?.url;

  /// The error response body
  String get errorResponseBody => response.body;

  /// Construct a [SimpleErrorResponseException] with a [response].
  SimpleErrorResponseException(this.response) : super._() {
    if (response.isSuccessful) {
      throw ArgumentError.value(
        response,
        'response',
        'statusCode must be in the 2xx range',
      );
    }
  }

  @override
  String toString() => 'SimpleErrorResponseException{response: $response}';
}

/// Provides [isSuccessful] extension methods on [http.Response].
extension ResponseExtensions on http.Response {
  /// Check if the [response] is a successful response.
  /// A successful response is a response with a status code that is in the `2xx` range.
  bool get isSuccessful =>
      HttpStatus.ok <= statusCode && statusCode < HttpStatus.multipleChoices;
}
