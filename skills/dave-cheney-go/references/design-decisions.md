# Applied design decisions

Load this after a gate in [SKILL.md](../SKILL.md) has told you *whether* to do the thing, when
you need the pattern for *how*.

Concrete rule lookups are not here — `new` vs `make`, receiver kind tables, field tags, the
Google/Uber rule text, and the 100-Go-Mistakes catalogue all live in the **`effective-go`**
skill. Naming mechanics live in **`go-naming`**. This file only covers decisions where those
two are silent.

## Contents

1. [Errors: opaque by default](#1-errors-opaque-by-default)
2. [Concurrency: ownership and stopping](#2-concurrency-ownership-and-stopping)
3. [API shape](#3-api-shape)
4. [Packages and boundaries](#4-packages-and-boundaries)
5. [Pointers, values, interfaces](#5-pointers-values-interfaces)
6. [Declarations and clarity](#6-declarations-and-clarity)
7. [Performance method](#7-performance-method)

---

## 1. Errors: opaque by default

Errors are part of your public API. Treat a change to error *identity* the same as a change to
a function signature — because for callers who match on it, it is one.

**Default: opaque.** Propagate with `return err`, or wrap once with context as soon as the
error occurs:

```go
if err := cfg.load(path); err != nil {
    return fmt.Errorf("load config %s: %w", path, err)
}
```

Wrapping with `%w` preserves the chain for `errors.Is` / `errors.As` without committing you to
exporting anything.

**When callers genuinely must branch, assert behavior — not type, not value:**

```go
// The interface is unexported: callers use IsTemporary, not the type.
type temporary interface{ Temporary() bool }

// IsTemporary reports whether err indicates a retryable condition.
func IsTemporary(err error) bool {
    var t temporary
    return errors.As(err, &t) && t.Temporary()
}
```

This gives callers the decision they need (retry or not) without forcing them to import your
package or to know which of your five error types they're holding.

**Escalation order**, cheapest commitment first:

| Caller needs | Expose |
|---|---|
| To report the failure | Nothing — `return err` / wrap once |
| To make one decision (retry? not-found?) | A predicate function over an unexported behavior interface |
| To distinguish a small closed set of outcomes | A sentinel value, `ErrXxx`, documented as API |
| Structured detail (field, offset, path) | An error *type*, `XxxError`, with exported fields |

Naming of the last two: `go-naming`. Whether you get there at all: the gate in SKILL.md.

**Also:**
- Handle an error exactly once. Do not both log it and return it.
- Design error handling away where you can — `bufio.Scanner` over raw `bufio.Reader` absorbs
  the edge cases rather than making every caller handle them.
- Never use `panic`/`recover` for ordinary errors in a library. Reserve `panic` for genuinely
  unrecoverable states, and keep `log.Fatal` inside `main`.
- Always check `err != nil` before touching the other return values — they are undefined
  otherwise.

## 2. Concurrency: ownership and stopping

**The stop condition comes first.** Write it down before the `go` statement:

```go
// watch runs until ctx is cancelled; the caller waits on the returned channel.
func (w *Watcher) watch(ctx context.Context) <-chan struct{} {
    done := make(chan struct{})
    go func() {
        defer close(done)          // the starter can observe exit
        for {
            select {
            case <-ctx.Done():     // the stop condition, stated once
                return
            case ev := <-w.events:
                w.handle(ev)
            }
        }
    }()
    return done
}
```

Three properties to check on every goroutine you write: it has **one** stop signal (a cancelled
context or a closed channel), the starter can **wait** for exit when cleanup matters, and the
goroutine that created a resource is the one that **releases** it.

**Rules that follow from ownership:**
- Only the sender closes a channel. Closing is a signal, not memory management.
- Channel buffer is 0 or 1. Anything larger needs a stated reason — a large buffer is usually
  an unmeasured guess about a rate mismatch.
- Prefer doing the work yourself over launching a goroutine and immediately waiting on it.
- No empty spin loops. No goroutines started in `init()`.
- Library functions are synchronous. The caller adds concurrency; you cannot remove it.

## 3. API shape

- **Easy to use correctly, hard to misuse.** Prefer small interfaces that describe behavior,
  defined by the *caller* that needs them, not by the implementer.
- **Avoid same-type parameter lists.** `Copy(dst, src string)` invites transposition; distinct
  types or an options struct make it impossible.
- **Prefer streaming.** `io.Reader`/`io.Writer` over loading a whole value into memory — it
  removes a size limit from your API rather than documenting one.
- **Make the common case simple**; put advanced configuration behind functional options rather
  than growing the constructor's parameter list.
- **Prefer varargs** where a slice would force an allocation or an awkward call site.
- **Make the zero value useful.** No public `Init`, no half-constructed value that can escape.
- **Don't force allocations on callers**, and don't return pointers into internal mutable
  state — copy slices and maps at the boundary, in both directions.
- **Receiver kind: be consistent per type.** Consistency across a type's method set matters
  more than the individual value-vs-pointer choice.

## 4. Packages and boundaries

- Name a package for what it provides; reject `util`, `common`, `base`, `helpers`, `misc`.
- Prefer fewer, larger packages with a single responsibility over many thin ones.
- `internal/` is where a design lives until it has earned a public surface. Prototype there.
- The package name is part of every identifier at the call site (`http.Get`, `bytes.Buffer`) —
  choose a name that reads well qualified. (Mechanics: `go-naming`.)
- Inject loggers, metrics, and clients through constructors or options. No package-level
  loggers, no mutable package state, no `init()` side effects.
- `main` does flag parsing and wiring only.

## 5. Pointers, values, interfaces

- A pointer holds an address. `&` takes an address, `*` dereferences. There is no
  pass-by-reference in Go: everything is passed by value, including pointer values.
- **An interface holds a (type, value) pair.** A nil *concrete pointer* stored in an interface
  is not a nil interface — this is the classic non-nil-error bug:

```go
func find() error {
    var e *NotFoundError   // nil pointer
    return e               // NOT nil: interface has a type
}
```

  Return a literal `nil` when you mean "no value".
- Prefer small interfaces, declared by the consumer.
- Never take a pointer to an interface. Verify compliance at compile time:
  `var _ Store = (*postgresStore)(nil)`.
- Avoid embedding in public structs — it leaks implementation into your API forever. Hand-write
  the delegating methods you actually want. Never embed a mutex; use a named field.

## 6. Declarations and clarity

- Short functions, each at a single level of abstraction. Extract rather than comment.
- Comments explain *why*, or state the external contract. They do not narrate *what*. If a
  block needs a comment to be understood, extract it and let the name carry the meaning.
  Document every exported symbol, starting with its own name.
- `var` for zero-value initialization, `:=` for explicit values. Declare close to first use.
  Avoid shadowing.
- Reuse conventional names (`ctx`, `err`, `db`) so readers don't relearn vocabulary per file.
  Length tracks scope. (Full rules: `go-naming`.)
- Prefer `nil` slices over empty ones; test emptiness with `len(s) == 0`.
- `context.Context` is the first parameter, and is for cancellation and deadlines. Carrying
  values through it is a secondary use — reach for it only when a parameter genuinely cannot
  thread through.
- Table-driven tests with named `t.Run` subtests; `cmp.Diff` (or equivalent) for failure
  messages you can read. `t.Helper()` in helpers.

## 7. Performance method

1. Establish the benchmark first (`testing.B`), on the workload you actually care about.
2. Profile (`pprof`) to find where the time or the allocations go.
3. Change one thing. Re-measure. Keep the benchmark in the repo as the justification for the
   complexity you just added.

Know that allocation sources, escape analysis, inlining budgets, and size classes exist — and
verify every claim about them rather than reasoning from memory. Mid-stack inlining, compiler
intrinsics, and binary-size tricks are real but advanced; they need a measurement to earn their
readability cost. Prefer streaming and reuse over large temporaries. Consider whether an
interface is forcing a concrete value onto the heap.
