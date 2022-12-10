import 'dart:convert';
import 'dart:io';

import 'package:cancellation_token_hoc081098/cancellation_token_hoc081098.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

Uri getUri(String unencodedPath) => Uri.https('hoc081098.com', unencodedPath);

String getFixtureString(String name) =>
    File('test/fixtures/$name').readAsStringSync();

dynamic getFixtureJson(String name) => jsonDecode(getFixtureString(name));

Future<http.StreamedResponse> responseToStreamedResponse(
        http.Response response) async =>
    http.StreamedResponse(
      http.ByteStream.fromBytes(response.bodyBytes),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );

const _key = 'custom-header';
const _value = 'custom-value';

const mockHeaders = {_key: _value};

final throwsACancellationException = throwsA(isA<CancellationException>());

void expectMockHeaders(http.BaseRequest request) =>
    expect(request.headers[_key], _value);

class RequestsSpy {
  final _requests = <http.BaseRequest>[];
  final _onCallListeners = <void Function(http.BaseRequest)>[];

  void clear() {
    _requests.clear();
    _onCallListeners.clear();
  }

  void addOnCallListener(void Function(http.BaseRequest) listener) =>
      _onCallListeners.add(listener);

  List<http.BaseRequest> get requests => List.unmodifiable(_requests);

  http.BaseRequest call(http.BaseRequest req) {
    for (final f in _onCallListeners) {
      f(req);
    }
    _requests.add(req);
    return req;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestsSpy &&
          runtimeType == other.runtimeType &&
          const ListEquality<http.BaseRequest>()
              .equals(_requests, other._requests);

  @override
  int get hashCode => const ListEquality<http.BaseRequest>().hash(_requests);

  @override
  String toString() => 'RequestsSpy{requests: $_requests}';
}

class ResponseSpy {
  final _responses = <http.Response>[];

  void clear() => _responses.clear();

  List<http.Response> get responses => List.unmodifiable(_responses);

  http.Response call(http.BaseRequest request, http.Response response) {
    _responses.add(response);
    return response;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponseSpy &&
          runtimeType == other.runtimeType &&
          const ListEquality<http.Response>()
              .equals(_responses, other.responses);

  @override
  int get hashCode => const ListEquality<http.Response>().hash(_responses);
}
