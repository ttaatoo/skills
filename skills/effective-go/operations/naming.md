# Naming Conventions

> **Naming lives in the `go-naming` skill.** It is the single source of truth for every
> naming decision — files, directories, packages, and all identifiers. This file used to
> duplicate its form-layer rules; two copies drifted apart, so what remains here is the
> pocket summary plus a pointer.
>
> Invoke `go-naming` when you are naming or reviewing names. It adds what is not below:
> the semantic layer (does the name tell the truth about cost, side effects, and absence
> behavior), the generated-code casing firewall, tests / generics / doc-comment / module-path
> conventions, and the lint config that automates all of it.

## Pocket summary

| Element | Convention | ✅ | ❌ |
|---|---|---|---|
| Package | lowercase, one word, no underscores/mixedCaps; named for what it provides | `bufio`, `timefmt` | `http_server`, `goUtils`, `util` |
| Package qualifier | don't repeat the package in its identifiers | `bufio.Reader`, `ring.New` | `bufio.BufReader`, `ring.NewRing` |
| Exported / unexported | `MixedCaps` / `mixedCaps`, never underscores | `ReadWriter`, `readBuffer` | `Read_Writer`, `max_buffer_size` |
| Initialisms | one case throughout | `userID`, `HTTPServer`, `urlPath` | `userId`, `HttpServer`, `Url` |
| Interface | ability noun, method + `-er`; no `I` prefix, no `Interface` suffix | `Reader`, `Uploader` | `IReader`, `ReaderInterface` |
| Getter / setter | field name / `Set` + field name | `Name()`, `SetName(n)` | `GetName()` |
| Canonical methods | `Read`/`Write`/`Close`/`Flush`/`String` only with their standard meaning | `func (t Token) String() string` | `String()` returning a DSN |
| Receiver | 1–2 chars, same name for every method of the type | `func (c *Client)` | `func (client *Client)`, `this`, `self` |
| Constant | MixedCaps, named by role | `MaxItems`, `defaultTimeout` | `MAX_ITEMS`, `KMaxItems` |
| Variable | length ∝ scope; noun, no type in the name | `i` in a loop, `userCount` | `index` in a loop, `numUsers`, `userSlice` |
| Error | sentinel **value** `ErrXxx`; error **type** `XxxError` | `ErrNotFound`, `PathError` | `NotFoundErr`, `ErrPathStruct` |
| Doc comment | starts with the symbol's own name | `// Client is an HTTP client.` | `// This type represents…` |
| Type parameter | single capital | `[K comparable, V any]` | `[TKey, TValue any]` |

## Full references in `go-naming`

- `SKILL.md` — the `look → test → name → check` process, quick-rule table with
  tool/canon/house provenance, self-check list
- `references/rules-bank.md` — per-category deep reference, including **reserved file
  suffixes** (`_linux.go` and friends silently exclude a file from the build)
- `references/semantic-naming.md` — verb contracts, absence semantics, mutation disclosure
- `references/generated-code.md` — keeping protobuf's `SessionId`/`GetX()` style quarantined
- `references/tooling.md` — `.golangci.yml` for the machine-checkable rules, `gopls rename`
