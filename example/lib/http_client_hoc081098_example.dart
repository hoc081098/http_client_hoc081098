import 'dart:io';

import 'package:http_client_hoc081098/http_client_hoc081098.dart';
import 'package:http/http.dart' as http;

void main() async {
  final cancelToken = CancellationToken();

  final loggingInterceptor = SimpleHttpClientLoggingInterceptor(
    DefaultSimpleHttpClientLogger(
      level: SimpleHttpClientLogLevel.body,
      headersToRedact: {
        HttpHeaders.authorizationHeader,
      },
    ),
  );

  final client = SimpleHttpClient(
    client: http.Client(),
    timeout: const Duration(seconds: 10),
    requestInterceptors: [
      (request) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final token = 'hoc081098';
        request.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';

        return request;
      },
      loggingInterceptor.requestInterceptor,
    ],
    responseInterceptors: [
      loggingInterceptor.responseInterceptor,
    ],
  );

  final uri = Uri.parse('https://jsonplaceholder.typicode.com/users/1');

  final dynamic json = await client.getJson(
    uri,
    headers: {},
    cancelToken: cancelToken,
  );
  print('Done $json');
}
