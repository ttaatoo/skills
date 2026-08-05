# Code and Project Organization (#1-16)

## #1 - Unintended Variable Shadowing

**Problem:** Redeclaring variables in inner scopes causes confusion and bugs.

```go
// Bad - shadowing outer err
var err error
if condition {
    val, err := doSomething()  // Creates new err, doesn't assign outer
    // outer err is still nil!
}

// Good - use = instead of :=
var err error
if condition {
    var val int
    val, err = doSomething()  // Assigns to outer err
}
```

## #2 - Unnecessary Nested Code

**Problem:** Deep nesting reduces readability.

```go
// Bad
func process(data []byte) error {
    if data != nil {
        if len(data) > 0 {
            if isValid(data) {
                // actual work
            }
        }
    }
    return nil
}

// Good - return early, align happy path left
func process(data []byte) error {
    if data == nil {
        return errors.New("nil data")
    }
    if len(data) == 0 {
        return errors.New("empty data")
    }
    if !isValid(data) {
        return errors.New("invalid data")
    }
    // actual work
    return nil
}
```

## #3 - Misusing init Functions

**Problem:** Init functions limit error handling and complicate testing.

```go
// Bad - can't handle errors, hard to test
func init() {
    db, _ = sql.Open("postgres", connStr)  // Error ignored!
}

// Good - explicit initialization
func NewApp() (*App, error) {
    db, err := sql.Open("postgres", connStr)
    if err != nil {
        return nil, err
    }
    return &App{db: db}, nil
}
```

## #4 - Overusing Getters and Setters

**Problem:** Unnecessary encapsulation patterns from other languages.

```go
// Bad - over-engineering
type User struct {
    name string
}
func (u *User) GetName() string { return u.name }
func (u *User) SetName(n string) { u.name = n }

// Good - use exported field if no validation needed
type User struct {
    Name string  // Exported directly
}
```

## #5 - Interface Pollution

**Principle:** "Create an interface when you need it, not when you foresee needing it."

```go
// Bad - premature interface
type UserStore interface {
    Get(id int) (*User, error)
    Save(user *User) error
    Delete(id int) error
    List() ([]*User, error)
    // ... many more methods
}

// Good - minimal interface when needed
type UserGetter interface {
    Get(id int) (*User, error)
}
```

## #6 - Interface on the Producer Side

**Problem:** Defining interfaces where they're implemented, not where they're used.

```go
// Bad - producer defines interface
package store
type UserStore interface { ... }
type PostgresStore struct { ... }

// Good - consumer defines interface
package handler
type UserGetter interface {
    Get(id int) (*User, error)
}
func NewHandler(store UserGetter) *Handler { ... }
```

## #7 - Returning Interfaces

**Problem:** Returning interfaces reduces flexibility.

```go
// Bad
func NewStore() Store {
    return &PostgresStore{}
}

// Good - return concrete type
func NewStore() *PostgresStore {
    return &PostgresStore{}
}
```

## #8 - any Says Nothing

**Problem:** Using `any` when specific types would be more expressive.

```go
// Bad
func process(data any) { ... }

// Good - specific types
func process(data []byte) { ... }
func processJSON(data json.RawMessage) { ... }
```

## #9 - Being Confused About When to Use Generics

**Guideline:** Use generics for data structures and algorithms, not business logic.

```go
// Good use of generics
func Min[T constraints.Ordered](a, b T) T {
    if a < b {
        return a
    }
    return b
}

// Bad - unnecessary generics
func ProcessUser[T User](u T) { ... }  // Just use User type
```

## #10 - Type Embedding Problems

**Problem:** Embedding types solely for convenience promotes hidden fields.

```go
// Bad - exposes all sync.Mutex methods
type Cache struct {
    sync.Mutex
    data map[string]string
}
// cache.Lock() is now public!

// Good - keep it private
type Cache struct {
    mu   sync.Mutex
    data map[string]string
}
```

## #11 - Not Using Functional Options Pattern

**Pattern:** Clean API for optional configuration.

```go
type Server struct {
    host    string
    port    int
    timeout time.Duration
}

type Option func(*Server)

func WithPort(port int) Option {
    return func(s *Server) { s.port = port }
}

func WithTimeout(t time.Duration) Option {
    return func(s *Server) { s.timeout = t }
}

func NewServer(host string, opts ...Option) *Server {
    s := &Server{host: host, port: 8080, timeout: 30 * time.Second}
    for _, opt := range opts {
        opt(s)
    }
    return s
}

// Usage
s := NewServer("localhost", WithPort(9000), WithTimeout(time.Minute))
```

## #12 - Project Misorganization

**Guidelines:**
- Organize by context (domain) or layer
- Avoid premature packaging
- Keep package names meaningful

## #13 - Creating Utility Packages

**Problem:** Vague package names like `common`, `util`, `helpers`.

```go
// Bad
package util
func FormatDate(t time.Time) string { ... }

// Good - specific package name
package timeformat
func Date(t time.Time) string { ... }
```

## #14 - Ignoring Package Name Collisions

**Problem:** Variable names that conflict with imported packages.

```go
// Bad
var http = fetchHTTP()  // Shadows http package

// Good - use alias or different name
import nethttp "net/http"
var httpClient = fetchHTTP()
```

## #15 - Missing Code Documentation

**Rule:** Document all exported elements.

```go
// Package user provides user management functionality.
package user

// User represents a system user with authentication credentials.
type User struct {
    // ID is the unique identifier for this user.
    ID   int
    // Name is the user's display name.
    Name string
}

// New creates a new User with the given name.
// It returns an error if the name is empty.
func New(name string) (*User, error) { ... }
```

## #16 - Not Using Linters

**Essential tools:**
- `go vet` - built-in static analysis
- `golangci-lint` - comprehensive linter aggregator
- `gofmt` / `goimports` - formatting

```bash
# Run before committing
go vet ./...
golangci-lint run
```
