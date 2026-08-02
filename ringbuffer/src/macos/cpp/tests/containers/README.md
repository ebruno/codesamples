# Build Container Configuration (macOS)

This directory provides the configuration for a standardized build environment.

## Key Configuration Details

- **Base Image**: Fedora 44 (Used as the build toolchain environment).
- **GNU Toolchain**: Includes `gcc`, `gcc-c++`, and `binutils`.
- **LLVM Toolchain**: Includes `clang` and `clang-tools-extra` (providing `clang-tidy` and `clang-format`).
- **Build Utilities**: Includes `make`, `cmake`, and `doxygen`.
- **System Tools**: Includes `procps-ng`, `coreutils`, and `findutils` for binary verification and system monitoring.
- **Default Compiler**: Environment variables `CXX=g++` and `CC=gcc` are set.

## Running the Container

To use this container for building the Ringbuffer library, follow these steps from the `ringbuffer/src/macos/cpp` directory:

### Option 1: Apple Container Utility (Recommended)
Ensure the container system is running first:
```bash
container system start
```
Build the image using the Apple container utility:
```bash
container build -t ringbuffer-macos-build ./tests/containers/macos
```
Run the container interactively:
```bash
container run -it --rm     -v $(pwd):/workspace     --user $(id -u):$(id -g)     ringbuffer-macos-build
```

### Option 2: Docker
Build the image using Docker:
```bash
docker build -t ringbuffer-macos-build ./tests/containers/macos
```
Run the container interactively:
```bash
docker run -it --rm     -v $(pwd):/workspace     --user $(id -u):$(id -g)     ringbuffer-macos-build
```

### Option 3: Podman
Build the image using Podman:
```bash
podman build -t ringbuffer-macos-build ./tests/containers/macos
```
Run the container interactively:
```bash
podman run -it --rm     -v $(pwd):/workspace     --user $(id -u):$(id -g)     ringbuffer-macos-build
```

### Explanation of Flags:
- `-it`: Runs the container in interactive mode with a TTY.
- `--rm`: Automatically removes the container when you exit.
- `-v $(pwd):/workspace`: Maps the current working directory (`ringbuffer/src/macos/cpp`) to `/workspace` inside the container.
- `--user $(id -u):$(id -g)`: Runs the container as the current host user, ensuring read/write permissions to the mapped volume without creating root-owned files.

## Cleanup and Image Management

Since the run commands above include the `--rm` flag, containers are automatically deleted upon exit. If you need to manually remove containers or delete the image, use the following commands:

### Apple Container Utility
- **Remove Image**: `container rmi ringbuffer-macos-build`
- **Remove Container**: `container rm <container_id>`

### Docker
- **Remove Image**: `docker rmi ringbuffer-macos-build`
- **Remove Container**: `docker rm <container_id>`

### Podman
- **Remove Image**: `podman rmi ringbuffer-macos-build`
- **Remove Container**: `podman rm <container_id>`
