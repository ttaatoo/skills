#!/usr/bin/env bash
# Bump a skill (or the all-bundle) version so Claude/Codex clients pick up updates.
#
# Usage:
#   scripts/bump-version.sh <skill-name> [new-version]
#   scripts/bump-version.sh all [new-version]
#   scripts/bump-version.sh --list
#
# If new-version is omitted, patches the current semver (0.1.0 -> 0.1.1).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

list_skills() {
  for d in skills/*/; do
    name="$(basename "$d")"
    ver="$(python3 -c "import json; print(json.load(open('skills/${name}/.claude-plugin/plugin.json'))['version'])" 2>/dev/null || echo "?")"
    printf "  %-20s %s\n" "$name" "$ver"
  done
  all_ver="$(python3 -c "import json; print(json.load(open('.claude-plugin/plugin.json'))['version'])" 2>/dev/null || echo "?")"
  printf "  %-20s %s\n" "all (bundle)" "$all_ver"
}

bump_patch() {
  python3 -c "
v = '$1'.split('.')
if len(v) != 3 or not all(p.isdigit() for p in v):
    raise SystemExit(f'not semver: $1')
print(f'{v[0]}.{v[1]}.{int(v[2])+1}')
"
}

set_json_version() {
  local file="$1"
  local version="$2"
  python3 - "$file" "$version" <<'PY'
import json, sys
path, version = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
data["version"] = version
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"  {path} -> {version}")
PY
}

sync_marketplace_entry() {
  local name="$1"
  local version="$2"
  python3 - "$name" "$version" <<'PY'
import json, sys
name, version = sys.argv[1], sys.argv[2]
path = ".claude-plugin/marketplace.json"
with open(path) as f:
    data = json.load(f)
found = False
for p in data.get("plugins", []):
    if p.get("name") == name:
        p["version"] = version
        found = True
if name == "all" and "metadata" in data:
    data["metadata"]["version"] = version
if not found:
    raise SystemExit(f"plugin {name!r} not found in marketplace.json")
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"  {path} entry {name!r} -> {version}")
PY
}

if [[ "${1:-}" == "--list" || "${1:-}" == "-l" ]]; then
  echo "Skills and versions:"
  list_skills
  exit 0
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <skill-name|all> [new-version]" >&2
  echo "       $0 --list" >&2
  exit 1
fi

NAME="$1"
NEW_VERSION="${2:-}"

if [[ "$NAME" == "all" ]]; then
  CURRENT="$(python3 -c "import json; print(json.load(open('.claude-plugin/plugin.json'))['version'])")"
  if [[ -z "$NEW_VERSION" ]]; then
    NEW_VERSION="$(bump_patch "$CURRENT")"
  fi
  echo "Bumping all-bundle: $CURRENT -> $NEW_VERSION"
  set_json_version ".claude-plugin/plugin.json" "$NEW_VERSION"
  set_json_version ".codex-plugin/plugin.json" "$NEW_VERSION"
  sync_marketplace_entry "all" "$NEW_VERSION"
else
  CLAUDE_PLUGIN="skills/${NAME}/.claude-plugin/plugin.json"
  CODEX_PLUGIN="skills/${NAME}/.codex-plugin/plugin.json"
  if [[ ! -f "$CLAUDE_PLUGIN" ]]; then
    echo "Unknown skill: $NAME (missing $CLAUDE_PLUGIN)" >&2
    echo "Available:" >&2
    list_skills >&2
    exit 1
  fi
  CURRENT="$(python3 -c "import json; print(json.load(open('$CLAUDE_PLUGIN'))['version'])")"
  if [[ -z "$NEW_VERSION" ]]; then
    NEW_VERSION="$(bump_patch "$CURRENT")"
  fi
  echo "Bumping $NAME: $CURRENT -> $NEW_VERSION"
  set_json_version "$CLAUDE_PLUGIN" "$NEW_VERSION"
  if [[ -f "$CODEX_PLUGIN" ]]; then
    set_json_version "$CODEX_PLUGIN" "$NEW_VERSION"
  fi
  sync_marketplace_entry "$NAME" "$NEW_VERSION"
fi

echo
echo "Done. Commit the version bumps, push, then users can:"
echo "  Claude:  /plugin marketplace update ttaatoo-skills && /plugin update ${NAME}@ttaatoo-skills"
echo "  npx:     npx skills update ${NAME}"
