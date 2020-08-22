import 'dart:async';
import 'dart:io';

import 'package:badges_bar/src/pub_client.dart';
import 'package:sentry/sentry.dart';

import 'sentry.dart';
import 'base.dart';
import 'svg.dart';

/// Starts a server that generates SVG badges for pub.dev scores.
Future<void> start() async {
  Sentry.init(
      "https://09a6dc7f166e467793a5d2bc7c7a7df2@o117736.ingest.sentry.io/1857674",
      (SentryClient sentry) => _run(sentry));
}

Future<void> _run(SentryClient sentry) async {
  final httpClient = new HttpClient();
  httpClient.idleTimeout = Duration(minutes: 2);

  var client = PubClient(httpClient);

  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 31337;
  var address =
      _isProduction ? InternetAddress.anyIPv4 : InternetAddress.loopbackIPv4;
  var server = await HttpServer.bind(address, port);

  print(
      'Running (prod:$_isProduction): http://${address.address}:${server.port}');

  int counter = 0;
  await for (final request in server) {
    try {
      final serveFuture = _serve(request, client);
      if (_isProduction) {
        serveFuture.catchError((e, s) async =>
            await sentry.captureException(exception: e, stackTrace: s));
      } else {
        final current = counter++;
        print('Starting to serve request: $current');
        serveFuture
            .catchError((e, s) => print("$e\n$s"))
            .whenComplete(() => print('Done serving request: $current'));
      }
    } catch (e, s) {
      await sentry.captureException(exception: e, stackTrace: s);
    }
  }
}

Future<void> _serve(HttpRequest request, PubClient client) async {
  if (request.method != 'GET') {
    request.response.statusCode = 400;
  } else if (request.requestedUri.pathSegments.length == 0) {
    request.response.headers.contentType = ContentType.html;
    await request.response.addStream(_index.openRead());
  } else if (request.requestedUri.pathSegments.length != 2 ||
      !scoreTypes.contains(request.requestedUri.pathSegments.last)) {
    request.response.statusCode = 302;
    request.response.redirect(Uri(
        host: request.requestedUri.host,
        port: request.requestedUri.port,
        scheme: request.requestedUri.scheme));
  } else {
    request.response.headers.contentType = _contentTypeSvg;
    request.response.headers.add('Cache-Control',
        'public, max-age=3600, stale-while-revalidate=30, stale-if-error=86400');

    final scoreType = request.requestedUri.pathSegments.last;
    final package = request.requestedUri.pathSegments.reversed.skip(1).first;

    final score = await client.getScore(package);
    request.response
        .write(svg(scoreType, score.getValueByType(scoreType).toString()));
  }

  await request.response.close();
}

final _contentTypeSvg = new ContentType("image", "svg+xml");
final _index = File('web/index.html');

get _isProduction => Platform.environment['ENVIRONMENT'] == 'prod';
