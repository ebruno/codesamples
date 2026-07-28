# Bash Samples

This directory contains Bash scripts and utility functions.

## Files

### `fizzbuzz.sh`
A Bash implementation of the classic FizzBuzz problem. It prints numbers from a start value to an end value, replacing multiples of 3 with "Fizz", multiples of 5 with "Buzz", and multiples of both with "FizzBuzz".

**Usage:**
```bash
# Run with default values (1 to 100)
bash fizzbuzz.sh

# Run with a specific start value
bash fizzbuzz.sh 10

# Run with a specific start and end value
bash fizzbuzz.sh 10 50
```
*Note: Requires Bash 3.0 or higher.*

### `trim_whitespace.sh`
A Bash utility function `remove_whitespace` that removes leading and trailing whitespace from a string using built-in parameter expansion.

**Usage:**
You can source this file in your Bash session or script to use the function:
```bash
source trim_whitespace.sh
result=$(remove_whitespace "  Hello World  ")
echo "$result" # Output: Hello World
```
