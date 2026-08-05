# Concurrency (#55-74)

## Foundations (#55-60)

### #55 - Mixing Up Concurrency and Parallelism

- **Concurrency:** Dealing with multiple tasks (structure)
- **Parallelism:** Executing tasks simultaneously (execution)

```go
// Concurrency - single core can handle multiple tasks
go handleRequest(req1)
go handleRequest(req2)

// Parallelism - requires multiple cores
runtime.GOMAXPROCS(4)  // Use 4 CPU cores
```

### #56 - Thinking Concurrency Is Always Faster

**Reality:** Concurrency has overhead.

```go
// Bad - parallel overhead exceeds benefit
func sumParallel(nums []int) int {
    if len(nums) < 1000 {
        return sumSequential(nums)  // Sequential is faster for small data
    }
    // ... parallel implementation
}

// I/O-bound: concurrency helps
// CPU-bound small tasks: sequential often faster
```

### #57 - Being Puzzled About Channels vs Mutexes

| Use Channels | Use Mutexes |
|--------------|-------------|
| Passing ownership | Protecting state |
| Coordinating goroutines | Simple locking |
| Signaling | Cache/counter |

```go
// Channel - transfer ownership
results := make(chan Result)
go func() { results <- compute() }()
r := <-results  // Ownership transferred

// Mutex - protect shared state
type Counter struct {
    mu    sync.Mutex
    count int
}
func (c *Counter) Inc() {
    c.mu.Lock()
    c.count++
    c.mu.Unlock()
}
```

### #58 - Not Understanding Race Problems

**Data race:** Concurrent unsynchronized access (detectable with `-race`)
**Race condition:** Timing-dependent bugs (harder to detect)

```go
// Data race - concurrent read/write
var count int
go func() { count++ }()
go func() { fmt.Println(count) }()

// Race condition - timing bug
// Check-then-act without atomicity
if cache.Get(key) == nil {  // Another goroutine may set between check and set
    cache.Set(key, compute())
}
```

### #59 - Not Understanding Workload Concurrency Impacts

```go
// CPU-bound - limit to GOMAXPROCS
workers := runtime.GOMAXPROCS(0)

// I/O-bound - can use more goroutines
workers := 100  // OK for network calls
```

### #60 - Misunderstanding Contexts

**Context uses:**
- Deadlines/timeouts
- Cancellation signals
- Request-scoped values

```go
// Timeout
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()

// Cancellation
ctx, cancel := context.WithCancel(context.Background())
go func() {
    <-stopCh
    cancel()  // Signal all workers to stop
}()

// Check cancellation
select {
case <-ctx.Done():
    return ctx.Err()
default:
    // Continue work
}
```

## Practice (#61-74)

### #61 - Propagating Inappropriate Context

```go
// Bad - using background when parent context available
func handler(ctx context.Context) {
    go doWork(context.Background())  // Ignores cancellation!
}

// Good - propagate context
func handler(ctx context.Context) {
    go doWork(ctx)  // Respects cancellation
}
```

### #62 - Starting Goroutines Without Stop Signals

```go
// Bad - goroutine leak
func start() {
    go func() {
        for {
            process()  // Runs forever!
        }
    }()
}

// Good - provide stop mechanism
func start(ctx context.Context) {
    go func() {
        for {
            select {
            case <-ctx.Done():
                return  // Clean exit
            default:
                process()
            }
        }
    }()
}
```

### #63 - Not Being Careful with Goroutines and Loop Variables

```go
// Bug (Go < 1.22) - all goroutines see same i
for i := 0; i < 3; i++ {
    go func() {
        fmt.Println(i)  // May print 3, 3, 3
    }()
}

// Fix - capture variable
for i := 0; i < 3; i++ {
    i := i  // Shadow with local copy
    go func() {
        fmt.Println(i)  // Prints 0, 1, 2
    }()
}

// Fix - pass as argument
for i := 0; i < 3; i++ {
    go func(i int) {
        fmt.Println(i)
    }(i)
}
```

### #64 - Expecting Deterministic Select Behavior

```go
// Non-deterministic - any ready case may be selected
select {
case <-ch1:
    // ...
case <-ch2:
    // ...
}

// If both ready, Go randomly chooses one
```

### #65 - Not Using Notification Channels

```go
// Signal completion without data
done := make(chan struct{})
go func() {
    work()
    close(done)  // Signal completion
}()
<-done  // Wait for completion
```

### #66 - Not Using Nil Channels

```go
// Nil channel blocks forever - useful for disabling select cases
var ch1, ch2 <-chan int

// Dynamically enable/disable
if condition {
    ch1 = realCh1
}

select {
case v := <-ch1:  // Disabled if ch1 is nil
    process(v)
case v := <-ch2:
    process(v)
}
```

### #67 - Being Puzzled About Channel Size

```go
// Unbuffered (size 0) - synchronous
ch := make(chan int)

// Buffered - asynchronous up to capacity
ch := make(chan int, 10)

// Rule of thumb:
// - 0: When sender should wait for receiver
// - 1: When decoupling is needed
// - N: When you know production rate
```

### #68 - Forgetting Side Effects with String Formatting

```go
// Deadlock risk
type T struct {
    mu sync.Mutex
}
func (t *T) String() string {
    t.mu.Lock()
    defer t.mu.Unlock()
    return "T"
}

// Bug: fmt.Printf acquires lock via String(), may deadlock
```

### #69 - Creating Data Races with Append

```go
// Data race - concurrent append
var s []int
go func() { s = append(s, 1) }()
go func() { s = append(s, 2) }()

// Fix - use mutex or channel
var mu sync.Mutex
go func() {
    mu.Lock()
    s = append(s, 1)
    mu.Unlock()
}()
```

### #70 - Using Mutexes Inaccurately with Collections

```go
// Bug - lock doesn't cover map access
mu.Lock()
v := m[key]
mu.Unlock()
v.Process()  // Data race if v is modified concurrently

// Fix - copy or extend lock
mu.Lock()
v := m[key]
vCopy := *v  // Copy while locked
mu.Unlock()
vCopy.Process()
```

### #71 - Misusing sync.WaitGroup

```go
// Bug - Add called in goroutine
go func() {
    wg.Add(1)  // May not execute before Wait()
    // ...
    wg.Done()
}()
wg.Wait()

// Fix - Add before goroutine
wg.Add(1)
go func() {
    defer wg.Done()
    // ...
}()
wg.Wait()
```

### #72 - Forgetting About sync.Cond

```go
// Efficient waiting for condition changes
var (
    mu    sync.Mutex
    cond  = sync.NewCond(&mu)
    ready bool
)

// Waiter
mu.Lock()
for !ready {
    cond.Wait()  // Releases lock, waits, reacquires
}
mu.Unlock()

// Signaler
mu.Lock()
ready = true
cond.Broadcast()  // Wake all waiters
mu.Unlock()
```

### #73 - Not Using errgroup

```go
import "golang.org/x/sync/errgroup"

g, ctx := errgroup.WithContext(context.Background())

for _, url := range urls {
    url := url
    g.Go(func() error {
        return fetch(ctx, url)
    })
}

if err := g.Wait(); err != nil {
    // First error returned
}
```

### #74 - Copying sync Types

```go
// Bug - copying mutex
type T struct {
    mu sync.Mutex
}

t1 := T{}
t2 := t1  // Copies mutex state - undefined behavior!

// Fix - use pointer or don't copy
t2 := &t1  // Share, don't copy
```
