import 'dart:convert';
import 'dart:io';

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

void expectMockHeaders(http.BaseRequest request) =>
    expect(request.headers[_key], _value);

class RequestsSpy {
  final _requests = <http.BaseRequest>[];

  void clear() => _requests.clear();

  List<http.BaseRequest> get requests => List.unmodifiable(_requests);

  http.BaseRequest call(http.BaseRequest req) {
    _requests.add(req);
    return req;
  }
}
