# FizzBuzz

FizzBuzz written in Go. Processes numbers 1 to 100:
- Multiple of 3 → "Fizz"
- Multiple of 5 → "Buzz"
- Multiple of both → "FizzBuzz"
- Otherwise → the number itself

## Tested Environments

- Fedora 43 (Bazel 9)
- macOS 26 (Bazel 8)

## Build

Either Make or Bazel can be used.

### Using Make

```bash
make
```

To clean up:

```bash
make clean
make dist-clean
```

### Using Bazel

```bash
. ./setup_bazel_env.sh
bazel build //:fizzbuzz
```

To clean up:

```bash
./clean_bazel.sh
```

## Run

### Make

```bash
./fizzbuzz
```

### Bazel

```bash
bazel run //:fizzbuzz
```

## Sample Output

```text
  1
  2
  fizz
  4
  buzz
  fizz
  7
  8
  fizz
  buzz
  11
  fizz
  13
  14
  fizzbuzz
  ...
  97
  98
  fizz
  buzz
```
