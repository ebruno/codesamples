# PowerShell Samples

This directory contains PowerShell coding samples.

## Files

### `fizzbuzz.ps1`
A PowerShell implementation of the classic FizzBuzz problem. It prints numbers from a start value to an end value, replacing multiples of 3 with "Fizz", multiples of 5 with "Buzz", and multiples of both with "FizzBuzz".

**Usage:**
```powershell
# Run with default values (1 to 100)
pwsh -File fizzbuzz.ps1

# Run with a specific start value
pwsh -File fizzbuzz.ps1 -Start 10

# Run with a specific start and end value
pwsh -File fizzbuzz.ps1 -Start 10 -End 50
```
