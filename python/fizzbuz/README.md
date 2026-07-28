# FizzBuzz

A simple Python implementation of the classic FizzBuzz problem.

## Application Summary

The `fizzbuzz.py` script prints numbers from 1 to 100 with the following rules:
- For multiples of 3, it prints **"Fizz"** instead of the number.
- For multiples of 5, it prints **"Buzz"** instead of the number.
- For numbers that are multiples of both 3 and 5, it prints **"FizzBuzz"**.

## How to Run

You can run the application using Python 3:

```bash
python3 fizzbuzz.py
```

## Implementation Details

The script uses a `fizzbuzz` function that allows for customizable:
- `start`: Starting number (default 1)
- `end`: Ending number (default 100)
- `increment`: Step size (default 1)
- `modulo_fizz`: The divisor for "Fizz" (default 3)
- `modulo_buzz`: The divisor for "Buzz" (default 5)
