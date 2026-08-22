### Container Naming Convention
- **Build containers**: `ringbuffer_<os>_build` — used only by `verify_build`. Contains full toolset for all languages (C/C++, Java, Python).
- **Test containers**: `ringbuffer_<os>_test` — used only by `run_regression`. Identical content to build container.
- **OS names**: `debian`, `fedora`, `ubuntu`, `raspios` (macOS is native-only, no containers).
- **Example**: `ringbuffer_fedora_build`, `ringbuffer_debian_test`, `ringbuffer_ubuntu_build`.
