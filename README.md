# http_client_hoc081098

Simple and powerful HTTP client for Flutter and Dart application.

[![codecov](https://codecov.io/gh/hoc081098/http_client_hoc081098/graph/badge.svg?token=TNspe4aF8b)](https://codecov.io/gh/hoc081098/http_client_hoc081098)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fhoc081098%2Fhttp_client_hoc081098&count_bg=%239858E5&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)

```dart
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/retry.dart' as httpRetry;
import 'package:http_client_hoc081098/http_client_hoc081098.dart';

import 'user.dart';

void main() async {
  final loggingInterceptor = SimpleLoggingInterceptor(
    SimpleLogger(
      level: SimpleLogLevel.body,
      headersToRedact: {
        HttpHeaders.authorizationHeader,
      },
    ),
  );

  final innerClient = httpRetry.RetryClient(
    http.Client(),
    retries: 3,
    when: (response) {
      print(
          '[RetryClient] Checking response: request=${response.request} statusCode=${response.statusCode}');
      print('-' * 128);
      return response.statusCode == HttpStatus.unauthorized;
    },
    onRetry: (request, response, retryCount) async {
      print(
          '[RetryClient] Retrying request: request=$request, response=$response, retryCount=$retryCount');
      // Simulate refreshing token
      await Future<void>.delayed(const Duration(seconds: 1));
      print('-' * 128);
    },
  );

  final client = SimpleHttpClient(
    client: innerClient,
    timeout: const Duration(seconds: 10),
    requestInterceptors: [
      (request) async {
        print('[requestInterceptors] request=$request');
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

  await getExample(client);
  print('-' * 128);

  await getSingleExample(client);
  print('-' * 128);

  await postExample(client);
  print('-' * 128);

  client.close();
  print('Client closed gratefully.');
}

Future<void> postExample(SimpleHttpClient client) async {
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

Future<void> getSingleExample(SimpleHttpClient client) async {
  final single = useCancellationToken<dynamic>(
    (cancelToken) => client.getJson(
      Uri.parse('https://jsonplaceholder.typicode.com/users/2'),
      headers: {},
      cancelToken: cancelToken,
    ),
  ).cast<Map<String, dynamic>>().map(User.fromJson);
  final subscription = single.listen(print, onError: print);

  () async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await subscription.cancel();
    print('Cancelling single...');
  }()
      .ignore();

  await Future<void>.delayed(const Duration(seconds: 1));
}

Future<void> getExample(SimpleHttpClient client) async {
  final cancelToken = CancellationToken();
  final uri = Uri.parse('https://jsonplaceholder.typicode.com/users/1');

  () async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    cancelToken.cancel();
    print('Cancelling...');
  }()
      .ignore();

  try {
    final json = await client.getJson(
      uri,
      headers: {},
      cancelToken: cancelToken,
    ) as Map<String, dynamic>;
    print(json);
  } catch (e) {
    print(e);
  }
}
```
