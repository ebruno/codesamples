### Container Commands (macOS)
- **NEVER use `podman` on macOS.** Use only the `container` CLI (Apple Container service).
- **Always omit `localhost/` prefix** from image names. The `container` CLI resolves images locally — prepending `localhost/` forces a network lookup that times out. Use `container run ringbuffer_fedora_build:latest ...`, NOT `container run localhost/ringbuffer_fedora_build:latest ...`.
- **Debian Makefile LTO_FLAG:** The Debian container's g++ does not support `-flto=thin`. Use `-flto` instead. The Makefile's LTO_FLAG logic must reflect this.
