import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
// import as can be dropped once fixed: https://github.com/getsentry/sentry-dart/issues/250#issuecomment-782882646
import 'package:sentry/sentry.dart' as sentry;

import 'base.dart';
import 'version.dart';

/// A pub.dev client that is able to retrieve a packages' Pub Scores.
class PubClient {
  /// Creates an instance of [PubClient] using an optional [HttpClient].
  PubClient([this.httpClient]) {
    httpClient ??= sentry.SentryHttpClient();
  }

  Client httpClient;

  /// Fetches the packages' score from pub.dev.
  Future<Metrics> getMetrics(String name) async {
    final url = Uri.parse(
        'https://pub.dev/api/packages/${Uri.encodeComponent(name)}/metrics');
    final req = Request('GET', url);
    req.headers['User-Agent'] = 'badges.bar/$version (+$site)';
    final streamedResponse = await httpClient.send(req);
    final response = await Response.fromStream(streamedResponse);

    if (streamedResponse.statusCode == 404) {
      return null;
    }

    if (streamedResponse.statusCode != 200) {
      throw 'URL $url fetching returned ${streamedResponse.statusCode}';
    }

    return _parseMetrics(response.body);
  }

  Future<Metrics> _parseMetrics(String body) async {
    if (body == null || body == '') {
      throw "Can't parse body for Metrics because it's empty.";
    }

    final dynamic metrics = jsonDecode(body);

    final dynamic score = metrics['score'];
    final likes = score['likeCount'] as int;
    final popularity = score['popularityScore'] as double;
    final points = score['grantedPoints'] as int;
    final maxPoints = score['maxPoints'] as int;

    final lastUpdated = SafeCast.tryCast<DateTime>(score, 'lastUpdated');
    final dynamic scoreCard = metrics['scorecard'];
    final packageName = scoreCard['packageName'] as String;
    final packageVersion = scoreCard['packageVersion'] as String;
    final packageCreated = scoreCard['packgeCreated'] as DateTime;
    final packageVersionCreated =
        SafeCast.tryCast<DateTime>(score, 'packageVersionCreated');
    final derivedTags = SafeCast.tryCast<List<String>>(score, 'derivedTags');
    final flags = SafeCast.tryCast<List<String>>(score, 'flags');
    final reportTypes = SafeCast.tryCast<List<String>>(score, 'reportTypes');

    int roundedPopularity;
    if (popularity != null) {
      roundedPopularity = (popularity * 100).round();
    }
    return Metrics(
      likes: likes,
      points: points,
      popularity: roundedPopularity,
      maxPoints: maxPoints,
      lastUpdated: lastUpdated,
      packageName: packageName,
      packageVersion: packageVersion,
      packageCreated: packageCreated,
      packageVersionCreated: packageVersionCreated,
      derivedTags: derivedTags,
      flags: flags,
      reportTypes: reportTypes,
    );
  }
}

/// Scores of a package on pub.dev.
class Metrics {
  const Metrics({
    this.likes,
    this.points,
    this.popularity,
    this.maxPoints,
    this.lastUpdated,
    this.packageName,
    this.packageVersion,
    this.runtimeVersion,
    this.packageCreated,
    this.packageVersionCreated,
    this.derivedTags,
    this.flags,
    this.reportTypes,
  });

  /// Package 'Likes'.
  final int likes;

  /// Package 'Pub Points'.
  final int points;

  /// Package 'Popularity'.
  final int popularity;

  /// Package 'Maximum Pub Points'
  final int maxPoints;

  /// Package 'Time of Last Update'
  final DateTime lastUpdated;

  /// Name of the package hosted on pub.dev
  final String packageName;

  /// Version of the package hosted on pub.dev
  final String packageVersion;

  /// Runtime Version of the package hosted on pub.dev
  final String runtimeVersion;

  /// Time of creation of the package in DateTime format
  final DateTime packageCreated;

  /// Time of creation of the latest version of the package in DateTime format
  final DateTime packageVersionCreated;

  final List<String> derivedTags;

  final List<String> flags;

  final List<String> reportTypes;

  String listParse(List<String> list) {
    String returnValue = '';
    for (int i = 0; i < list.length; i++) {
      if (i != 0) {
        returnValue += ' | ';
      }
      returnValue += list[i];
    }
    return returnValue;
  }

  /// Returns the numeric value of the specified [type] from [scoreTypes].
  String getValueByType(String type) {
    if (type == scoreTypes[0]) {
      return points.toString();
    } else if (type == scoreTypes[1]) {
      return maxPoints.toString();
    } else if (type == scoreTypes[2]) {
      return likes.toString();
    } else if (type == scoreTypes[3]) {
      return popularity.toString();
    } else if (type == scoreTypes[4]) {
      return lastUpdated.toString();
    } else if (type == scorecardTypes[0]) {
      return packageName;
    } else if (type == scorecardTypes[1]) {
      return packageVersion;
    } else if (type == scorecardTypes[2]) {
      return runtimeVersion;
    } else if (type == scorecardTypes[3]) {
      return packageCreated.toString();
    } else if (type == scorecardTypes[4]) {
      return packageVersionCreated.toString();
    } else if (type == scorecardTypes[5]) {
      return listParse(derivedTags);
    } else if (type == scorecardTypes[6]) {
      return listParse(flags);
    } else if (type == scorecardTypes[7]) {
      return listParse(reportTypes);
    } else {
      throw "Type '$type' is not supported";
    }
  }
}
