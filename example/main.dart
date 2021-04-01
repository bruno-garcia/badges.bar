import 'dart:async';
import 'package:badges_bar/badges_bar.dart';

Future<void> main() async {
  // Render a SVG badge with the Dart logo:
  print(svg('Title', 'Value'));

  // Get the pub.dev metrics for a package:
  final client = PubClient();
  final metrics = await client.getMetrics('sentry');
  print('Stats for sentry:');
  print('Likes: ${metrics.likes}');
  print('Popularity: ${metrics.popularity}');
  print('Pub Points: ${metrics.points}');
  print('Max Points: ${metrics.maxPoints}');
  print('Last Updated: ${metrics.lastUpdated}');
  print('Package Name: ${metrics.packageName}');
  print('Package Version: ${metrics.packageVersion}');
  print('Runtime Version: ${metrics.runtimeVersion}');
  print('Created: ${metrics.packageCreated}');
  print('Version Created: ${metrics.packageVersionCreated}');
  print('Derived Tags: ${metrics.derivedTags}');
  print('Flags: ${metrics.flags}');
  print('Report Types: ${metrics.reportTypes}');
}
