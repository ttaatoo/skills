# Optimizations (#91-100)

## #91 - Not Understanding CPU Caches

**Principle:** Access memory in predictable, sequential patterns.

```go
// Bad - column-major access (cache-unfriendly)
var matrix [1000][1000]int
for col := 0; col < 1000; col++ {
    for row := 0; row < 1000; row++ {
        matrix[row][col]++  // Jumps around memory
    }
}

// Good - row-major access (cache-friendly)
for row := 0; row < 1000; row++ {
    for col := 0; col < 1000; col++ {
        matrix[row][col]++  // Sequential memory access
    }
}
```

## #92 - False Sharing in Concurrent Code

**Problem:** Multiple goroutines modify adjacent memory locations on same cache line.

```go
// Bad - false sharing
type Counters struct {
    a int64  // Same cache line
    b int64  // Same cache line
}

// Good - pad to separate cache lines (64 bytes typical)
type Counters struct {
    a   int64
    _   [56]byte  // Padding to fill cache line
    b   int64
}

// Alternative - use atomic with proper alignment
type Counters struct {
    a atomic.Int64
    _ [56]byte
    b atomic.Int64
}
```

## #93 - Not Considering Instruction-Level Parallelism

**Principle:** CPUs execute independent instructions in parallel.

```go
// Sequential dependencies - slow
a := compute1()
b := compute2(a)  // Depends on a
c := compute3(b)  // Depends on b

// Independent operations - CPU can parallelize
a := compute1()
b := compute2()  // Independent
c := compute3()  // Independent
d := combine(a, b, c)  // Depends on all
```

## #94 - Not Being Aware of Data Alignment

**Principle:** Struct field ordering affects memory layout.

```go
// Bad - 24 bytes due to padding
type Bad struct {
    a bool    // 1 byte + 7 padding
    b int64   // 8 bytes
    c bool    // 1 byte + 7 padding
}

// Good - 16 bytes (fields ordered by size)
type Good struct {
    b int64   // 8 bytes
    a bool    // 1 byte
    c bool    // 1 byte + 6 padding
}

// Check size
fmt.Println(unsafe.Sizeof(Bad{}))   // 24
fmt.Println(unsafe.Sizeof(Good{}))  // 16
```

## #95 - Not Understanding Stack vs Heap

**Stack:** Fast, automatic, limited size
**Heap:** Slower, GC-managed, larger

```go
// Stack allocation (usually)
func stackAlloc() int {
    x := 42  // Stays on stack
    return x
}

// Heap allocation (escape)
func heapAlloc() *int {
    x := 42
    return &x  // x escapes to heap
}

// Check escape analysis
// go build -gcflags="-m" ./...
```

## #96 - Not Reducing Allocations

### Pre-allocate Slices

```go
// Bad - multiple allocations
var result []int
for i := 0; i < n; i++ {
    result = append(result, i)
}

// Good - single allocation
result := make([]int, 0, n)
for i := 0; i < n; i++ {
    result = append(result, i)
}
```

### Use sync.Pool

```go
var bufPool = sync.Pool{
    New: func() interface{} {
        return new(bytes.Buffer)
    },
}

func process() {
    buf := bufPool.Get().(*bytes.Buffer)
    buf.Reset()
    defer bufPool.Put(buf)

    // Use buf...
}
```

### Avoid String Concatenation in Loops

```go
// Bad
var s string
for _, item := range items {
    s += item  // New allocation each time
}

// Good
var b strings.Builder
b.Grow(estimatedSize)
for _, item := range items {
    b.WriteString(item)
}
s := b.String()
```

## #97 - Not Relying on Inlining

**Principle:** Small functions may be inlined by compiler.

```go
// Likely inlined
func add(a, b int) int {
    return a + b
}

// Check inlining decisions
// go build -gcflags="-m" ./...

// Factors preventing inlining:
// - Function too complex
// - Contains defer
// - Contains recover
// - Marked with //go:noinline
```

## #98 - Not Using Diagnostics Tools

### Profiling

```go
import _ "net/http/pprof"

func main() {
    go func() {
        http.ListenAndServe(":6060", nil)
    }()
    // ...
}

// Access: http://localhost:6060/debug/pprof/
```

```bash
# CPU profile
go test -cpuprofile=cpu.out -bench=.
go tool pprof cpu.out

# Memory profile
go test -memprofile=mem.out -bench=.
go tool pprof mem.out

# Trace
go test -trace=trace.out
go tool trace trace.out
```

### Benchmark Comparison

```bash
# Run benchmarks
go test -bench=. -count=10 > old.txt
# Make changes
go test -bench=. -count=10 > new.txt

# Compare
benchstat old.txt new.txt
```

## #99 - Not Understanding GC Behavior

**Reduce GC pressure:**
- Reduce allocations (reuse objects)
- Use sync.Pool for temporary objects
- Pre-allocate slices/maps
- Use value types over pointers when possible

```go
// Monitor GC
import "runtime/debug"

debug.SetGCPercent(100)  // Default, trigger at 100% heap growth

// Log GC stats
var stats runtime.MemStats
runtime.ReadMemStats(&stats)
fmt.Printf("Alloc: %d MB\n", stats.Alloc/1024/1024)
fmt.Printf("NumGC: %d\n", stats.NumGC)
```

## #100 - Not Understanding Docker/Kubernetes Impacts

**Problem:** Container limits affect Go runtime defaults.

```go
// GOMAXPROCS defaults to host CPU count, not container limit
// In container with 2 CPU limit on 64-core host: GOMAXPROCS=64 (wrong!)

// Fix - use automaxprocs
import _ "go.uber.org/automaxprocs"

// Or set manually
runtime.GOMAXPROCS(2)

// Memory limits
// Go GC doesn't know container memory limit
// Set GOMEMLIMIT (Go 1.19+)
// GOMEMLIMIT=1GiB

// Or in code
debug.SetMemoryLimit(1 << 30)  // 1 GiB
```
