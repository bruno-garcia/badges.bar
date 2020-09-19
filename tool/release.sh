#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Pass the new version as an argument."
    exit
fi

if ! egrep "^\d+\.\d+\.\d+(-.+)?$" <<< $1 > /dev/null; then
    echo 'Invalid version. Try the format 0.0.0'
    exit
fi

export version=$1
echo Releasing v$version

sed -i '' -e "s/version: \(.*\)/version: $version/g" pubspec.yaml
sed -i '' -e "s/version = '\(.*\)'/version = '$version'/g" lib/src/version.dart
sed -i '' -e "s/v\([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\)/v$version/g" web/index.html

if ! pub publish --dry-run > /dev/null; then
    echo
    echo 'Running "pub publish --dry-run" gives warnings. Correct those before proceeding.'
    exit
fi

git add CHANGELOG.md
git add pubspec.yaml
git add lib/src/version.dart
git add web/index.html

git status
git diff --staged

echo CTRL + C to quit or anything else to continue
read

git commit -m "Releasing $version"

export git_tag=v$version
if ! git tag $git_tag; then
    echo "Failed to create git tag $git_tag"
    exit
fi

pub publish
git push --tags
git push origin main