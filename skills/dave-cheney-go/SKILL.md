---
name: dave-cheney-go
description: >
  Use when a Go design decision has two defensible answers and the rule book is silent —
  simple vs clever, whether to launch a goroutine at all, whether to export a sentinel error
  or a concrete error type, whether to add a package-level var, whether an interface /
  embedding / channel / type parameter earns its complexity, whether to optimize at all.
  Also use when Go code passes lint and review but feels hard to change, or when a review
  needs a maintainability verdict rather than a style fix. Go 设计取舍、并发生命周期、包级
  状态、错误暴露程度、可维护性评审时使用。For concrete idiom rules use effective-go instead;
  for naming decisions use go-naming instead.
---

# Dave Cheney's Go Philosophy

`effective-go` gives you the rule. `go-naming` gives you the name. This skill is for the
moment both are silent and two designs are still defensible — it supplies the priority order
that breaks the tie, so the choice gets settled on maintainability instead of taste.

**Clear is better than clever.** Code is decoded far more often than it is written.

## The tie-breaker rule

When a concrete rule (Google/Uber style, a linter, a framework convention) conflicts with
clarity, simplicity, or maintainability: **prefer the principle and document the trade-off at
the declaration** — not just in your reply. A rule exists to serve the next reader; where it
stops serving the reader it has stopped being a rule and become a habit.

When the principles themselves collide, resolve in this order:

1. **Clarity** — can the next reader predict what this does without running it?
2. **Simplicity** — a prerequisite for reliability, not a synonym for easy.
3. **Explicitness** — no hidden state, no action at a distance.
4. **Maintainability** — will this outlive its author?

Consistency with the surrounding codebase outranks all four for *surface* decisions (naming,
layout — see `go-naming`). It never outranks them for *structural* ones.

## Five gates to pass before you write

Each row is a decision gate. If you cannot answer the question, the default column *is* the
answer — do not proceed on the assumption that you will figure it out later.

| About to… | Question you must answer | Default if you can't |
|---|---|---|
| write `go f()` | Under exactly what condition does this goroutine stop, and how does the starter wait for it? | Don't launch it. Do the work synchronously and let the caller add concurrency. |
| add a package-level `var` | Which test breaks when two of them run in parallel? | Encapsulate it in a type; inject via constructor or functional option. |
| add an interface, embed a struct, open a channel, add a type parameter | Does this remove more complexity than it introduces, *today*? | Wait for the second concrete implementation. Moderation is a virtue. |
| export `ErrX` or a concrete error type | Must callers branch on this, or do they only need to report it? | Keep it opaque — `return err`, or wrap once. Exported error identity is API forever. |
| make it faster | What does the benchmark say? | Don't. Write `testing.B` first, then profile. Refuse the temptation to guess. |

## Ownership and shape

- **Make the zero value useful** — `var b bytes.Buffer` must work. Avoid public `Init` and any
  two-step construction a caller can get half-done.
- **Leave concurrency to the caller.** Libraries expose synchronous APIs; the caller decides
  what runs in parallel.
- **Whoever creates a resource releases it.** Tie its lifetime to a scope you can point at.
- **Don't force allocations on callers**, and don't hand out pointers into your own mutable
  state — copy slices and maps at the API boundary.
- **Design so misuse is hard**: avoid same-type parameter lists that invite argument-order
  bugs; prefer streaming (`io.Reader`/`io.Writer`) over whole-value-in-memory.
- **Keep `main` to flag parsing and wiring.** Logic lives in packages, behind `internal/`
  until it has earned a public surface.

## When NOT to use this skill

- Casing, receivers, initialisms, `Get` prefixes, package/file/directory names → **`go-naming`**
- Concrete idiom lookups (`new` vs `make`, receiver kind, field tags, the 100-mistakes
  catalogue, Google/Uber rule text) → **`effective-go`**
- A decision the codebase has already made consistently → follow the codebase

**This skill and `go-naming` do not conflict on sentinel errors.** This skill argues about
*whether* to expose one (prefer opaque). `go-naming` governs *how to name* the ones you do
expose (`ErrXxx` for values, `XxxError` for types). Answer this skill's question first, then
name the result with that one.

## Deeper reading — load only when the decision needs it

| Load | When |
|---|---|
| [references/zen-of-go.md](references/zen-of-go.md) | The trade-off is between two of the eleven values, or you must justify a design in review |
| [references/design-decisions.md](references/design-decisions.md) | You've passed the gate and need the pattern: opaque-error inspection, goroutine ownership, API shape, nil-interface trap, performance method |
| [references/sources.md](references/sources.md) | Citing the original posts |

## Design red flags

- A goroutine whose stop condition is "the process exits"
- An interface with exactly one implementation, declared next to that implementation
- An error type exported so that one caller can `switch` on it
- A config flag added for a need exactly one caller has
- A comment explaining *what* a block does — extract the block instead
- "It's faster this way", with no benchmark
- A type that has grown three unrelated responsibilities
- Both logging an error and returning it

Code must work today and remain changeable forever. The second half is the hard part.
