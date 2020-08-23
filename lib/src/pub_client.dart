import 'dart:async';

import 'package:http/http.dart';
import 'package:xpath/xpath.dart';

import 'base.dart';

/// A pub.dev client that is able to retrieve a packages' Pub Scores.
class PubClient {
  BaseClient httpClient;

  /// Creates an instance of [PubClient] using an optional [HttpClient].
  PubClient([BaseClient this.httpClient]) {
    this.httpClient ??= Client();
  }

  /// Fetches the packages' score from pub.dev.
  Future<Score> getScore(String name) async {
    // Even though the scores are available in any detail page of the package,
    // the 'score' page is the best candidate becase the size doesn't vary.
    final url = Uri.parse(
        'https://pub.dev/packages/${Uri.encodeComponent(name)}/score');
    var streamedResponse =
        await httpClient.send(Request('GET', url)..followRedirects = false);
    var response = await Response.fromStream(streamedResponse);

    // Packages that don't exist result in a redirect to the search page.
    if (streamedResponse.statusCode == 303) {
      return null;
    }

    if (streamedResponse.statusCode != 200) {
      throw ("URL $url fetching returned ${streamedResponse.statusCode}");
    }

    return _parseScore(response.body);
  }

  Future<Score> _parseScore(String body) async {
    if (body == null || body == "") {
      throw ('Can\'t parse body for Scores because it\'s empty.');
    }
    var figures = ETree.fromString(body);
    var scores = figures.xpath('//*[@class="score-key-figures"]')?.first;
    if (scores == null) {
      throw ('Expected div with class \'score-key-figures\' not found.');
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
        throw ('Expected \'${scoreTypes[i]}\' not found.');
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
    throw ("Type \'$type\' is not supported");
  }
}
