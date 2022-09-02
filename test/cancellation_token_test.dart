import 'package:http_client_hoc081098/http_client_hoc081098.dart';
import 'package:http_client_hoc081098/src/cancellation_token.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('CancellationToken', () {
    group('cancellationGuard', () {
      test('do not cancel', () {
        {
          final token = CancellationToken();
          final future = cancellationGuard(token, () async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            return 42;
          });
          expect(future, completion(42));
        }

        {
          final token = CancellationToken();
          final future = cancellationGuard(token, () async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            throw Exception();
          });
          expect(future, throwsException);
        }
      });

      test('cancel', () async {
        final list = <int>[];
        final token = CancellationToken();
        final future = cancellationGuard(token, () async {
          list.add(1);

          await Future<void>.delayed(const Duration(milliseconds: 100));

          list.add(2);

          token.guard(StackTrace.current);

          list.add(3);

          await Future<void>.delayed(const Duration(milliseconds: 500));

          list.add(4);

          token.guard(StackTrace.current);

          await Future<void>.delayed(const Duration(milliseconds: 500));

          list.add(5);

          return 42;
        });

        await Future<void>.delayed(const Duration(milliseconds: 100));
        token.cancel();

        await expectLater(
            future, throwsA(isA<SimpleHttpClientCancellationException>()));
        expect(list, [1, 2, 3]);
      });
    });
  });
}
