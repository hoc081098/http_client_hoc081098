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

    test('success', () async {
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

    test('failure', () async {
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
  });
}
