import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:badges_bar/src/pedantic.dart';
import 'package:badges_bar/src/pub_client.dart';
import 'package:sentry/sentry.dart';
import 'package:http/http.dart' as http;

import 'package:badges_bar/badges_bar.dart';

/// Starts a server that generates SVG badges for pub.dev scores.
Future<void> main() async {
  await Sentry.init((SentryOptions o) {
    o.dsn =
        'https://09a6dc7f166e467793a5d2bc7c7a7df2@o117736.ingest.sentry.io/1857674';
    o.release = Platform.environment['VERSION'];
    o.environment = Platform.environment['ENVIRONMENT'];
  });
  Isolate.current.addSentryErrorListener();

  // Should go into Sentry
  await runZonedGuarded(
    () async {
      await _run();
    },
    (error, stackTrace) async {
      try {
        await Sentry.captureException(
          error,
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

Future<void> _run() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 31337;
  final address =
      isProduction ? InternetAddress.anyIPv4 : InternetAddress.loopbackIPv4;
  final server = await HttpServer.bind(address, port);

  print('''Running: 
  Version: ${Platform.environment['VERSION']} 
  Environment: ${Platform.environment['ENVIRONMENT']}
  Endpoint: http://${address.address}:${server.port}''');

  final httpClient = http.Client();
  final client = PubClient(httpClient);
  try {
    var counter = 0;
    await for (final request in server) {
      try {
        final serveFuture = _serve(request, client);
        if (isProduction) {
          unawaited(serveFuture.catchError((dynamic e, dynamic s) async {
            request.response.trySetServerError();
            return await Sentry.captureException(e, stackTrace: s);
          }).whenComplete(() => request.response.close()));
        } else {
          final current = counter++;
          print('Starting to serve request: $current');
          unawaited(serveFuture.catchError((dynamic e, dynamic s) {
            print('$e\n$s');
            request.response.trySetServerError();
          }).whenComplete(() {
            print('Done serving request: $current');
            return request.response.close();
          }));
        }
      } catch (e, s) {
        await Sentry.captureException(e, stackTrace: s);
      }
    }
  } finally {
    httpClient.close();
  }
}

Future<void> _serve(HttpRequest request, PubClient client) async {
  if (request.method != 'GET') {
    request.response.statusCode = 400;
  } else if (request.requestedUri.pathSegments.isEmpty) {
    request.response.headers.contentType = ContentType.html;
    await request.response.addStream(_index.openRead());
  } else if (request.requestedUri.pathSegments.length != 2 ||
      !scoreTypes.contains(request.requestedUri.pathSegments.last)) {
    redirectHome(request);
  } else {
    final package = request.requestedUri.pathSegments.reversed.skip(1).first;
    final score = await client.getScore(package);
    if (score == null) {
      redirectHome(request);
    }
    request.response.headers.contentType = _contentTypeSvg;
    request.response.headers.add('Cache-Control',
        'public, max-age=3600, stale-while-revalidate=30, stale-if-error=86400');
    final scoreType = request.requestedUri.pathSegments.last;
    request.response
        .write(svg(scoreType, score.getValueByType(scoreType).toString()));
  }
}

void redirectHome(HttpRequest request) {
  request.response.statusCode = 302;
  request.response.redirect(Uri(
      host: request.requestedUri.host,
      port: request.requestedUri.port,
      scheme: request.requestedUri.scheme));
}

final _contentTypeSvg = ContentType('image', 'svg+xml');
final _index = File('web/index.html');

extension HttpResponseExtensions on HttpResponse {
  void trySetServerError() {
    try {
      statusCode = 500;
    } catch (_) {
      // Headers were likely already sent out.
    }
  }
}

bool get isProduction => Platform.environment['ENVIRONMENT'] == 'prod';
