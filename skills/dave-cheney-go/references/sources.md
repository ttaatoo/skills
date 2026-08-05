# Sources

Load only when citing an argument back to its origin — e.g. justifying a design decision in a
review or a design doc.

## Primary — the philosophy layer (this skill)

| Source | What to cite it for |
|---|---|
| [The Zen of Go](https://dave.cheney.net/2020/02/23/the-zen-of-go) | The eleven values; the framing that simplicity precedes reliability |
| [Practical Go](https://dave.cheney.net/practical-go/presentations/gophercon-israel.html) | Package design, API shape, guard clauses, project layout |
| [Never start a goroutine without knowing how it will stop](https://dave.cheney.net/2016/12/22/never-start-a-goroutine-without-knowing-how-it-will-stop) | The goroutine stop-condition gate |
| [Don't just check errors, handle them gracefully](https://dave.cheney.net/2016/04/27/dont-just-check-errors-handle-them-gracefully) | Opaque errors; asserting behavior over type; handle-once |
| [Clear is better than clever](https://dave.cheney.net/2019/07/09/clear-is-better-than-clever) | The core maxim; reading cost vs writing cost |
| [Simplicity Debt](https://dave.cheney.net/2021/02/28/simplicity-debt) | Why each added feature is a cost paid by every future reader |

## Concrete rule sources — cite via `effective-go`

These are the authorities behind the rules in the `effective-go` skill. Named here so this
skill doesn't restate their content:

- [Effective Go](https://go.dev/doc/effective_go)
- [Google Go Style Guide — Decisions](https://google.github.io/styleguide/go/decisions.html)
- [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments)
- [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md)
- [100 Go Mistakes](https://100go.co)

## Citing honestly in review

Distinguish what you are invoking, the same way `go-naming` does with its `tool`/`canon`/`house`
labels:

- **canon** — cite Effective Go, the Google guide, or Code Review Comments; state it as a rule.
- **philosophy** — cite Cheney; state it as a trade-off with a named cost ("this leaks the
  goroutine for the process lifetime"), never as "Go requires this".
- **house** — the repo does it consistently; say so, and don't dress it up as canon.
