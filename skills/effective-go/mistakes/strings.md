# String Handling (#36-41)

## #36 - Misunderstanding Runes

**Key concepts:**
- `rune` = Unicode code point (int32)
- `len(s)` returns bytes, not characters
- UTF-8 encodes runes as 1-4 bytes

```go
s := "Hello, 世界"

// len returns bytes
len(s)  // 13 bytes (7 ASCII + 2×3 Chinese)

// Count runes
utf8.RuneCountInString(s)  // 9 runes

// Rune types
var r rune = '世'  // int32, value 19990
len(string(r))     // 3 bytes in UTF-8
```

## #37 - Inaccurate String Iteration

**Problem:** Indexing strings gives bytes, not runes.

```go
s := "Hello, 世界"

// Bad - iterates bytes
for i := 0; i < len(s); i++ {
    fmt.Printf("%c ", s[i])  // Garbled output for Chinese
}

// Good - range iterates runes
for i, r := range s {
    fmt.Printf("%d: %c\n", i, r)
}
// 0: H, 1: e, ..., 7: 世, 10: 界

// Access specific rune by index
runes := []rune(s)
runes[7]  // '世'
```

## #38 - Misusing Trim Functions

**Distinction:**
- `TrimRight`/`TrimLeft` - remove character SET
- `TrimSuffix`/`TrimPrefix` - remove exact STRING

```go
s := "hello!!!"

// TrimRight removes any chars in the set
strings.TrimRight(s, "!")   // "hello"
strings.TrimRight(s, "!o")  // "hell"  (removes !, then o)

// TrimSuffix removes exact suffix
strings.TrimSuffix(s, "!")    // "hello!!"
strings.TrimSuffix(s, "!!!")  // "hello"

// Same for left/prefix
strings.TrimLeft("...hello", ".")     // "hello"
strings.TrimPrefix("...hello", "...")  // "hello"
```

## #39 - Under-Optimized String Concatenation

**Problem:** `+=` creates new string each time.

```go
// Bad - O(n²) complexity
var result string
for _, s := range slices {
    result += s  // New allocation each iteration
}

// Good - use strings.Builder
var b strings.Builder
b.Grow(totalLen)  // Pre-allocate if known
for _, s := range slices {
    b.WriteString(s)
}
result := b.String()

// Alternative - strings.Join
result := strings.Join(slices, "")
```

## #40 - Useless String Conversions

**Problem:** Converting []byte to string when bytes package works.

```go
// Bad - unnecessary conversion
s := string(data)
if strings.Contains(s, "error") { ... }

// Good - use bytes package directly
if bytes.Contains(data, []byte("error")) { ... }

// bytes package mirrors strings:
// bytes.Contains, bytes.Split, bytes.Index, etc.
```

## #41 - Substring Memory Leaks

**Problem:** Substrings share backing array with original string.

```go
// Memory leak - keeps entire msg in memory
func getToken(msg string) string {
    return msg[:16]  // Still references full msg
}

// Solution 1 - copy
func getToken(msg string) string {
    token := msg[:16]
    return strings.Clone(token)  // Go 1.18+
}

// Solution 2 - convert through bytes
func getToken(msg string) string {
    return string([]byte(msg[:16]))
}
```
