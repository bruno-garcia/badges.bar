# Badges for Dart and Flutter packages

[![build](https://github.com/bruno-garcia/badges.bar/workflows/build/badge.svg?branch=main)](https://github.com/bruno-garcia/badges.bar/actions?query=branch%3Amain) 
[![likes](https://badges.bar/badges_bar/likes)](https://pub.dev/packages/badges_bar/score) [![popularity](https://badges.bar/badges_bar/popularity)](https://pub.dev/packages/badges_bar/score) [![pub points](https://badges.bar/badges_bar/pub%20points)](https://pub.dev/packages/badges_bar/score)

## On Docker Hub

https://hub.docker.com/r/brunogarcia/badges.bar/tags

## Using badges.bar

You can create a badge for your package by using `https://badges.bar/{package}/{score_type}`.
Score types can be either:

* `likes`
* `pub points`
* `popularity`

For example for the package `sentry`:

[![likes](https://badges.bar/sentry/likes)](https://pub.dev/packages/sentry/score): `[![likes](https://badges.bar/sentry/likes)](https://pub.dev/packages/sentry/score)`

[![popularity](https://badges.bar/sentry/popularity)](https://pub.dev/packages/sentry/score): `[![popularity](https://badges.bar/sentry/popularity)](https://pub.dev/packages/sentry/score)`

[![pub points](https://badges.bar/sentry/pub%20points)](https://pub.dev/packages/sentry/score): `[![pub points](https://badges.bar/sentry/pub%20points)](https://pub.dev/packages/sentry/score)`

## Using the API

### Render an SVG badge with the Dart logo

```dart
final textSvg = svg('Title', 'Value');
```

The `textSvg` above would render the svg like in  [![likes](https://badges.bar/sentry/likes)](https://pub.dev/packages/sentry/score) but instead with `Title` on the left hand and `Value` on the right (green background) side.

### Fetch the pub.dev scores for a package

```dart
const package = 'badge_bar';
final client = PubClient();
final score = await client.getMetrics(package);
print('Stats for $package:');
print('Likes: ${score.likes}');
print('Popularity: ${score.popularity}');
print('Pub Points: ${score.points}');
```
