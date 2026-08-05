# Data Allocation

## new vs make

### Summary Table

| Function | Types | Returns | Initializes |
|----------|-------|---------|-------------|
| `new(T)` | Any type | `*T` | Zeros memory |
| `make(T)` | Slice, Map, Channel only | `T` | Initializes internal structure |

## new(T)

**Allocates zeroed memory, returns pointer:**

```go
// Allocate zeroed int, returns *int
p := new(int)      // *p == 0

// Allocate zeroed struct, returns *SyncedBuffer
sb := new(SyncedBuffer)  // Ready to use if zero value is useful
```

### Zero-Value Design
Design types so zero value is useful without initialization:

```go
// Good - zero value is ready to use
type Buffer struct {
    buf  []byte
    // ...
}
var b bytes.Buffer  // Ready to use immediately
b.WriteString("hello")

// Good - zero value is unlocked mutex
var mu sync.Mutex   // Ready to use
mu.Lock()

// Composite types with useful zero values
type SyncedBuffer struct {
    lock   sync.Mutex  // Zero value: unlocked
    buffer bytes.Buffer // Zero value: empty buffer
}
// SyncedBuffer is immediately usable after allocation
```

## make(T, args)

**Only for slices, maps, and channels.** Creates initialized (not zeroed) values:

```go
// Slice: length 10, capacity 100
s := make([]int, 10, 100)

// Slice: length and capacity both 10
s := make([]int, 10)

// Map with default capacity
m := make(map[string]int)

// Map with capacity hint (optimization)
m := make(map[string]int, 100)

// Unbuffered channel
ch := make(chan int)

// Buffered channel with capacity 100
ch := make(chan int, 100)
```

### Why make Exists
Slices, maps, and channels are references to data structures that must be initialized:

```go
// Slice is (pointer, length, capacity)
// make allocates underlying array and initializes descriptor

// Map is pointer to hash table
// make sets up internal hash structure

// Channel is pointer to channel structure
// make sets up internal queue
```

## Common Patterns

### Slice Allocation

```go
// Fixed size, all zeros
data := make([]byte, 100)

// Dynamic, start empty
data := make([]byte, 0, 100)  // len=0, cap=100

// Append will grow as needed
var data []byte  // nil slice, append works
data = append(data, byte(1))
```

### Map Initialization

```go
// Empty map, ready to use
m := make(map[string]int)

// With capacity hint for performance
m := make(map[string]int, 1000)

// Map literal
m := map[string]int{
    "one": 1,
    "two": 2,
}
```

### Channel Creation

```go
// Unbuffered - synchronous
done := make(chan struct{})

// Buffered - asynchronous up to capacity
jobs := make(chan Job, 100)

// Receive-only and send-only types
func worker(jobs <-chan Job, results chan<- Result) {
    // ...
}
```

## Arrays vs Slices

### Arrays
- Fixed size, part of type
- Value type (copied on assignment)
- Rarely used directly

```go
var a [10]int           // Array of 10 ints
b := [...]int{1, 2, 3}  // Size inferred: [3]int
```

### Slices
- Dynamic size
- Reference type (shares underlying array)
- Preferred in most cases

```go
s := []int{1, 2, 3}     // Slice literal
s := make([]int, 10)    // make for specific size
s = append(s, 4, 5, 6)  // Grow dynamically
```

## Struct Allocation

```go
// Using new
p := new(Point)  // Returns *Point, zero values

// Using composite literal
p := &Point{X: 1, Y: 2}  // Returns *Point

// Taking address of literal
p := &Point{}  // Same as new(Point)

// Named fields (order doesn't matter)
p := &Point{Y: 2, X: 1}

// Positional (must match field order)
p := &Point{1, 2}  // X: 1, Y: 2
```
