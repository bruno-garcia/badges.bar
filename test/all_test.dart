import 'package:badges_bar/badges_bar.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('svg renders with title and value', () {
    const title = '!title|title!';
    const value = '!value|value!';

    final actual = svg(title, value);
    expect(actual, contains(title));
    expect(actual, contains(value));
  });

  group('getScore', () {
    test('with valid package, returns expected scores', () async {
      final sut = PubClient(MockClient((r) async => _validResponse));
      final scores = await sut.getScore('badges_bar');
      expect(scores.likes, 1);
      expect(scores.points, 2);
      expect(scores.popularity, 3);
    });
    test('pub.dev changed score payload, throws error', () async {
      final sut = PubClient(MockClient((r) async =>
          Response('{"likeCount":1,"popularity":2,"grantedPoints":3}', 200)));
      expect(
          () => sut.getScore('badges_bar'),
          throwsA(predicate((String e) =>
              e ==
              'Unexpected valyes: likes: "1" popularity: "null" points: "3"')));
    });
    test('package name is URI encoded', () async {
      final expectedUri = Uri.parse(
          'https://pub.dev/api/packages/..%2F..%2Fmy-packages%3F%F0%9F%94%93%3D/score');
      Uri actualUri;
      final mockHttpClient = MockClient((r) async {
        actualUri = r.url;
        return _validResponse;
      });
      final sut = PubClient(mockHttpClient);
      final _ = await sut.getScore('../../my-packages?🔓=');
      expect(actualUri, equals(expectedUri));
    });
    test('pub.dev returns empty body, throws error', () {
      final mockHttpClient = MockClient((r) async => Response('', 200));
      final sut = PubClient(mockHttpClient);

      expect(
          () => sut.getScore('badges_bar'),
          throwsA(predicate((String e) =>
              e == 'Can\'t parse body for Scores because it\'s empty.')));
    });
    test('pub.dev returns 500, throws error', () {
      final mockHttpClient = MockClient((r) async => Response('', 500));
      final sut = PubClient(mockHttpClient);

      expect(
          () => sut.getScore('wrong-package-name'),
          throwsA(predicate((String e) =>
              e ==
              'URL https://pub.dev/api/packages/wrong-package-name/score fetching returned 500')));
    });
    test('pub.dev returns 404, returns null', () async {
      final mockHttpClient = MockClient((r) async => Response('', 404));
      final sut = PubClient(mockHttpClient);

      expect(await sut.getScore('unexistent package'), isNull);
    });
    test('requests include User-Agent header', () async {
      final mockHttpClient = MockClient((r) async {
        expect(
            r.headers['User-Agent'],
            matches(
                r'badges\.bar\/\d+\.\d+\.\d+ \(\+https:\/\/badges\.bar\/\)'));
        return Response('', 404);
      });

      final _ = PubClient(mockHttpClient).getScore('package');
    });
  });

  group('Score', () {
    test('returns expected score through getValueByType', () {
      const sut = Score(likes: 1, points: 2, popularity: 3);
      expect(sut.getValueByType('likes'), 1);
      expect(sut.getValueByType('pub points'), 2);
      expect(sut.getValueByType('popularity'), 3);
    });
    test('getValueByType throws on unknown type', () {
      const sut = Score(likes: 1, points: 2, popularity: 3);
      expect(
          () => sut.getValueByType('wut?'),
          throwsA(
              predicate((String e) => e == 'Type \'wut?\' is not supported')));
    });
  });
}

Response _validResponse = Response(_validScoresHtmlElement, 200);
Response _differentLabelsResponse = Response(_wrongLabelsScores, 200);

String _validScoresHtmlElement = '''
{"grantedPoints":2,
"maxPoints":110,
"likeCount":1,
"popularityScore":0.0277782364,
"lastUpdated":"2020-09-12T00:18:21.847457Z"}''';

String _wrongLabelsScores = '''
{"error":{"code":"NotFound","message":"Could not find `package \"asdasd\"`."},
"code":"NotFound","message":"Could not find `package \"asdasd\"`."}
''';
