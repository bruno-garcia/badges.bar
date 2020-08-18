import 'dart:async';
import '../lib/badges_bar.dart';

Future<void> main() async {
  // Render a SVG badge with the Dart logo:
  print(svg('Title', 'Value'));

  // Get the pub.dev score for a package:
  final client = PubClient();
  final score = await client.getScore('sentry');
  print('Stats for sentry:');
  print('Likes: ${score.likes}');
  print('Popularity: ${score.popularity}');
  print('Pub Points: ${score.points}');
}
