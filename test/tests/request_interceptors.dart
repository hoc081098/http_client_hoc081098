import 'package:http/http.dart' as http;
import 'package:http_client_hoc081098/http_client_hoc081098.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../mock.mocks.dart';
import '../utils.dart';

void main() {
  group('SimpleHttpClient.requestInterceptors', () {
    late SimpleHttpClient simpleClient;
    late MockClient mockClient;
    final requestsSpy1 = RequestsSpy();
    final requestsSpy2 = RequestsSpy();

    setUp(() {
      mockClient = MockClient();
      simpleClient = SimpleHttpClient(
        client: mockClient,
        requestInterceptors: [
          requestsSpy1.call,
          requestsSpy2.call,
        ],
      );

      when(mockClient.send(any)).thenAnswer(
        (_) => responseToStreamedResponse(
          http.Response(
            getFixtureString('user.json'),
            200,
          ),
        ),
      );
    });

    tearDown(() {
      simpleClient.close();
      requestsSpy1.clear();
      requestsSpy2.clear();
    });

    test('execute interceptors in order', () async {
      await simpleClient.get(getUri('users/1'), headers: mockHeaders);

      expect(requestsSpy1, requestsSpy2);
      expect(requestsSpy1.requests.single.url, getUri('users/1'));
      expect(requestsSpy1.requests.single.method, 'GET');
      expectMockHeaders(requestsSpy1.requests.single);
    });

    test(
      'do not run interceptors if cancel token is cancelled before sending',
      () async {
        final responseFuture = simpleClient.get(
          getUri('users/1'),
          headers: mockHeaders,
          cancelToken: CancellationToken()..cancel(),
        );

        await expectLater(responseFuture, throwsACancellationException);
        expect(requestsSpy1, requestsSpy2);
        expect(requestsSpy1.requests.isEmpty, isTrue);
      },
    );

    test(
      'cancel request if cancel token is cancelled when running the first interceptor',
      () async {
        final token = CancellationToken();
        requestsSpy1.addOnCallListener((_) => token.cancel());

        final responseFuture = simpleClient.get(
          getUri('users/1'),
          headers: mockHeaders,
          cancelToken: token,
        );

        await expectLater(responseFuture, throwsACancellationException);

        // The first interceptor is called.
        expect(requestsSpy1.requests.single.url, getUri('users/1'));
        expect(requestsSpy1.requests.single.method, 'GET');
        expectMockHeaders(requestsSpy1.requests.single);

        // The second interceptor should not be called
        expect(requestsSpy2.requests.isEmpty, isTrue);
      },
    );

    test(
      'cancel request if cancel token is cancelled when running the last interceptor',
      () async {
        final token = CancellationToken();
        requestsSpy2.addOnCallListener((_) => token.cancel());

        final responseFuture = simpleClient.get(
          getUri('users/1'),
          headers: mockHeaders,
          cancelToken: token,
        );

        await expectLater(responseFuture, throwsACancellationException);

        // Two interceptors are called with same request.
        expect(requestsSpy1, requestsSpy2);

        // The first interceptor is called.
        expect(requestsSpy1.requests.single.url, getUri('users/1'));
        expect(requestsSpy1.requests.single.method, 'GET');
        expectMockHeaders(requestsSpy1.requests.single);
      },
    );
  });
}
