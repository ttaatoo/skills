# Method Receivers

## Pointer vs Value Receivers

### Decision Table

| Condition | Receiver Type | Reason |
|-----------|--------------|--------|
| Method modifies receiver | `*T` | Changes persist |
| Receiver is large struct | `*T` | Avoid copy overhead |
| Consistency with other methods | `*T` | If any method uses pointer, all should |
| Small immutable value | `T` | Safe, clear semantics |
| Basic type (int, string) | `T` | Copying is cheap |
| Thread safety needed | `T` | Value copy prevents races |

## When to Use Pointer Receiver

### 1. Method Modifies Receiver

```go
type Counter struct {
    value int
}

// Must use pointer - modifies receiver
func (c *Counter) Increment() {
    c.value++
}

// Value receiver would modify a copy (useless)
func (c Counter) IncrementWrong() {
    c.value++  // Modifies copy, original unchanged
}
```

### 2. Large Struct

```go
type LargeStruct struct {
    data [1024]byte
    // ... many fields
}

// Pointer avoids copying 1KB+ on each call
func (s *LargeStruct) Process() {
    // ...
}
```

### 3. Consistency

```go
type User struct {
    name  string
    email string
}

// If one method needs pointer, use pointer for all
func (u *User) SetName(name string) {
    u.name = name
}

// Even read-only methods use pointer for consistency
func (u *User) Name() string {
    return u.name
}
```

## When to Use Value Receiver

### 1. Small Immutable Types

```go
type Point struct {
    X, Y float64
}

// Value receiver - Point is small and not modified
func (p Point) Distance(q Point) float64 {
    dx := p.X - q.X
    dy := p.Y - q.Y
    return math.Sqrt(dx*dx + dy*dy)
}
```

### 2. Basic Types

```go
type Duration int64

// Value receiver for basic type wrapper
func (d Duration) Hours() float64 {
    return float64(d) / float64(Hour)
}
```

### 3. Thread Safety

```go
type SafeValue struct {
    data string
}

// Value receiver creates copy - safe for concurrent use
func (v SafeValue) Get() string {
    return v.data  // Returns copy, original unaffected
}
```

## Automatic Dereferencing

Go automatically handles pointer/value conversion for method calls:

```go
type T struct {
    value int
}

func (t *T) SetValue(v int) { t.value = v }
func (t T) GetValue() int   { return t.value }

func main() {
    var t T
    var p *T = &t

    // All of these work:
    t.SetValue(1)   // Go converts to (&t).SetValue(1)
    p.SetValue(2)   // Direct pointer call
    t.GetValue()    // Direct value call
    p.GetValue()    // Go converts to (*p).GetValue()
}
```

**Exception:** Can't call pointer method on non-addressable value:

```go
// This fails - map values are not addressable
m := map[string]T{"key": T{}}
m["key"].SetValue(1)  // Compile error!

// Fix: use pointer in map
m := map[string]*T{"key": &T{}}
m["key"].SetValue(1)  // Works
```

## Interface Implementation

```go
type Sizer interface {
    Size() int
}

type Data struct {
    content []byte
}

// Value receiver - both Data and *Data implement Sizer
func (d Data) Size() int {
    return len(d.content)
}

// Pointer receiver - only *Data implements Modifier
type Modifier interface {
    Modify(b byte)
}

func (d *Data) Modify(b byte) {
    d.content = append(d.content, b)
}

func main() {
    var d Data
    var s Sizer = d   // OK - value implements Sizer
    var s2 Sizer = &d // OK - pointer also implements Sizer

    var m Modifier = &d // OK - pointer implements Modifier
    // var m2 Modifier = d // ERROR - value doesn't implement Modifier
}
```

## Method on Non-Struct Types

```go
type ByteSlice []byte

func (b *ByteSlice) Append(data []byte) {
    *b = append(*b, data...)
}

// Implements io.Writer
func (b *ByteSlice) Write(data []byte) (n int, err error) {
    *b = append(*b, data...)
    return len(data), nil
}
```
