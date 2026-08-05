# Error Handling

## Core Principles

1. **Errors are values** - treat them as data, not exceptions
2. **Always check errors** - never ignore with `_`
3. **Return errors, don't panic** - panic is for truly unrecoverable situations
4. **Add context when propagating** - wrap errors with additional information

## Error Interface

```go
type error interface {
    Error() string
}
```

## Basic Error Handling

### Check Every Error

```go
// Good
f, err := os.Open(filename)
if err != nil {
    return err
}
defer f.Close()

// Bad - silently ignores error
f, _ := os.Open(filename)  // DON'T DO THIS
```

### Error as Last Return Value

```go
func Read(filename string) ([]byte, error) {
    f, err := os.Open(filename)
    if err != nil {
        return nil, err
    }
    defer f.Close()

    return io.ReadAll(f)
}
```

## Creating Errors

### Simple Errors

```go
import "errors"

// Static error
var ErrNotFound = errors.New("item not found")

// Dynamic error
func validate(name string) error {
    if name == "" {
        return errors.New("name cannot be empty")
    }
    return nil
}

// Formatted error
import "fmt"

func load(id int) error {
    return fmt.Errorf("failed to load item %d", id)
}
```

### Custom Error Types

```go
type PathError struct {
    Op   string  // Operation: "open", "read", etc.
    Path string  // File path
    Err  error   // Underlying error
}

func (e *PathError) Error() string {
    return e.Op + " " + e.Path + ": " + e.Err.Error()
}

func (e *PathError) Unwrap() error {
    return e.Err
}

// Usage
return &PathError{Op: "open", Path: filename, Err: syscall.ENOENT}
// Error: "open /etc/passwd: no such file or directory"
```

## Error Wrapping (Go 1.13+)

### Wrap with Context

```go
// Wrap error with context using %w
if err != nil {
    return fmt.Errorf("failed to process user %d: %w", userID, err)
}

// Chain of wrapped errors
// "save failed: validate failed: name cannot be empty"
```

### Unwrap and Check

```go
// Check if error is specific type
var pathErr *PathError
if errors.As(err, &pathErr) {
    fmt.Println("Operation:", pathErr.Op)
    fmt.Println("Path:", pathErr.Path)
}

// Check if error is specific value
if errors.Is(err, os.ErrNotExist) {
    // Handle file not found
}
```

## Error Handling Patterns

### Guard Clauses

```go
func process(data *Data) error {
    if data == nil {
        return errors.New("data is nil")
    }
    if len(data.Items) == 0 {
        return errors.New("no items to process")
    }

    // Happy path continues unindented
    for _, item := range data.Items {
        if err := handle(item); err != nil {
            return fmt.Errorf("handle item %s: %w", item.ID, err)
        }
    }
    return nil
}
```

### Defer for Cleanup on Error

```go
func writeFile(filename string, data []byte) (err error) {
    f, err := os.Create(filename)
    if err != nil {
        return err
    }
    defer func() {
        closeErr := f.Close()
        if err == nil {
            err = closeErr
        }
    }()

    _, err = f.Write(data)
    return err
}
```

## Panic and Recover

### When to Panic

- **Initialization failures** that prevent program from running
- **Impossible conditions** (bugs in code)
- **Never for normal errors** in libraries

```go
func MustCompile(pattern string) *Regexp {
    re, err := Compile(pattern)
    if err != nil {
        panic(`regexp: Compile(` + pattern + `): ` + err.Error())
    }
    return re
}

// Used for package-level initialization
var validID = regexp.MustCompile(`^[a-z]+$`)
```

### Recover from Panic

```go
func safeCall(fn func()) (err error) {
    defer func() {
        if r := recover(); r != nil {
            err = fmt.Errorf("panic recovered: %v", r)
        }
    }()
    fn()
    return nil
}
```

### Server Pattern

```go
func serve(w http.ResponseWriter, r *http.Request) {
    defer func() {
        if err := recover(); err != nil {
            log.Printf("panic: %v\n%s", err, debug.Stack())
            http.Error(w, "Internal Server Error", 500)
        }
    }()

    // Handler code that might panic
    doWork(w, r)
}
```

## Sentinel Errors

```go
// Package-level error values
var (
    ErrNotFound     = errors.New("not found")
    ErrUnauthorized = errors.New("unauthorized")
    ErrInvalidInput = errors.New("invalid input")
)

// Usage
if errors.Is(err, ErrNotFound) {
    // Handle not found case
}
```

## Error Naming Conventions

**Exported error variables:** Use `Err` prefix

```go
var (
    ErrBrokenLink = errors.New("link is broken")
    ErrCouldNotOpen = errors.New("could not open")
)
```

**Custom error types:** Use `Error` suffix

```go
type NotFoundError struct {
    Name string
}

type ResolveError struct {
    Path string
}
```

## Error Wrapping: %w vs %v

**Use `%w`** when callers should be able to match the underlying error:

```go
// Caller can use errors.Is(err, sql.ErrNoRows)
return fmt.Errorf("user lookup failed: %w", sql.ErrNoRows)
```

**Use `%v`** to obfuscate implementation details:

```go
// Caller cannot match underlying error - implementation hidden
return fmt.Errorf("user lookup failed: %v", err)
```

**Decision guide:**
- `%w`: Error is part of your API contract
- `%v`: Error is implementation detail, may change

## Exit Only in Main

**Never call `os.Exit` or `log.Fatal` in library code:**

```go
// Bad - in library/handler
func process() {
    if err != nil {
        log.Fatal(err)  // Kills entire program!
    }
}

// Good - return error, let main decide
func process() error {
    if err != nil {
        return err
    }
    return nil
}

// Good - exit in main
func main() {
    if err := run(); err != nil {
        fmt.Fprintln(os.Stderr, err)
        os.Exit(1)
    }
}

func run() error {
    // All actual logic here, returns errors
}
```
