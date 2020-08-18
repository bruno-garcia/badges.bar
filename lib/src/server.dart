import 'dart:async';
import 'dart:io';

import 'package:badges_bar/src/pub_client.dart';
import 'package:sentry/sentry.dart';

import 'sentry.dart';
import 'base.dart';
import 'svg.dart';

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
  var server = await HttpServer.bind(
    Platform.environment['ENVIRONMENT'] == 'prod'
        ? InternetAddress.anyIPv4
        : InternetAddress.loopbackIPv4,
    port,
  );

  print('Listening on http://localhost:${server.port}');

  int counter = 0;
  await for (final request in server) {
    try {
      final current = counter++;
      print('Starting to serving request: $current');
      _serve(request, client)
          .whenComplete(() => print('Done serving request: $current'));
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
    await request.response.addStream(index.openRead());
  } else if (request.requestedUri.pathSegments.length != 2 ||
      !scoreTypes.contains(request.requestedUri.pathSegments.last)) {
    request.response.statusCode = 302;
    request.response.redirect(Uri(
        host: request.requestedUri.host,
        port: request.requestedUri.port,
        scheme: request.requestedUri.scheme));
  } else {
    final scoreType = request.requestedUri.pathSegments.last;
    final package = request.requestedUri.pathSegments.reversed.skip(1).first;

    request.response.headers.contentType = contentTypeSvg;
    request.response.headers.add('Cache-Control', 'max-age=3600');

    final score = await client.getScore(package);
    request.response
        .write(svg(scoreType, score.getValueByType(scoreType).toString()));
  }

  await request.response.close();
}

final contentTypeSvg = new ContentType("image", "svg+xml");
final index = File('web/index.html');
