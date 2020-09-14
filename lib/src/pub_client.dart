import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

import 'base.dart';

/// A pub.dev client that is able to retrieve a packages' Pub Scores.
class PubClient {
  /// Creates an instance of [PubClient] using an optional [HttpClient].
  PubClient([this.httpClient]) {
    httpClient ??= Client();
  }

  Client httpClient;

  /// Fetches the packages' score from pub.dev.
  Future<Score> getScore(String name) async {
    final url = Uri.parse(
        'https://pub.dev/api/packages/${Uri.encodeComponent(name)}/score');
    final req = Request('GET', url);
    req.headers['User-Agent'] = 'badges.bar/0.0.2 (+https://badges.bar/)';
    final streamedResponse = await httpClient.send(req);
    final response = await Response.fromStream(streamedResponse);

    if (streamedResponse.statusCode == 404) {
      return null;
    }

    if (streamedResponse.statusCode != 200) {
      throw 'URL $url fetching returned ${streamedResponse.statusCode}';
    }

    return _parseScore(response.body);
  }

  Future<Score> _parseScore(String body) async {
    if (body == null || body == '') {
      throw "Can't parse body for Scores because it's empty.";
    }

    final dynamic score = jsonDecode(body);

    final likes = score['likeCount'] as int;
    final popularity = score['popularityScore'] as double;
    final points = score['grantedPoints'] as int;
    if (likes == null || popularity == null || points == null) {
      throw 'Unexpected valyes: likes: "$likes" popularity: "$popularity" points: "$points"';
    }
    return Score(likes, (popularity * 100).round(), points);
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
    throw "Type '$type' is not supported";
  }
}
