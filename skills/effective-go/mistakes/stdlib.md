# Standard Library (#75-81)

## #75 - Providing Wrong Time Duration

**Problem:** Confusing time units.

```go
// Bug - intending 3 seconds, gets 3 nanoseconds
time.Sleep(3)  // 3 nanoseconds!

// Correct
time.Sleep(3 * time.Second)
time.Sleep(500 * time.Millisecond)

// Bug - wrong unit multiplication
timeout := 30 * 1000  // Intending 30 seconds in ms
time.Sleep(time.Duration(timeout))  // 30 microseconds!

// Correct
timeout := 30 * time.Second
```

## #76 - time.After and Memory Leaks

**Problem:** `time.After` holds resources until timer fires.

```go
// Memory leak in loop
for {
    select {
    case <-ch:
        // ...
    case <-time.After(time.Second):  // New timer each iteration!
        // ...
    }
}

// Fix - reuse timer
ticker := time.NewTicker(time.Second)
defer ticker.Stop()

for {
    select {
    case <-ch:
        // ...
    case <-ticker.C:
        // ...
    }
}

// Or use context timeout
ctx, cancel := context.WithTimeout(ctx, time.Second)
defer cancel()
```

## #77 - JSON Handling Mistakes

### Unmarshaling Errors

```go
// Always check unmarshal errors
var data MyStruct
if err := json.Unmarshal(jsonBytes, &data); err != nil {
    return err
}
```

### Type Mismatches

```go
type Response struct {
    Count int `json:"count"`
}

// Bug - JSON has string "5", struct expects int
// {"count": "5"} → unmarshal fails

// Fix - use json.Number or string
type Response struct {
    Count json.Number `json:"count"`
}
```

### nil vs Empty Slice

```go
type Response struct {
    Items []string `json:"items"`
}

// nil slice → "items": null
// empty slice → "items": []

// To always get array:
r := Response{Items: []string{}}
```

## #78 - Common SQL Mistakes

### Not Closing Rows

```go
// Bug - rows not closed on error
rows, err := db.Query("SELECT ...")
if err != nil {
    return err
}
// If error occurs below, rows leak!

// Fix - defer close
rows, err := db.Query("SELECT ...")
if err != nil {
    return err
}
defer rows.Close()
```

### Ignoring Rows.Err()

```go
// Bug - iteration may have failed
for rows.Next() {
    rows.Scan(&v)
}
// rows.Err() not checked!

// Fix
for rows.Next() {
    if err := rows.Scan(&v); err != nil {
        return err
    }
}
if err := rows.Err(); err != nil {
    return err
}
```

### Not Using Context

```go
// Bad - no timeout
rows, err := db.Query("SELECT ...")

// Good - with context
ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
defer cancel()
rows, err := db.QueryContext(ctx, "SELECT ...")
```

## #79 - Not Closing Transient Resources

**Always close:**
- `http.Response.Body`
- `sql.Rows`
- `os.File`

```go
// HTTP response
resp, err := http.Get(url)
if err != nil {
    return err
}
defer resp.Body.Close()

// SQL rows
rows, err := db.Query(...)
if err != nil {
    return err
}
defer rows.Close()

// Files
f, err := os.Open(path)
if err != nil {
    return err
}
defer f.Close()
```

## #80 - Forgetting Return After HTTP Response

**Problem:** Continuing execution after writing response.

```go
// Bug - executes both branches
func handler(w http.ResponseWriter, r *http.Request) {
    if err := validate(r); err != nil {
        http.Error(w, err.Error(), 400)
        // Missing return! Falls through to success path
    }
    json.NewEncoder(w).Encode(success)  // Writes to already-written response
}

// Fix - always return after response
func handler(w http.ResponseWriter, r *http.Request) {
    if err := validate(r); err != nil {
        http.Error(w, err.Error(), 400)
        return  // Critical!
    }
    json.NewEncoder(w).Encode(success)
}
```

## #81 - Using Default HTTP Client/Server

**Problem:** No timeouts = potential resource exhaustion.

```go
// Bad - no timeouts
http.Get(url)  // Uses http.DefaultClient

// Good - configure client
client := &http.Client{
    Timeout: 10 * time.Second,
    Transport: &http.Transport{
        MaxIdleConns:        100,
        MaxIdleConnsPerHost: 10,
        IdleConnTimeout:     90 * time.Second,
    },
}
resp, err := client.Get(url)

// Bad - no timeouts on server
http.ListenAndServe(":8080", handler)

// Good - configure server
server := &http.Server{
    Addr:         ":8080",
    Handler:      handler,
    ReadTimeout:  5 * time.Second,
    WriteTimeout: 10 * time.Second,
    IdleTimeout:  120 * time.Second,
}
server.ListenAndServe()
```
