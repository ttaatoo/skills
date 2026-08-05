---
name: effective-go
description: Use when writing, reviewing, or refactoring Go code for idiomatic style, correctness, and maintainability. Also covers public library/API design patterns.
---

# Effective Go Skill

Apply official Go best practices and idioms when writing, reviewing, or refactoring Go code.

## Style Principles (Priority Order)

1. **Clarity** - Code's purpose and rationale is clear to reader
2. **Simplicity** - Accomplish goals in most straightforward way
3. **Concision** - High signal-to-noise ratio
4. **Maintainability** - Future programmers can modify correctly
5. **Consistency** - Align with codebase patterns

## Quick Reference

**Core Principles:**
1. Use `gofmt` for formatting - non-negotiable
2. Follow naming conventions strictly
3. Write clear, idiomatic code
4. Handle errors explicitly
5. Leverage concurrency wisely

## When to Use This Skill

- Writing new Go code
- Reviewing Go code for idiomaticity
- Refactoring existing Go code
- Debugging Go programs
- Designing Go APIs and packages
- Designing public library/SDK interfaces

## Neighbouring Skills

This skill holds the **concrete rules**. Two neighbours hold what it deliberately doesn't:

- **`go-naming`** — every naming decision beyond the pocket table below: package/file/directory
  names, receiver consistency, semantic verb contracts, generated-code casing.
- **`dave-cheney-go`** — the design *trade-off* when two options are both idiomatic: whether to
  launch a goroutine at all, whether to export a sentinel error, whether an interface earns its
  complexity. Use it when a rule here and clarity/maintainability pull in opposite directions.

## Quick Decision Guides

### Naming Decisions

**Naming decisions belong to the `go-naming` skill** — invoke it for anything beyond the
table below (package/file/directory names, semantic verb contracts, generated-code casing).

| Element | Convention | Example |
|---------|-----------|---------|
| Package | lowercase, single word | `bufio`, `http` |
| Exported | MixedCaps | `ReadWriter` |
| Unexported | mixedCaps | `readBuffer` |
| Interface (1 method) | Method + -er | `Reader`, `Writer` |
| Getter | Field name (uppercase) | `Owner()` not `GetOwner()` |
| Setter | SetField | `SetOwner(user)` |

### Allocation Decisions

| Need | Use | Returns |
|------|-----|---------|
| Zero value of any type | `new(T)` | `*T` |
| Slice/Map/Channel | `make(T, ...)` | `T` |

### Receiver Decisions

| Condition | Use |
|-----------|-----|
| Modifies receiver | Pointer `*T` |
| Large struct | Pointer `*T` |
| Needs nil check | Pointer `*T` |
| Small immutable value | Value `T` |
| Thread safety needed | Value `T` |

## Core Guidelines

See [operations/](operations/) for detailed guidelines:
- [formatting.md](operations/formatting.md) - Code formatting rules
- [naming.md](operations/naming.md) - Naming pocket summary; full rules live in the `go-naming` skill
- [control.md](operations/control.md) - Control structures
- [functions.md](operations/functions.md) - Function design
- [data.md](operations/data.md) - Data allocation
- [interfaces.md](operations/interfaces.md) - Interface design
- [methods.md](operations/methods.md) - Method receivers
- [errors.md](operations/errors.md) - Error handling
- [concurrency.md](operations/concurrency.md) - Goroutines and channels
- [style.md](operations/style.md) - Code style (Uber & Google conventions)

## 100 Go Mistakes to Avoid

See [mistakes/](mistakes/) for detailed mistake patterns:
- [organization.md](mistakes/organization.md) - Code & project organization (#1-16)
- [data-types.md](mistakes/data-types.md) - Data types (#17-29)
- [control-flow.md](mistakes/control-flow.md) - Control structures (#30-35)
- [strings.md](mistakes/strings.md) - String handling (#36-41)
- [functions-methods.md](mistakes/functions-methods.md) - Functions & methods (#42-47)
- [error-handling.md](mistakes/error-handling.md) - Error management (#48-54)
- [concurrency-mistakes.md](mistakes/concurrency-mistakes.md) - Concurrency (#55-74)
- [stdlib.md](mistakes/stdlib.md) - Standard library (#75-81)
- [testing.md](mistakes/testing.md) - Testing (#82-90)
- [optimizations.md](mistakes/optimizations.md) - Optimizations (#91-100)

## Critical Rules

**ALWAYS:**
- Run `gofmt` before committing
- Return errors as the last return value
- Check all error returns
- Use `defer` for cleanup
- Keep interfaces small (1-3 methods ideal)
- Accept interfaces, return concrete types
- Document all exported symbols
- Use field tags for marshaled structs (`json:"field"`)
- Verify interface compliance at compile time
- Ensure goroutines have controllable lifetimes

**NEVER:**
- Use underscores in names (except `_` blank identifier or unexported globals)
- Ignore errors with `_`
- Use `panic` for normal errors
- Create getters with `Get` prefix
- Reuse canonical method names (`Read`, `Write`, `Close`) with different semantics
- Call `os.Exit` or `log.Fatal` outside of `main()`
- Start goroutines in `init()` functions
- Use pointer to interface (almost never needed)

## Code Review Checklist

Before approving Go code:
- [ ] `gofmt` applied
- [ ] Names follow conventions
- [ ] Errors handled explicitly (once per error)
- [ ] No unnecessary else after return
- [ ] Interfaces are minimal
- [ ] Concurrency is correct (goroutines can exit)
- [ ] Documentation complete for exports
- [ ] Field tags present for marshaled structs
- [ ] Channel sizes are 0 or 1 (or justified)
- [ ] Line length reasonable (~99 chars soft limit)

## Library & API Design

### Accept Interfaces, Return Structs

```go
func NewService(repo UserRepository) *Service {  // not ServiceInterface
    return &Service{repo: repo}
}
```

### Keep Interfaces Small (1-3 methods)

```go
type UserRepository interface {
    GetByID(ctx context.Context, id string) (*User, error)
}
```

### Zero Value Usability

Design types so `var t T` works without initialization (e.g. `sync.Mutex`, `bytes.Buffer`).

### Functional Options Pattern

```go
type Option func(*config)

func WithTimeout(d time.Duration) Option {
    return func(c *config) { c.timeout = d }
}

func New(opts ...Option) *Client {
    cfg := defaultConfig()
    for _, opt := range opts { opt(&cfg) }
    return &Client{cfg: cfg}
}
```

### No Global State

Use explicit dependency injection instead of package-level vars (except `errors.New` sentinels).

### Use Internal Packages

```
mylib/
├── client.go          # Public API
├── options.go         # Public options
└── internal/
    ├── transport/     # Not importable by users
    └── encoding/
```

### Context Propagation

Context as first parameter, never stored in structs.

## References

- Official Guide: https://go.dev/doc/effective_go
- Google Style Guide: https://google.github.io/styleguide/go/
- Uber Style Guide: https://github.com/uber-go/guide/blob/master/style.md
- 100 Go Mistakes: https://100go.co
- Code Review Comments: https://github.com/golang/go/wiki/CodeReviewComments
