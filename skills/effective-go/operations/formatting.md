# Formatting Guidelines

## Core Tool: gofmt

**Use `gofmt` for all formatting decisions.** This is non-negotiable in Go.

```bash
gofmt -w .          # Format all Go files in current directory
go fmt ./...        # Format all packages
```

## Key Formatting Rules

### Indentation
- Use **tabs** for indentation (not spaces)
- `gofmt` handles this automatically

### Line Length
- No hard limit
- For long lines: wrap and indent with extra tab

### Brace Placement
Opening brace must be on same line as control statement:

```go
// Correct
if condition {
    doSomething()
}

// Wrong - causes syntax error
if condition
{
    doSomething()
}
```

### Parentheses
- Control structures (`if`, `for`, `switch`) don't need parentheses
- Operator precedence is clearer than C

```go
// Correct
if x > 0 && y > 0 {
    return x + y
}

// Wrong - unnecessary parentheses
if (x > 0) && (y > 0) {
    return (x + y)
}
```

## Commentary

### Line Comments
Use `//` style for most comments:

```go
// calculateTotal returns the sum of all items
func calculateTotal(items []int) int {
    // ...
}
```

### Block Comments
Use `/* */` for package documentation:

```go
/*
Package http provides HTTP client and server implementations.

The package supports HTTP/1.1 and HTTP/2 protocols.
*/
package http
```

### Doc Comments
- Place directly before declaration (no blank line)
- Start with the name being documented
- Complete sentences

```go
// Buffer is a variable-sized buffer of bytes with Read and Write methods.
// The zero value for Buffer is an empty buffer ready to use.
type Buffer struct {
    // ...
}

// Read reads the next len(p) bytes from the buffer or until the buffer
// is drained. The return value n is the number of bytes read.
func (b *Buffer) Read(p []byte) (n int, err error) {
    // ...
}
```
