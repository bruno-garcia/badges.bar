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

const Map<String, String> svgTitle = {
  'pub points': 'Points',
  'max points': 'Max Points',
  'likes': 'Likes',
  'popularity': 'Popularity',
  'last updated': 'Last Updated',
  'name': 'Package Name',
  'version': 'Package Version',
  'runtime version': 'Runtime Version',
  'created': 'Created',
  'version created': 'Version Created',
  'derived tags': 'Platforms',
  'flags': 'Flags',
  'report types': 'Report Types'
};