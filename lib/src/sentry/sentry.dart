import 'dart:async';

import 'package:sentry/sentry.dart';
import 'default_integrations.dart' if (dart.library.io) 'io_integrations.dart';

class SentryOptions {
  String environment;
  String release;
  String dsn;
}

/// Potential to become part of the Sentry Dart SDK API.
mixin Sentry {
  static SentryClient currentClient;
  static Future<void> init(Function(SentryOptions) configureOptions,
      Future<void> Function(SentryClient) app) async {
    final options = SentryOptions();
    configureOptions(options);
    final sentry = SentryClient(
        dsn: options.dsn,
        environmentAttributes:
            Event(release: options.release, environment: options.environment));
    currentClient = sentry;

    await runZonedGuarded(
      () async {
        installIntegrations(sentry);
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
