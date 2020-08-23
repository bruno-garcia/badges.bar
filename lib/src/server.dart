import 'dart:async';
import 'dart:io';

import 'package:badges_bar/src/pub_client.dart';
import 'package:sentry/sentry.dart';
import 'package:http/http.dart' as http;

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
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 31337;
  var address =
      isProduction ? InternetAddress.anyIPv4 : InternetAddress.loopbackIPv4;
  var server = await HttpServer.bind(address, port);

  print(
      'Running (prod:$isProduction): http://${address.address}:${server.port}');

  final httpClient = http.Client();
  var client = PubClient(httpClient);
  try {
    int counter = 0;
    await for (final request in server) {
      try {
        final serveFuture = _serve(request, client);
        if (isProduction) {
          serveFuture.catchError((e, s) async {
            request.response.trySetServerError();
            return await sentry.captureException(exception: e, stackTrace: s);
          }).whenComplete(() => request.response.close());
        } else {
          final current = counter++;
          print('Starting to serve request: $current');
          serveFuture.catchError((e, s) {
            print("$e\n$s");
            request.response.trySetServerError();
          }).whenComplete(() {
            print('Done serving request: $current');
            return request.response.close();
          });
        }
      } catch (e, s) {
        await sentry.captureException(exception: e, stackTrace: s);
      }
    }
  } finally {
    httpClient.close();
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

final _contentTypeSvg = ContentType("image", "svg+xml");
final _index = File('web/index.html');

extension HttpResponseExtensions on HttpResponse {
  void trySetServerError() {
    try {
      this.statusCode = 500;
    } catch (_) {
      // Headers were likely already sent out.
    }
  }
}
