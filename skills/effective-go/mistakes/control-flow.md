# Control Structures (#30-35)

## #30 - Range Loop Element Copying

**Problem:** Range loop elements are copies, not references.

```go
type Account struct {
    Balance int
}

// Bad - modifies copy, not original
accounts := []Account{{Balance: 100}, {Balance: 200}}
for _, acc := range accounts {
    acc.Balance += 10  // Modifies copy only!
}
// accounts unchanged: [{100}, {200}]

// Good - use index
for i := range accounts {
    accounts[i].Balance += 10
}
// accounts changed: [{110}, {210}]

// Good - use pointer slice
accounts := []*Account{{Balance: 100}, {Balance: 200}}
for _, acc := range accounts {
    acc.Balance += 10  // Works with pointers
}
```

## #31 - Range Argument Evaluation

**Problem:** Range expression evaluates once before loop starts.

```go
// The slice length is captured at start
s := []int{0, 1, 2}
for range s {
    s = append(s, 10)  // s grows but loop runs only 3 times
}
// Loop runs 3 times, not infinite

// Channel is evaluated once
ch := make(chan int)
go func() {
    for i := 0; i < 3; i++ {
        ch <- i
    }
    close(ch)
}()
for v := range ch {  // ch captured once
    fmt.Println(v)
}
```

## #32 - Pointer Elements in Range Loops

**Note:** This issue is fixed in Go 1.22+.

```go
// Before Go 1.22 - Bug
var ptrs []*int
for _, v := range []int{1, 2, 3} {
    ptrs = append(ptrs, &v)  // All point to same variable!
}
// All ptrs point to 3

// Before Go 1.22 - Fix
for _, v := range []int{1, 2, 3} {
    v := v  // Create new variable
    ptrs = append(ptrs, &v)
}

// Go 1.22+ - Fixed automatically
// Each iteration has its own variable
```

## #33 - Map Iteration Assumptions

**Problems:**
- Maps don't preserve insertion order
- Order changes between iterations
- Elements added during iteration may or may not appear

```go
// Order is random
m := map[string]int{"a": 1, "b": 2, "c": 3}
for k, v := range m {
    fmt.Println(k, v)  // Different order each run
}

// For deterministic order, sort keys
keys := make([]string, 0, len(m))
for k := range m {
    keys = append(keys, k)
}
sort.Strings(keys)
for _, k := range keys {
    fmt.Println(k, m[k])
}
```

## #34 - Break Statement Confusion

**Problem:** `break` only terminates innermost loop/switch/select.

```go
// Bad - break exits switch, not loop
for i := 0; i < 10; i++ {
    switch i {
    case 5:
        break  // Only exits switch, loop continues!
    }
}

// Good - use labeled break
Loop:
    for i := 0; i < 10; i++ {
        switch i {
        case 5:
            break Loop  // Exits the for loop
        }
    }

// Same for select
Loop:
    for {
        select {
        case <-done:
            break Loop  // Exits for loop, not just select
        case msg := <-ch:
            process(msg)
        }
    }
```

## #35 - Defer Inside Loops

**Problem:** Defer executes when function returns, not at end of iteration.

```go
// Bad - files accumulate until function returns
func processFiles(paths []string) error {
    for _, path := range paths {
        f, err := os.Open(path)
        if err != nil {
            return err
        }
        defer f.Close()  // Won't close until function returns!
        // ... process f
    }
    return nil
}
// If 1000 files, 1000 file handles open simultaneously

// Good - extract to function
func processFiles(paths []string) error {
    for _, path := range paths {
        if err := processFile(path); err != nil {
            return err
        }
    }
    return nil
}

func processFile(path string) error {
    f, err := os.Open(path)
    if err != nil {
        return err
    }
    defer f.Close()  // Closes when processFile returns
    // ... process f
    return nil
}

// Alternative - closure
for _, path := range paths {
    func() {
        f, err := os.Open(path)
        if err != nil {
            return
        }
        defer f.Close()
        // ... process f
    }()
}
```
