# Ringbuffer Test Suite

This directory contains the test suite for the Ringbuffer library.

## Directory Structure
- `src/`: Test source code.
- `data/inputs/`: Input files for the Reader.
- `data/expected/`: Golden files for verification.
- `bin/`: Compiled test binaries.
- `utils/bin/`: Test utility scripts.
- `containers/`: Standardized container build environments (see [containers/README.md](containers/README.md)).

## Build Process
The test binaries are built by linking against the static library:
```bash
g++ -std=c++20 -I../ -o bin/test001_staticlib src/test001_staticlib.cpp ../lib/libswtr_ringbuffer.a
```

## Running Test Scenarios

### T001: Exact Match
Verify that input is passed through without changes.
```bash
./bin/test001_staticlib -o data/expected/t001.out data/inputs/test001.txt 2> t001.log
diff data/inputs/test001.txt data/expected/t001.out
```

### T002: Stress Test (Smallest Config)
Verify stability with 1 slot and 1 byte buffer size.
```bash
./bin/test001_staticlib -o data/expected/t002.out -s 1 -b 1 data/inputs/test001.txt 2> t002.log
diff data/inputs/test001.txt data/expected/t002.out
```

### T003: Uppercase Transform
Verify that the uppercase transformation is applied.
```bash
./bin/test001_staticlib -o data/expected/t003.out -b 10 -t 1 data/inputs/test001.txt 2> t003.log
# Verification: check if all alphabetic chars in output are uppercase.
```

## Containerized Build Environment
To ensure build reproducibility, this project provides container configurations in the `containers/` directory. These allow you to build the library in a controlled Fedora 44 environment using Apple Container Utility, Docker, or Podman. 
For detailed setup and usage instructions, please refer to the [containers/README.md](containers/README.md) file.

## Verification of Artifacts
To verify the binary properties:
- `file lib/libswtr_ringbuffer.so`
- `readelf -d lib/libswtr_ringbuffer.so | grep SONAME`
- `size -m lib/libswtr_ringbuffer.so`
- `nm -gjU lib/libswtr_ringbuffer.so`

## License
This project is licensed under the BSD 3-Clause License.
