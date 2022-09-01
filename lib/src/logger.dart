import 'package:http/http.dart' as http;

import 'simple_http_client.dart';

// ignore_for_file: prefer_function_declarations_over_variables

/// An interceptor which logs request and response information.
///
/// The format of the logs created by this class should not be considered stable and may
/// change slightly between releases. If you need a stable logging format, use your own interceptor.
class SimpleHttpClientLoggingInterceptor {
  /// The logger used to log messages.
  final SimpleHttpClientLogger logger;

  /// Construct a [SimpleHttpClientLoggingInterceptor] with a [logger].
  SimpleHttpClientLoggingInterceptor(this.logger);

  /// A [RequestInterceptor] which logs request information.
  late final RequestInterceptor requestInterceptor = (request) {
    logger.logRequest(request);
    return request;
  };

  /// A [ResponseInterceptor] which logs response information.
  late final ResponseInterceptor responseInterceptor =
      (_, response) => logger.logResponse(response);
}

/// TODO(docs)
typedef LoggerFunction = void Function(String message);

/// TODO(docs)
abstract class SimpleHttpClientLogger {
  /// Logging HTTP request.
  void logRequest(http.BaseRequest request);

  /// Logging HTTP response.
  void logResponse(http.Response response);
}

/// The log level.
enum SimpleHttpClientLogLevel {
  /// No logs.
  none,

  /// Logs request and response lines.
  ///
  /// Example:
  /// ```
  /// --> POST /greeting http/1.1 (3-byte body)
  ///
  /// <-- 200 OK (22ms, 6-byte body)
  /// ```
  basic,

  /// Logs request and response lines and their respective headers.
  ///
  /// Example:
  /// ```
  /// --> POST /greeting http/1.1
  /// Host: example.com
  /// Content-Type: plain/text
  /// Content-Length: 3
  /// --> END POST
  ///
  /// <-- 200 OK (22ms)
  /// Content-Type: plain/text
  /// Content-Length: 6
  /// <-- END HTTP
  /// ```
  headers,

  /// Logs request and response lines and their respective headers and bodies (if present).
  ///
  /// Example:
  /// ```
  /// --> POST /greeting http/1.1
  /// Host: example.com
  /// Content-Type: plain/text
  /// Content-Length: 3
  ///
  /// Hi?
  /// --> END POST
  ///
  /// <-- 200 OK (22ms)
  /// Content-Type: plain/text
  /// Content-Length: 6
  ///
  /// Hello!
  /// <-- END HTTP
  /// ```
  body,
}

/// The default implementation of [SimpleHttpClientLogger] that logs request and response information.
class DefaultSimpleHttpClientLogger implements SimpleHttpClientLogger {
  /// TODO(docs)
  static const defaultTag = '🚀 [SIMPLE-HTTP-CLIENT] ';

  final LoggerFunction _loggerFunction;

  /// Logging level.
  final SimpleHttpClientLogLevel level;
  final Set<String> _headersToRedact;

  /// TODO(docs)
  DefaultSimpleHttpClientLogger({
    LoggerFunction loggerFunction = print,
    this.level = SimpleHttpClientLogLevel.none,
    String tag = defaultTag,
    Set<String> headersToRedact = const <String>{},
  })  : _loggerFunction = ((s) => loggerFunction(tag + s)),
        _headersToRedact = Set.unmodifiable(headersToRedact);

  @override
  void logRequest(http.BaseRequest request) {
    if (level == SimpleHttpClientLogLevel.none) {
      return;
    }

    _logRequest(
      request: request,
      includeBody: level == SimpleHttpClientLogLevel.body,
      includeHeaders: level == SimpleHttpClientLogLevel.headers ||
          level == SimpleHttpClientLogLevel.body,
    );
  }

  @override
  void logResponse(http.Response response) {
    if (level == SimpleHttpClientLogLevel.none) {
      return;
    }

    _logResponse(
      response: response,
      includeBody: level == SimpleHttpClientLogLevel.body,
      includeHeaders: level == SimpleHttpClientLogLevel.headers ||
          level == SimpleHttpClientLogLevel.body,
    );
  }

  void _logRequest({
    required http.BaseRequest request,
    required bool includeBody,
    required bool includeHeaders,
  }) {
    var requestStartMessage = '--> $request';
    if (!includeHeaders) {
      final contentLength = request.contentLength;
      final bodySize =
          contentLength != null ? '$contentLength-byte' : 'unknown-length';
      requestStartMessage += ' ($bodySize body)';
    }
    _loggerFunction(requestStartMessage);

    if (includeHeaders) {
      request.headers.forEach((name, value) => _logHeader(name, value));

      final contentLength = request.contentLength;
      if (contentLength != null) {
        _loggerFunction('${_indent}content-length: $contentLength');
      }
    }

    if (includeBody) {
      if (request is http.Request) {
        _loggerFunction('${_indent}bodyBytes: ${request.bodyBytes.length}');
        try {
          _loggerFunction('${_indent}body: ' + request.body);
        } catch (_) {}

        try {
          _loggerFunction('${_indent}bodyFields: ${request.bodyFields}');
        } catch (_) {}
      } else if (request is http.MultipartRequest) {
        _loggerFunction('${_indent}fields: ${request.fields}');
        _loggerFunction('${_indent}files: ${request.files}');
      }
    }

    _loggerFunction('--> END ${request.method}\n');
  }

  void _logHeader(String name, String value) {
    final v = _headersToRedact.contains(name) ? '██' : value;
    _loggerFunction(_indent + name + ': ' + v);
  }

  void _logResponse({
    required http.Response response,
    required bool includeBody,
    required bool includeHeaders,
  }) {
    final reasonPhrase = response.reasonPhrase;
    final reasonPhraseIfNotEmpty =
        reasonPhrase == null || reasonPhrase.isEmpty ? '' : ' $reasonPhrase';

    var message =
        '<-- ${response.statusCode}$reasonPhraseIfNotEmpty ${response.request}';
    if (!includeHeaders) {
      final contentLength = response.contentLength;
      final bodySize =
          contentLength != null ? '$contentLength-byte' : 'unknown-length';
      message += ' ($bodySize body)';
    }
    _loggerFunction(message);

    if (includeHeaders) {
      response.headers.forEach((name, value) => _logHeader(name, value));

      final contentLength = response.contentLength;
      if (contentLength != null) {
        _loggerFunction('${_indent}content-length: $contentLength');
      }
    }

    if (includeBody) {
      _loggerFunction('${_indent}bodyBytes: ${response.bodyBytes.length}');

      try {
        _loggerFunction('${_indent}body: ' + response.body);
      } catch (_) {}
    }

    _loggerFunction('<-- END HTTP');
  }
}

const _indent = '  • ';
