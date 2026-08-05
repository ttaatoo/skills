# Go Naming Rule Bank

Deep reference for the quick rules in SKILL.md. Organized by what you're naming.
Read the section relevant to your current decision; you rarely need the whole file.

Rules here are form-layer: most are citable to Effective Go, Google's style guide, Code
Review Comments, or stdlib practice, and many are lint-enforceable — see
[tooling.md](tooling.md) for which tool catches which. The judgment-heavy layer lives in
[semantic-naming.md](semantic-naming.md).

## Contents

1. [Packages](#1-packages)
2. [Directories](#2-directories)
3. [Files](#3-files) — incl. **reserved suffixes that change the build**
4. [Acronyms and initialisms](#4-acronyms-and-initialisms)
5. [Receivers](#5-receivers)
6. [Getters, setters, methods](#6-getters-setters-methods)
7. [Functions](#7-functions)
8. [Interfaces](#8-interfaces)
9. [Errors](#9-errors)
10. [Variables and parameters](#10-variables-and-parameters)
11. [Constants](#11-constants)
12. [Struct fields and types](#12-struct-fields-and-types)
13. [Tests](#13-tests)
14. [Type parameters (generics)](#14-type-parameters-generics)
15. [Doc comments](#15-doc-comments)
16. [Module and import paths](#16-module-and-import-paths)
17. [Words to avoid](#17-words-to-avoid)

---

## 1. Packages

The package name is typed by every importer, forever. It is the highest-leverage name in
the codebase.

**Rules**

- Lowercase, single word, no underscores or mixedCaps: `base64`, `json`, `githubconnector`.
- **Singular vs plural is not the rule** (a common over-correction). Prefer singular when
  the package provides *a thing* (`connector`, not `connectors`), but plural is canonical
  when the package provides **operations over a kind of value** — the stdlib is full of it:
  `strings`, `bytes`, `errors`, `slices`, `maps`, `bits`. What actually goes wrong is the
  **plural role-word grab-bag**: `adapters`, `models`, `handlers`, `helpers` collect
  unrelated things and collide when two of them want the same import name. Judge by
  "is this one thing?", not by the trailing `s`.
- Short — everyone types it. Err toward brevity; a doc comment is worth more than a long name.
- Named for what it **provides**, not a role word: `ids`, `timefmt`, `safego`, `csvx`.
  Never `util`, `utility`, `common`, `helper`, `misc`, `base`, `shared`, `tools`.
  A package mixing env helpers + time formatting + string dedupe + ID factories is not one
  thing; split it. If you can't say what the package provides in one noun, it's two packages.
  - `types` is on the same list **only when it's a grab-bag** (a package holding every
    struct in the service, so call sites read `types.User`, `types.Order`,
    `types.Whatever`). It is a legitimate name when the package genuinely provides a type
    system — `go/types` is stdlib. Same for `models`: the smell is the role word standing
    in for a domain word, not the spelling.
- Don't shadow names importers will also need from stdlib or big dependencies: `errors`,
  `sql`, `context`, `http`, `kubernetes`. Shadowing `errors` once forced 230 files in one
  codebase to carry an import alias. Prefer `apperr`, `errcodes`, `dbsql`, `kuberuntime`.
- Avoid package names that double as common local-variable names — a local `buf` shadows
  the import `buf` on the first `buf := …`, making the package unreachable in that
  function. The stdlib picks `bufio` over `buf` for exactly this reason. The shadow-stdlib
  rule above is the severe case; this is the mild, easy-to-miss one.
- Package name = directory base name. Intentional deviation is fine **only** to disambiguate
  at the call site: directories `github/`, `gitlab/`, `lark/` declaring
  `package githubconnector` etc., so call sites read `githubconnector.Connector`. Do this
  on purpose and consistently, or not at all.
- Don't repeat the package name in exported identifiers. The importer sees
  `pkg.Name`, so the package word is already there:
  - ❌ `exporttask.ExportTaskStatus`, `user.UserService`, `bufio.BufReader`, `sheets.SheetsService`
  - ✅ `exporttask.Status`, `user.Service`, `bufio.Reader`, `sheets.Client`
  - Single main type in a package: constructor is `New`, read as `ring.New` — not `NewRing`.
- Proto-generated packages: rename on import to drop underscores and add `pb`:
  `complaintpb "…/gen/complaint_analysis"`. Keep the local alias consistent everywhere.

**Import aliases** follow the same rules (lowercase, no underscores) and the same package
gets the same alias in every file.

## 2. Directories

Directory names are not Go identifiers — underscores are *legal* — but they become package
names, so the package rules mostly apply.

- **One casing style per repo.** The most common failure is two styles under the same
  parent: `pkg/handler/complaint_analysis/` beside `pkg/handler/accesscontrol/`. New code
  follows the repo's *dominant* style, not the nearest neighbor's.
- Joined lowercase (`accesscontrol`, `entitydictionary`) and snake_case (`data_center`)
  are both seen in the wild; kebab-case is conventional only for `cmd/` binaries
  (`cmd/example-server/`) and non-Go dirs (`tools/e2e-framework/`, `testdata/*`). Never
  camelCase or PascalCase (`ConfigTemplate/` is a smell).
- No meaningless path segments: `sdk/connectors/sdk/go/` says nothing and stutters;
  `rpc/larkrpc/` says "rpc" twice. Name each level for what lives in it.
- testdata fixtures may use kebab-case freely.

## 3. Files

### Reserved suffixes: a file name can silently change the build

This is the only naming mistake in Go that changes program behavior instead of just
readability, and it fails **silently** — the file compiles fine, it just isn't there.

- `_test.go` — test-only. Code your production build needs must not live here.
- `_<GOOS>.go` and `_<GOARCH>.go` — an implicit build constraint, no `//go:build` line
  required. `metrics_linux.go` is compiled **only on Linux**. Name a Linux-metrics
  collector `metrics_linux.go` and every `go test` on a macOS laptop passes while the
  symbol simply doesn't exist there; the failure surfaces in CI as `undefined:`, or worse,
  as a silently-missing registration.
  - The full list is the `GOOS`/`GOARCH` value sets (`linux`, `darwin`, `windows`, `js`,
    `plan9`, `android`, `ios`, …; `amd64`, `arm64`, `386`, `wasm`, …), plus the combined
    form `name_linux_amd64.go`. `_unix.go` is **not** magic; `_js.go` and `_ios.go` are.
  - Want the word in the name without the constraint? Put it first or in the middle:
    `linux_metrics.go`, `metrics_linuxcgroup.go`. Want the constraint? Use the suffix *and*
    say so in a comment, so the next reader knows it's deliberate.
- A leading `_` or `.` (`_scratch.go`, `.old.go`) — **ignored by the go tool entirely**.
  Not a build tag, not an error: invisible. This is the trap behind "my file isn't
  compiling and there's no error".
- `testdata/` as a directory name is likewise ignored by the go tool.

Check with `go build ./...` after adding a file; a suffix mistake shows up there and
nowhere else.

### The conventions

- **Match the local family.** In a directory of `*_repo.go` files, write `x_repo.go` —
  not `x_repository.go` and not unsuffixed `x.go`. Suffix drift (`_repo` ×32 vs
  `_repository` ×7 in one directory) is pure noise.
- **Never name the file after its package.** `strutil/strutil.go` forces the reader to open
  it to learn anything; `jsonutil/json.go` + `value.go` tells you what's inside from the
  file list. Split by concept.
- **One operation per file, named after it**, for handlers/usecases:
  `get_workspace.go`, `create_workspace.go`, `list_sessions.go`. Makes the package
  navigable by filename alone.
- Go source files conventionally use snake_case (`signal_grouping_runtime.go`). This is
  fine and legal — just keep it uniform.
- Mocks: pick one convention per repo (`x_mock.go` is most common) — not `service_mock.go`
  here, `mock.go` there, `interface_mock.go` elsewhere.
- Long package docs go in `doc.go`.

## 4. Acronyms and initialisms

All letters of an initialism share one case: all caps when any part is exported, all lower
when fully unexported.

| ✅ | ❌ |
|---|---|
| `ID`, `userID`, `UserID` | `Id`, `userId`, `UserId` |
| `URL`, `sourceURL`, `SourceURL` | `Url`, `sourceUrl`, `SourceUrl` |
| `JSON`, `cardJSON` | `Json`, `cardJson` |
| `HTTP`, `HTTPServer` | `Http`, `HttpServer` |
| `API`, `APIBaseURL`, `EncryptAPIKey` | `Api`, `ApiBaseUrl` |
| `OAuth`, `OAuthProvider` | `Oauth`, `OauthProvider` |
| `DB`, `Tx` | `Db`, `Txn` (acceptable, but pick one per repo) |
| `UUID`, `ULID`, `IDE`, `RPC`, `S3` | `Uuid`, `Ulid`, `Ide` |

Multi-acronym names keep each initialism internally uniform: `IDEUpstreamProber`,
`OAuthCallbackURL`. `UID` is a legitimate initialism; `IUid` is not a word — avoid
unpronounceable stacks.

The #1 source of violations is generated code — see [generated-code.md](generated-code.md).
The second is muscle memory from other languages.

## 5. Receivers

- 1–2 letters, an abbreviation of the type: `(s *service)`, `(h *Handler)`,
  `(r *ChatRepository)`, `(c *Client)`.
- **The same name for every method of the type, in every file.** This is the rule most
  often broken. If `registryCore` is `c` in helpers and `uc` in the main file, one of them
  is wrong — fix to whichever the majority uses.
- Never `this` or `self` (Java/Python leakage). Never the full type name
  (`(controller *controller)`, `(service *service)` — the type word appears three times
  per signature). Omit the name entirely if unused: `func (T) String() string`.
- Value vs pointer: be consistent per type (mixing value and pointer receivers on one type
  changes identity semantics).
- House style may mandate a longer receiver for a specific aggregate role (e.g. always
  `provider` for runtime providers). That's legitimate **if enforced uniformly** — the sin
  is mixing short and long receivers for one type.
- Established shorthand is good: `w` for `http.ResponseWriter`/`io.Writer`, `r` for
  `io.Reader`/`*http.Request`, `ctx` for `context.Context`.

## 6. Getters, setters, methods

- A getter is the field name, exported: field `owner` → method `Owner()`. Never `GetOwner()`.
  Export casing is exactly what distinguishes field from method — `Get` adds nothing.
- Setter keeps `Set`: `SetOwner(user)`.
- If the operation is expensive or remote, the name should say so: `ComputeChecksum`,
  `FetchReport` — not `Get` for something that does real work.
- Don't generate bean-style getter/setter pairs on Go structs. Expose the field, or provide
  a method only when there's logic. A struct with `GetClient()`/`SetClient()` wrapping one
  field is a Java object wearing a Go costume.
- Canonical method names (`Read`, `Write`, `Close`, `Flush`, `String`, `Format`) carry
  canonical signatures and meanings. Don't borrow them for different behavior; do reuse
  them (same signature + meaning) so your type satisfies the standard interfaces for free.
  `String()`, never `ToString()`.

## 7. Functions

Omit from the name: the package (it's in the qualifier), the receiver type, parameter
names, return types, pointer-ness.

- ❌ `yamlconfig.ParseYAMLConfig(s)` → ✅ `yamlconfig.Parse(s)`
- ❌ `c.WriteConfigTo(w)` → ✅ `c.WriteTo(w)`
- ❌ `OverrideFirstWithSecond(dest, src)` → ✅ `Override(dest, src)`
- ❌ `TransformToJSON(in)` → ✅ `Transform(in)`
- Add a disambiguating word only when a sibling forces it: `WriteTextTo` beside `WriteTo`.
- **Verb if it does, noun if it returns.** Actions: `Write`, `Flush`, `Send`. Computations:
  `JobName(key) (string, bool)` — not `GetJobName`. Map-lookups returning `(value, ok)`
  read perfectly as nouns.
- Type-specific variants put the type last: `ParseInt`, `ParseInt64`; the primary form
  drops it: `Marshal()` / `MarshalText()`.
- Named result parameters: use when repeated types need labels
  (`(value, nextPos int)`) or a deferred closure must write them. Don't use them just to
  skip a local var declaration, and don't naked-return from a long function.

## 8. Interfaces

- One-method interface: method name + `-er` (or agent noun): `Reader`, `Writer`,
  `Formatter`, `Uploader`, `Presigner`, `SecretEncryptor`, `CredentialTester`.
- No `I` prefix (`IUserService`), no `Interface` suffix
  (`EnumOptionRepositoryInterface` — the word "interface" twice). The `interface` keyword
  at the declaration already says what it is.
- **The consumer defines the interface** it needs, next to where it's used — small,
  ability-based, 1–3 methods. Keep internal-only interfaces unexported.
- Take interfaces, return concrete types.
- Behavior-specific mocks/fakes name the behavior: `AlwaysDeclines`, `StubStoredValue`;
  helper test packages append `test`: `package creditcardtest`.

## 9. Errors

**The split that matters: values get a prefix, types get a suffix.** Both spellings are
correct Go — for different things. Getting this backwards is the most common error-naming
mistake.

| Kind | Convention | Stdlib | ❌ |
|---|---|---|---|
| Sentinel **value** (`var`, `errors.New`) | `ErrXxx` / unexported `errXxx` | `io.EOF`, `os.ErrNotExist`, `sql.ErrNoRows` | `NotFoundErr`, `ErrorNotFound` |
| Error **type** (`struct` implementing `error`) | `XxxError` | `os.PathError`, `json.SyntaxError`, `net.OpError` | `ErrPathStruct`, `PathErr` |

- Sentinels: `ErrCacheMiss`, `ErrTooManyRows`, unexported `errFenceLost`. The `Err` prefix
  asserts "this value is an `error`" — never use it for numeric codes
  (`ErrDatabaseInsert = 11741` lies; call it `CodeDatabaseInsert`).
- Types: `type NotFoundError struct{}` with `func (e *NotFoundError) Error() string`.
  Reach for a type only when callers need **fields** off the error (which path, which
  field, which retry-after); otherwise prefer a sentinel value plus `fmt.Errorf("%w")`
  wrapping, and let callers use `errors.Is`/`errors.As`.
- Never `ErrorXxx` for either, and never the abbreviated `-Err` suffix (`ParseErr`).
- Error **strings**: lowercase, no trailing punctuation (they get wrapped),
  origin-prefixed when useful: `"rowmap: too many rows"`, `"image: unknown format"`.

## 10. Variables and parameters

- Length ∝ scope, ∝ 1/frequency-of-use. `i` for a tight loop; `r` for a request used twice;
  `cfg`, `buf` inside a function; full words for anything exported or package-wide.
- Single letters only where the full word is obvious: loop indices `i j k`, `ctx`, `err`,
  `w`/`r` for the http pair, `ok`.
- Nouns; no type in the name — the compiler knows the type:
  - ❌ `numUsers`, `usersInt` → ✅ `userCount`
  - ❌ `userSlice`, `userMap` → ✅ `users`, `usersByID`
- No redundant context: inside `func (u *User) Count()`, a local `userCount` is noise —
  it's just `count`.
- Don't mutilate words to save typing (`usrCnt`); abbreviate whole words or not at all.
- Don't shadow popular package names (`ctx`, `err`, `json`, `http`) as long-lived locals.
- `err` reused via `:=` down a function is idiomatic; a fresh word per error
  (`err1`, `errRead`, `errParse`) is only for when they must coexist.

## 11. Constants

- MixedCaps like every Go name. Never `SCREAMING_SNAKE_CASE`, never a `K` prefix
  (`KMaxRetries`) — both are imports from C/Java.
- No single-letter constants (`const c = 299792458`). A constant exists to name a *role*;
  one letter names neither the role nor the value and reads as a leftover. Use the role
  (`const speedOfLight`). (Single capitals `T`/`K`/`V` are fine — for *type parameters*,
  a different context; see §14.)
- Name by **role**, not value: `maxRetries`, `defaultPort`, `TimeFormatRFC3339`.
  A constant named `threeHundred` or derived from its own value (`FiveMinutes = 5 * time.Minute`
  with no role) may not deserve to be a constant.
- Untyped constants (`const maxRetries = 3`) are preferred unless the type carries meaning.
- Exported constant groups: give the group a name via `iota` + type
  (`type Status int; const ( StatusActive Status = iota …)`).

## 12. Struct fields and types

- Fields: MixedCaps, acronym rules apply (`UserID`, `SourceURL`, `CardJSON`).
- json/protobuf tags carry the wire name (`user_id`) — the Go field keeps Go casing; the
  tag is where other languages' conventions live. Don't let tag casing bleed into field names.
- Types named for the domain concept: `EventPreview`, `ExportTaskResult`,
  `OperationObjectBindingCandidate`. No `DTO`/`VO`/`DO`/`PO`/`Entity`/`Bean` suffixes —
  those describe layers Go doesn't have. If you feel the need for a suffix, the package
  boundary is doing too little work.
- If a type name exceeds ~30 chars, the package boundary is in the wrong place — the name
  is carrying context the package should carry. `OperationObjectBindingClassifierPromptTestRetrievedCandidateOutput`
  (65 chars) wants to live in a package that already says most of those words.

## 13. Tests

Test names are the one place where naming is **load-bearing for the tool**: `go test`
discovers functions by name, so a misnamed test doesn't fail — it doesn't run.

- `func TestXxx(t *testing.T)` — the character after `Test` must not be a lowercase letter.
  `TestparseEmpty` is silently never run; `TestParseEmpty` and `Test_parseEmpty` both run.
  Same rule for `BenchmarkXxx(b *testing.B)`, `FuzzXxx(f *testing.F)`,
  `TestMain(m *testing.M)`.
- Examples are compiled documentation and their names bind to identifiers:
  `ExampleParse`, `ExampleClient_Do` (method), `ExampleParse_emptyInput` (variant, lowercase
  suffix). A typo'd identifier makes `go vet` complain — that's the `tests` analyzer.
- Naming the scenario: `TestParse_emptyInput` or a subtest
  `t.Run("empty input", …)`. Note `t.Run` **replaces spaces with underscores** in the
  reported name, so `-run 'TestParse/empty_input'` is how you select it. Keep subtest names
  short and free of `/` (which nests) and spaces if you'll be typing them.
- Table-driven fields: `tests`/`cases` for the slice, `tt`/`tc` for the loop variable,
  `name` for the label. `want`/`got` for expectation and result — in that order in messages
  (`got %v, want %v`). Don't mix `expected`/`actual` into a repo that says `want`/`got`.
- Test helpers: `newTestClient`, `mustParse`, `setupX(t *testing.T)`. Helpers call
  `t.Helper()`; the name doesn't have to say "helper".
- Fakes and stubs name the **behavior**, not the pattern: `alwaysDeclines`,
  `stubStoredValue`, `failingWriter` — not `MockThing2`. A separate helper package appends
  `test`: `package creditcardtest`.
- External test package: `package foo_test` in the same directory tests `foo` as an importer
  sees it. This is the only legal underscore in a package clause, and the right default for
  testing exported API surface.

## 14. Type parameters (generics)

- Single capital letters, following the community/stdlib set: `T` (the value), `K`/`V`
  (map key/value), `E` (element of a collection), `S` (the slice/sequence itself, usually
  constrained `S ~[]E`), `R` (result of a transform), `F` (function).
  `func Map[E, R any](s []E, f func(E) R) []R`.
- A short word only when a single letter genuinely loses information, and then keep Go
  casing with no prefix: `Req`, `Resp`, `Num`. Never the C#/TypeScript habit of prefixing
  (`TInput`, `TKey`) — Go's convention is bare.
- Constraint interfaces are named for the **ability or set**, like any interface:
  `constraints.Ordered`, `Number`, `Stringer`. No `Constraint` suffix.
- If a function needs more than ~3 type parameters, the names stop helping — that's a
  signal to take a struct or an interface instead.

## 15. Doc comments

Naming and doc comments are coupled: the comment must **start with the identifier's own
name**, so `go doc` output and search read as sentences. This is checked by revive
(`exported`) and stylecheck (`ST1020`–`ST1022`).

- `// Parse converts s into a Config.` — not `// this function parses…`, not
  `// Parses the string`.
- Package comment on exactly one file (`doc.go` when long):
  `// Package timefmt formats timestamps for log output.`
- `// Deprecated: use Status instead.` — tooling (gopls, staticcheck `SA1019`) recognizes
  this exact prefix and will flag callers. Anything else is just prose.
- A doc comment you can't start with the name usually means the name is wrong: if
  `// Handle processes the thing and also writes the audit row` is the honest sentence, the
  function needs splitting or renaming, not a longer comment.

## 16. Module and import paths

- Module path is a URL-ish identifier: **all lowercase**. Uppercase in a module path breaks
  on case-insensitive filesystems and forces `!` escaping in the module cache
  (`github.com/Foo/Bar` → `github.com/!foo/!bar` on disk). Repo names with capitals are a
  real, recurring source of proxy confusion.
- The path is the package's globally-unique identity, not a label: base it on a host/path
  you own (`github.com/yourorg/…`) and, if you publish, make it match where the code is
  fetched from. A path you don't control can collide with someone else's module. Uniqueness
  is convention, not enforced — so pick a path no one else will.
- Major version ≥ 2 puts the version in the path: `module example.com/thing/v2`, imported
  as `thing/v2` — and the last path element (`v2`) is *not* the package name; the package
  is still `thing`.
- `internal/` is compiler-enforced, not a convention: anything under it is importable only
  by code rooted at the parent of `internal/`. Use it as the real boundary rather than
  naming things `private`/`impl`.
- `cmd/<binary>/` — the directory name **is** the produced binary name, so it follows
  binary conventions (kebab-case is fine: `cmd/example-server/`), while the package inside
  is `main`.
- Don't repeat the module name in inner paths: `github.com/acme/lark/lark/client` reads
  `lark` twice at every import.
- `pkg/` is a convention some repos use and some reject; either is fine, but a repo with
  both `pkg/` and top-level packages has no boundary at all. Follow whatever is dominant.

## 17. Words to avoid

Zero-information fillers — each one needs an explicit justification or it goes:

`util` `utility` `common` `helper` `helpers` `misc` `base` `shared` `tools`
`manager` `processor` `handler` (as a suffix on a non-handler) `service` (when the package
already says what it serves) `adapter` `info` `data` `object` `item` `thing`
`DTO` `VO` `DO` `PO` `Entity` `Bean` `Impl`

Context-dependent, not banned: `types`, `models`, `errors`, `config` are fine when the
package really provides that one thing (`go/types` is stdlib), and rot when they're a
dumping ground. Ask "is this one thing?" before reaching for the ban list.

And casing imports from other languages: `Get`/`Set` bean pairs, `IXxx` interfaces,
`SCREAMING_CONSTANTS`, `snake_case_identifiers` (outside file names), Hungarian type
prefixes (`strName`, `iCount`).

The test for every name: if you can delete the word and the identifier still means the
same thing, delete it.
