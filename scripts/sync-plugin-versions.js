#!/usr/bin/env node
/**
 * Train versioning: copy package.json version into every plugin / marketplace
 * manifest so Claude, Codex, and the catalog stay aligned.
 *
 * Usage:
 *   node scripts/sync-plugin-versions.js           # use package.json version
 *   node scripts/sync-plugin-versions.js 0.2.0     # set package.json + sync
 */
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");

function readJson(rel) {
  const full = path.join(ROOT, rel);
  return { full, data: JSON.parse(fs.readFileSync(full, "utf8")) };
}

function writeJson(full, data) {
  fs.writeFileSync(full, JSON.stringify(data, null, 2) + "\n");
  console.log(`  ${path.relative(ROOT, full)}`);
}

function setVersion(rel, version, mutator) {
  const { full, data } = readJson(rel);
  mutator(data, version);
  writeJson(full, data);
}

function main() {
  const packagePath = path.join(ROOT, "package.json");
  const pkg = JSON.parse(fs.readFileSync(packagePath, "utf8"));
  const explicit = process.argv[2];
  const version = explicit || pkg.version;

  if (!/^\d+\.\d+\.\d+$/.test(version)) {
    console.error(`Invalid semver: ${version}`);
    process.exit(1);
  }

  if (explicit && explicit !== pkg.version) {
    pkg.version = version;
    writeJson(packagePath, pkg);
  } else {
    console.log(`Train version: ${version}`);
  }

  console.log("Syncing plugin manifests:");

  setVersion(".claude-plugin/plugin.json", version, (d, v) => {
    d.version = v;
  });

  setVersion(".codex-plugin/plugin.json", version, (d, v) => {
    d.version = v;
  });

  setVersion(".claude-plugin/marketplace.json", version, (d, v) => {
    if (d.metadata) d.metadata.version = v;
    for (const p of d.plugins || []) {
      p.version = v;
    }
  });

  const skillsDir = path.join(ROOT, "skills");
  for (const name of fs.readdirSync(skillsDir).sort()) {
    const skillPath = path.join(skillsDir, name);
    if (!fs.statSync(skillPath).isDirectory()) continue;

    for (const rel of [
      path.join("skills", name, ".claude-plugin", "plugin.json"),
      path.join("skills", name, ".codex-plugin", "plugin.json"),
    ]) {
      const full = path.join(ROOT, rel);
      if (!fs.existsSync(full)) continue;
      setVersion(rel, version, (d, v) => {
        d.version = v;
      });
    }
  }

  console.log("Done.");
}

main();
