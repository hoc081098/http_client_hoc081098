import 'dart:async';
import 'dart:convert';

import 'package:cancellation_token_hoc081098/cancellation_token_hoc081098.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'default_simple_http_client.dart';
import 'exception.dart';

import 'dart:typed_data';

/// If one or more request interceptors are set, they will be called before the
/// request is sent to allow for modification of the original request.
///
/// Usually this is used to add other headers (such as authentication headers)
/// to the request or log the request, ...
typedef RequestInterceptor = FutureOr<http.BaseRequest> Function(
    http.BaseRequest request);

/// Used to able to modify the response before it is returned to the caller.
///
/// Usually this is used to log the response, retry the request, transform the
/// response body, refresh the access token, ...
typedef ResponseInterceptor = FutureOr<http.Response> Function(
    http.BaseRequest request, http.Response response);

/// A function used to parse the string and returns the resulting JSON object.
typedef JsonDecoderFunction = dynamic Function(String source);

/// A function used to convert the object to a JSON string.
typedef JsonEncoderFunction = String Function(Object object);

/// TODO(docs)
@sealed
abstract class SimpleHttpClient {
  /// JSON utf8 content type.
  static const jsonUtf8ContentType = 'application/json; charset=utf-8';

  /// Multipart form data content type.
  static const multipartFormDataContentType = 'multipart/form-data';

  /// Construct a new [SimpleHttpClient].
  /// Parameters:
  /// * [client]: The underlying HTTP client.
  /// * [requestInterceptors]: The request interceptors.
  /// * [responseInterceptors]: The response interceptors.
  /// * [jsonDecoder]: The function used to parse strings to JSON object.
  /// * [jsonEncoder]: The JSON encoder used to convert a object to JSON string.
  factory SimpleHttpClient({
    required http.Client client,
    Duration? timeout,
    List<RequestInterceptor> requestInterceptors = const <RequestInterceptor>[],
    List<ResponseInterceptor> responseInterceptors =
        const <ResponseInterceptor>[],
    JsonDecoderFunction jsonDecoder = jsonDecode,
    JsonEncoderFunction jsonEncoder = jsonEncode,
  }) =>
      DefaultSimpleHttpClient(
        client: client,
        timeout: timeout,
        requestInterceptors: requestInterceptors,
        responseInterceptors: responseInterceptors,
        jsonDecoder: jsonDecoder,
        jsonEncoder: jsonEncoder,
      );

  /// Sends an HTTP request and asynchronously returns the response.
  ///
  /// The [cancelToken] is used to cancel the [request].
  /// Throws [SimpleTimeoutException] if sending request and receiving response timeout.
  /// When the response status code is not `2xx`, the result [Future] do NOT
  /// throws [SimpleErrorResponseException], it returns the response as normal.
  Future<http.Response> send(
    http.BaseRequest request, {
    CancellationToken? cancelToken,
  });

  //
  //
  //

  /// Sends an HTTP GET request with the given headers to the given URL.
  /// The `content-type` of the request will be set to [jsonUtf8ContentType].
  /// Returns the parsed JSON object.
  ///
  /// The [cancelToken] is used to cancel the request.
  /// Throws [SimpleErrorResponseException] if the response status code is not `2xx`.
  /// Throws [SimpleTimeoutException] if sending request and receiving response timeout.
  ///
  /// For more fine-grained control over the request, use [send] or [get] instead.
  Future<dynamic> getJson(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  });

  /// Sends an Multipart Form Data HTTP POST request with the given headers, [files] and [fields]
  /// to the given URL.
  ///
  /// [files] is the list of files to upload for this request.
  /// [fields] is the form fields to send for this request.
  /// The `content-type` header of the request will be set to [multipartFormDataContentType].
  /// Returns the parsed JSON object.
  ///
  /// The [cancelToken] is used to cancel the request.
  /// Throws [SimpleErrorResponseException] if the response status code is not `2xx`.
  /// Throws [SimpleTimeoutException] if sending request and receiving response timeout.
  ///
  /// For more fine-grained control over the request, use [send] or [post] instead.
  Future<dynamic> postMultipart(
    Uri url,
    List<http.MultipartFile> files, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    CancellationToken? cancelToken,
  });

  /// Sends an HTTP POST request with the given headers and body to the given
  /// URL.
  ///
  /// The `content-type` header of the request will be set to [jsonUtf8ContentType].
  /// The [body] will be encoded as JSON string.
  /// Returns the parsed JSON object.
  ///
  /// The [cancelToken] is used to cancel the request.
  /// Throws [SimpleErrorResponseException] if the response status code is not `2xx`.
  /// Throws [SimpleTimeoutException] if sending request and receiving response timeout.
  ///
  /// For more fine-grained control over the request, use [send] or [post] instead.
  Future<dynamic> postJson(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    CancellationToken? cancelToken,
  });

  /// Sends an HTTP PUT request with the given headers and body to the given
  /// URL.
  ///
  /// The `content-type` header of the request will be set to [jsonUtf8ContentType].
  /// The [body] will be encoded as JSON string.
  /// Returns the parsed JSON object.
  ///
  /// The [cancelToken] is used to cancel the request.
  /// Throws [SimpleErrorResponseException] if the response status code is not `2xx`.
  /// Throws [SimpleTimeoutException] if sending request and receiving response timeout.
  ///
  /// For more fine-grained control over the request, use [send] or [put] instead.
  Future<dynamic> putJson(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    CancellationToken? cancelToken,
  });

  /// Sends an HTTP DELETE request with the given headers to the given URL.
  ///
  /// The [cancelToken] is used to cancel the request.
  /// Throws [SimpleTimeoutException] if sending request and receiving response timeout.
  /// When the response status code is not `2xx`, the result [Future] do NOT
  /// throws [SimpleErrorResponseException], it returns the response as normal.
  ///
  /// For more fine-grained control over the request, use [send] or [delete] instead.
  Future<dynamic> deleteJson(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  });

  //
  //
  //

  /// Sends an HTTP HEAD request with the given headers to the given URL.
  ///
  /// The [cancelToken] is used to cancel the request.
  /// Throws [SimpleTimeoutException] if sending request and receiving response timeout.
  /// When the response status code is not `2xx`, the result [Future] do NOT
  /// throws [SimpleErrorResponseException], it returns the response as normal.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<http.Response> head(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  });

  /// Sends an HTTP GET request with the given headers to the given URL.
  ///
  /// The [cancelToken] is used to cancel the request.
  /// Throws [SimpleTimeoutException] if sending request and receiving response timeout.
  /// When the response status code is not `2xx`, the result [Future] do NOT
  /// throws [SimpleErrorResponseException], it returns the response as normal.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  });

  /// Sends an HTTP POST request with the given headers and body to the given
  /// URL.
  ///
  /// [body] sets the body of the request. It can be a [String], a [List<int>]
  /// or a [Map<String, String>].
  ///
  /// If [body] is a String, it's encoded using [encoding] and used as the body
  /// of the request. The content-type of the request will default to
  /// "text/plain".
  ///
  /// If [body] is a List, it's used as a list of bytes for the body of the
  /// request.
  ///
  /// If [body] is a Map, it's encoded as form fields using [encoding]. The
  /// content-type of the request will be set to
  /// `"application/x-www-form-urlencoded"`; this cannot be overridden.
  ///
  /// [encoding] defaults to [utf8].
  ///
  /// The [cancelToken] is used to cancel the request.
  /// Throws [SimpleTimeoutException] if sending request and receiving response timeout.
  /// When the response status code is not `2xx`, the result [Future] do NOT
  /// throws [SimpleErrorResponseException], it returns the response as normal.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancellationToken? cancelToken,
  });

  /// Sends an HTTP PUT request with the given headers and body to the given
  /// URL.
  ///
  /// [body] sets the body of the request. It can be a [String], a [List<int>]
  /// or a [Map<String, String>]. If it's a String, it's encoded using
  /// [encoding] and used as the body of the request. The content-type of the
  /// request will default to "text/plain".
  ///
  /// If [body] is a List, it's used as a list of bytes for the body of the
  /// request.
  ///
  /// If [body] is a Map, it's encoded as form fields using [encoding]. The
  /// content-type of the request will be set to
  /// `"application/x-www-form-urlencoded"`; this cannot be overridden.
  ///
  /// [encoding] defaults to [utf8].
  ///
  /// The [cancelToken] is used to cancel the request.
  /// Throws [SimpleTimeoutException] if sending request and receiving response timeout.
  /// When the response status code is not `2xx`, the result [Future] do NOT
  /// throws [SimpleErrorResponseException], it returns the response as normal.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancellationToken? cancelToken,
  });

  /// Sends an HTTP PATCH request with the given headers and body to the given
  /// URL.
  ///
  /// [body] sets the body of the request. It can be a [String], a [List<int>]
  /// or a [Map<String, String>]. If it's a String, it's encoded using
  /// [encoding] and used as the body of the request. The content-type of the
  /// request will default to "text/plain".
  ///
  /// If [body] is a List, it's used as a list of bytes for the body of the
  /// request.
  ///
  /// If [body] is a Map, it's encoded as form fields using [encoding]. The
  /// content-type of the request will be set to
  /// `"application/x-www-form-urlencoded"`; this cannot be overridden.
  ///
  /// [encoding] defaults to [utf8].
  ///
  /// The [cancelToken] is used to cancel the request.
  /// Throws [SimpleTimeoutException] if sending request and receiving response timeout.
  /// When the response status code is not `2xx`, the result [Future] do NOT
  /// throws [SimpleErrorResponseException], it returns the response as normal.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancellationToken? cancelToken,
  });

  /// Sends an HTTP DELETE request with the given headers to the given URL.
  ///
  /// The [cancelToken] is used to cancel the request.
  /// Throws [SimpleTimeoutException] if sending request and receiving response timeout.
  /// When the response status code is not `2xx`, the result [Future] do NOT
  /// throws [SimpleErrorResponseException], it returns the response as normal.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancellationToken? cancelToken,
  });

  /// Sends an HTTP GET request with the given headers to the given URL and
  /// returns a Future that completes to the body of the response as a String.
  ///
  /// The Future will emit a [ClientException] if the response doesn't have a
  /// success status code.
  ///
  /// The [cancelToken] is used to cancel the request.
  /// Throws [SimpleTimeoutException] if sending request and receiving response timeout.
  /// When the response status code is not `2xx`, the result [Future] do NOT
  /// throws [SimpleErrorResponseException], it returns the response as normal.
  ///
  /// For more fine-grained control over the request and response, use [send] or
  /// [get] instead.
  Future<String> read(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  });

  /// Sends an HTTP GET request with the given headers to the given URL and
  /// returns a Future that completes to the body of the response as a list of
  /// bytes.
  ///
  /// The Future will emit a [ClientException] if the response doesn't have a
  /// success status code.
  ///
  /// The [cancelToken] is used to cancel the request.
  /// Throws [SimpleTimeoutException] if sending request and receiving response timeout.
  /// When the response status code is not `2xx`, the result [Future] do NOT
  /// throws [SimpleErrorResponseException], it returns the response as normal.
  ///
  /// For more fine-grained control over the request and response, use [send] or
  /// [get] instead.
  Future<Uint8List> readBytes(
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
