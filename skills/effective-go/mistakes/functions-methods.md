# Functions and Methods (#42-47)

## #42 - Wrong Receiver Type Choice

**Decision guide:**

| Use Pointer `*T` | Use Value `T` |
|------------------|---------------|
| Method modifies receiver | Receiver is immutable |
| Receiver is large struct | Receiver is small (< 64 bytes) |
| Receiver contains sync primitives | Basic types (int, string) |
| Consistency with other methods | Thread safety needed |

```go
// Pointer - modifies receiver
func (u *User) UpdateName(name string) {
    u.Name = name
}

// Pointer - large struct
type BigStruct struct {
    Data [1024]byte
}
func (b *BigStruct) Process() { ... }

// Value - small, immutable
type Point struct {
    X, Y int
}
func (p Point) Distance(q Point) float64 {
    return math.Sqrt(float64((p.X-q.X)*(p.X-q.X) + (p.Y-q.Y)*(p.Y-q.Y)))
}
```

## #43 - Never Using Named Result Parameters

**When to use:**
- Multiple parameters of same type
- Improve documentation
- Simplify defer usage

```go
// Good - clarifies what each int means
func SplitHostPort(addr string) (host, port string, err error) {
    // ...
}

// Good - documents return values
func parse(s string) (value int, rest string, err error) {
    // ...
}

// Unnecessary - obvious from context
func Add(a, b int) int {  // Not: (sum int)
    return a + b
}
```

## #44 - Named Result Parameter Side Effects

**Problem:** Named results initialize to zero values.

```go
// Bug - can return zero for valid input
func getBalance(id int) (balance int, err error) {
    rows, err := db.Query("SELECT balance FROM accounts WHERE id = ?", id)
    if err != nil {
        return  // Returns 0, err
    }
    defer rows.Close()

    if !rows.Next() {
        return  // Bug! Returns 0, nil (no error but wrong balance)
    }

    err = rows.Scan(&balance)
    return
}

// Fix - explicit return values or check
func getBalance(id int) (balance int, err error) {
    rows, err := db.Query(...)
    if err != nil {
        return 0, err
    }
    defer rows.Close()

    if !rows.Next() {
        return 0, errors.New("not found")  // Explicit error
    }

    err = rows.Scan(&balance)
    return balance, err
}
```

## #45 - Returning Nil Receiver

**Problem:** Returning nil pointer through interface results in non-nil interface.

```go
type Result struct {
    Value int
}

// Bug - returns non-nil interface containing nil pointer
func getResult() error {
    var r *Result = nil
    return r  // Interface is not nil!
}

func main() {
    err := getResult()
    if err != nil {  // This is TRUE!
        fmt.Println("error:", err)  // Panic: nil pointer
    }
}

// Fix - return explicit nil
func getResult() error {
    var r *Result = nil
    if r == nil {
        return nil  // Explicit nil interface
    }
    return r
}
```

## #46 - Filename as Function Input

**Problem:** Functions that take filenames are hard to test and less reusable.

```go
// Bad - hard to test, requires actual file
func countLines(filename string) (int, error) {
    f, err := os.Open(filename)
    if err != nil {
        return 0, err
    }
    defer f.Close()
    // ...
}

// Good - accepts io.Reader
func countLines(r io.Reader) (int, error) {
    scanner := bufio.NewScanner(r)
    count := 0
    for scanner.Scan() {
        count++
    }
    return count, scanner.Err()
}

// Usage
f, _ := os.Open("file.txt")
countLines(f)

// Easy to test
countLines(strings.NewReader("line1\nline2\n"))
```

## #47 - Defer Argument Evaluation

**Problem:** Defer arguments evaluate immediately, not at execution time.

```go
// Bug - status captured at defer time
func process() error {
    status := "started"
    defer log.Printf("status: %s", status)  // Logs "started"

    status = "processing"
    // ...
    status = "done"
    return nil
}
// Logs: "status: started" (wrong!)

// Fix 1 - use pointer
func process() error {
    status := "started"
    defer func() {
        log.Printf("status: %s", status)  // Closure captures variable
    }()

    status = "done"
    return nil
}
// Logs: "status: done" (correct)

// Fix 2 - use named return
func process() (status string, err error) {
    status = "started"
    defer func() {
        log.Printf("status: %s", status)
    }()

    status = "done"
    return
}
```
