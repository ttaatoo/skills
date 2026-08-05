# Changesets

Record user-facing changes before they land on `main`. On merge, CI opens a version PR; when that PR merges, CI tags `vX.Y.Z` and a GitHub Release is created.

## Add a changeset

```bash
npx changeset
# or: npm run changeset
```

Pick **patch** / **minor** / **major** for `ttaatoo-skills` and write a short summary of what users should know.

Commit the generated file under `.changeset/` with your skill changes.

## What happens next

1. PR with `.changeset/*.md` merges to `main`.
2. Release workflow opens (or updates) **chore: version skills**.
3. Merging that PR runs `changeset version` + `scripts/sync-plugin-versions.js` (train version → all plugin manifests) and updates `CHANGELOG.md`.
4. Publish step runs `changeset tag` → git tag `vX.Y.Z`.
5. Tag push creates a GitHub Release from the matching `CHANGELOG.md` section.

See [VERSIONING.md](../VERSIONING.md).
