---
name: go-naming
description: >
  Use when naming or renaming anything in Go — a file, directory, or package; a type, function,
  method, receiver, interface, error, variable, constant, or struct field — and when reviewing
  Go code for naming. Applies to changes of any size, including one new helper function or a
  single new struct field. 每次写 Go 代码、新建文件/文件夹/包/函数/变量/结构体字段、重命名或
  检查 Go 命名时都必须使用，哪怕只是加一个小函数。
---

# Go Naming

Naming has two layers. A linter polices the **form layer** (casing, prefixes, receivers). The
**semantic layer** — does the name tell the truth about what the code *does*, its cost, and its
side effects? — is where names earn their keep: readers predict behavior from a name and act on
the prediction without reading the body, so every prediction the name gets wrong is a bug
waiting for a trusting caller.

Both layers serve one bar: **a reader grasps what a name is for from the name alone.** A name
that needs a comment to explain its purpose has failed — the comment is patching the name.

Bad names rarely come from not knowing the rules. They come from not looking at the
neighborhood, and from letting generated code or other-language habits (Java beans, `DTO`s,
`SCREAMING_CONSTANTS`) leak in. Work the process: **look → test → name → check**.

## 1. Scope router — run only what the change needs

The full process is for new surfaces. Naming one local variable does not deserve a directory
listing. Pick the row that matches what you are actually doing.

| What you're doing | Run | Skip |
|---|---|---|
| Naming a local, a loop var, or a parameter inside one function | §3 length-vs-scope test only | §2, §4, §7 |
| Adding one function, method, or struct field to an existing type or file | §2 greps for **that type** + §3 four tests + the §7 semantic lines | §4 table (you're not creating a file or package) |
| Creating a file, directory, package, or module | §2 in full + §4 table + §7 in full | — |
| Renaming across files | §2 + §4 + `references/tooling.md` (use `gopls rename`) | — |
| Reviewing someone else's Go code | linters first (§5), then §3 truth test + `references/semantic-naming.md` in full | — |

If a change spans rows, run the widest one. The router bounds the *process*, never the rules:
a name that fails §3 is wrong no matter which row you took.

## 2. Look before you name (non-negotiable for new surfaces)

Inspect the immediate neighborhood and copy its conventions. Two minutes of looking prevents
drift that takes months to clean up.

- **New file** → list the directory. If 32 files are `*_repo.go`, yours is `x_repo.go`, not
  `x_repository.go`, even if you prefer it. Match the local prefix/suffix family exactly.
- **New package/directory** → check sibling casing (joined lowercase `accesscontrol` vs
  snake_case `data_center`) and take the repo's **dominant** style, not the nearest neighbor's
  when the repo is inconsistent.
- **New method on an existing type** → two greps, both mandatory:
  1. the **receiver name** its other methods use — copy it exactly. The worst inconsistency is
     one type with `(c *registryCore)` in one file and `(uc *registryCore)` in another.
  2. the **verb set** already on that type. List every existing method name before naming
     yours, and reuse the verb that covers your operation. A type with
     `AcquireLease`/`ReleaseLease` gets `ReleaseX` for the next teardown — not `DiscardLease`,
     `DropLease`, or `FreeLease`. Synonym drift is invisible unless you look at the whole
     method set at once.
- **New domain identifier** → reuse the vocabulary already in the package. If everything
  nearby says "workspace", don't introduce "project".

**House style beats general advice.** If the project consistently does something unusual (a
type named `Usecase` across 15 packages, `*util` subpackages mandated by an AGENTS.md), follow
it. One consistent unusual choice beats fifteen locally-"better" divergent ones. Deviate only
when the user asks — then **document the deviation where the code lives** (package doc or a
comment at the declaration), not just in your reply. Future readers see the code, not your
justification; an undocumented deviation reads as a mistake and invites a "fix".

## 3. The four tests

**Call-site test** — a name is always read with its package qualifier, so read it as an
importer does. If the package name repeats inside the identifier, delete it.

- ✅ `exporttask.Status` — ❌ `exporttask.ExportTaskStatus` (stutter)
- ✅ `sheets.Client` — ❌ `sheets.SheetsService` (stutter + filler)
- ✅ `githubconnector.Connector` — ❌ `connectors.Connector` (vague qualifier)

If the qualifier itself is vague (`util.FormatTime`, `common.ErrX`), the *package* is the
problem — name it for what it provides (`timefmt`, `apperr`).

**Filler test** — delete words until something would be lost. Zero-information words:
`Manager`, `Processor`, `Handler`, `Helper`, `Util`, `Info`, `Data`, `Service`, `Adapter`, and
the Java imports `DTO`/`VO`/`Entity`/`Bean`.

- `RuleCronJobManager` → "rule cron job job manager" → `RuleScheduler`
- `CellDataProcessor` (stateless struct) → `CellData` + functions, or `CellFormatter`
- `EventPreviewDTO` → `EventPreview` (Go has no DTO layer; it's a struct)

**Length-vs-scope test** — length ∝ scope size, ∝ 1/frequency of use. Loop index `i`;
one-line local `v`, `ok`; function-wide `buf`, `cfg`; package-wide exported type gets full
words. A local named `parsedValidatedSanitizedUserDTO` is a smell; a widely-used exported type
named `d` is worse. If a name must be long to be clear, the function is often doing too much.

**Truth test (the strict one)** — read the body: does it do what the name says, *only* that,
and could the name describe any implementation of the same contract? Readers predict cost,
side effects, and absence behavior from the name alone.

- `GetX` promises cheap + present. A `Get` that hits the network is a `Fetch`; a `Get` that
  returns `(nil, nil)` on absence is a `Find`.
- Pure vocabulary (`Format`/`Parse`/`Validate`/`Compute`/`Normalize`) must not do I/O, mutate
  non-local state, or spawn goroutines. Side effects hidden behind pure-sounding names are the
  most dangerous kind — nobody looks for them there.
- Verbs carry contracts: `Fetch` = remote, `Load` = I/O, `Compute` = CPU, `Find` = may not
  exist, `Lookup` = comma-ok, `Ensure` = create-if-missing, `Must*` = panics, `*f` = format
  string. Pick the verb whose contract matches the body.
- Mutation must be announced: noun methods and value receivers must not mutate; argument
  mutation needs an `InPlace`/`Into` marker or a returned copy.
- Symmetric pairs stay canonical: `Open`/`Close`, `Start`/`Stop`, `Acquire`/`Release`,
  `Marshal`/`Unmarshal` — never `Open`/`Shutdown` coin-flips.
- One concept, one word: `Fetch|Retrieve|Obtain|Get` for the same operation is rot.

Full strict layer — verb table, existence semantics, predicate rules, affix contracts, enum
zero values: [references/semantic-naming.md](references/semantic-naming.md). Load it in full
when reviewing; its verb/affix contracts apply whenever you name a function.

## 4. Quick rules

The **Src** column says which authority a review comment may invoke: **tool** = a linter or the
go tool enforces it (§5); **canon** = citable to Effective Go / Google's style guide / Code
Review Comments / stdlib practice; **house** = this skill's default — good, but argue it as
"this repo does X", never as "Go requires X".

| What | Rule | ✅ | ❌ | Src |
|---|---|---|---|---|
| Package | short, lowercase, one word; no underscores or mixedCaps | `base64`, `githubconnector` | `goUtils`, `complaint_analysis` | canon |
| Package | named for what it provides, never a grab-bag | `ids`, `timefmt`, `safego` | `util`, `common`, `helper`, `misc`, `adapters`, `models` | canon |
| Package | don't shadow a stdlib name importers also need | `apperr`, `dbsql` | `errors`, `sql`, `context` | house |
| Directory | one casing style repo-wide; dir base name = package name | `accesscontrol/` | `complaint_analysis/` beside `accesscontrol/` | house |
| File | match the local family; never name a file after its package | `chat_repo.go` among `*_repo.go` | `user_repository.go` there; `strutil/strutil.go` | house |
| File | **reserved suffixes are build constraints**: `_test.go`, `_<GOOS>.go`, `_<GOARCH>.go`, leading `_` or `.` | `linux_metrics.go` | `metrics_linux.go` — vanishes off Linux | tool |
| File | one operation per file, named after it (handlers/usecases) | `get_workspace.go` | `workspace_service_impl.go` | house |
| Acronyms | uniform all-caps, exported or not | `ID`, `APIBaseURL`, `errIDEStartSuperseded` | `Id`, `ApiBaseUrl`, `IUid` | tool |
| Receiver | 1–2 letters, one name per type across all files, never `this`/`self` | `func (s *service)` everywhere | `(service *service)`; `(c *T)` here / `(uc *T)` there | tool |
| Getter | method = field name; no `Get` | `Owner()` / `SetOwner(x)` | `GetOwner()` — unless it truly fetches/computes | canon |
| Interface | ability noun (usually `-er`); consumer-defined; no `I` prefix, no `Interface` suffix | `Reader`, `Presigner` | `IUserService`, `EnumOptionRepositoryInterface` | canon |
| Canonical names | reuse `String`/`Read`/`Write`/`Close` only with their canonical signature | `func (t T) String() string` | `ToString()`; a `Close` that doesn't close | canon |
| Error | **value** `ErrXxx`/`errXxx`; **type** `XxxError` — prefix for sentinels, suffix for types | `ErrCacheMiss`, `type PathError struct` | `NotFoundErr`; `ErrDatabaseInsert = 11741` (an int is not an error) | canon |
| Variable | noun; never encode the type | `userCount`, `users` | `numUsers`, `userSlice` | canon |
| Constant | MixedCaps; named by role, not by value | `maxRetries`, `DefaultPort` | `MAX_RETRIES`, `KDefaultPort`, `threeHundred` | canon |
| Function | verb if it acts, noun if it returns; never repeat the package, receiver, or params | `config.Parse`, `c.WriteTo(w)` | `yamlconfig.ParseYAMLConfig`, `c.WriteConfigTo` | canon |
| Type variants | type name goes at the end | `ParseInt64`, `MarshalText` | `IntParser.Parse` | canon |
| Tests | `go test` finds tests **by name**: `TestXxx`/`BenchmarkXxx`/`FuzzXxx`/`ExampleT_M`, next letter not lowercase; `got`/`want` | `TestParse_emptyInput` | `TestparseEmpty` (never runs); `expected`/`actual` | tool |
| Type params | single capital: `T`/`K`/`V`/`E`, `S ~[]E`; a word only when the role demands it | `func Map[E, R any](…)` | `func Map[TInput, TOutput any]` | canon |
| Doc comment | starts with the identifier it documents; package comment starts `Package x` | `// Parse reports …` | `// this function parses …` | tool |
| Module path | host/path form you'd plausibly own | `github.com/you/csvdedup` | `csvdedup`, `app`, `mymodule` | canon |

Reasoning, edge cases, and more examples per row: [references/rules-bank.md](references/rules-bank.md).

## 5. Let tools hold the form layer

Every `tool` row above is machine-checkable. Reading 200 identifiers looking for `Id` is work a
linter does for free and better — spend your attention on the semantic layer, which no linter
can reach.

```bash
gofmt -l ./...                    # formatting; also flags files the go tool ignores
go vet ./...                      # includes tests/examples with malformed names
staticcheck ./...                 # ST1003: initialisms, underscores, ALL_CAPS
golangci-lint run                 # revive/stylecheck: receivers, exported doc comments
go doc ./pkg/...                  # if a doc comment reads wrong here, it's named wrong
go build ./... && go vet ./...    # catches a file excluded by an accidental _linux.go
```

When reviewing: **run the linters first**, then read for semantics. If a finding is one a
linter would have caught, the real fix is enabling that linter in CI. Config, coverage limits,
and safe renaming (`gopls rename` over `sed`): [references/tooling.md](references/tooling.md).

## 6. Generated code is a firewall

protobuf-generated Go emits `SessionId`, `ApiBaseUrl`, `GetHeroId()`. You can't fix generated
code; your job is to stop its casing and JavaBean getters from colonizing hand-written code —
the single most common source of `Id`/`Url` in otherwise-clean codebases.

- Hand-written types always use correct casing: `SessionID`, `APIBaseURL`, `HeroID`.
- Conversion happens exactly once, in a mapper, where both casings sit on adjacent lines
  (`SessionId: turn.SessionID`). That mapper is the only file you own where `Id` may appear.
- Never let generated getters (`req.GetPostUrl()`) into your own interfaces — yours say
  `PostURL() string`.

Patterns and lint guards: [references/generated-code.md](references/generated-code.md).

## 7. Self-check before you finish

Against what you just wrote. Each line is a pass/fail question, not a reminder — expanded
version with rationale and examples in [references/self-check.md](references/self-check.md).

Form layer:

- [ ] No package-name stutter, no vague qualifier (§3 call-site)
- [ ] Acronyms uniformly cased: `ID`/`URL`/`JSON`/`HTTP`/`API`/`DB`/`Tx`/`OAuth`/`UUID`
- [ ] Receivers ≤2 chars, identical for every method of the type, no `this`/`self`
- [ ] No new `Get`-prefixed accessor; no `I`-prefixed or `-Interface`-suffixed interface
- [ ] New files/packages match the local family (§2); no accidental `_<GOOS>.go`/`_<GOARCH>.go`
- [ ] Test/benchmark/fuzz/example names are ones `go test` discovers; comparisons use `got`/`want`
- [ ] Type params are single capitals; every exported doc comment starts with its identifier
- [ ] No grab-bag package; no `DTO`/`Manager`/`Processor` filler
- [ ] Errors: `Err*`/`err*` values, `*Error` types; strings lowercase and unpunctuated
- [ ] No generated-code casing (`Id`/`Url`/`Json`) outside a mapper (§6)

Semantic layer — the part linters can't reach:

- [ ] Purpose obvious without a comment
- [ ] Verbs match the **repo's** vocabulary first, then §3 — where the repo already says `Get`
      for a DB read, match it; consistency outranks the table
- [ ] No pure-sounding name hides I/O, mutation, or a goroutine (also check
      `Check`/`Prepare`/`Refresh`)
- [ ] `Get` errors on absence, never `(nil, nil)`; `Find`/`Lookup` treat absence as normal
- [ ] Mutation announced: pointer receiver + action verb, `InPlace`/`Into`, or a returned copy
- [ ] Booleans read as questions; symmetric pairs canonical; no negation of a state that already
      has a word
- [ ] Same verb as the **whole method set of the type you just extended**; `Must*` only for
      init-time panics; `*f` only for format strings
- [ ] Deliberate deviations documented at the declaration
- [ ] Reviewing others' code: every comment labeled per the **Src** column (§4)

## Neighbouring skills

- Idiom and correctness rules beyond naming (`new` vs `make`, receiver kind, field tags,
  interface size, the 100-mistakes catalogue) → **`effective-go`**
- *Whether* to expose a sentinel error or concrete error type at all, whether to launch a
  goroutine, whether an interface earns its complexity → **`dave-cheney-go`**. That skill
  decides whether the thing should exist; this one names it once it does.

A bad name that lands is a convention the next ten files will copy. Fix it now.
