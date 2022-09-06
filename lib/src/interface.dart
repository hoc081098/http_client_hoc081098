import 'dart:async';
import 'dart:convert';

import 'package:cancellation_token_hoc081098/cancellation_token_hoc081098.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'default_simple_http_client.dart';
import 'exception.dart';

import 'dart:typed_data';

/// TODO(docs)
typedef RequestInterceptor = FutureOr<http.BaseRequest> Function(
    http.BaseRequest request);

/// TODO(docs)
typedef ResponseInterceptor = FutureOr<http.Response> Function(
    http.BaseRequest request, http.Response response);

/// TODO(docs)
typedef JsonDecoderFunction = dynamic Function(String source);

/// TODO(docs)
typedef JsonEncoderFunction = String Function(Object object);

/// TODO(docs)
@sealed
abstract class SimpleHttpClient {
  /// JSON utf8 content type.
  static const jsonUtf8ContentType = 'application/json; charset=utf-8';

  /// Multi-part form data content type.
  static const multipartContentType = 'multipart/form-data';

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
      DefaultSimpleHttpClient(
        client: client,
        timeout: timeout,
        requestInterceptors: requestInterceptors,
        responseInterceptors: responseInterceptors,
        jsonDecoder: jsonDecoder,
        jsonEncoder: jsonEncoder,
      );

  /// Sends an HTTP request and asynchronously returns the response.
  Future<http.Response> send(
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
    Object? body,
    CancellationToken? cancelToken,
  });

  /// TODO(docs)
  Future<dynamic> putJson(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    CancellationToken? cancelToken,
  });

  /// TODO(docs)
  Future<dynamic> deleteJson(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  });

  //
  //
  //

  /// TODO(docs)
  Future<http.Response> head(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  });

  /// TODO(docs)
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  });

  /// TODO(docs)
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancellationToken? cancelToken,
  });

  /// TODO(docs)
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancellationToken? cancelToken,
  });

  /// TODO(docs)
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancellationToken? cancelToken,
  });

  /// TODO(docs)
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancellationToken? cancelToken,
  });

  /// TODO(docs)
  Future<String> read(
    Uri url, {
    Map<String, String>? headers,
    CancellationToken? cancelToken,
  });

  /// TODO(docs)
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
