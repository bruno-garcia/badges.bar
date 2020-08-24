import 'dart:isolate';

import 'package:sentry/sentry.dart';

void install(SentryClient client) {
  Isolate.current.addSentryErrorListener(client);
}

extension IsolateExtensions on Isolate {
  void addSentryErrorListener(SentryClient sentry) {
    var receivePort = RawReceivePort((dynamic values) async {
      await sentry.captureIsolateError(values);
    });

    Isolate.current.addErrorListener(receivePort.sendPort);
  }
}

extension SentryExtensions on SentryClient {
  Future<void> captureIsolateError(dynamic error) {
    if (error is List<dynamic> && error.length != 2) {
      /// https://api.dart.dev/stable/2.9.0/dart-isolate/Isolate/addErrorListener.html
      var stackTrace = error[1];
      if (stackTrace != null) {
        stackTrace = StackTrace.fromString(stackTrace);
      }
      return captureException(exception: error[0], stackTrace: stackTrace);
    } else {
      // not a valid isolate error
      return Future.value();
    }
  }
}
