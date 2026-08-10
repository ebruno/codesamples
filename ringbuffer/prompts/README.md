# Ringbuffer Project Prompts

This directory contains the functional and testing requirements for the ringbuffer library, organized by operating system and programming language.

## Structure

`ringbuffer/prompts/{os}/{language}/`

- `functional.md`: Defines the functional requirements for the library in the specific language on the specific OS.
- `testing.md`: Defines the testing requirements and test cases for the library in the specific language on the specific OS.

## Operating Systems

### Implemented
The currently implemented operating systems are defined by the directories present in `ringbuffer/src/`. These are the only platforms that should be processed during creation or update cycles.

### Supported (Prompts Available)
The following platforms have prompt specifications available in this directory:
- `macos`: MacOS X
- `freebsd14`: FreeBSD 14
- `freebsd15`: FreeBSD 15
- `fedora`: Fedora
- `debian`: Debian
- `archlinux`: ArchLinux
- `ubuntu`: Ubuntu

## Supported Languages

- `c`: C
- `cpp`: C++
- `go`: Golang
- `rust`: Rust
- `python`: Python
- `java`: Java
