### Arch Linux Container Image Pinning
- **Arch Linux is a rolling release** — it has no `VERSION_ID` in `/etc/os-release`. Always identify by `ID=arch` alone.
- **Container tag strategy: datestamp-based.** Pin to a specific date 3 months in the past for reproducible builds. Never use `latest` or unversioned tags like `base`.
- **Example:** If today is 2026-08-21, use `FROM archlinux:2026.05.01`.
- **How to determine the date:** Calculate 3 months back from today, format as `YYYY.MM.DD`. Check Docker Hub for the exact datestamp tag that exists (Arch publishes daily snapshots).
- **macOS hosts:** `archlinux:base` and datestamp tags are amd64-only. macOS scripts must skip Arch Linux containers with a logged message (already handled by the "Linux-hosts-only" rule).
- **Linux hosts:** Use `podman` with the pinned datestamp tag.
