import 'dart:io';

/// The types of scores. In the order they are presented on pub.dev
const scoreTypes = ['likes', 'pub points', 'popularity'];
bool get isProduction => 





Platform.environment['ENVIRONMENT'] == 'prod';
