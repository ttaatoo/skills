# Self-check, expanded

The terse checklist in [SKILL.md](../SKILL.md) §7 is the one to run every time. Load this file
when a check is ambiguous, when you need the grep that finds violations, or when you're writing
the review comment and need to state *why* it matters.

Order: run the linters first (§5) — everything in the form-layer table below that has a tool
column is cheaper to find that way than by reading.

## Form layer

| Check | Why it matters | How to find it |
|---|---|---|
| No package-name stutter | The name is always read qualified; `exporttask.ExportTaskStatus` makes the reader parse the same word twice | Read your new identifiers with the package prefix out loud |
| Uniform acronym casing | `Id` beside `ID` on the same struct is the signal that generated code leaked in | `staticcheck` ST1003; `grep -rn 'Id\b\|Url\b\|Json\b' --include='*.go'` |
| Receiver name identical per type | A type with two receiver names makes every future method a coin flip, and diffs stop being greppable | `grep -rn "func (.* \*YourType)"` and compare |
| No `Get`-prefixed accessor | `Get` promises cheap+present; a bare field read doesn't need the promise, and spending `Get` here means you can't use it where it would mean something | `grep -rn 'func (.*) Get[A-Z]'` |
| New file matches the local family | The directory listing *is* the convention; one `_repository.go` among 32 `_repo.go` files teaches the next author the wrong thing | `ls` the directory before you create the file |
| No accidental `_<GOOS>.go` / `_<GOARCH>.go` | `metrics_linux.go` silently drops out of a macOS build — tests pass because the code isn't compiled | `go build ./... && go vet ./...`; `gofmt -l ./...` lists ignored files |
| Test names `go test` discovers | `TestparseEmpty` never runs. A test that never runs is worse than no test: it reads as coverage | `go test -run . -v ./...` and count the names |
| Type params single capitals | `TInput`/`TOutput` is a C#/Java habit; Go's convention makes the constraint position do the explaining | Read the type parameter list |
| Exported doc comment starts with the identifier | `go doc` renders the comment next to the name; a mismatch means one of them is wrong, usually the name | `go doc ./pkg/...` and read the output |
| No grab-bag package, no filler type | `util` and `Manager` are places for the next unrelated thing to land — the name has no boundary to violate | `grep -rn 'package \(util\|utils\|common\|helper\|misc\|base\|shared\)'` |
| Error values `Err*`, error types `*Error` | The prefix/suffix split tells the reader at the call site whether to use `errors.Is` or `errors.As` | `grep -rn 'Err[A-Z].*=\|Err[a-z].*=\|type .*Error\b'` |
| Error strings lowercase, unpunctuated | They get wrapped, and `"Failed to open file.: permission denied"` is the result of ignoring this | `go vet` catches some; read the rest |
| No generated casing outside a mapper | One leak becomes the precedent for the next twenty | `grep -rn 'Id\b' --include='*.go' \| grep -v '_pb\|mapper\|convert'` |

## Semantic layer

No linter reaches any of these. Each is a question about the body, not the string.

**Purpose obvious without a comment.** If you wrote a comment explaining what the function is
*for* (not why it exists, not its contract), the name failed. Delete the comment, fix the name,
and see whether the comment is still needed.

**Verb matches the repo's vocabulary first.** The verb table in
[semantic-naming.md](semantic-naming.md) is a default, not an override. Where the repo or its
ORM already says `Get` for a database read, `Get` is correct *in that repo* — a lone
`FetchUser` next to forty `GetX` methods is the inconsistency, even though the table would have
picked `Fetch`. Grep the surrounding method set before invoking the table.

**No pure-sounding name hides an effect.** `Validate` that writes an audit row, `Format` that
calls a locale service, `Compute` that spawns a goroutine — these are the bugs nobody looks for,
because the name told the reader there was nothing to look for. Also check
`Check`/`Prepare`/`Refresh`, which sound read-only and frequently aren't.

**Absence semantics match the name.** Three shapes, three names:

| Body returns on absence | Correct name |
|---|---|
| an error | `Get*` |
| zero value + `false` | `Lookup*` (comma-ok) or `Find*` |
| `(nil, nil)` | none — this shape has no honest name; change the signature |

**Mutation announced.** A noun method (`Config()`) and a value receiver must not mutate.
Mutating an argument needs `InPlace`/`Into` in the name or a returned copy. A pointer receiver
plus an action verb is the honest form.

**Booleans read as questions.** `IsReady`, `CanRetry`, `HasQuota`. Don't name the negation of a
state you already have a word for — `IsNotReady` beside `IsReady` doubles the vocabulary for one
bit. An inherently negative concept keeps its negative name (`os.IsNotExist` is right).

**Same operation, same verb — across the whole method set you just extended.** This is the check
that has actually failed in benchmarking: given a type with `AcquireLease`/`ReleaseLease`, the
natural pull is to add `DiscardLease` for the broken-lease path. List every existing method name
before you name yours. If a genuinely different contract needs a different verb, document the
difference at the declaration.

**Affix contracts.** `Must*` panics, and only for init-time programmer error. `*f` takes a
format string. `*Context` / `*WithContext` for the ctx-taking variant. Don't spend these affixes
on anything else.

**Deviations documented at the declaration.** Not in the PR description, not in your reply —
future readers see the code. An undocumented deviation reads as a mistake and invites a "fix"
that breaks the intent.

## Reviewing someone else's code

Label every comment with what backs it, per the **Src** column in §4:

- **tool** — "staticcheck ST1003 flags this" → state it as a rule, and if CI doesn't run that
  linter, the real finding is that CI doesn't run that linter.
- **canon** — cite Effective Go / Google's guide / Code Review Comments / stdlib practice.
- **house** — "this repo consistently does X (32 of 33 files)" → say the count. Never dress a
  house preference as "Go requires this"; it burns the credibility of your `tool` and `canon`
  findings.

A finding you can't label is a preference. State it as one, or drop it.
