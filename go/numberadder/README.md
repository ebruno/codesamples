# Number Adder

Adds two arbitrarily large numbers stored one digit at a time in a slice.
The second number is reversed before addition.

- Input numbers can be any length (20+ digits)
- `num1` and `num2` can be different lengths

**Sample:**
```
num1 = 123456
num2 = 123456
Result: 777777
```

The application generates a random set of test values. Unit tests are provided.

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

> **Note:** `GOPATH` should not be set.

### Using Bazel

```bash
. ./setup_bazel_env.sh
bazel build //:numberadder
```

To run tests:

```bash
bazel test //:numberadder_test
```

To clean up:

```bash
./clean_bazel.sh
```

## Run

```bash
./numberadder
```

To run tests (Make build):

```bash
go test
```

## Sample Output

```text
 Number 1        | Number 2              | Reversed Number 2     | Result
 ----------------|-----------------------|-----------------------|--------------------
 06027027006     | 537445562340147383    | 383741043265544735    | 383741049292571741
 404361066208    | 177471                | 174771                | 404361240979
 ...
 24832627        | 3112575843883253804872| 2784083523883485752113| 2784083523883510584740
```

## Test Output

```text
=== RUN   TestBasic
--- PASS: TestBasic (0.00s)
=== RUN   TestVariablelength
--- PASS: TestVariablelength (0.00s)
PASS
ok      github.com/ebruno/codesamples/go/numberadder    0.025s
```
