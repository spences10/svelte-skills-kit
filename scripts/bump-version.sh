#!/bin/bash
# Bump version in all plugin.json files

set -e

VERSION=${1:-}

if [ -z "$VERSION" ]; then
  echo "Usage: ./scripts/bump-version.sh <version>"
  echo "Example: ./scripts/bump-version.sh 1.2.0"
  exit 1
fi

# Validate semver format
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Version must be semver format (e.g., 1.2.0)"
  exit 1
fi

# Find and update all plugin.json files
for file in plugins/*/.claude-plugin/plugin.json; do
  if [ -f "$file" ]; then
    sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$VERSION\"/" "$file"
    echo "Updated: $file -> $VERSION"
  fi
done

echo "Done. Run: git add -A && git commit -m \"chore: bump to $VERSION\" && git push"
