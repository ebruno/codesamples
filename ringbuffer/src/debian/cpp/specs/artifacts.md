# Ringbuffer Debian - Artifacts Documentation

**Platform:** Debian 13 (Linux kernel 6.12 LTS)  
**Language:** C++20  
**Build System:** GNU Make  

## Library Artifacts

### Static Library
- **Path:** `lib/libswtr_ringbuffer-1.0.0-1.a`
- **Alias:** `lib/libswtr_ringbuffer.a` → `libswtr_ringbuffer-1.0.0-1.a`
- **Format:** ELF 64-bit ar archive (Linux)
- **Toolchain:** g++ or clang++ with `-fPIC -flto`

### Shared Library
- **Path:** `lib/libswtr_ringbuffer-1.0.0-1.so`
- **Alias:** `lib/libswtr_ringbuffer.so` → `libswtr_ringbuffer-1.0.0-1.so`
- **SONAME:** `libswtr_ringbuffer.so`
- **Format:** ELF 64-bit shared object (Linux)

## Source Files

### Core Lifecycle
| File | Purpose |
|------|---------|
| `Lifecycle.cpp` | Constructor, destructor, initialization |
| `Threading.cpp` | Thread management (start/stop/wait) |

### Read Operations
| File | Purpose |
|------|---------|
| `ReadOps.cpp` | Data reading from ring buffer slots |

### Write Operations  
| File | Purpose |
|------|---------|
| `WriteOps.cpp` | Data writing to ring buffer slots |

### Transform Operations
| File | Purpose |
|------|---------|
| `TransformOps.cpp` | Data transformation pipeline |

### Error Operations
| File | Purpose |
|------|---------|
| `ErrorOps.cpp` | Error handling and reporting |

### Logging Operations (6 files)
| File | Purpose |
|------|---------|
| `LoggingOps_1.cpp` | Log initialization and configuration |
| `LoggingOps_2.cpp` | Log message formatting |
| `LoggingOps_3.cpp` | Log output routing |
| `LoggingOps_4.cpp` | Log level management |
| `LoggingOps_5.cpp` | Log file operations |
| `LoggingOps_6.cpp` | Log cleanup and shutdown |

### Accessor Operations (6 files)
| File | Purpose |
|------|---------|
| `Accessors_Status.cpp` | Buffer status getters/setters |
| `Accessors_ChecksumAlg.cpp` | Checksum algorithm configuration |
| `Accessors_ChecksumVal.cpp` | Checksum value access |
| `Accessors_Size_Max.cpp` | Maximum size configuration |
| `Accessors_Size_Data.cpp` | Current data size access |
| `Accessors_Size_Transformed.cpp` | Transformed data size access |

## Header Files
| File | Purpose |
|------|---------|
| `ringbuffer.hpp` | Public API header (RingBuffer abstract class) |
| `status.hpp` | BufferStatus enum, ChecksumAlgorithm enum, LogLevel enum |
| `swtr_ringbuffer_impl.hpp` | SwtrRingBuffer implementation class |

## Build Configuration
| File | Purpose |
|------|---------|
| `version.mk` | Version variables (MAJOR, MINOR, SUBVERSION, BUILD_ID) |
| `Makefile` | Build orchestration (static, shared, clean, dist-clean) |
| `containers/Dockerfile` | Debian 13 container image definition |

## Test Infrastructure
| Path | Purpose |
|------|---------|
| `tests/src/test001.cpp` | Test program with full CLI interface |
| `tests/Makefile` | Test build and verification orchestration |
| `tests/data/inputs/test001.txt` - `test007.txt` | Zig-zag pattern test data (25-250 lines) |
| `tests/utils/bin/generate_test_data.sh` | Bash test data generator |
| `tests/utils/bin/generate_test_data.zsh` | Zsh test data generator |
| `tests/utils/bin/generate_test_data.tcsh` | Tcsh test data generator |
| `tests/utils/bin/generate_test_data_bin_sh.sh` | Bourne shell test data generator |
| `tests/containers/debian/Dockerfile` | Debian 13 test container image |

## Documentation
| Path | Purpose |
|------|---------|
| `README.md` | Project overview and usage instructions |
| `LICENSE` | BSD 3-Clause License |
| `specs/build.md` | Build requirements specification |
| `specs/testing.md` | Testing requirements specification |
| `specs/artifacts.md` | This file - artifact documentation |

## Version History
- **Current:** 1.0.0-1 (MAJOR=1, MINOR=0, SUBVERSION=0, BUILD_ID=1)
