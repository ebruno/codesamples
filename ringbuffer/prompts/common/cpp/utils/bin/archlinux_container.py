#!/usr/bin/env python3
"""archlinux_container.py — Helper for managing Arch Linux container images.

Finds and optionally pulls a pinned Arch Linux container image from Docker Hub
using datestamp-based tags. Designed for use in verify_build and run_regression
workflows where reproducible Arch Linux builds are needed.

Only the base-devel variant is supported — it includes compilers and build tools
needed for the ringbuffer C++ project. The base variant is too minimal; devel
lacks some required dependencies.

Usage as a module:
    from archlinux_container import find_tag, pull_image, resolve_container

Usage as a script:
    python3 archlinux_container.py [--months N] [--pull] [--quiet]

Examples:
    python3 archlinux_container.py                          # Find base-devel from 3 months ago
    python3 archlinux_container.py -m 6                     # Find base-devel from 6 months ago
    python3 archlinux_container.py --pull                   # Find and pull base-devel
    python3 archlinux_container.py --quiet                  # Suppress output, return tag only

Returns:
    On success: prints the full image name (e.g., "archlinux:base-devel-20260514.0.538921")
    On failure: exits with code 1 and prints error to stderr
"""

import argparse
import json
import subprocess
import sys
from datetime import datetime, timedelta

# ── Platform detection ─────────────────────────────────────────────────────
IS_MACOS = sys.platform == "darwin"


# ── Constants ───────────────────────────────────────────────────────────────
DOCKERHUB_API = "https://hub.docker.com/v2/repositories/library/archlinux/tags"
DEFAULT_VARIANT = "base-devel"
DEFAULT_MONTHS_BACK = 3


# ── Date calculation ───────────────────────────────────────────────────────
def calculate_target_month(months_back: int) -> str:
    """Calculate the target month (YYYYMM) from N months ago.

    Uses pure Python datetime for cross-platform compatibility
    (works identically on macOS, Linux, Windows).

    Args:
        months_back: Number of months to go back from today.

    Returns:
        Month string in YYYYMM format (e.g., "202605").
    """
    now = datetime.now()
    # Go back N months, clamping day to avoid overflow (e.g., Jan 31 - 1 month = Dec 31)
    month = now.month - months_back
    year = now.year
    while month <= 0:
        month += 12
        year -= 1
    return f"{year:04d}{month:02d}"


# ── Docker Hub API ─────────────────────────────────────────────────────────
def fetch_tags(variant: str, page_size: int = 100) -> list[str]:
    """Fetch all tags for a given variant from Docker Hub.

    Handles pagination automatically (Docker Hub returns max 100 results per page).

    Args:
        variant: Image variant to search for (e.g., "base-devel", "base", "devel").
        page_size: Number of results per page (max 100).

    Returns:
        List of tag name strings.

    Raises:
        RuntimeError: If the API request fails or returns invalid JSON.
    """
    import urllib.request

    all_tags: list[str] = []
    page = 1
    max_pages = 50

    while True:
        url = f"{DOCKERHUB_API}?page_size={page_size}&name={variant}&page={page}"
        try:
            req = urllib.request.Request(url)
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except Exception as e:
            raise RuntimeError(f"Failed to fetch tags from Docker Hub (page {page}): {e}")

        for tag in data.get("results", []):
            all_tags.append(tag["name"])

        if data.get("next") is None:
            break

        page += 1
        if page > max_pages:
            raise RuntimeError("Too many pages fetching tags — API may be rate-limited")

    return all_tags


def find_tag(months_back: int = DEFAULT_MONTHS_BACK) -> tuple[str, str]:
    """Find the closest matching Arch Linux container tag for the target date.

    Searches Docker Hub for base-devel tags from N months ago and returns the
    tag with the latest date that is not in the future relative to the target month.

    Only base-devel tags are supported — they include compilers and build tools
    needed for the ringbuffer C++ project.

    Args:
        months_back: Number of months back from today to target.

    Returns:
        Tuple of (full_image_name, date_string).
        Example: ("archlinux:base-devel-20260514.0.538921", "20260514")

    Raises:
        RuntimeError: If no matching tag is found.
    """
    target_month = calculate_target_month(months_back)
    all_tags = fetch_tags(DEFAULT_VARIANT)

    matching_tag: str | None = None
    best_date = "0"

    for tag in all_tags:
        # Skip the plain variant tag (e.g., "base-devel" without date)
        if tag == DEFAULT_VARIANT:
            continue

        # Only consider tags that start with exactly base-devel-
        if not tag.startswith(f"{DEFAULT_VARIANT}-"):
            continue

        # Extract YYYYMMDD from tag name (e.g., "base-devel-20260809.0.570793")
        parts = tag.split("-")
        if len(parts) < 2:
            continue

        date_str = parts[-1].split(".")[0] if "." in parts[-1] else parts[-1]
        if len(date_str) != 8 or not date_str.isdigit():
            continue

        # Only consider tags from the target month or earlier (never future)
        if date_str > f"{target_month}31":
            continue

        # Keep the latest (closest to target month) matching tag
        if date_str > best_date:
            best_date = date_str
            matching_tag = tag

    if matching_tag is None:
        available_dates = sorted(set(
            "-".join(t.split("-")[-1].split(".")[0] for t in all_tags
                     if len(t.split("-")) >= 2 and t.split("-")[-1].split(".")[0].isdigit()
                     and len(t.split("-")[-1].split(".")[0]) == 8)
        ))
        raise RuntimeError(
            f"No matching base-devel tag found for time window {target_month}. "
            f"Available dates: {available_dates[:5]}..." if available_dates else "No tags found."
        )

    full_image = f"archlinux:{matching_tag}"
    return full_image, best_date


# ── Container pull ─────────────────────────────────────────────────────────
def _detect_runtime() -> str:
    """Detect the available container runtime.

    Returns:
        One of 'container' (macOS Apple Container), 'podman', or 'docker'.

    Raises:
        RuntimeError: If no container runtime is found.
    """
    import shutil

    if shutil.which("container"):
        return "container"
    elif shutil.which("podman"):
        return "podman"
    elif shutil.which("docker"):
        return "docker"
    else:
        raise RuntimeError(
            "No container runtime found. Install 'container' (macOS), "
            "'podman' (Linux), or 'docker'."
        )


def pull_image(image_name: str, runtime: str | None = None) -> None:
    """Pull a container image using the detected or specified runtime.

    Args:
        image_name: Full image name (e.g., "archlinux:base-devel-20260514.0.538921").
        runtime: Container runtime to use ('container', 'podman', or 'docker').
                 If None, auto-detect based on host OS.

    Raises:
        RuntimeError: If the pull fails or no runtime is available.
    """
    if runtime is None:
        runtime = _detect_runtime()

    cmd = [runtime, "pull", image_name]
    try:
        subprocess.run(cmd, check=True, capture_output=False)
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"Failed to pull image '{image_name}' via '{runtime}': {e}")


def resolve_container(months_back: int = DEFAULT_MONTHS_BACK) -> tuple[str, str]:
    """Find and pull an Arch Linux container image in one call.

    Convenience function that combines find_tag() and pull_image().
    Only base-devel variant is supported.

    On macOS (Apple Silicon), this function skips the pull step and returns
    only the identified tag, since Arch Linux containers are amd64-only.

    Args:
        months_back: Number of months back from today to target.

    Returns:
        Tuple of (full_image_name, date_string).

    Raises:
        RuntimeError: If no matching tag is found.
    """
    image_name, date_str = find_tag(months_back)
    if not IS_MACOS:
        pull_image(image_name)
    return image_name, date_str


# ── CLI entry point ────────────────────────────────────────────────────────
def main() -> None:
    parser = argparse.ArgumentParser(
        description="Find and optionally pull a pinned Arch Linux container image from Docker Hub.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Examples:
  %(prog)s                          # Find base-devel from 3 months ago
  %(prog)s -m 6                     # Find base-devel from 6 months ago
  %(prog)s --pull                   # Find and pull base-devel
  %(prog)s --quiet                  # Suppress output, return tag only""",
    )
    parser.add_argument(
        "-m", "--months", type=int, default=DEFAULT_MONTHS_BACK,
        help=f"Months back to target (default: {DEFAULT_MONTHS_BACK})",
    )
    parser.add_argument(
        "-p", "--pull", action="store_true",
        help="Actually pull the image after finding it",
    )
    parser.add_argument(
        "-q", "--quiet", action="store_true",
        help="Suppress informational output",
    )

    args = parser.parse_args()

    try:
        image_name, date_str = find_tag(args.months)

        if not args.quiet:
            print(f"[archlinux_container] Found target container: {image_name} (date: {date_str})")

        if args.pull:
            if IS_MACOS:
                print(
                    "[archlinux_container] Arch Linux container images are amd64-only.",
                    file=sys.stderr,
                )
                print(
                    "[archlinux_container] No ARM64 Arch Linux container is available on Docker Hub.",
                    file=sys.stderr,
                )
                print(
                    "[archlinux_container] Source code identification works; build/test requires a Linux host with podman/docker.",
                    file=sys.stderr,
                )
                # Exit successfully — this is expected behavior, not an error
                sys.exit(0)
            pull_image(image_name)
            if not args.quiet:
                print(f"[archlinux_container] Successfully pulled {image_name}")

        # Always output the image name (for use by calling scripts)
        print(image_name)

    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
