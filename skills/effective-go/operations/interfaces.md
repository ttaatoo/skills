# Interface Design

## Core Philosophy

**Interfaces specify behavior, not data.**

"If something can do *this*, it can be used *here*."

## Interface Design Principles

### Keep Interfaces Small

```go
// Good - single method, highly reusable
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}

// Combine when needed
type ReadWriter interface {
    Reader
    Writer
}
```

### Accept Interfaces, Return Concrete Types

```go
// Good - accepts interface
func Copy(dst Writer, src Reader) (written int64, err error) {
    // Works with any Reader and Writer
}

// Good - returns concrete type
func NewBuffer() *Buffer {
    return &Buffer{}
}

// Avoid - returning interface hides implementation
func NewBuffer() io.ReadWriter {  // Don't do this
    return &Buffer{}
}
```

### Exception: Unexported Concrete + Exported Interface (SDK Pattern)

When building SDKs or libraries where the interface IS the public API contract,
returning an interface from factory functions is correct. The concrete type is
private; the interface is the stable contract users depend on.

```go
// The interface IS the public API — users write against this
type Repository interface {
    Find(ctx context.Context, filter any) *FindQuery
    InsertOne(ctx context.Context, doc any) (*InsertOneResult, error)
    // ...
}

// The concrete struct is private — implementation detail
type repository struct {
    database string
    coll     string
    client   *Client
}

// Factory returns interface, not *repository
func (c *Client) Collection(db, coll string) Repository {
    return &repository{database: db, coll: coll, client: c}
}

// Compile-time check
var _ Repository = (*repository)(nil)
```

**Why this works for SDKs:**
- Users can never reference `*repository` directly — no accidental coupling to internals
- The concrete type can gain new fields/methods without any API surface change
- Constructor wrappers like `FromRepository[T](repo Repository)` accept the interface,
  allowing injection of any mock or alternate implementation

**Generic interfaces: keep flat for mockability**

Generic interfaces with methods that return concrete builder types force mock
authors to instantiate those builders, which require a real backend. Keep generic
typed interfaces flat (no builders):

```go
// TypedRepository[T] — flat only, trivial to mock
type TypedRepository[T any] interface {
    GetOne(ctx context.Context, filter any) (T, error)
    GetAll(ctx context.Context, filter any) ([]T, error)
    UpdateOne(ctx context.Context, filter, update any, opts ...UpdateOption) (*UpdateResult, error)
    // ...no Find() *FindQuery — that returns a concrete builder type
}

// GenericRepository[T] wraps the Repository interface and adds typed builders
// It implements TypedRepository[T] via the flat methods
type GenericRepository[T any] struct {
    repo Repository  // holds the interface, not *repository
}

func FromRepository[T any](repo Repository) *GenericRepository[T] {
    return &GenericRepository[T]{repo: repo}
}
```

### Implicit Implementation
Types implement interfaces automatically - no `implements` declaration:

```go
type MyReader struct {
    data []byte
    pos  int
}

// MyReader implements io.Reader by having this method
func (r *MyReader) Read(p []byte) (n int, err error) {
    if r.pos >= len(r.data) {
        return 0, io.EOF
    }
    n = copy(p, r.data[r.pos:])
    r.pos += n
    return n, nil
}
```

## Standard Interface Patterns

### Single-Method Interfaces

```go
type Stringer interface {
    String() string
}

type Error interface {
    Error() string
}

type Handler interface {
    ServeHTTP(ResponseWriter, *Request)
}
```

### Composition Through Embedding

```go
type ReadCloser interface {
    Reader
    Closer
}

type ReadWriteCloser interface {
    Reader
    Writer
    Closer
}

type ReadWriteSeeker interface {
    Reader
    Writer
    Seeker
}
```

## Interface Naming

| Pattern | Example |
|---------|---------|
| Single method + `-er` | `Reader`, `Writer`, `Closer` |
| Agent noun | `Formatter`, `Scanner` |
| Descriptive for multi-method | `ReadWriter`, `ReadCloser` |

## Type Assertions and Type Switches

### Type Assertion

```go
// Assert concrete type
r, ok := reader.(*os.File)
if ok {
    // r is *os.File
}

// Assert interface
rw, ok := reader.(io.ReadWriter)
if ok {
    // reader also implements Writer
}
```

### Type Switch

```go
switch v := value.(type) {
case string:
    return processString(v)
case int:
    return processInt(v)
case io.Reader:
    return processReader(v)
default:
    return fmt.Errorf("unsupported type: %T", value)
}
```

## Interface Best Practices

### Define Interfaces Where Used

```go
// Package consumer defines interface
package consumer

type DataSource interface {
    Fetch() ([]byte, error)
}

func Process(src DataSource) error {
    data, err := src.Fetch()
    // ...
}

// Package provider implements without importing consumer
package provider

type HTTPSource struct {
    URL string
}

func (s *HTTPSource) Fetch() ([]byte, error) {
    // Implements consumer.DataSource without knowing it
}
```

### Avoid Premature Abstraction

```go
// Bad - interface with one implementation
type UserRepository interface {
    Find(id int) (*User, error)
    Save(user *User) error
}

// Good - just use concrete type until you need abstraction
type UserRepository struct {
    db *sql.DB
}

func (r *UserRepository) Find(id int) (*User, error) { /* ... */ }
func (r *UserRepository) Save(user *User) error { /* ... */ }

// Create interface later when you have multiple implementations
```

### Empty Interface

```go
// interface{} or any (Go 1.18+) accepts any value
func Printf(format string, args ...any) {
    // ...
}

// Use sparingly - prefer specific interfaces
```

## Compile-Time Interface Verification

**Verify types implement interfaces at compile time:**

```go
// Verify *Handler implements http.Handler
var _ http.Handler = (*Handler)(nil)

// Verify *Config implements json.Marshaler
var _ json.Marshaler = (*Config)(nil)

// Place at package level, near type definition
type Handler struct { /* ... */ }
var _ http.Handler = (*Handler)(nil)
```

## Pointer to Interface

**Almost never use pointer to interface:**

```go
// Bad - pointer to interface
func process(r *io.Reader) { ... }

// Good - interface value (already contains pointer internally)
func process(r io.Reader) { ... }
```

Interfaces internally hold a pointer to the concrete value, so passing `*io.Reader` creates unnecessary indirection.
