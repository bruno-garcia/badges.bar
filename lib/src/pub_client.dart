import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:badges_bar/src/sentry.dart';
import 'package:sentry/sentry.dart';
import 'package:xpath/xpath.dart';

import 'base.dart';

/// A pub.dev client that is able to retrieve a packages' Pub Scores.
class PubClient {
  HttpClient httpClient;

  /// Creates an instance of [PubClient] using an optional [HttpClient].
  PubClient([HttpClient httpClient]) {
    this.httpClient ??= HttpClient();
  }

  /// Fetches the packages' score from pub.dev.
  Future<Score> getScore(String name) async {
    // Even though the scores are available in any detail page of the package,
    // the 'score' page is the best candidate becase the size doesn't vary.
    final url = Uri.parse(
        'https://pub.dev/packages/${Uri.encodeComponent(name)}/score');
    var request = await httpClient.getUrl(url);

    var response = await request.close();
    if (response.statusCode != 200) {
      print(response);
      await Sentry.captureEvent(
          Event(message: "URL $url fetching returned ${response.statusCode}"));
    }

    final buffer = StringBuffer();

    // Can I push raw data and encode on Isolate?
    await for (var content in response.transform(Utf8Decoder())) {
      buffer.write(content);
    }

    return _parseScore(buffer.toString());
  }

  Future<Score> _parseScore(String body) async {
    var figures = ETree.fromString(body);
    var scores = figures.xpath('//*[@class="score-key-figures"]')[0];
    if (scores == null) {
      throw Exception(
          'Expected div with class \'score-key-figures\' not found.');
    }

    assert(scoreTypes.length == 3);
    final scoreValues = List(scoreTypes.length);
    for (var i = 0; i < scoreTypes.length; i++) {
      var value = int.tryParse(scores.children[i]?.children[0]?.children[0]
          ?.xpath('/text()')[0]
          ?.name);
      var valueLabel =
          scores.children[i]?.children[1]?.xpath('/text()')[0]?.name;
      if (value == null || valueLabel != scoreTypes[i]) {
        throw Exception(
            'Expected \'${scoreTypes[i]}\' not found. Main div: $scores');
      }
      scoreValues[i] = value;
    }

    return Score(scoreValues[0], scoreValues[1], scoreValues[2]);
  }
}

/// Scores of a package on pub.dev.
class Score {
  const Score(this.likes, this.points, this.popularity);

  /// Package 'Likes'.
  final int likes;

  /// Package 'Pub Points'.
  final int points;

  /// Package 'Popularity'.
  final int popularity;

  /// Returns the numeric value of the specified [type] from [scoreTypes].
  int getValueByType(String type) {
    if (type == scoreTypes[0]) {
      return likes;
    } else if (type == scoreTypes[1]) {
      return points;
    } else if (type == scoreTypes[2]) {
      return popularity;
    }
    throw Exception("Type \'$type\' is not supported");
  }
}
