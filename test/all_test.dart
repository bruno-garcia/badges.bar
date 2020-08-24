import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:badges_bar/badges_bar.dart';

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
    test('pub.dev changed score labels, throws error', () async {
      final sut = PubClient(MockClient((r) async => _differentLabelsResponse));
      expect(
          () => sut.getScore('badges_bar'),
          throwsA(
              predicate((String e) => e == 'Expected \'likes\' not found.')));
    });
    test('pub.dev changed score layout, throws error', () async {
      final sut = PubClient(MockClient((r) async => Response('<div />', 200)));
      expect(
          () => sut.getScore('badges_bar'),
          throwsA(predicate((String e) =>
              e ==
              'Expected div with class \'score-key-figures\' not found.')));
    });
    test('package name is URI encoded', () async {
      final expectedUri = Uri.parse(
          'https://pub.dev/packages/..%2F..%2Fmy-packages%3F%F0%9F%94%93%3D/score');
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
    test('pub.dev returns 404, throws error', () {
      final mockHttpClient = MockClient((r) async => Response('', 404));
      final sut = PubClient(mockHttpClient);

      expect(
          () => sut.getScore('wrong-package-name'),
          throwsA(predicate((String e) =>
              e ==
              'URL https://pub.dev/packages/wrong-package-name/score fetching returned 404')));
    });
    test('pub.dev returns 303, returns null', () async {
      final mockHttpClient = MockClient((r) async => Response('', 303));
      final sut = PubClient(mockHttpClient);

      expect(await sut.getScore('unexistent package'), isNull);
    });
  });

  group('Score', () {
    test('returns expected score through getValueByType', () {
      const sut = Score(1, 2, 3);
      expect(sut.getValueByType('likes'), 1);
      expect(sut.getValueByType('pub points'), 2);
      expect(sut.getValueByType('popularity'), 3);
    });
    test('getValueByType throws on unknown type', () {
      const sut = Score(1, 2, 3);
      expect(
          () => sut.getValueByType('wut?'),
          throwsA(
              predicate((String e) => e == 'Type \'wut?\' is not supported')));
    });
  });
}

Response _validResponse = Response(_validScoresHtmlElement, 200);
Response _differentLabelsResponse =
    Response(_wrongLabelsScoresHtmlElement, 200);

String _validScoresHtmlElement = '''
<div class="score-key-figures">
<p>
  <p><p>1</p></p>
  <p>likes</p>
</p>
<p>
  <p><p>2</p></p>
  <p>pub points</p>
</p>
<p>
  <p><p>3</p></p>
  <p>popularity</p>
</p>
</div>''';

String _wrongLabelsScoresHtmlElement = '''
<div class="score-key-figures">
<p>
  <p><p>1</p></p>
  <p>expected likes to be here</p>
</p>
<p>
  <p><p>2</p></p>
  <p>pub points</p>
</p>
<p>
  <p><p>3</p></p>
  <p>popularity</p>
</p>
</div>''';
