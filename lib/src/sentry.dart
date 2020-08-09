// Potential to become part of the Sentry Dart SDK API:
import 'dart:async';
import 'dart:isolate';

import 'package:sentry/sentry.dart';

class Sentry {
  static SentryClient currentClient;
  static Future<void> init(
      String dsn, Future<void> Function(SentryClient) app) async {
    var sentry = SentryClient(dsn: dsn);
    currentClient = sentry;

    await runZonedGuarded(
      () async {
        Isolate.current.addSentryErrorListener(sentry);
        await app(sentry);
      },
      (error, stackTrace) async {
        try {
          await sentry.captureException(
            exception: error,
            stackTrace: stackTrace,
          );
          print('Error sent to sentry.io: $error');
        } catch (e) {
          print('Capture failed: $e');
          print('Original error: $error');
        }
      },
    );
  }

  static Future<void> captureException(dynamic exception, dynamic stackTrace) {
    return currentClient?.captureException(
        exception: exception, stackTrace: stackTrace);
  }

  static Future<void> captureEvent(Event event) {
    return currentClient?.capture(event: event);
  }
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
      // not valid isolate error
      return Future.value();
    }
  }
}
