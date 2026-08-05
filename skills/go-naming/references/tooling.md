# Make Tools Hold the Form Layer

Every naming rule falls in one of three buckets. Know which, and you stop spending
attention where a machine is faster:

1. **A tool enforces it** — never review this by eye. Put the tool in CI instead.
2. **Convention, no tool** — needs a human, but is mechanical (grep helps).
3. **Semantic** — needs someone who read the body. This is where review time belongs.

## Rule → tool map

| Rule | Tool | Check |
|---|---|---|
| Initialism casing (`Id`→`ID`, `Url`→`URL`) | staticcheck / `stylecheck` | `ST1003` |
| Underscores or ALL_CAPS in identifiers | staticcheck | `ST1003` |
| Receiver name consistent per type, not `this`/`self` | revive | `receiver-naming` |
| Var/param naming (`userSlice`, single-letter misuse) | revive | `var-naming` |
| Exported decl has a doc comment, comment starts with the name | revive / stylecheck | `exported`, `ST1020`–`ST1022` |
| Package comment starts `Package x` | stylecheck | `ST1000` |
| Package name has underscores / mixedCaps | revive | `var-naming` (package scope) |
| `Error()` string is lowercase, unpunctuated | staticcheck | `ST1005` |
| Malformed `TestXxx`/`ExampleXxx` signature or suffix | `go vet` | `tests` analyzer |
| Unused / shadowed names | `go vet`, `golangci-lint` | `shadow`, `unused` |
| File silently excluded by a `_linux.go`-style suffix | `go build ./...`, `gofmt -l` | build constraint |
| Import alias inconsistency | `gci` / `importas` | `importas` (pin one alias per path) |
| Formatting, receiver spacing, etc. | `gofmt` / `gofumpt` | — |

Not covered by any linter — the reason this skill exists: package-name stutter
(`exporttask.ExportTaskStatus`), filler words (`Manager`, `DTO`), verb/cost mismatch
(`Get` doing a network call), absence semantics (`(nil, nil)` from a `Get`), hidden
mutation, synonym drift across a codebase, and house-style conformance.

## Minimal `.golangci.yml` for naming

```yaml
version: "2"
linters:
  enable:
    - revive
    - staticcheck
    - govet
    - importas
  settings:
    revive:
      rules:
        - name: var-naming
        - name: receiver-naming
        - name: exported
          arguments: [checkPrivateReceivers]
        - name: error-naming      # sentinel values must be Err*/err*
        - name: error-strings
        - name: increment-decrement
    staticcheck:
      checks: ["all"]             # ST1003 and friends are off unless you say this
    importas:
      no-unaliased: false
      alias:
        - pkg: myservice/gen/complaint_analysis
          alias: complaintpb      # one alias per generated package, repo-wide
```

`staticcheck`'s `ST*` (stylecheck) rules are **not** on by default in golangci-lint — the
`checks: ["all"]` line is what turns initialism enforcement on. This is the single
highest-value line in the file: `ST1003` alone removes most `Id`/`Url`/`Json` drift.

### Guarding the generated-code firewall

`ST1003` won't help inside `gen/`, and you don't want it to. Instead, forbid the generated
casing everywhere *except* the generated tree and the mapper files:

```yaml
  settings:
    forbidigo:
      analyze-types: true
      forbid:
        - pattern: '\.(Get)?[A-Za-z]*(Id|Url|Json)\b'
          msg: "generated-code casing outside a mapper — see go-naming/references/generated-code.md"
issues:
  exclude-rules:
    - path: '(^|/)gen/'          # generated tree
      linters: [forbidigo, revive, staticcheck]
    - path: '_(mapper|converter)\.go$'   # the firewall itself
      linters: [forbidigo]
```

Pick one mapper filename convention (`*_converter.go` or `*_mapper.go`) so this exclusion
stays a two-line rule rather than a growing list.

## Commands, in the order to run them

```bash
gofmt -l ./...          # unformatted files; also reveals files the go tool ignores
go build ./...          # a file lost to an accidental _linux.go suffix shows up as
                        # "undefined: X" here and nowhere else
go vet ./...            # malformed test/example names, shadowing
staticcheck ./...       # ST1003 initialisms, ST1005 error strings
golangci-lint run       # everything above plus revive's receiver/var rules
go doc ./pkg/...        # read your own API as an importer sees it — stutter and bad doc
                        # comments are obvious here and invisible in the source file
```

`go doc` is the underused one. `exporttask.ExportTaskStatus` looks fine in its own file and
absurd in `go doc` output; that's the call-site test, automated.

## Renaming safely

- **`gopls rename` (or your editor's rename symbol), never `sed`.** It's type-aware: it
  won't touch a same-named field on a different type, and it updates every package that
  imports yours.
  ```bash
  gopls rename -w ./pkg/exporttask/status.go:12:6 Status
  ```
- Renaming an **exported** identifier in a published module is a breaking change: keep the
  old name as a deprecated alias for one minor version.
  ```go
  // Deprecated: use Status. Will be removed in v2.
  type ExportTaskStatus = Status
  ```
- Renaming a **package** means the directory, the `package` clause, every import path, and
  every alias — do it in one commit, and grep for the old name in non-Go files too
  (Dockerfiles, Makefiles, CI configs, `go:generate` directives).
- Renaming a **file** across a `_test.go` boundary: make sure you don't land on a reserved
  suffix (`_linux.go`, `_amd64.go`) — `go build ./...` is the check.

## When a linter finding and this skill disagree

The linter wins on form (it's the repo's enforced contract, and CI will block you anyway).
This skill wins on semantics, because no linter has an opinion there. If a `tool`-bucket
rule in [SKILL.md](../SKILL.md) isn't enabled in the repo's config, the useful fix is a PR
enabling it — not a review comment asking one author to hand-apply it.
