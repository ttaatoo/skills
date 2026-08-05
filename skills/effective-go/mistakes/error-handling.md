# Error Management (#48-54)

## #48 - Panicking

**Rule:** Reserve panic for truly unrecoverable situations.

```go
// Acceptable panic - programmer error
func MustCompile(pattern string) *Regexp {
    re, err := Compile(pattern)
    if err != nil {
        panic(err)  // Bug in code, pattern should be valid
    }
    return re
}

// Acceptable panic - initialization failure
func init() {
    if err := loadConfig(); err != nil {
        panic(err)  // Can't run without config
    }
}

// Bad - don't panic for runtime errors
func getUser(id int) *User {
    user, err := db.Find(id)
    if err != nil {
        panic(err)  // Wrong! Return error instead
    }
    return user
}

// Good - return error
func getUser(id int) (*User, error) {
    return db.Find(id)
}
```

## #49 - Ignoring When to Wrap Errors

**When to wrap:**
- Add context about what operation failed
- Mark error for checking with `errors.Is`/`errors.As`

**When NOT to wrap:**
- Creates coupling to implementation
- No additional context to add

```go
// Good - adds context
func readConfig(path string) (*Config, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, fmt.Errorf("read config %s: %w", path, err)
    }
    // ...
}

// Consider not wrapping - if caller shouldn't know about SQL
func getUser(id int) (*User, error) {
    var user User
    err := db.QueryRow("...").Scan(&user.Name)
    if err != nil {
        return nil, err  // Don't expose SQL details
    }
    return &user, nil
}
```

## #50 - Comparing Error Types Inaccurately

**Problem:** Using type assertion on wrapped errors.

```go
// Bad - fails with wrapped errors
if err, ok := err.(*PathError); ok {
    // Won't match: fmt.Errorf("failed: %w", pathErr)
}

// Good - use errors.As
var pathErr *os.PathError
if errors.As(err, &pathErr) {
    fmt.Println("Path:", pathErr.Path)
}
```

## #51 - Comparing Error Values Inaccurately

**Problem:** Using `==` on wrapped errors.

```go
// Bad - fails with wrapped errors
if err == sql.ErrNoRows {
    // Won't match: fmt.Errorf("user not found: %w", sql.ErrNoRows)
}

// Good - use errors.Is
if errors.Is(err, sql.ErrNoRows) {
    return nil, ErrNotFound
}
```

## #52 - Handling Errors Twice

**Problem:** Both logging AND returning an error.

```go
// Bad - error handled twice
func process() error {
    err := doWork()
    if err != nil {
        log.Printf("error: %v", err)  // Handled once (logged)
        return err                     // Handled again (returned)
    }
    return nil
}
// Caller may log again - duplicate log entries

// Good - handle once
// Option 1: Return only (let caller decide)
func process() error {
    if err := doWork(); err != nil {
        return fmt.Errorf("process failed: %w", err)
    }
    return nil
}

// Option 2: Log only (if terminal operation)
func handleRequest(w http.ResponseWriter, r *http.Request) {
    if err := process(); err != nil {
        log.Printf("request failed: %v", err)
        http.Error(w, "Internal error", 500)
        return
    }
}
```

## #53 - Not Handling Errors

**Rule:** Never ignore errors with `_`.

```go
// Bad - error ignored
result, _ := doRiskyOperation()

// Bad - error explicitly ignored but risky
_ = file.Close()  // Might lose data on write!

// Good - always check
result, err := doRiskyOperation()
if err != nil {
    return err
}

// Good - if truly ignorable, document why
_ = file.Close()  // Read-only file, close error is not actionable
```

## #54 - Not Handling Defer Errors

**Problem:** Deferred operations can fail, especially writes.

```go
// Bad - close error ignored
func writeFile(path string, data []byte) error {
    f, err := os.Create(path)
    if err != nil {
        return err
    }
    defer f.Close()  // Error ignored! May lose data

    _, err = f.Write(data)
    return err
}

// Good - handle close error
func writeFile(path string, data []byte) (err error) {
    f, err := os.Create(path)
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

// Alternative - explicit close
func writeFile(path string, data []byte) error {
    f, err := os.Create(path)
    if err != nil {
        return err
    }

    _, err = f.Write(data)
    if err != nil {
        f.Close()  // Best effort close on error
        return err
    }

    return f.Close()  // Check close error
}
```
