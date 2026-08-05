# Concurrency

## Core Philosophy

**"Do not communicate by sharing memory; instead, share memory by communicating."**

- Pass data on channels
- Only one goroutine has access at a time
- Data races prevented by design

## Goroutines

### Launching Goroutines

```go
// Simple function call
go doWork()

// Method call
go obj.Process()

// Function literal
go func() {
    // ... work ...
}()

// Function literal with arguments
go func(id int) {
    process(id)
}(itemID)  // Pass current value, not reference
```

### Goroutine Characteristics

- Lightweight (small stack, grows as needed)
- Multiplexed onto OS threads
- Cheap to create thousands

```go
// This is fine
for i := 0; i < 10000; i++ {
    go process(items[i])
}
```

## Channels

### Creating Channels

```go
// Unbuffered - synchronous
ch := make(chan int)

// Buffered - asynchronous up to capacity
ch := make(chan int, 100)

// Typed channels
stringCh := make(chan string)
structCh := make(chan MyStruct)
```

### Channel Size Guidelines

**Prefer size 0 or 1.** Any other size requires justification:

| Size | Use Case |
|------|----------|
| 0 (unbuffered) | Synchronization, handoff guarantee |
| 1 | Decoupling, single item buffer |
| N > 1 | Only with measured, justified need |

```go
// Good - unbuffered for synchronization
done := make(chan struct{})

// Good - size 1 for signal without blocking
notify := make(chan struct{}, 1)

// Needs justification - why 100?
queue := make(chan Job, 100)  // Document: "buffered for batch processing"
```

### Channel Operations

```go
// Send
ch <- value

// Receive
value := <-ch

// Receive with ok (check if closed)
value, ok := <-ch
if !ok {
    // Channel closed
}

// Close (only sender should close)
close(ch)
```

### Channel Directions

```go
// Send-only
func sender(ch chan<- int) {
    ch <- 42
}

// Receive-only
func receiver(ch <-chan int) {
    value := <-ch
}
```

## Common Patterns

### Wait for Completion

```go
done := make(chan struct{})

go func() {
    doWork()
    close(done)  // Signal completion
}()

<-done  // Wait for completion
```

### Fan-out / Fan-in

```go
// Fan-out: multiple workers
func fanOut(jobs <-chan Job, numWorkers int) <-chan Result {
    results := make(chan Result)

    var wg sync.WaitGroup
    for i := 0; i < numWorkers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for job := range jobs {
                results <- process(job)
            }
        }()
    }

    go func() {
        wg.Wait()
        close(results)
    }()

    return results
}
```

### Semaphore (Limit Concurrency)

```go
var sem = make(chan struct{}, 10)  // Max 10 concurrent

func process(item Item) {
    sem <- struct{}{}        // Acquire
    defer func() { <-sem }() // Release

    // ... process item ...
}
```

### Worker Pool

```go
func worker(id int, jobs <-chan Job, results chan<- Result) {
    for job := range jobs {
        results <- Result{
            JobID:  job.ID,
            Output: process(job),
        }
    }
}

func main() {
    jobs := make(chan Job, 100)
    results := make(chan Result, 100)

    // Start workers
    for w := 1; w <= 3; w++ {
        go worker(w, jobs, results)
    }

    // Send jobs
    for _, job := range jobList {
        jobs <- job
    }
    close(jobs)

    // Collect results
    for i := 0; i < len(jobList); i++ {
        result := <-results
        // ...
    }
}
```

### Pipeline

```go
func gen(nums ...int) <-chan int {
    out := make(chan int)
    go func() {
        for _, n := range nums {
            out <- n
        }
        close(out)
    }()
    return out
}

func sq(in <-chan int) <-chan int {
    out := make(chan int)
    go func() {
        for n := range in {
            out <- n * n
        }
        close(out)
    }()
    return out
}

// Usage
c := gen(2, 3, 4)
out := sq(c)
for n := range out {
    fmt.Println(n)  // 4, 9, 16
}
```

## Select Statement

### Basic Select

```go
select {
case msg := <-ch1:
    process(msg)
case ch2 <- value:
    // Sent successfully
case <-time.After(time.Second):
    // Timeout
default:
    // Non-blocking: no channel ready
}
```

### Select Patterns

```go
// Timeout
select {
case result := <-ch:
    return result, nil
case <-time.After(5 * time.Second):
    return nil, errors.New("timeout")
}

// Cancellation
select {
case result := <-ch:
    return result
case <-ctx.Done():
    return ctx.Err()
}

// Non-blocking send/receive
select {
case ch <- value:
    // Sent
default:
    // Channel full, skip
}
```

## Context for Cancellation

```go
func worker(ctx context.Context, jobs <-chan Job) error {
    for {
        select {
        case <-ctx.Done():
            return ctx.Err()
        case job, ok := <-jobs:
            if !ok {
                return nil
            }
            if err := process(job); err != nil {
                return err
            }
        }
    }
}

// Usage
ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
defer cancel()

go worker(ctx, jobs)
```

## sync Package

### WaitGroup

```go
var wg sync.WaitGroup

for _, item := range items {
    wg.Add(1)
    go func(item Item) {
        defer wg.Done()
        process(item)
    }(item)
}

wg.Wait()  // Wait for all goroutines
```

### Mutex

```go
type SafeCounter struct {
    mu    sync.Mutex
    count int
}

func (c *SafeCounter) Inc() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.count++
}

func (c *SafeCounter) Value() int {
    c.mu.Lock()
    defer c.mu.Unlock()
    return c.count
}
```

### Once

```go
var (
    instance *Singleton
    once     sync.Once
)

func GetInstance() *Singleton {
    once.Do(func() {
        instance = &Singleton{}
    })
    return instance
}
```

## Mutex Best Practices

### Zero-Value Mutex

**Use zero-value mutex, never pointer:**

```go
// Good - zero value is ready to use
var mu sync.Mutex

// Good - as struct field
type Cache struct {
    mu    sync.Mutex
    items map[string]Item
}

// Bad - unnecessary allocation
mu := new(sync.Mutex)
```

### Never Embed Mutex in Public Struct

```go
// Bad - exposes Lock/Unlock methods
type Cache struct {
    sync.Mutex  // cache.Lock() is now public!
    items map[string]Item
}

// Good - unexported field
type Cache struct {
    mu    sync.Mutex
    items map[string]Item
}
```

## No Fire-and-Forget Goroutines

**Every goroutine must have controllable lifetime:**

```go
// Bad - no way to stop
func startWorker() {
    go func() {
        for {
            process()  // Runs forever, can't stop
        }
    }()
}

// Good - controllable via context
type Worker struct {
    cancel context.CancelFunc
    done   chan struct{}
}

func NewWorker() *Worker {
    ctx, cancel := context.WithCancel(context.Background())
    w := &Worker{cancel: cancel, done: make(chan struct{})}

    go func() {
        defer close(w.done)
        for {
            select {
            case <-ctx.Done():
                return
            default:
                process()
            }
        }
    }()

    return w
}

func (w *Worker) Stop() {
    w.cancel()
    <-w.done  // Wait for goroutine to finish
}
```

## No Goroutines in init()

**Spawn goroutines only in constructors with shutdown methods:**

```go
// Bad - goroutine in init
func init() {
    go backgroundTask()  // Can't control lifecycle
}

// Good - constructor returns object with Stop method
func NewService() *Service {
    s := &Service{stop: make(chan struct{})}
    go s.run()
    return s
}

func (s *Service) Stop() {
    close(s.stop)
}
```

## Type-Safe Atomics

**Prefer go.uber.org/atomic over sync/atomic:**

```go
// Using sync/atomic - error prone
var running int32
atomic.StoreInt32(&running, 1)
if atomic.LoadInt32(&running) == 1 { ... }

// Using go.uber.org/atomic - type safe
import "go.uber.org/atomic"

var running atomic.Bool
running.Store(true)
if running.Load() { ... }
```

## Best Practices Summary

1. **Prefer channels** over shared memory with mutexes
2. **Close channels** from sender side only
3. **Use context** for cancellation and timeouts
4. **No fire-and-forget goroutines** - ensure all can exit
5. **No goroutines in init()** - use constructors
6. **Channel size 0 or 1** unless justified
7. **Use zero-value mutex** - never embed in public structs
8. **Use `go vet`** and race detector: `go test -race`
