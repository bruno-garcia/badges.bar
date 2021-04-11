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

  group('getMetrics', () {
    test('with valid package, returns expected Metrics', () async {
      final sut = PubClient(MockClient((r) async => _validResponse));
      final metrics = await sut.getMetrics('badges_bar');
      expect(metrics.likes, 17);
      expect(metrics.points, 60);
      expect(metrics.popularity, 65);
    });
    test('package name is URI encoded', () async {
      final expectedUri = Uri.parse(
          'https://pub.dev/api/packages/..%2F..%2Fmy-packages%3F%F0%9F%94%93%3D/metrics');
      Uri actualUri;
      final mockHttpClient = MockClient((r) async {
        actualUri = r.url;
        return _validResponse;
      });
      final sut = PubClient(mockHttpClient);
      final _ = await sut.getMetrics('../../my-packages?🔓=');
      expect(actualUri, equals(expectedUri));
    });
    test('pub.dev returns empty body, throws error', () {
      final mockHttpClient = MockClient((r) async => Response('', 200));
      final sut = PubClient(mockHttpClient);

      expect(
          () => sut.getMetrics('badges_bar'),
          throwsA(predicate((String e) =>
              e == 'Can\'t parse body for Metrics because it\'s empty.')));
    });
    test('pub.dev returns 500, throws error', () {
      final mockHttpClient = MockClient((r) async => Response('', 500));
      final sut = PubClient(mockHttpClient);

      expect(
          () => sut.getMetrics('wrong-package-name'),
          throwsA(predicate((String e) =>
              e ==
              'URL https://pub.dev/api/packages/wrong-package-name/metrics fetching returned 500')));
    });
    test('pub.dev returns 404, returns null', () async {
      final mockHttpClient = MockClient((r) async => Response('', 404));
      final sut = PubClient(mockHttpClient);

      expect(await sut.getMetrics('unexistent package'), isNull);
    });
    test('requests include User-Agent header', () async {
      final mockHttpClient = MockClient((r) async {
        expect(
            r.headers['User-Agent'],
            matches(
                r'badges\.bar\/\d+\.\d+\.\d+(-[A-Za-z]+\.\d+)? \(\+https:\/\/badges\.bar\/\)'));
        return Response('', 404);
      });

      final _ = PubClient(mockHttpClient).getMetrics('package');
    });
  });

  group('Metrics', () {
    test('returns expected metrics through getValueByType', () {
      final DateTime now = DateTime.now();
      final Metrics sut = Metrics(
        likes: 2000,
        points: 100,
        popularity: 100,
        lastUpdated: now,
        packageName: 'test',
        packageVersion: '0.0.1',
        packageCreated: now,
        packageVersionCreated: now,
        runtimeVersion: '0000.00.00',
        maxPoints: 120,
        derivedTags: ['sdk:dart'],
        flags: ['latest-stable'],
        reportTypes: ['dartdoc'],
      );
      expect(sut.getValueByType('likes'), 2000.toString());
      expect(sut.getValueByType('pub points'), 100.toString());
      expect(sut.getValueByType('max points'), 120.toString());
      expect(sut.getValueByType('popularity'), 100.toString());
      expect(sut.getValueByType('last updated'), now.toString());
      expect(sut.getValueByType('name'), 'test');
      expect(sut.getValueByType('version'), '0.0.1');
      expect(sut.getValueByType('runtime version'), '0000.00.00');
      expect(sut.getValueByType('created'), now.toString());
      expect(sut.getValueByType('version created'), now.toString());
      expect(sut.getValueByType('derived tags'), sut.listParse(['sdk:dart']));
      expect(sut.getValueByType('flags'), sut.listParse(['latest-stable']));
      expect(sut.getValueByType('report types'), sut.listParse(['dartdoc']));
    });
    test('getValueByType throws on unknown type', () {
      final DateTime now = DateTime.now();
      final Metrics sut = Metrics(
        likes: 2000,
        points: 100,
        popularity: 100,
        lastUpdated: now,
        packageName: 'test',
        packageVersion: '0.0.1',
        packageCreated: now,
        packageVersionCreated: now,
        runtimeVersion: '0000.00.00',
        maxPoints: 120,
        derivedTags: ['sdk:dart'],
        flags: ['latest-stable'],
        reportTypes: ['dartdoc'],
      );
      expect(
          () => sut.getValueByType('wut?'),
          throwsA(
              predicate((String e) => e == 'Type \'wut?\' is not supported')));
    });
  });
}

Response _validResponse = Response(_validMetricsResponse, 200);
Response _differentLabelsResponse = Response(_wrongLabelsMetrics, 200);

String _validMetricsResponse = '''
{"score":{"grantedPoints":60,"maxPoints":110,"likeCount":17,"popularityScore":0.6504369538077404,"lastUpdated":"2021-03-30T23:22:46.439201Z"},"scorecard":{"packageName":"pana","packageVersion":"0.15.4","runtimeVersion":"2021.03.19","updated":"2021-03-30T23:22:46.439201Z","packageCreated":"2015-09-25T06:45:22.439Z","packageVersionCreated":"2021-03-15T10:34:06.601324Z","grantedPubPoints":60,"maxPubPoints":110,"popularityScore":0.6504369538077404,"derivedTags":["sdk:dart","sdk:flutter","platform:android","platform:ios","platform:windows","platform:linux","platform:macos","runtime:native-aot","runtime:native-jit"],"flags":["latest-stable"],"reportTypes":["dartdoc","pana"]}}''';

String _wrongLabelsMetrics = '''
{"error":{"code":"NotFound","message":"Could not find `package \"asdasd\"`."},
"code":"NotFound","message":"Could not find `package \"asdasd\"`."}
''';
