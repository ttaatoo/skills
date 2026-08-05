# Testing (#82-90)

## #82 - Not Categorizing Tests

**Organize tests by type:**

```go
// Build tags for integration tests
//go:build integration

package mypackage

func TestIntegration(t *testing.T) {
    // ...
}

// Run: go test -tags=integration

// Short mode for quick tests
func TestSlow(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping in short mode")
    }
    // Long-running test
}

// Run fast only: go test -short
```

## #83 - Not Enabling Race Flag

**Always test with race detector:**

```bash
go test -race ./...
```

```go
// CI pipeline should include race detection
// Add to Makefile:
test:
    go test -race -v ./...
```

## #84 - Not Using Test Execution Modes

```bash
# Parallel execution
go test -parallel 4 ./...

# Shuffle test order (find order-dependent bugs)
go test -shuffle=on ./...

# Verbose output
go test -v ./...

# Coverage
go test -cover ./...
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

## #85 - Not Using Table-Driven Tests

```go
// Bad - repetitive tests
func TestAdd(t *testing.T) {
    if Add(1, 2) != 3 {
        t.Error("1+2 should be 3")
    }
    if Add(0, 0) != 0 {
        t.Error("0+0 should be 0")
    }
    // ... more cases
}

// Good - table-driven
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive", 1, 2, 3},
        {"zero", 0, 0, 0},
        {"negative", -1, -2, -3},
        {"mixed", -1, 2, 1},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.expected {
                t.Errorf("Add(%d, %d) = %d, want %d",
                    tt.a, tt.b, got, tt.expected)
            }
        })
    }
}
```

## #86 - Sleeping in Unit Tests

**Problem:** `time.Sleep` makes tests slow and flaky.

```go
// Bad - slow and flaky
func TestAsync(t *testing.T) {
    go doWork()
    time.Sleep(100 * time.Millisecond)  // Arbitrary wait
    // Check result
}

// Good - use synchronization
func TestAsync(t *testing.T) {
    done := make(chan struct{})
    go func() {
        doWork()
        close(done)
    }()

    select {
    case <-done:
        // Check result
    case <-time.After(time.Second):
        t.Fatal("timeout")
    }
}

// Good - use mock time
type mockClock struct {
    now time.Time
}
func (c *mockClock) Now() time.Time { return c.now }
func (c *mockClock) Advance(d time.Duration) { c.now = c.now.Add(d) }
```

## #87 - Not Dealing with Time Efficiently

```go
// Bad - hard to test
func IsExpired(createdAt time.Time) bool {
    return time.Now().Sub(createdAt) > 24*time.Hour
}

// Good - inject time source
type Clock interface {
    Now() time.Time
}

type RealClock struct{}
func (RealClock) Now() time.Time { return time.Now() }

func IsExpired(clock Clock, createdAt time.Time) bool {
    return clock.Now().Sub(createdAt) > 24*time.Hour
}

// Test
type mockClock struct{ t time.Time }
func (c mockClock) Now() time.Time { return c.t }

func TestIsExpired(t *testing.T) {
    now := time.Date(2024, 1, 2, 0, 0, 0, 0, time.UTC)
    clock := mockClock{t: now}

    old := now.Add(-25 * time.Hour)
    if !IsExpired(clock, old) {
        t.Error("should be expired")
    }
}
```

## #88 - Not Using Testing Utilities

### httptest Package

```go
func TestHandler(t *testing.T) {
    // Create test request
    req := httptest.NewRequest("GET", "/api/users", nil)
    rec := httptest.NewRecorder()

    // Call handler
    handler(rec, req)

    // Check response
    if rec.Code != http.StatusOK {
        t.Errorf("status = %d, want %d", rec.Code, http.StatusOK)
    }
}

// Test server
func TestClient(t *testing.T) {
    ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintln(w, "Hello")
    }))
    defer ts.Close()

    resp, err := http.Get(ts.URL)
    // ...
}
```

### iotest Package

```go
import "testing/iotest"

// Test with error-prone reader
func TestRead(t *testing.T) {
    r := iotest.TimeoutReader(strings.NewReader("data"))
    // Tests handling of timeout errors

    r = iotest.HalfReader(strings.NewReader("data"))
    // Reads half the requested bytes
}
```

## #89 - Writing Inaccurate Benchmarks

```go
// Bad - compiler may optimize away
func BenchmarkBad(b *testing.B) {
    for i := 0; i < b.N; i++ {
        compute()  // Result unused, may be eliminated
    }
}

// Good - use result
var result int

func BenchmarkGood(b *testing.B) {
    var r int
    for i := 0; i < b.N; i++ {
        r = compute()
    }
    result = r  // Prevent elimination
}

// Reset timer after setup
func BenchmarkWithSetup(b *testing.B) {
    data := expensiveSetup()
    b.ResetTimer()  // Don't count setup time

    for i := 0; i < b.N; i++ {
        process(data)
    }
}

// Parallel benchmark
func BenchmarkParallel(b *testing.B) {
    b.RunParallel(func(pb *testing.PB) {
        for pb.Next() {
            compute()
        }
    })
}
```

## #90 - Not Exploring Testing Features

### Subtests

```go
func TestGroup(t *testing.T) {
    t.Run("case1", func(t *testing.T) {
        t.Parallel()  // Run in parallel
        // ...
    })
    t.Run("case2", func(t *testing.T) {
        t.Parallel()
        // ...
    })
}
```

### Test Helpers

```go
func assertEqual(t *testing.T, got, want int) {
    t.Helper()  // Report caller's line, not this function's
    if got != want {
        t.Errorf("got %d, want %d", got, want)
    }
}
```

### Cleanup

```go
func TestWithCleanup(t *testing.T) {
    f := createTempFile(t)
    t.Cleanup(func() {
        os.Remove(f.Name())
    })
    // Test using f
}
```

## Google Testing Best Practices

### Test Failure Messages

**Use consistent format: `YourFunc(%v) = %v, want %v`**

```go
// Good - clear format
func TestAdd(t *testing.T) {
    got := Add(1, 2)
    want := 3
    if got != want {
        t.Errorf("Add(1, 2) = %d, want %d", got, want)
    }
}

// Good - with named test cases
for _, tc := range testCases {
    t.Run(tc.name, func(t *testing.T) {
        got := Process(tc.input)
        if got != tc.want {
            t.Errorf("Process(%v) = %v, want %v", tc.input, got, tc.want)
        }
    })
}

// Bad - unclear what failed
if got != want {
    t.Errorf("failed")  // What failed? What values?
}

// Bad - wrong order
if got != want {
    t.Errorf("want %v, got %v", want, got)  // Inconsistent order
}
```

### Avoid Assertion Libraries

**Use standard `t.Errorf`/`t.Fatalf` instead of assertion libraries:**

```go
// Good - standard testing
if got != want {
    t.Errorf("Process() = %v, want %v", got, want)
}

if err != nil {
    t.Fatalf("Setup failed: %v", err)
}

// Bad - assertion libraries
assert.Equal(t, want, got)  // Hides test logic
require.NoError(t, err)     // Non-standard
```

**Why avoid assertions?**
- Standard library is sufficient
- Custom error messages are clearer
- No external dependencies
- Consistent with Go philosophy

### Use cmp.Diff for Complex Comparisons

```go
import "github.com/google/go-cmp/cmp"

// Good - shows exact differences
func TestProcess(t *testing.T) {
    got := Process(input)
    want := &Result{
        Name:  "test",
        Items: []string{"a", "b"},
    }
    if diff := cmp.Diff(want, got); diff != "" {
        t.Errorf("Process() mismatch (-want +got):\n%s", diff)
    }
}

// Bad - unhelpful for complex types
if !reflect.DeepEqual(got, want) {
    t.Errorf("got %v, want %v", got, want)  // Huge output, hard to diff
}
```

### No t.Fatal in Goroutines

**NEVER call t.Fatal/t.Fatalf from a test goroutine:**

```go
// Bad - t.Fatal in goroutine causes panic
func TestConcurrent(t *testing.T) {
    go func() {
        if err := doWork(); err != nil {
            t.Fatal(err)  // PANIC! FailNow called from non-test goroutine
        }
    }()
}

// Good - use channels to report errors
func TestConcurrent(t *testing.T) {
    errs := make(chan error, 1)
    go func() {
        errs <- doWork()
    }()

    if err := <-errs; err != nil {
        t.Fatal(err)  // Called from test goroutine - OK
    }
}

// Good - use t.Error (non-fatal) with sync
func TestConcurrent(t *testing.T) {
    var wg sync.WaitGroup
    wg.Add(1)
    go func() {
        defer wg.Done()
        if err := doWork(); err != nil {
            t.Error(err)  // t.Error is safe (doesn't call FailNow)
        }
    }()
    wg.Wait()
}
```

### Use %q for Quoted Strings

```go
// Good - shows whitespace and special chars
if got != want {
    t.Errorf("Name() = %q, want %q", got, want)
    // Output: Name() = "hello\n", want "hello"
}

// Bad - whitespace invisible
if got != want {
    t.Errorf("Name() = %s, want %s", got, want)
    // Output: Name() = hello
    // , want hello  (newline invisible!)
}
```

### Test File Organization

```go
// Place tests in same package for white-box testing
package mypackage

// Or use _test suffix for black-box testing
package mypackage_test

import "mypackage"

// Test functions start with Test
func TestFunctionName(t *testing.T) { ... }

// Benchmark functions start with Benchmark
func BenchmarkFunctionName(b *testing.B) { ... }

// Example functions start with Example
func ExampleFunctionName() {
    // Output: expected output
}
```
