# Code Style Guidelines

## Variable Declarations

### Local Variables

```go
// Use := for assignments
s := "hello"
n := 42

// Use var for zero values
var s string
var n int
var items []Item
```

### Top-Level Variables

```go
// Use var keyword at package level
var config Config

// Only specify type when different from expression
var ratio = 0.5           // float64 inferred
var timeout time.Duration // Can't infer, must specify
```

### Unexported Global Prefix

**Use `_` prefix for unexported package-level vars (except errors):**

```go
var (
    _defaultPort = 8080
    _maxRetries  = 3
)

// Exception: error variables use err prefix
var (
    errInvalidInput = errors.New("invalid input")
)
```

## Struct Initialization

### Use Field Names

```go
// Good - explicit field names
user := User{
    Name:  "Alice",
    Email: "alice@example.com",
}

// Bad - positional (fragile)
user := User{"Alice", "alice@example.com"}
```

### Omit Zero Values

```go
// Good - zero values omitted
user := User{
    Name: "Alice",
    // Age: 0,     // Omit zero values
    // Active: false,
}

// For all-zero struct, use var
var config Config
```

### Use &T{} Over new(T)

```go
// Preferred
user := &User{Name: "Alice"}

// Less common
user := new(User)
user.Name = "Alice"
```

## Slice and Map Initialization

### nil is Valid Slice

```go
// Good - return nil for empty
func getItems() []Item {
    if noItems {
        return nil  // Not []Item{}
    }
    return items
}

// Check with len, not nil
if len(items) == 0 { ... }
```

### Map Initialization

```go
// Empty map for programmatic use
m := make(map[string]int)

// Map literal for fixed sets
m := map[string]int{
    "one": 1,
    "two": 2,
}

// With capacity hint
m := make(map[string]int, 100)
```

## Field Tags for Marshaling

**Always use tags for marshaled structs:**

```go
// Good - explicit tags
type User struct {
    ID        int    `json:"id"`
    Name      string `json:"name"`
    Email     string `json:"email,omitempty"`
    CreatedAt time.Time `json:"created_at"`
}

// Bad - relies on default behavior
type User struct {
    ID    int
    Name  string
    Email string
}
```

## Enums: Start at One

**Use `iota + 1` to avoid zero-value ambiguity:**

```go
// Good - zero is invalid/unset
type Status int

const (
    StatusPending Status = iota + 1
    StatusActive
    StatusInactive
)

// Bad - zero is valid value
type Status int

const (
    StatusPending Status = iota  // 0 - same as zero value!
    StatusActive
    StatusInactive
)
```

**Exception:** When zero value is meaningful (e.g., default behavior).

## Time Handling

### Use Proper Types

```go
// Instants - use time.Time
type Event struct {
    CreatedAt time.Time
    UpdatedAt time.Time
}

// Durations - use time.Duration
type Config struct {
    Timeout     time.Duration
    RetryDelay  time.Duration
}

// Bad - ambiguous
type Config struct {
    TimeoutSec int  // Seconds? Milliseconds?
}
```

### External Time Formats

```go
// Use RFC 3339 for JSON/APIs
type Response struct {
    Timestamp string `json:"timestamp"`  // "2024-01-15T10:30:00Z"
}

// Or use time.Time with proper marshaling
type Response struct {
    Timestamp time.Time `json:"timestamp"`
}
```

## String Formatting

### Raw String Literals

```go
// Good - no escaping needed
query := `SELECT * FROM users WHERE name = "John"`
regex := `\d+\.\d+`

// Verbose with regular strings
query := "SELECT * FROM users WHERE name = \"John\""
regex := "\\d+\\.\\d+"
```

### Format Strings as Constants

```go
// Good - go vet can check
const msgFormat = "user %s has %d items"
fmt.Printf(msgFormat, name, count)

// Bad - can't verify at compile time
fmt.Printf("user %s has %d items", name, count)  // Still works but less safe
```

### Naming Printf-Style Functions

```go
// End with 'f' for format string functions
func Wrapf(err error, format string, args ...interface{}) error
func Logf(format string, args ...interface{})
```

## Avoid Naked Parameters

**Use C-style comments for unclear parameters:**

```go
// Bad - what does true mean?
db.Connect("localhost", true)

// Good - clarify with comment
db.Connect("localhost", true /* isSecure */)

// Better - use config struct
db.Connect(ConnConfig{
    Host:     "localhost",
    IsSecure: true,
})
```

## Avoid Mutable Globals

**Use dependency injection instead:**

```go
// Bad - global function pointer
var timeNow = time.Now

func process() {
    t := timeNow()
}

// Good - inject dependency
type Processor struct {
    now func() time.Time
}

func NewProcessor() *Processor {
    return &Processor{now: time.Now}
}

func (p *Processor) process() {
    t := p.now()
}
```

## Line Length

**Soft limit of ~99 characters.** Prioritize readability:

```go
// OK to exceed for long strings
err := fmt.Errorf("failed to process user %s with status %d: %w", username, status, err)

// Break long function signatures
func ProcessUserWithOptions(
    ctx context.Context,
    userID string,
    options ProcessOptions,
) (*Result, error) {
    // ...
}
```

## Import Organization

**Group imports in order: standard library, external, internal:**

```go
import (
    // Standard library (first group)
    "context"
    "fmt"
    "net/http"

    // External packages (second group)
    "github.com/pkg/errors"
    "go.uber.org/zap"

    // Internal packages (third group)
    "mycompany/myproject/internal/config"
)
```

**No dot imports (except in tests):**

```go
// Bad - pollutes namespace
import . "fmt"
Println("hello")  // Where does this come from?

// Good - explicit
import "fmt"
fmt.Println("hello")

// Exception: test files for generated code
import . "mypackage"  // OK in mypackage_test.go
```

**No blank imports except for side effects:**

```go
// Good - document why
import _ "image/png"  // Register PNG decoder

// Bad - unexplained
import _ "some/package"
```

## Performance Tips

### strconv Over fmt

```go
// Good - faster
s := strconv.Itoa(42)
n, _ := strconv.Atoi("42")

// Slower
s := fmt.Sprintf("%d", 42)
n, _ := fmt.Sscanf("42", "%d", &n)
```

### Avoid Repeated Conversions

```go
// Bad - converts each iteration
for i := 0; i < len(s); i++ {
    r := []rune(s)[i]  // Converts entire string each time
}

// Good - convert once
runes := []rune(s)
for i := 0; i < len(runes); i++ {
    r := runes[i]
}
```

## Modern Go Idioms

### Use `any` Over `interface{}`

**Go 1.18+: Prefer `any` type alias:**

```go
// Good - Go 1.18+
func Process(data any) { ... }
func Store(key string, value any) { ... }

// Old style - still valid but less idiomatic
func Process(data interface{}) { ... }
```

### Use crypto/rand for Security

**Never use math/rand for security-sensitive values:**

```go
// Good - cryptographically secure
import "crypto/rand"

func GenerateToken() (string, error) {
    b := make([]byte, 32)
    if _, err := rand.Read(b); err != nil {
        return "", err
    }
    return base64.URLEncoding.EncodeToString(b), nil
}

// Bad - predictable, NOT secure
import "math/rand"

func GenerateToken() string {
    return fmt.Sprintf("%d", rand.Int())  // Predictable!
}
```

### Prefer Synchronous Functions

**Return values directly instead of using channels when possible:**

```go
// Good - synchronous, simpler to use
func Lookup(key string) (Value, error) {
    // ...
    return value, nil
}

// Bad - unnecessarily async
func Lookup(key string) <-chan Value {
    ch := make(chan Value, 1)
    go func() {
        // ...
        ch <- value
    }()
    return ch
}
```

**When to use async patterns:**
- Naturally concurrent operations (multiple I/O)
- Streaming data
- Long-running background tasks
- Fan-out/fan-in patterns

### Error String Format

**Error strings: lowercase, no ending punctuation:**

```go
// Good
return errors.New("connection refused")
return fmt.Errorf("user %d not found", id)

// Bad - uppercase
return errors.New("Connection refused")

// Bad - ends with punctuation
return errors.New("connection refused.")

// Bad - ends with newline
return fmt.Errorf("failed\n")
```

**Why?** Error messages are often wrapped or prefixed:
```go
// Good: "open config: connection refused"
// Bad:  "open config: Connection refused."
```
