# Function Design

## Multiple Return Values

### Error as Last Return
Standard pattern for operations that can fail:

```go
func (f *File) Read(b []byte) (n int, err error) {
    // ...
}

func (f *File) Write(b []byte) (n int, err error) {
    // ...
}

// Usage
n, err := file.Read(buf)
if err != nil {
    return err
}
```

### Return Multiple Values Instead of Modifying Parameters

```go
// Good - returns multiple values
func nextInt(b []byte, pos int) (value int, nextPos int) {
    // ...
    return v, pos
}

// Bad - modifies through pointer
func nextInt(b []byte, pos *int) int {
    // ...
}
```

## Named Return Parameters

### Benefits
- Self-documenting
- Auto-initialized to zero values
- Enable bare returns

```go
// Named returns document what's returned
func ReadFull(r Reader, buf []byte) (n int, err error) {
    for len(buf) > 0 && err == nil {
        var nr int
        nr, err = r.Read(buf)
        n += nr
        buf = buf[nr:]
    }
    return  // Returns current n and err
}
```

### When to Use Named Returns

| Use Named | Use Unnamed |
|-----------|-------------|
| Multiple same-type returns | Single return value |
| Return values need documentation | Obvious from context |
| Using with defer | Short functions |

### Named Returns with Defer

```go
func CopyFile(dst, src string) (written int64, err error) {
    sf, err := os.Open(src)
    if err != nil {
        return
    }
    defer sf.Close()

    df, err := os.Create(dst)
    if err != nil {
        return
    }
    defer func() {
        if closeErr := df.Close(); err == nil {
            err = closeErr  // Modify named return in defer
        }
    }()

    written, err = io.Copy(df, sf)
    return
}
```

## Defer Statement

### Basic Usage
Schedules function call before enclosing function returns:

```go
func process(filename string) error {
    f, err := os.Open(filename)
    if err != nil {
        return err
    }
    defer f.Close()  // Will run when function returns

    // ... work with file ...
    return nil
}
```

### Arguments Evaluated at Defer Time

```go
func trace(msg string) func() {
    start := time.Now()
    log.Printf("enter %s", msg)
    return func() {
        log.Printf("exit %s (%s)", msg, time.Since(start))
    }
}

func foo() {
    defer trace("foo")()  // Arguments evaluated now
    // ... do work ...
}
```

### LIFO Order
Multiple defers execute in reverse order:

```go
func countdown() {
    for i := 0; i < 5; i++ {
        defer fmt.Print(i, " ")
    }
}
// Output: 4 3 2 1 0
```

### Common Defer Patterns

```go
// Mutex unlock
mu.Lock()
defer mu.Unlock()

// File close
f, err := os.Open(name)
if err != nil {
    return err
}
defer f.Close()

// Response body close
resp, err := http.Get(url)
if err != nil {
    return err
}
defer resp.Body.Close()

// Recover from panic
defer func() {
    if r := recover(); r != nil {
        log.Printf("recovered: %v", r)
    }
}()
```

## Variadic Functions

```go
// Accept any number of arguments
func Printf(format string, args ...interface{}) {
    // args is []interface{}
}

// Pass slice to variadic
values := []int{1, 2, 3}
sum(values...)  // Expands slice
```

## Function Length

Go has no hard limit on function lines, but long functions hurt readability, testability, and maintainability.

### Practical Guidelines

Go 没有硬性行数限制。真正重要的是**可读性**和**单一职责**。

热门开源项目的实际做法：
- **Go stdlib**: 标准库中 50-100 行的函数很常见，特别是表示清晰工作流的函数
- **Kubernetes**: controller 逻辑常超过 50 行，只要逻辑清晰
- **CockroachDB**: 注重代码清晰而非行数，某些核心函数较长
- **Prometheus**: 超过 50 行会被 peer review 关注，但不会被硬性拒绝

| 信号 | 建议 |
|------|------|
| 需要滚动查看 | 考虑拆分 |
| 多个职责混合 | 必须拆分 |
| 嵌套超过 2-3 层 | 考虑提取分支逻辑 |
| 难以命名（"and"连词） | 考虑拆分 |
| 难以单独测试 | 考虑拆分 |

### When to Split

Ask yourself:
1. Can I describe this function in one sentence?
2. Does it have independent sub-steps?
3. Is the same logic needed elsewhere?
4. Does it require scrolling to see the whole thing?

### How to Split

Extract helper functions for:
- **Independent sub-tasks**: Validation, building, conversion
- **Repeated logic**: DRY — if used twice, extract it
- **Complex conditions**: Named predicates clarify intent

```go
// Bad - mixed responsibilities, hard to follow
func (s *Service) GetEvent(ctx context.Context, id string) (*Event, error) {
    if id == "" {
        return nil, errors.New("id required")
    }
    objID, err := primitive.ObjectIDFromHex(id)
    if err != nil {
        return nil, errors.New("invalid id")
    }
    event, err := s.repo.FindByID(ctx, objID)
    if err != nil {
        return nil, err
    }
    if event == nil {
        return nil, errors.New("not found")
    }
    // ... long conversion logic
    return dto, nil
}

// Good - each step is a named responsibility
func (s *Service) GetEvent(ctx context.Context, id string) (*Event, error) {
    objID, err := s.parseID(id)
    if err != nil {
        return nil, err
    }
    event, err := s.repo.FindByID(ctx, objID)
    if err != nil {
        return nil, err
    }
    return s.toEventDTO(event)
}

func (s *Service) parseID(id string) (primitive.ObjectID, error) {
    if id == "" {
        return primitive.Nil, errors.New("id required")
    }
    objID, err := primitive.ObjectIDFromHex(id)
    if err != nil {
        return primitive.Nil, errors.New("invalid id")
    }
    return objID, nil
}
```

### Key Principle

> **Do one thing and do it well.** A function should have a single responsibility. If you need to say "and" to describe what it does, it should probably be two functions.
