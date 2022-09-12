import 'dart:io';

import 'package:http_client_hoc081098/http_client_hoc081098.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../mock.mocks.dart';
import '../utils.dart';

void main() {
  group('SimpleHttpClient.put', () {
    late SimpleHttpClient simpleClient;
    late MockClient mockClient;
    final requestsSpy = RequestsSpy();

    setUp(() {
      mockClient = MockClient();
      simpleClient = SimpleHttpClient(
        client: mockClient,
        requestInterceptors: [requestsSpy],
      );
    });

    tearDown(() {
      simpleClient.close();
      requestsSpy.clear();
    });

    test('200 response', () async {
      when(mockClient.send(any)).thenAnswer(
        (_) => responseToStreamedResponse(
          http.Response(
            getFixtureString('user.json'),
            201,
          ),
        ),
      );

      final response = await simpleClient.put(
        getUri('users'),
        body: getFixtureString('user.json'),
        headers: mockHeaders,
      );
      verify(mockClient.send(any)).called(1);

      expect(response.statusCode, 201);
      expect(response.body, getFixtureString('user.json'));

      expect(requestsSpy.requests.length, 1);
      expect(requestsSpy.requests[0].url, getUri('users'));
      expect(
        (requestsSpy.requests[0] as http.Request).body,
        getFixtureString('user.json'),
      );
      expectMockHeaders(requestsSpy.requests[0]);
    });

    test('non-200 response', () async {
      when(mockClient.send(any)).thenAnswer(
        (_) => responseToStreamedResponse(
          http.Response(
            getFixtureString('error.json'),
            500,
          ),
        ),
      );

      final response = await simpleClient.put(
        getUri('users'),
        body: getFixtureString('user.json'),
        headers: mockHeaders,
      );
      verify(mockClient.send(any)).called(1);

      expect(response.statusCode, 500);
      expect(response.body, getFixtureString('error.json'));

      expect(requestsSpy.requests.length, 1);
      expect(requestsSpy.requests[0].url, getUri('users'));
      expect(
        (requestsSpy.requests[0] as http.Request).body,
        getFixtureString('user.json'),
      );
      expectMockHeaders(requestsSpy.requests[0]);
    });

    test('throw exception', () async {
      when(mockClient.send(any)).thenAnswer(
        (_) => throw const SocketException.closed(),
      );

      await expectLater(
        simpleClient.put(
          getUri('users'),
          body: getFixtureString('user.json'),
          headers: mockHeaders,
        ),
        throwsA(isA<SocketException>()),
      );
      verify(mockClient.send(any)).called(1);

      expect(requestsSpy.requests.length, 1);
      expect(requestsSpy.requests[0].url, getUri('users'));
      expect(
        (requestsSpy.requests[0] as http.Request).body,
        getFixtureString('user.json'),
      );
      expectMockHeaders(requestsSpy.requests[0]);
    });

    test('cancel', () async {
      when(mockClient.send(any)).thenAnswer(
        (_) => responseToStreamedResponse(
          http.Response(
            getFixtureString('user.json'),
            201,
          ),
        ),
      );
      final cancelToken = CancellationToken();

      final future = expectLater(
        simpleClient.put(
          getUri('users'),
          body: getFixtureString('user.json'),
          headers: mockHeaders,
          cancelToken: cancelToken,
        ),
        throwsACancellationException,
      );
      cancelToken.cancel();

      await future;
      verifyNever(mockClient.send(any));
      expect(requestsSpy.requests.isEmpty, isTrue);
    });
  });
}
