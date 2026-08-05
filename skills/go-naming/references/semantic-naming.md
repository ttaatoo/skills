# Semantic Naming: The Name Must Tell the Truth

The form layer (casing, prefixes, receivers) a linter can police. The semantic layer is
where names earn their keep: a reader **predicts behavior from a name and acts on that
prediction without reading the body**. Every prediction the name gets wrong is a bug
waiting for a trusting caller. A name that lies is worse than a bad name — it actively
misleads, and the betrayal compounds at every call site.

This is the strict layer. When writing or reviewing, hold every name to it.

## Two kinds of rule — say which one you're invoking

Almost nothing in this file is enforced by a Go tool, and only some of it is citable to an
official source. Mixing the two up is how a review comment turns into an argument, so each
section is tagged:

- **`[canon]`** — traceable to [Effective Go](https://go.dev/doc/effective_go),
  [Google's Go Style Guide](https://google.github.io/styleguide/go/),
  [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments), or the stdlib's own
  practice. You can assert these.
- **`[house]`** — this skill's opinionated default. Good defaults, and worth adopting
  repo-wide, but **do not present them as "Go requires"**. In review, phrase them as
  "this repo consistently uses X" — and if the repo doesn't, the repo's existing choice
  wins (§6 beats every other section here).

## Contents

1. [The truth test](#1-the-truth-test) `[house]`
2. [The verb system: cost and side effects in the name](#2-the-verb-system) `[house]`
3. [Purity must be readable from the signature](#3-purity) `[mixed]`
4. [Existence semantics: Get vs Find vs Lookup vs Load](#4-existence-semantics) `[house]`
5. [Booleans and predicates](#5-booleans-and-predicates) `[mixed]`
6. [One concept, one word](#6-one-concept-one-word) `[canon]`
7. [Symmetric pairs](#7-symmetric-pairs) `[house]`
8. [Mutation must be announced](#8-mutation-must-be-announced) `[mixed]`
9. [Behavior-bearing suffixes and prefixes](#9-behavior-bearing-affixes) `[canon]`
10. [Enum and constant truth](#10-enums-and-constants) `[mixed]`
11. [Deviations must be documented where the code lives](#11-deviations) `[house]`

---

## 1. The truth test

For every function or method you write or review, ask three questions of the body:

1. **Does it do what the name says?** `ValidateConfig` that *also writes a normalized copy
   back* is lying — validation implies read-only judgment. Split it, or rename to
   `ValidateAndNormalize`.
2. **Does it do *only* what the name says?** `ParseRequest` that registers metrics and
   emits a log line has side effects the name doesn't admit. Side effects in
   pure-sounding functions are the most dangerous kind: nobody looks for them there.
3. **Could the name describe a different implementation of the same contract?** Good:
   `Checksum()` could be CRC or SHA — the contract (deterministic digest) holds. Bad:
   `ReadConfig()` that actually *creates the file with defaults if missing* — the name
   describes an implementation surprise, not a contract.

When the body and the name disagree, **fix whichever is wrong** — often the body (the name
revealed a design muddle), sometimes the name.

## 2. The verb system

**Read this framing before the table.** `[house]` — Go has no official verb→cost mapping,
and the stdlib does not follow one (see "Where the stdlib disagrees" below). The only
canonical piece is Effective Go's getter rule: a getter is `Owner()`, not `GetOwner()`.
Everything below is a **default vocabulary to adopt per repo**, not a rule you can cite at
someone. Its value is that callers predict cost and side effects from the name — which only
works if the whole repo uses one mapping.

| Verb | Contract | Returns when absent | May do I/O? |
|---|---|---|---|
| `GetX` / `X()` | cheap retrieval: field, cache, in-memory map | — (implies present; error if not) | no |
| `Find` | search/query; result **may not exist** | `(nil, nil)` or `(T, bool)` ok | yes |
| `Lookup` | keyed lookup, comma-ok idiom | `(value, ok bool)` | no |
| `Fetch` | retrieval involving a **remote call** | error | yes (network) |
| `Load` | retrieval involving **I/O** (disk, DB), often populates state | error | yes |
| `Compute` | expensive calculation, no I/O | — | no |
| `Read` | consumes from a stream/source, advances position | error / EOF | yes |
| `List` | returns an **ordered collection**, possibly empty, never nil-confusing | empty slice | yes |
| `Count` | cardinality only, no rows | 0 | yes |
| `Create`/`Save`/`Update`/`Delete` | the named mutation — announces the write | error | yes |
| `Apply`/`Update`/`Set` | mutates receiver or argument state | — | maybe |
| `Send`/`Publish`/`Emit`/`Notify` | irreversible outward effect | error | yes |
| `Ensure` | idempotent make-it-so: creates if missing | error | yes |
| `Sync` | reconciles two states, reads AND writes | error | yes |

### Where the stdlib disagrees (do not "fix" these)

| Skill's default | Stdlib counter-example |
|---|---|
| `Get` = cheap, no I/O | `http.Get` does a full network round-trip |
| `Load` = disk/DB I/O | `atomic.Int64.Load`, `sync.Map.Load` — the most common `Load` in modern Go is a cheap in-memory read |
| `Lookup` = in-memory, no error | `net.LookupHost`, `net.LookupIP`, `user.Lookup` all do I/O and return `error`; `os.LookupEnv` is the comma-ok sense |

Two senses of a verb can coexist in a repo as long as **each package picks one and stays
consistent** — `Load` meaning "atomic read" in a metrics package and "read from DB" in a
repository package is fine; alternating within one package is not.

### Framework and generated code keeps its own verbs

sqlc, ent, gorm and protobuf emit `GetUser(ctx, id)` that hits the database. That is not
yours to rename, and hand-written code sitting in the same repository layer should **match
it rather than fight it** — a repository where 40 methods say `Get` and your new one says
`Fetch` is worse than one that is uniformly `Get`. What still applies to generated-code
neighborhoods is the honesty rules below (§4 absence semantics, §8 mutation), plus the
casing firewall in [generated-code.md](generated-code.md).

### What holds regardless of which vocabulary you picked

These four survive any verb mapping — enforce them even when the repo's verbs differ from
the table:

1. **Absence semantics are honest** (§4): nothing that promises presence returns
   `(nil, nil)` for "not there".
2. **Side effects are not hidden in pure-sounding names** (§3): no I/O, mutation, or
   goroutine behind `Format`/`Validate`/`Compute`/a noun method.
3. **One operation, one verb per codebase** (§6): `FetchUser` here, `GetUser` there,
   `RetrieveUser` elsewhere is rot no matter which one you'd have chosen.
4. **Affix contracts hold** (§9): `Must*` panics, `*f` takes a format string.

Violations to flag (relative to the repo's own vocabulary, not the table):

- `GetX` that makes a network/DB call **in a repo whose other remote calls say `Fetch`**.
- `GetX` or a noun method that returns `(nil, nil)` on absence → it's a `Find`.
- `Fetch` that just reads a struct field → it's a `Get` (or just `X()`).
- `Load` that is pure computation → `Compute`.
- A write hidden behind `Get`/`Init`/`Setup`/`Refresh` with no verb admitting the write.
- Two live verbs for one operation in the same codebase.

## 3. Purity

A reader should be able to predict "does this touch the outside world / change anything?"
from signature + name, without reading the body. The signals, in order:

1. **Name**: pure vocabulary = `Format`, `Parse`, `Validate`, `Compute`, `Normalize`,
   `Marshal`, `Encode`, `String`, `Equal`, `Less`, `Is*`, `Has*`. These **must not** do
   I/O, mutate non-local state, or spawn goroutines. If `NormalizeJSON` writes a file,
   the reader was betrayed.
2. **Receiver kind**: value receiver sets the expectation "my object is unchanged".
   Pointer receiver means "may mutate me" — honor it in the verb too
   (`func (s *State) Apply(...)` ✅; `func (s State) Apply(...)` mutating a copy = bug +
   lie).
3. **Parameters**: a pure-sounding function taking pointer/slice/map parameters must not
   mutate them unless the name announces it (§8). `normalize(cfg *Config)` that edits
   `cfg` is lying; `normalizeInto(dst, src *Config)` or `NormalizeCopy(cfg) *Config` is
   not.
4. **`ctx context.Context`**: presence says "I may block, do I/O, or be canceled" — that's
   honest. Absence on a function that does network I/O is a lie by omission.
5. **Return shape**: pure functions return values; side-effecting functions return
   `error` (or nothing). A function returning only `error` is visibly an action;
   a function returning only a value is visibly a query.

Flag: noun or pure-verb names on methods whose bodies contain writes, sends, `time.Now`
coupled to state, randomness coupled to state, or goroutine spawns.

## 4. Existence semantics

The contract around "what if it's not there" must be in the name:

- **`Get`/`X()`** — caller may assume presence; absence is an **error**
  (`ErrNotFound`), never silent `(nil, nil)`.
- **`Find`** — absence is a **normal outcome**: `(nil, nil)`, `(T, bool)`, or an empty
  slice. Never an error for "just not there".
- **`Lookup`** — the comma-ok idiom: `v, ok := m.Lookup(k)`. When the lookup can also
  *fail* as opposed to *miss* (a DNS query, an OS user database), `(T, bool, error)` or
  `(T, error)` is correct — that's what `net.LookupHost` does. What stays fixed is that a
  miss is not an error.
- **`Load`/`Fetch`** — absence is an error, but the verb admits I/O cost.

This section is the strict one **regardless of vocabulary**: whatever verb the repo uses,
the reader must be able to tell from the name whether "not there" is an error, a `false`,
or a nil. Absence semantics are where a wrong prediction turns into a nil dereference.

A `GetUser` that returns `(nil, nil)` when the user doesn't exist forces every caller to
nil-check what the name promised they wouldn't have to. That nil-check will be skipped —
that's the bug. Rename to `FindUser`, or return `ErrUserNotFound`.

Consistency within the codebase matters as much as the individual choice: if the repo's
repositories use `Get` + `ErrNotFound` for single rows and `List` for many, a new
`FetchRecords` that returns `(nil, nil)` is a triple violation.

## 5. Booleans and predicates

- Prefix: `Is`/`Has`/`Can`/`Should`/`Allows` so the value reads as a yes/no question:
  `IsReady`, `HasChildren`, `CanRetry`, `ShouldRetry`. Bare adjectives (`Ready`,
  `Enabled`) are acceptable as struct **fields** (`if cfg.Enabled`), but exported
  **methods** and package-level vars want the predicate prefix.
- **Don't name the negation of a state you already have a positive word for**:
  `IsNotReady` beside `IsReady`, `Disable`-as-bool. They invert every call site into a
  double negative (`if !isNotReady`). Name the positive and let callers negate —
  `!IsReady` reads correctly.
  - Exception, with stdlib precedent: when the **concept itself** is an absence or a
    failure classification, the negative *is* the positive name — `os.IsNotExist(err)`,
    `errors.Is(err, fs.ErrNotExist)`, `ErrNotFound`. There is no sensible `Exists(err)`
    for "this error means it wasn't there". The test is not "does the name contain a
    negation" but "does the common call site need a `!`".
- The true/false meaning must be obvious without reading the body. `CheckStatus() bool`
  says nothing — which value is good? `IsHealthy() bool` does.
- Config/options: `WithX` sets a positive; avoid `WithNoX` / `WithoutX` unless the
  default is "with" (`WithoutRetry` is fine when retry is default-on).

## 6. One concept, one word

The strongest signal of a disciplined codebase: the same operation has the same name
everywhere. Uber's guide puts it flatly — "Above all else, be consistent."

- One verb per operation kind (§2's table is the menu; choose once per repo).
- One noun per domain concept. If the domain says "workspace", no `project`/`env`/
  `sandbox` synonyms for the same thing (distinct concepts getting distinct names is
  correct — synonyms for one concept is rot).
- Same signature shape for same-named operations across types: every `Save` takes the
  entity and returns `error`; every `String()` takes nothing and returns `string`.
- Canonical names (`Read`/`Write`/`Close`/`Flush`/`String`/`Format`) keep their standard
  signatures and meanings — reuse them only when you mean exactly that, so standard
  interfaces come for free.

When reviewing, grep for synonym clusters (`Fetch|Retrieve|Obtain|Get`, `Delete|Remove|
Destroy|Purge|Drop`) — more than one live verb for the same operation is a finding.

## 7. Symmetric pairs

Operations with inverses must use the canonical pair, and use both halves consistently:

`Open`/`Close` · `Start`/`Stop` · `Begin`/`End` (transactions) · `Acquire`/`Release`
(locks, leases) · `Lock`/`Unlock` · `Marshal`/`Unmarshal` · `Encode`/`Decode` ·
`Subscribe`/`Unsubscribe` · `Register`/`Unregister` · `Enable`/`Disable` ·
`Increment`/`Decrement`

Flag: `Open` with no `Close` (or a `Close` paired with `Shutdown`), `Start`/`Terminate`
mixes, `Marshal`/`Deserialize` crosses. If a type has one half of a pair, the other half
gets the canonical partner name — not a coin-flip synonym.

## 8. Mutation must be announced

If a function changes state that outlives the call — receiver, pointer/slice/map
arguments, globals, the outside world — the name must say so:

- Receiver mutation: action verbs (`Apply`, `Update`, `Set`, `Reset`, `Add`, `Remove`,
  `Append`) plus pointer receiver. A noun method (`Config`, `Options`, `Status`) must not
  mutate.
- Argument mutation: announce with direction/marker — `SortInPlace(xs)`,
  `FillInto(dst, src)`, or return the mutated copy instead (`Sorted(xs)`). A function
  named `Merge(a, b)` that edits `a` and returns nothing is the classic ambush;
  `MergeInto(a, b)` or `Merged(a, b) *T` is honest.
- Outward effects: `Send`/`Publish`/`Emit`/`Notify`/`Write`/`Delete` — never hidden
  inside `Check`/`Validate`/`Prepare`/`GetOrCreate` (that last one at least admits half
  of it; prefer `EnsureX`).
- `init()` and constructors must not have effects beyond construction — no network,
  no goroutines, no registration side channels.

## 9. Behavior-bearing affixes

These affixes are behavior contracts, not decoration:

- **`Must` prefix** — panics on failure, for initialization-time invariants:
  `template.Must`, `MustParse`, `MustCompile`. Never on the request path; never
  `MustGet` for something that can legitimately be absent.
- **`f` suffix** — takes a format string + args: `Printf`, `Errorf`, `Sprintf`.
  A function ending in `f` that isn't printf-style is lying.
- **`WithContext` / ctx-first variant** — when a context-less and context-full form
  coexist, the ctx form is recognizable (`Do` / `DoWithContext`), or the ctx form is the
  only form (preferred).
- **`-er` interface** — the capability contract; an `-er` that doesn't do the verb
  (`type Validator` that *fixes* things) is lying.
- **`New`** — allocates and returns; `NewX` must not reach into a registry/cache and
  return a shared instance (that's `GetX` or `SharedX`), and must not have effects
  beyond wiring.
- **`Default`** — returns the standard instance/value with no I/O.
- **`Try`** (when used) — failure is a normal value return, not an error/panic.

## 10. Enums and constants

- iota groups: prefix members with the type name (`StatusUnknown`, `StatusActive`,
  `StatusFailed`) so an unqualified use site still reads.
- **Reserve zero for unknown/invalid** (`StatusUnknown = iota`), unless the domain has a
  meaningful natural zero. A zero value that silently means "the first thing we happened
  to list" produces bugs wherever a var is declared and forgotten.
- Name by role, not value (`maxRetries`, not `three`; `DefaultTimeout`, not
  `ThirtySeconds`) — the value will change and the name will lie.

## 11. Deviations

When you knowingly deviate from a convention — a user asked for one grab-bag package, a
legacy API forces a `Get` prefix, a stdlib mirror keeps stdlib spelling (`LastInsertId`,
`Getenv`) — **document the deviation where the code lives** (package doc or a comment at
the declaration), not only in the commit message or a chat. Future readers see the code;
they don't see your justification. An undocumented deviation reads as a mistake and
invites a "fix" that breaks the intent.
