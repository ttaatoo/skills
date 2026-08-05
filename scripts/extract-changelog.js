#!/usr/bin/env node
/**
 * Print the CHANGELOG.md section for a version (e.g. 0.1.0 or v0.1.0).
 * Falls back to empty string if no matching section.
 */
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const raw = process.argv[2] || "";
const version = raw.replace(/^v/, "");

if (!version) {
  console.error("Usage: node scripts/extract-changelog.js <version>");
  process.exit(1);
}

const changelog = fs.readFileSync(path.join(ROOT, "CHANGELOG.md"), "utf8");
const lines = changelog.split(/\r?\n/);

// Match ## 0.1.0 or ## 0.1.0 — date or ## [0.1.0]
const header = new RegExp(
  `^##\\s+\\[?${version.replace(/\./g, "\\.")}\\]?(?:\\s|$)`
);

let start = -1;
for (let i = 0; i < lines.length; i++) {
  if (header.test(lines[i])) {
    start = i;
    break;
  }
}

if (start === -1) {
  process.exit(0);
}

let end = lines.length;
for (let i = start + 1; i < lines.length; i++) {
  if (/^##\s+/.test(lines[i])) {
    end = i;
    break;
  }
}

const body = lines
  .slice(start + 1, end)
  .join("\n")
  .trim();
process.stdout.write(body ? body + "\n" : "");
