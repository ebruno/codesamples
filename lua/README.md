# Lua Samples

This directory contains Lua coding samples.

## Files

### `fizzbuzz.lua`
A Lua implementation of the classic FizzBuzz problem. It prints numbers from a start value to an end value, replacing multiples of 3 with "Fizz", multiples of 5 with "Buzz", and multiples of both with "FizzBuzz".

**Usage:**
```lua
# Run with default values (1 to 100)
lua fizzbuzz.lua

# Run with a specific start value
lua fizzbuzz.lua 10

# Run with a specific start and end value
lua fizzbuzz.lua 10 50
```

### `trim_whitespace.lua`
A Lua utility that provides a `trim` function to remove leading and trailing whitespace from a string using string patterns.

**Usage:**
You can require this file as a module or run it as a script:
```lua
-- As a script
lua trim_whitespace.lua "  Hello World  "

-- As a module
local trim = require("trim_whitespace")
print(trim("  Hello World  ")) -- Output: Hello World
```

