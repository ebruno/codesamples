#!/usr/bin/env python3
"""
LinkedIn Post Generator — ad-hoc product/project post creation.

Generates personal LinkedIn posts following these guidelines:
  • Hook in the first 140 characters (before "See more")
  • Short sentences, single-sentence paragraphs for white space
  • First-person tone ("I")
  • Optimal length: 1,000–1,500 characters (~150–250 words)
  • Ends with a question (call to action)
  • 3–5 relevant hashtags at the bottom

Usage:
    # Generate a post from a project metadata file (YAML):
    python3 generate_post.py --project my_project.yaml

    # Generate a post inline with CLI arguments:
    python3 generate_post.py \
        --name "Ringbuffer" \
        --description "A high-performance, cross-platform circular buffer library with a three-stage pipelined architecture" \
        --features "Cache-line-aligned counters, lock-free threading, MD5/SHA256/SHA512 checksums" \
        --tech "C++20, Java, Python, GCC, Clang" \
        --link "https://github.com/youruser/ringbuffer"

    # Generate from a project metadata file AND override specific fields:
    python3 generate_post.py --project ringbuffer.yaml --features "New feature A, New feature B"

    # Dry-run: show character count without writing:
    python3 generate_post.py --project ringbuffer.yaml --dry-run

Output:
    Writes the generated post to stdout and optionally to a file.
"""

import argparse
import json
import os
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Project metadata defaults (used when no YAML file is provided)
# ---------------------------------------------------------------------------

DEFAULT_PROJECT = {
    "name": "My Project",
    "description": "",
    "features": [],
    "tech": "",
    "link": "",
    "lesson": "",
    "feedback_area": "",
}

# ---------------------------------------------------------------------------
# Post templates — each follows the user's sample message structure
# ---------------------------------------------------------------------------

HOOK_TEMPLATES = [
    "I just made my latest software project public on GitHub!",
    "Excited to share something I've been building — my newest open-source project is now live!",
    "I'm proud to announce the release of {name} — a project I've been working on.",
    "Just pushed my latest project to GitHub and wanted to share it with the community!",
]

BODY_TEMPLATE = """{hook}

{name_desc}

Building this taught me a lot about {lessons}.
I wanted to share it with the community so others can use, modify, or learn from it.

Check out the {name_lower} directory at: {link}

Key features:
{features_list}

{cta_question}

{hashtags}"""


def load_project_metadata(path: str) -> dict:
    """Load project metadata from a YAML-like JSON file."""
    p = Path(path)
    if not p.exists():
        print(f"Error: project file '{path}' not found.", file=sys.stderr)
        sys.exit(1)

    ext = p.suffix.lower()
    if ext == ".json":
        with open(p, "r") as f:
            return json.load(f)
    elif ext in (".yaml", ".yml"):
        try:
            import yaml

            with open(p, "r") as f:
                return yaml.safe_load(f) or {}
        except ImportError:
            print(
                "PyYAML not installed. Please use .json files or install PyYAML.",
                file=sys.stderr,
            )
            sys.exit(1)
    else:
        print(f"Unsupported file format: {ext}. Use .json or .yaml.", file=sys.stderr)
        sys.exit(1)


def merge_metadata(cli_args: argparse.Namespace, project_file: dict | None) -> dict:
    """Merge CLI arguments over project file defaults. CLI wins."""
    meta = dict(DEFAULT_PROJECT)

    # Layer 1: project file (if provided)
    if project_file:
        meta.update(project_file)

    # Layer 2: CLI overrides (only set values win)
    cli_map = {
        "name": "name",
        "description": "description",
        "features": "features",
        "tech": "tech",
        "link": "link",
        "lesson": "lesson",
        "feedback_area": "feedback_area",
    }
    for cli_key, meta_key in cli_map.items():
        val = getattr(cli_args, cli_key, None)
        if val is not None:
            meta[meta_key] = val

    # Normalize features to a list
    if isinstance(meta["features"], str):
        meta["features"] = [f.strip() for f in meta["features"].split(",") if f.strip()]
    elif not isinstance(meta["features"], list):
        meta["features"] = []

    return meta


def build_hashtags(tech: str, features: list) -> str:
    """Generate 3–5 relevant hashtags from tech stack and features."""
    tags = set()

    # Extract language/tech keywords
    tech_upper = tech.upper()
    for keyword, display in [("C++", "Cpp"), ("CPP", "Cpp"), ("JAVA", "Java"), ("PYTHON", "Python"), ("GO", "Go"), ("RUST", "Rust"), ("OPEN SOURCE", "OpenSource")]:
        if keyword in tech_upper:
            tags.add(f"#{display}")

    # Add generic dev tags if we have fewer than 3
    generic = ["#SoftwareEngineering", "#OpenSource", "#DeveloperCommunity", "#Coding"]
    for g in generic:
        if len(tags) >= 5:
            break
        tags.add(g)

    # Ensure at least 3, at most 5
    result = sorted(tags)[:5]
    while len(result) < 3:
        for g in generic:
            if g not in result:
                result.append(g)
                break
        if len(result) < 3:
            break

    return " ".join(result[:5])


def generate_post(meta: dict) -> str:
    """Generate a LinkedIn post from project metadata."""
    name = meta.get("name", DEFAULT_PROJECT["name"])
    description = meta.get("description", "")
    features = meta.get("features", [])
    tech = meta.get("tech", "")
    link = meta.get("link", "")
    lesson = meta.get("lesson", "")
    feedback_area = meta.get("feedback_area", "")

    # Build description line
    if description:
        name_desc = f"{name} — {description}"
    else:
        name_desc = name

    # Build features list
    if features:
        features_list = "\n".join(f"• {f}" for f in features)
    else:
        features_list = "  (coming soon)"

    # Default lesson from tech if not provided
    if not lesson:
        lesson = f"system design, cross-platform development, and concurrent programming"

    # Default feedback area
    if not feedback_area:
        feedback_area = "the architecture or any areas for improvement"

    # Build the call-to-action question from feedback area
    cta_question = (
        f"If you have a chance to look at the code and documentation, I'd would appreciate your feedback on {feedback_area}?"
    )

    # Pick a hook (rotate based on name hash for variety)
    hook_idx = sum(ord(c) for c in name) % len(HOOK_TEMPLATES)
    hook = HOOK_TEMPLATES[hook_idx].format(name=name)

    # Build hashtags
    hashtags = build_hashtags(tech, features)

    # Assemble post
    post = BODY_TEMPLATE.format(
        hook=hook,
        name=name,
        name_lower=name.lower(),
        name_desc=name_desc,
        lessons=lesson,
        link=link if link else "(link coming soon)",
        features_list=features_list,
        cta_question=cta_question,
        hashtags=hashtags,
    )

    return post


def validate_post(post: str) -> list[str]:
    """Validate a post against LinkedIn guidelines. Returns warnings."""
    warnings = []
    total_chars = len(post)

    # Check total length
    if total_chars > 3000:
        warnings.append(
            f"⚠️  Post is {total_chars} characters (max 3,000). Consider trimming."
        )
    elif total_chars < 500:
        warnings.append(
            f"ℹ️  Post is only {total_chars} characters. Aim for 1,000–1,500 for optimal engagement."
        )

    # Check hook (first 140 chars)
    first_140 = post[:140]
    if "I" not in first_140 and "Excited" not in first_140 and "Just" not in first_140:
        warnings.append(
            "ℹ️  Consider putting a compelling hook in the first 140 characters (before 'See more')."
        )

    # Check for call to action (question in last few content lines before hashtags)
    lines = post.strip().split("\n")
    # Strip trailing hashtag-only lines for the check
    content_lines = [l for l in lines if not l.startswith("#")]
    # Look at the last 3 content lines for a question
    recent = [l.rstrip() for l in content_lines[-3:] if l.strip()]
    has_question = any(l.endswith("?") for l in recent)
    if not has_question:
        warnings.append(
            "ℹ️  Consider ending with a question to invite comments and boost engagement."
        )

    # Check for hashtags
    hashtag_count = post.count("#")
    if hashtag_count < 3:
        warnings.append(
            f"ℹ️  Only {hashtag_count} hashtag(s). Aim for 3–5 relevant hashtags."
        )

    return warnings


def main():
    parser = argparse.ArgumentParser(
        description="Generate a LinkedIn post for an open-source project.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )

    parser.add_argument(
        "--project", "-p", type=str, help="Path to project metadata file (.json or .yaml)"
    )
    parser.add_argument("--name", type=str, help="Project name")
    parser.add_argument(
        "--description", type=str, help="One-sentence description of what the project does"
    )
    parser.add_argument(
        "--features", type=str, help="Comma-separated list of key features"
    )
    parser.add_argument("--tech", type=str, help="Tech stack (e.g., 'C++20, Java, Python')")
    parser.add_argument("--link", type=str, help="Repository URL")
    parser.add_argument(
        "--lesson", type=str, help="What building this taught you (skills)"
    )
    parser.add_argument(
        "--feedback-area", type=str, dest="feedback_area", help="Specific area to ask for feedback on"
    )
    parser.add_argument(
        "--output", "-o", type=str, help="Output file path (default: stdout)"
    )
    parser.add_argument(
        "--dry-run", "-d", action="store_true", help="Show character count and warnings without writing"
    )

    args = parser.parse_args()

    # Load project metadata
    project_file = None
    if args.project:
        project_file = load_project_metadata(args.project)

    # Merge metadata (CLI overrides file, file overrides defaults)
    meta = merge_metadata(args, project_file)

    # Generate post
    post = generate_post(meta)

    # Validate
    warnings = validate_post(post)

    # Output
    if args.dry_run:
        print(f"Character count: {len(post)}")
        for w in warnings:
            print(w, file=sys.stderr)
        return

    # Print post with character count
    print(f"Character count: {len(post)}")
    print()
    print(post)

    # Show validation info
    for w in warnings:
        print(w, file=sys.stderr)

    # Write to file if requested
    if args.output:
        with open(args.output, "w") as f:
            f.write(post)
        print(f"\n✓ Post written to {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
