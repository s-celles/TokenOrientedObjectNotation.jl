# Configuration Options

This guide covers all configuration options for encoding and decoding.

## EncodeOptions

Configure encoding behavior with `EncodeOptions`:

```julia
options = TOON.EncodeOptions(
    indent = 2,
    delimiter = TOON.COMMA,
    keyFolding = "off",
    flattenDepth = typemax(Int)
)

TOON.encode(data, options=options)
```

### indent

Number of spaces per indentation level.

**Type:** `Int`  
**Default:** `2`  
**Valid values:** Any positive integer

```julia
# 2 spaces (default)
options = TOON.EncodeOptions(indent=2)

# 4 spaces
options = TOON.EncodeOptions(indent=4)

# 8 spaces
options = TOON.EncodeOptions(indent=8)
```

### delimiter

Delimiter character for arrays.

**Type:** `Delimiter`  
**Default:** `TOON.COMMA`  
**Valid values:** `TOON.COMMA`, `TOON.TAB`, `TOON.PIPE`

```julia
# Comma (default)
options = TOON.EncodeOptions(delimiter=TOON.COMMA)
# Output: [3]: 1,2,3

# Tab
options = TOON.EncodeOptions(delimiter=TOON.TAB)
# Output: [3	]: 1	2	3

# Pipe
options = TOON.EncodeOptions(delimiter=TOON.PIPE)
# Output: [3|]: 1|2|3
```

**Use cases:**
- **Comma:** General purpose, most compact
- **Tab:** TSV-like data, easy to parse
- **Pipe:** Visual separation, database-style

### keyFolding

Enable flattening of nested objects into dotted keys.

**Type:** `String`  
**Default:** `"off"`  
**Valid values:** `"off"`, `"safe"`

```julia
data = Dict("a" => Dict("b" => Dict("c" => 42)))

# Off (default) - no folding
options = TOON.EncodeOptions(keyFolding="off")
TOON.encode(data, options=options)
# a:
#   b:
#     c: 42

# Safe - fold identifier keys only
options = TOON.EncodeOptions(keyFolding="safe")
TOON.encode(data, options=options)
# a.b.c: 42
```

**Safe mode rules:**
- Only folds keys that are valid identifiers
- Keys must match pattern: `^[A-Za-z_][A-Za-z0-9_]*$`
- Keys with spaces, special chars, or starting with numbers are not folded

### flattenDepth

Maximum depth for key folding.

**Type:** `Int`  
**Default:** `typemax(Int)` (unlimited)  
**Valid values:** Any non-negative integer

```julia
data = Dict("a" => Dict("b" => Dict("c" => Dict("d" => 42))))

# Unlimited depth (default)
options = TOON.EncodeOptions(keyFolding="safe")
TOON.encode(data, options=options)
# a.b.c.d: 42

# Limit to 2 levels
options = TOON.EncodeOptions(keyFolding="safe", flattenDepth=2)
TOON.encode(data, options=options)
# a.b:
#   c:
#     d: 42
```

## DecodeOptions

Configure decoding behavior with `DecodeOptions`:

```julia
options = TOON.DecodeOptions(
    indent = 2,
    strict = true,
    expandPaths = "off"
)

TOON.decode(input, options=options)
```

### indent

Expected number of spaces per indentation level.

**Type:** `Int`  
**Default:** `2`  
**Valid values:** Any positive integer

```julia
# 2 spaces (default)
options = TOON.DecodeOptions(indent=2)

# 4 spaces
options = TOON.DecodeOptions(indent=4)
```

**Note:** Must match the indentation used in the input.

### strict

Enable strict validation.

**Type:** `Bool`  
**Default:** `true`  
**Valid values:** `true`, `false`

```julia
# Strict mode (default) - validates everything
options = TOON.DecodeOptions(strict=true)

# Non-strict mode - lenient parsing
options = TOON.DecodeOptions(strict=false)
```

**Strict mode validates:**
- Array count matches declared length
- Row width matches field count in tabular arrays
- Colons present after keys and array headers
- Only valid escape sequences (`\\`, `\"`, `\n`, `\r`, `\t`)
- No unterminated strings
- Indentation is exact multiple of `indent`
- No tabs in indentation
- No blank lines inside arrays
- No path expansion conflicts

**Non-strict mode:**
- Accepts actual array length if different from declared
- Accepts variable row widths
- More lenient with formatting
- Uses last-write-wins for conflicts

### expandPaths

Enable expansion of dotted keys into nested objects.

**Type:** `String`  
**Default:** `"off"`  
**Valid values:** `"off"`, `"safe"`

```julia
input = "a.b.c: 42"

# Off (default) - no expansion
options = TOON.DecodeOptions(expandPaths="off")
TOON.decode(input, options=options)
# Dict("a.b.c" => 42)

# Safe - expand identifier keys only
options = TOON.DecodeOptions(expandPaths="safe")
TOON.decode(input, options=options)
# Dict("a" => Dict("b" => Dict("c" => 42)))
```

**Safe mode rules:**
- Only expands keys where all segments are valid identifiers
- Segments must match pattern: `^[A-Za-z_][A-Za-z0-9_]*$`
- Detects conflicts (e.g., `a: 1` followed by `a.b: 2`)
- In strict mode, errors on conflicts
- In non-strict mode, uses last-write-wins

## Common Configurations

### Production (Strict)

```julia
encode_opts = TOON.EncodeOptions(
    indent = 2,
    delimiter = TOON.COMMA
)

decode_opts = TOON.DecodeOptions(
    indent = 2,
    strict = true
)
```

### Development (Lenient)

```julia
decode_opts = TOON.DecodeOptions(
    strict = false
)
```

### Compact (Key Folding)

```julia
encode_opts = TOON.EncodeOptions(
    keyFolding = "safe",
    flattenDepth = 3
)

decode_opts = TOON.DecodeOptions(
    expandPaths = "safe"
)
```

### TSV-like (Tab Delimiter)

```julia
encode_opts = TOON.EncodeOptions(
    delimiter = TOON.TAB
)
```

### Custom Indentation

```julia
encode_opts = TOON.EncodeOptions(indent=4)
decode_opts = TOON.DecodeOptions(indent=4)
```

## Round-trip Compatibility

For perfect round-trips, use matching options:

```julia
# Encoding
encode_opts = TOON.EncodeOptions(
    indent = 4,
    keyFolding = "safe"
)
encoded = TOON.encode(data, options=encode_opts)

# Decoding
decode_opts = TOON.DecodeOptions(
    indent = 4,
    expandPaths = "safe"
)
decoded = TOON.decode(encoded, options=decode_opts)

# data == decoded (structurally equivalent)
```

## Next Steps

- Learn about [Encoding](encoding.md)
- Learn about [Decoding](decoding.md)
- See [Advanced Features](advanced.md)
