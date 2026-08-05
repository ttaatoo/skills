# The Zen of Go — the eleven values, and what each one buys

Load this when a trade-off is between two of these values, or when you must justify a design
decision in review. Each entry states the value, the failure it prevents, and the question to
ask at the keyboard.

## 1. A good package starts with a good name

Name a package after what it *provides* — a single clear purpose, usually a noun. The name is
the package's elevator pitch: if you can't say what it provides in one word, the package
doesn't have one purpose yet.

When the name no longer fits what the package does, **replace the package rather than
force-fit new behavior into it.** A package that accumulates unrelated behavior is how
`util` is born.

> Naming *mechanics* (casing, stutter, grab-bag words) belong to `go-naming`. This entry is
> about the design consequence: the name is a constraint on scope, not a label applied after.

## 2. Simplicity matters

Simple is better than complex, and simplicity is a **prerequisite for reliability** — you
cannot make a design you don't understand dependable by adding tests to it.

Ask: could a competent Go programmer who has never seen this file predict its behavior from
the signatures alone?

## 3. Avoid package-level state

Package-level variables create invisible coupling, hinder testing, and prevent two instances
from being used in parallel. Encapsulate state in types and inject dependencies.

The diagnostic question is concrete: *which test breaks when two of them run in parallel?*
If the answer is "some test, eventually", the state is already a bug.

Applies to loggers, metrics clients, HTTP clients, and `init()` side effects.

## 4. Plan for failure, not success

Errors are values. They must never pass silently, and they must be handled at the point where
you have enough context to decide something. Handle each error **exactly once**: retry, log,
abort, or wrap — then move on. Logging *and* returning the same error is handling it twice and
reads as two independent failures in production.

## 5. Return early rather than nesting deeply

Keep the happy path on the left — "line-of-sight" coding. Use guard clauses; no `else` after
an early `return`. Flat is better than nested. A reader should be able to scan the leftmost
column and see the function's purpose.

## 6. If you think it's slow, prove it with a benchmark

Refuse the temptation to guess. Measure with `testing.B`, then profile. Intuition about Go
performance is wrong often enough that acting on it unmeasured is a coin flip that also costs
you clarity.

## 7. Before you launch a goroutine, know when it will stop

Every `go` statement needs a clear termination condition — a closed channel, a cancelled
context, a finished range. If you cannot state the condition in one sentence, you have written
a leak, not a goroutine.

Where cleanup matters, also give the starter a way to *wait* for exit (`sync.WaitGroup`, a done
channel). "It stops when the process exits" is not a termination condition.

## 8. Leave concurrency to the caller

Libraries should expose synchronous APIs. A library that spawns goroutines the caller can't
observe or cancel has taken a decision that wasn't its to make — and the caller can always add
concurrency on top of a synchronous API, while the reverse is impossible.

## 9. Write tests to lock in the behavior of your package's API

Tests define the contract. If a change to your public API doesn't require a test update, the
tests weren't testing the contract. Prefer table-driven tests with `t.Run` subtests, so a
failure names the case rather than an index.

## 10. Moderation is a virtue

Goroutines, channels, interfaces, embedding, generics, reflection — each is powerful and each
is a cost paid by every future reader. Use them where they *demonstrably* improve the design.

Thousands of goroutines are fine; uncontrolled or idle ones are not. One interface with three
implementations is useful; one interface with one implementation is indirection.

## 11. Maintainability counts

The goal is code that outlives its author. Optimize for the next reader, who has less context
than you and no access to your reasoning except what's in the repository.

This is the value the other ten serve, and the tie-breaker when they disagree.

---

## Using these in review

State which value a comment invokes, and what it costs the reader — not just that something
is "unidiomatic". A review comment that says *"this goroutine has no stop condition (value 7),
so a failing request leaks it for the process lifetime"* is actionable; *"prefer simplicity"*
is not.

Where a value conflicts with a concrete rule from a style guide, see the tie-breaker rule in
[SKILL.md](../SKILL.md) — prefer the value, and document the trade-off at the declaration.
