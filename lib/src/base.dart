import 'package:sentry/sentry.dart';

/// The types of scores. In the order they are presented on pub.dev
const scoreTypes = [
  'pub points',
  'max points',
  'likes',
  'popularity',
  'last updated',
];

/// The types of scorecards. In the order they are presented on pub.dev API.
const scorecardTypes = [
  'name',
  'version',
  'runtime version',
  'created',
  'version created',
  'derived tags',
  'flags',
  'report types'
];

class SafeCast {
  static T tryCast<T>(dynamic map, String key) {
    try {
      return map[key] as T;
    } catch (e) {
      Sentry.addBreadcrumb(
          Breadcrumb(message: '"' + key + '" failed to cast. ' + e.toString()));
    }
    return null;
  }
}
