#!/usr/bin/env bash
# Bump the train (repo) version and sync every plugin / marketplace manifest.
#
# Formal releases on main go through Changesets (see VERSIONING.md).
# Use this script for local bumps or hotfixes when you are not using a changeset.
#
# Usage:
#   scripts/bump-version.sh              # patch 0.1.0 -> 0.1.1
#   scripts/bump-version.sh minor        # 0.1.0 -> 0.2.0
#   scripts/bump-version.sh major        # 0.1.0 -> 1.0.0
#   scripts/bump-version.sh 0.2.0        # explicit version
#   scripts/bump-version.sh --list
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

list_versions() {
  local train
  train="$(python3 -c "import json; print(json.load(open('package.json'))['version'])")"
  echo "Train (package.json): $train"
  echo
  echo "Plugin manifests (should match train after sync):"
  for d in skills/*/; do
    name="$(basename "$d")"
    ver="$(python3 -c "import json; print(json.load(open('skills/${name}/.claude-plugin/plugin.json'))['version'])" 2>/dev/null || echo "?")"
    printf "  %-20s %s\n" "$name" "$ver"
  done
  all_ver="$(python3 -c "import json; print(json.load(open('.claude-plugin/plugin.json'))['version'])" 2>/dev/null || echo "?")"
  printf "  %-20s %s\n" "all (bundle)" "$all_ver"
}

bump_semver() {
  local current="$1"
  local kind="$2"
  python3 -c "
v = '$current'.split('.')
if len(v) != 3 or not all(p.isdigit() for p in v):
    raise SystemExit(f'not semver: $current')
maj, minor, patch = map(int, v)
kind = '$kind'
if kind == 'major':
    print(f'{maj + 1}.0.0')
elif kind == 'minor':
    print(f'{maj}.{minor + 1}.0')
elif kind == 'patch':
    print(f'{maj}.{minor}.{patch + 1}')
else:
    raise SystemExit(f'unknown kind: {kind}')
"
}

if [[ "${1:-}" == "--list" || "${1:-}" == "-l" ]]; then
  list_versions
  exit 0
fi

CURRENT="$(python3 -c "import json; print(json.load(open('package.json'))['version'])")"
ARG="${1:-patch}"

if [[ "$ARG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  NEW_VERSION="$ARG"
elif [[ "$ARG" == "patch" || "$ARG" == "minor" || "$ARG" == "major" ]]; then
  NEW_VERSION="$(bump_semver "$CURRENT" "$ARG")"
else
  echo "Usage: $0 [patch|minor|major|X.Y.Z]" >&2
  echo "       $0 --list" >&2
  exit 1
fi

echo "Bumping train: $CURRENT -> $NEW_VERSION"
node scripts/sync-plugin-versions.js "$NEW_VERSION"

echo
echo "Done. For a formal release prefer:"
echo "  npx changeset          # record the change"
echo "  git commit && git push # CI opens version PR → tag → GitHub Release"
echo
echo "Local/hotfix path:"
echo "  update CHANGELOG.md, commit, tag v${NEW_VERSION}, push --tags"
