import 'dart:io';

import 'package:http_client_hoc081098/http_client_hoc081098.dart';
import 'package:http/http.dart' as http;

import 'user.dart';

void main() async {
  final loggingInterceptor = SimpleLoggingInterceptor(
    DefaultSimpleHttpClientLogger(
      level: SimpleLogLevel.body,
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

  final cancelToken = CancellationToken();
  final uri = Uri.parse('https://jsonplaceholder.typicode.com/users/1');

  // ignore: unawaited_futures
  () async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    cancelToken.cancel();
    print('Cancelling...');
  }();

  try {
    final json = await client.getJson(uri,
        headers: {}, cancelToken: cancelToken) as Map<String, dynamic>;
    print(json);
  } catch (e) {
    print(e);
  }

  print('-' * 128);

  final single = useCancellationToken<dynamic>(
    (cancelToken) => client.getJson(
      Uri.parse('https://jsonplaceholder.typicode.com/users/2'),
      headers: {},
      cancelToken: cancelToken,
    ),
  ).cast<Map<String, dynamic>>().map(User.fromJson);
  final subscription = single.listen(print, onError: print);

  // ignore: unawaited_futures
  () async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await subscription.cancel();
    print('Cancelling single...');
    // client.close();
  }();

  await Future<void>.delayed(const Duration(seconds: 1));
  print('-' * 128);

  try {
    final json = await client.postJson(
      Uri.parse('https://jsonplaceholder.typicode.com/users'),
      body: {
        'name': 'hoc081098',
        'username': 'hoc081098',
        'email': 'hoc081098@gmail.com',
      },
    ) as Map<String, dynamic>;
    print(json);
  } catch (e) {
    print(e);
  }
}
