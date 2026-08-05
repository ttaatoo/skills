# Data Types (#17-29)

## #17 - Octal Literals Confusion

**Problem:** `0` prefix indicates octal, which can cause confusion.

```go
// Confusing
x := 010  // This is 8, not 10!

// Clear - use 0o prefix (Go 1.13+)
x := 0o10  // Clearly octal 8
y := 10    // Decimal 10
z := 0x10  // Hex 16
```

## #18 - Neglecting Integer Overflows

**Problem:** Integer overflows are silent at runtime.

```go
// Overflow without error
var x int32 = math.MaxInt32
x++  // Silent overflow to -2147483648

// Solution: check before operations
func addInt32(a, b int32) (int32, error) {
    if (b > 0 && a > math.MaxInt32-b) ||
       (b < 0 && a < math.MinInt32-b) {
        return 0, errors.New("integer overflow")
    }
    return a + b, nil
}
```

## #19 - Not Understanding Floating-Points

**Problems:**
- Precision errors in comparisons
- Order of operations matters

```go
// Bad - direct comparison
if f1 == f2 { ... }  // May fail due to precision

// Good - compare within delta
const epsilon = 1e-9
if math.Abs(f1-f2) < epsilon { ... }

// Order matters for precision
// Bad: (a + b) + c
// Good: Group by magnitude, multiply/divide before add/subtract
```

## #20 - Slice Length vs Capacity

**Distinction:**
- `len(s)` - number of elements
- `cap(s)` - backing array size

```go
s := make([]int, 3, 10)
// len(s) = 3 (elements: s[0], s[1], s[2])
// cap(s) = 10 (can grow to 10 without reallocation)

s = append(s, 4)  // len=4, cap=10
```

## #21 - Inefficient Slice Initialization

**Problem:** Not pre-allocating when size is known.

```go
// Bad - multiple reallocations
var result []int
for _, item := range items {
    result = append(result, process(item))
}

// Good - pre-allocate
result := make([]int, 0, len(items))
for _, item := range items {
    result = append(result, process(item))
}

// Best - if transforming 1:1
result := make([]int, len(items))
for i, item := range items {
    result[i] = process(item)
}
```

## #22 - nil vs Empty Slice Confusion

**Key points:**
- `nil` slice: `var s []int` → s == nil, len(s) == 0
- Empty slice: `s := []int{}` → s != nil, len(s) == 0
- Both work with `append`, `range`, `len`

```go
// Don't distinguish in APIs - both mean "empty"
func process(items []int) {
    // Check length, not nil
    if len(items) == 0 {
        return
    }
}
```

## #23 - Not Checking Slice Emptiness Correctly

```go
// Bad - only catches nil
if items == nil { ... }

// Good - catches both nil and empty
if len(items) == 0 { ... }
```

## #24 - Incorrect Slice Copying

**Problem:** `copy` copies min(len(dst), len(src)) elements.

```go
src := []int{1, 2, 3}
dst := make([]int, 2)
copy(dst, src)  // dst = [1, 2], only 2 elements copied!

// Correct - ensure dst has enough capacity
dst := make([]int, len(src))
copy(dst, src)  // dst = [1, 2, 3]
```

## #25 - Slice Append Side Effects

**Problem:** Append may modify shared backing array.

```go
// Dangerous
s1 := []int{1, 2, 3, 4, 5}
s2 := s1[1:3]  // [2, 3], shares backing array
s2 = append(s2, 10)  // May modify s1!

// Safe - use full slice expression
s2 := s1[1:3:3]  // cap(s2) = 2, forces new allocation on append

// Or copy explicitly
s2 := make([]int, 2)
copy(s2, s1[1:3])
```

## #26 - Slices and Memory Leaks

**Problem:** Slicing retains entire backing array.

```go
// Memory leak - keeps entire msg in memory
func getFirst(msg []byte) []byte {
    return msg[:5]  // Still references full msg array
}

// Solution - copy
func getFirst(msg []byte) []byte {
    result := make([]byte, 5)
    copy(result, msg[:5])
    return result
}

// For pointer slices, nil out excluded elements
func removeFirst(ptrs []*BigStruct) []*BigStruct {
    ptrs[0] = nil  // Allow GC
    return ptrs[1:]
}
```

## #27 - Inefficient Map Initialization

**Problem:** Map growth is expensive.

```go
// Bad - grows multiple times
m := make(map[string]int)
for _, item := range largeSlice {
    m[item.Key] = item.Value
}

// Good - pre-allocate
m := make(map[string]int, len(largeSlice))
for _, item := range largeSlice {
    m[item.Key] = item.Value
}
```

## #28 - Maps and Memory Leaks

**Problem:** Maps never shrink, even after deleting keys.

```go
// If map grows large then shrinks, memory stays allocated
m := make(map[int]*BigStruct)
// ... add millions of entries
// ... delete most entries
// Memory still allocated!

// Solution: recreate map
newMap := make(map[int]*BigStruct, len(m))
for k, v := range m {
    newMap[k] = v
}
m = newMap
```

## #29 - Comparing Values Incorrectly

**Rules:**
- Use `==` for comparable types (primitives, structs with comparable fields)
- Slices, maps, functions are not comparable with `==`

```go
// Bad - doesn't compile
if slice1 == slice2 { ... }

// Good - use reflect or custom comparison
import "reflect"
if reflect.DeepEqual(slice1, slice2) { ... }

// Better - custom comparison for performance
func equal(a, b []int) bool {
    if len(a) != len(b) {
        return false
    }
    for i := range a {
        if a[i] != b[i] {
            return false
        }
    }
    return true
}
```
