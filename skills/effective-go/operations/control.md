# Control Structures

## If Statements

### Initialization in Condition
Common pattern - declare and test in one statement:

```go
// Good - err scoped to if block
if err := file.Chmod(0664); err != nil {
    log.Print(err)
    return err
}

// Also good for multiple returns
if n, err := fmt.Fprintf(w, "hello"); err != nil {
    return fmt.Errorf("write failed: %w", err)
}
```

### Omit Unnecessary Else
When body ends with `break`, `continue`, `goto`, or `return`:

```go
// Good - successful path flows down
f, err := os.Open(name)
if err != nil {
    return err
}
doSomethingWith(f)

// Bad - unnecessary else
f, err := os.Open(name)
if err != nil {
    return err
} else {
    doSomethingWith(f)
}
```

### Guard Clauses
Handle errors first, keep happy path unindented:

```go
// Good
func process(data []byte) error {
    if len(data) == 0 {
        return errors.New("empty data")
    }
    if !isValid(data) {
        return errors.New("invalid data")
    }

    // Happy path continues here
    result := transform(data)
    return save(result)
}
```

## For Loops

### Three Forms

```go
// C-style for
for i := 0; i < 10; i++ {
    fmt.Println(i)
}

// While-style (condition only)
for condition {
    doSomething()
}

// Infinite loop
for {
    if done() {
        break
    }
}
```

### Range Clause
Preferred for iterating collections:

```go
// Slice/array - index and value
for i, v := range slice {
    fmt.Printf("%d: %v\n", i, v)
}

// Map - key and value
for key, value := range m {
    fmt.Printf("%s: %v\n", key, value)
}

// Channel - values until closed
for msg := range ch {
    process(msg)
}

// String - rune index and rune value
for i, r := range "Hello, 世界" {
    fmt.Printf("%d: %c\n", i, r)
}
```

### Skipping Values
Use blank identifier `_`:

```go
// Skip index
for _, value := range slice {
    process(value)
}

// Skip value (index only)
for i := range slice {
    process(i)
}

// Skip both (just iterate)
for range slice {
    doSomething()
}
```

### Parallel Assignment

```go
// Reverse a slice
for i, j := 0, len(s)-1; i < j; i, j = i+1, j-1 {
    s[i], s[j] = s[j], s[i]
}
```

## Switch Statements

### No Automatic Fall-Through
Cases don't fall through - use `fallthrough` explicitly (rarely needed):

```go
switch n {
case 1:
    doOne()
    // No fallthrough - next case won't execute
case 2:
    doTwo()
case 3:
    fallthrough  // Explicit - continues to case 4
case 4:
    doThreeOrFour()
}
```

### Multiple Values Per Case

```go
switch char {
case ' ', '\t', '\n', '\r':
    return true  // Any whitespace
case 'a', 'e', 'i', 'o', 'u':
    return true  // Any vowel
default:
    return false
}
```

### Expression-less Switch
Switches on `true` - idiomatic for if-else chains:

```go
switch {
case n < 0:
    return "negative"
case n == 0:
    return "zero"
case n < 10:
    return "small"
default:
    return "large"
}
```

### Type Switch
Discover dynamic type of interface:

```go
switch v := value.(type) {
case string:
    return len(v)
case int:
    return v
case bool:
    if v {
        return 1
    }
    return 0
default:
    return 0
}
```

### Break with Labels

```go
Loop:
    for i := 0; i < 10; i++ {
        switch i {
        case 5:
            break Loop  // Breaks out of for loop, not just switch
        }
    }
```
