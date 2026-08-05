#!/usr/bin/env bash
# Validate marketplace + per-skill plugin manifests and SKILL.md frontmatter.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
errors=0

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "skip: $1 not installed"
    return 1
  fi
}

check_skill_md() {
  local skill="$1"
  local file="skills/${skill}/SKILL.md"
  if [[ ! -f "$file" ]]; then
    echo "FAIL: missing $file"
    errors=$((errors + 1))
    return
  fi
  if ! head -1 "$file" | grep -q '^---$'; then
    echo "FAIL: $file missing YAML frontmatter"
    errors=$((errors + 1))
    return
  fi
  if ! grep -qE '^name:[[:space:]]*' "$file"; then
    echo "FAIL: $file missing name: in frontmatter"
    errors=$((errors + 1))
  fi
  if ! grep -qE '^description:[[:space:]]*' "$file"; then
    echo "FAIL: $file missing description: in frontmatter"
    errors=$((errors + 1))
  fi
  echo "ok  SKILL.md  $skill"
}

check_json() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "FAIL: missing $file"
    errors=$((errors + 1))
    return
  fi
  if ! python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
    echo "FAIL: invalid JSON $file"
    errors=$((errors + 1))
    return
  fi
  echo "ok  json      $file"
}

echo "== JSON manifests =="
check_json ".claude-plugin/marketplace.json"
check_json ".claude-plugin/plugin.json"
check_json ".codex-plugin/plugin.json"
check_json ".agents/plugins/marketplace.json"

for d in skills/*/; do
  name="$(basename "$d")"
  check_json "skills/${name}/.claude-plugin/plugin.json"
  check_json "skills/${name}/.codex-plugin/plugin.json"
done

echo
echo "== SKILL.md frontmatter =="
for d in skills/*/; do
  check_skill_md "$(basename "$d")"
done

echo
echo "== Version consistency (Claude plugin.json ↔ marketplace entry) =="
python3 <<'PY'
import json, sys
from pathlib import Path

mp = json.loads(Path(".claude-plugin/marketplace.json").read_text())
errors = 0
by_name = {p["name"]: p for p in mp["plugins"]}

root = json.loads(Path(".claude-plugin/plugin.json").read_text())
if by_name.get("all", {}).get("version") != root.get("version"):
    print(f"FAIL: all bundle version mismatch marketplace={by_name.get('all',{}).get('version')} plugin.json={root.get('version')}")
    errors += 1
else:
    print(f"ok  all                  {root['version']}")

for skill_dir in sorted(Path("skills").iterdir()):
    if not skill_dir.is_dir():
        continue
    name = skill_dir.name
    plugin_path = skill_dir / ".claude-plugin" / "plugin.json"
    if not plugin_path.exists():
        print(f"FAIL: missing {plugin_path}")
        errors += 1
        continue
    ver = json.loads(plugin_path.read_text())["version"]
    mver = by_name.get(name, {}).get("version")
    if mver != ver:
        print(f"FAIL: {name} version mismatch marketplace={mver} plugin.json={ver}")
        errors += 1
    else:
        print(f"ok  {name:<20} {ver}")

    codex = skill_dir / ".codex-plugin" / "plugin.json"
    if codex.exists():
        cver = json.loads(codex.read_text())["version"]
        if cver != ver:
            print(f"FAIL: {name} codex version {cver} != claude {ver}")
            errors += 1

sys.exit(1 if errors else 0)
PY
if [[ $? -ne 0 ]]; then
  errors=$((errors + 1))
fi

echo
if need claude; then
  echo "== claude plugin validate =="
  if claude plugin validate .; then
    echo "ok  claude plugin validate ."
  else
    echo "FAIL: claude plugin validate ."
    errors=$((errors + 1))
  fi
  for d in skills/*/; do
    name="$(basename "$d")"
    if claude plugin validate "skills/${name}"; then
      echo "ok  claude plugin validate skills/${name}"
    else
      echo "FAIL: claude plugin validate skills/${name}"
      errors=$((errors + 1))
    fi
  done
fi

echo
if [[ "$errors" -gt 0 ]]; then
  echo "Validation failed with $errors error(s)."
  exit 1
fi
echo "All checks passed."
