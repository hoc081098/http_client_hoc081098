import 'dart:io';

import 'package:http_client_hoc081098/http_client_hoc081098.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../mock.mocks.dart';
import '../utils.dart';

void main() {
  group('SimpleHttpClient.get', () {
    late SimpleHttpClient simpleClient;
    late MockClient mockClient;
    final requests = <http.BaseRequest>[];

    setUp(() {
      mockClient = MockClient();
      simpleClient = SimpleHttpClient(
        client: mockClient,
        requestInterceptors: [
          (req) {
            requests.add(req);
            return req;
          }
        ],
      );
    });

    tearDown(() {
      simpleClient.close();
      requests.clear();
    });

    test('200 response', () async {
      when(mockClient.send(any)).thenAnswer(
        (_) => responseToStreamedResponse(
          http.Response(
            getFixtureString('user.json'),
            200,
          ),
        ),
      );

      final response = await simpleClient.get(getUri('users/1'));
      verify(mockClient.send(any)).called(1);

      expect(response.statusCode, 200);
      expect(response.body, getFixtureString('user.json'));

      expect(requests.length, 1);
      expect(requests[0].url, getUri('users/1'));
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

      final response = await simpleClient.get(getUri('users/1'));
      verify(mockClient.send(any)).called(1);

      expect(response.statusCode, 500);
      expect(response.body, getFixtureString('error.json'));

      expect(requests.length, 1);
      expect(requests[0].url, getUri('users/1'));
    });

    test('throw exception', () async {
      when(mockClient.send(any)).thenAnswer(
        (_) => throw const SocketException.closed(),
      );

      await expectLater(
        simpleClient.get(getUri('users/1')),
        throwsA(isA<SocketException>()),
      );
      verify(mockClient.send(any)).called(1);

      expect(requests.length, 1);
      expect(requests[0].url, getUri('users/1'));
    });
  });
}
