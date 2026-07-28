# Zsh Samples

This directory contains Zsh scripts and utility functions.

## Files

### `fizzbuzz.zsh`
A Zsh implementation of the classic FizzBuzz problem. It prints numbers from a start value to an end value, replacing multiples of 3 with "Fizz", multiples of 5 with "Buzz", and multiples of both with "FizzBuzz".

**Usage:**
```zsh
# Run with default values (1 to 100)
zsh fizzbuzz.zsh

# Run with a specific start value
zsh fizzbuzz.zsh 10

# Run with a specific start and end value
zsh fizzbuzz.zsh 10 50
```
*Note: Requires Zsh 5.0 or higher.*

### `trim_whitespace.zsh`
A Zsh utility function `remove_whitespace` that removes leading and trailing whitespace from a string using only built-in parameter expansion (no external programs).

**Usage:**
You can source this file in your Zsh session or script to use the function:
```zsh
source trim_whitespace.zsh
result=$(remove_whitespace "  Hello World  ")
echo "$result" # Output: Hello World
```
