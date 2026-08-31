#!/usr/bin/env python3
"""Regenerate the pipeline_animation.gif from scratch.

This script recreates the animated GIF that demonstrates the three-stage
ringbuffer pipeline (Read → Transform → Write) with slot state transitions.

Usage:
    python3 generate_pipeline_animation.py [--output PATH]

Output:
    animated_graphics/pipeline_animation.gif  (default)
"""

import argparse
import os
import sys
from PIL import Image, ImageDraw, ImageFont

# ─── Configuration ───────────────────────────────────────────────────────────

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..")
DEFAULT_OUTPUT = os.path.join(OUTPUT_DIR, "pipeline_animation.gif")

WIDTH = 1380
HEIGHT = 703
NUM_FRAMES = 45
FRAME_DURATION_MS = 1000  # ~45.0s total

# ─── Color Palette (extracted from original GIF) ─────────────────────────────

C = {
    "bg":            (250, 251, 252),
    "bg_alt":        (245, 245, 245),
    "purple":        (210, 185, 235),
    "purple_light":  (246, 232, 250),
    "gray_text":     (100, 100, 100),
    "dark_text":     (33,  33,  33),
    "read_bg":       (224, 242, 254),
    "transform_bg":  (255, 243, 224),
    "write_bg":      (232, 245, 233),
    "read_active":   (30,  136, 229),
    "transform_active": (245, 127, 23),
    "write_active":  (46,  125, 50),
    "border":        (158, 158, 158),
    "legend_read":   (30,  136, 229),
    "legend_transform": (245, 127, 23),
    "legend_write":  (46,  125, 50),
    "legend_ready_transform": (129, 199, 240),
    "legend_ready_write":     (255, 235, 160),
    "legend_ready_read":      (178, 235, 196),
}

# ─── Font Helper ─────────────────────────────────────────────────────────────

def _find_font(size: int) -> ImageFont.FreeTypeFont | None:
    """Try common macOS / system fonts, fall back to default."""
    for path in (
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/Arial.ttf",
        "/Library/Fonts/Arial.ttf",
    ):
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    try:
        return ImageFont.load_default()
    except Exception:
        return None


def _font(size: int) -> ImageFont.FreeTypeFont | None:
    return _find_font(size)


def _draw_text(draw, text, x, y, size, fill):
    """Draw centered or left-aligned text."""
    f = _font(size)
    draw.text((x, y), text, font=f, fill=fill)


# ─── Drawing Primitives ──────────────────────────────────────────────────────

def draw_thread_box(draw, x, y, title, bg_color, status_text, active_color):
    """Draw a thread-status pill at the top of the frame."""
    draw.rounded_rectangle(
        [x, y, x + 210, y + 75], radius=10,
        fill=bg_color, outline=C["border"], width=2,
    )
    _draw_text(draw, title, x + 10, y + 10, 24, C["dark_text"])
    status_color = active_color if status_text == "ACTIVE" else C["gray_text"]
    _draw_text(draw, f"Status: {status_text}", x + 10, y + 45, 18, status_color)


def draw_slots_area(draw, active_slot: int):
    """Draw the shared-slots container with 5 slot boxes."""
    # Container aligned with thread boxes (50 to 1140 = Write Thread right edge)
    container_w = 1140 - 50
    draw.rounded_rectangle(
        [50, 200, 1140, 340], radius=10,
        fill=C["bg_alt"], outline=C["border"], width=2,
    )

    slot_w, slot_h = 180, 75
    spacing = 20
    total_slots_w = 5 * slot_w + 4 * spacing  # 980
    start_x = 50 + (container_w - total_slots_w) // 2  # centered ≈ 105

    for i in range(5):
        sx = start_x + i * (slot_w + spacing)
        sy = 225

        if i == active_slot:
            fill = C["purple"]
            state = "being processed"
        else:
            fill = C["purple_light"]
            state = "ready for read"

        draw.rounded_rectangle(
            [sx, sy, sx + slot_w, sy + slot_h], radius=10,
            fill=fill, outline=C["border"], width=2,
        )
        # Vertically centered text: 75px box, 20px+16px=36px text, pad=(75-36)/2=19
        _draw_text(draw, f"Slot {i}", sx + 10, sy + 18, 20, C["dark_text"])
        _draw_text(draw, f"State: {state}", sx + 10, sy + 42, 16, C["gray_text"])


def draw_legend_area(draw):
    """Draw the legend + key-facts panel — compact 3-column layout."""
    draw.rounded_rectangle(
        [50, 390, 1140, 580], radius=10,
        fill=C["bg_alt"], outline=C["border"], width=2,
    )

    _draw_text(draw, "Pipeline Legend", 70, 405, 20, C["dark_text"])

    col_w = (1140 - 50 - 40) // 3  # ~350px per column

    # Threads row
    thread_items = [
        (C["legend_read"],   "Read Thread"),
        (C["legend_transform"], "Transform Thread"),
        (C["legend_write"],  "Write Thread"),
    ]
    for idx, (color, label) in enumerate(thread_items):
        lx = 70 + idx * col_w
        ly = 440
        draw.rectangle([lx, ly, lx + 16, ly + 16], fill=color)
        _draw_text(draw, label, lx + 22, ly, 16, C["dark_text"])

    # State colors row
    state_items = [
        (C["legend_ready_transform"], "ready for transform"),
        (C["legend_ready_write"],     "ready for write"),
        (C["legend_ready_read"],      "ready for read"),
    ]
    for idx, (color, label) in enumerate(state_items):
        lx = 70 + idx * col_w
        ly = 470
        draw.rectangle([lx, ly, lx + 16, ly + 16], fill=color)
        _draw_text(draw, label, lx + 22, ly, 16, C["dark_text"])

    # Key Facts header
    _draw_text(draw, "Key Facts:", 70, 508, 18, C["dark_text"])

    facts = [
        "3 independent threads",
        "Per-slot checksums (MD5/SHA256)",
        "Cache-line aligned slots",
        "Per-stage logging",
        "Atomic index counters",
        "Lock-free ringbuffer",
    ]

    for idx, fact in enumerate(facts):
        col = idx % 3
        row = idx // 3
        fx = 70 + col * col_w
        fy = 535 + row * 22
        _draw_text(draw, f"\u2022 {fact}", fx, fy, 16, C["dark_text"])


def draw_index_counters(draw, read_idx, transform_idx, write_idx):
    """Draw the three index counters at the bottom — aligned with thread boxes."""
    font = _font(26)
    base_y = HEIGHT - 75

    # Read — left-aligned with Read Thread box (x=50)
    draw.text((50, base_y), f"read_index: {read_idx}", font=font, fill=C["read_active"])

    # Transform — centered on Transform Thread box (center x=595)
    xform_text = f"transform_index: {transform_idx}"
    tw = draw.textlength(xform_text, font=font)
    draw.text((595 - tw / 2, base_y), xform_text, font=font, fill=C["transform_active"])

    # Write — right-aligned with Write Thread box right edge (x=1140)
    write_text = f"write_index: {write_idx}"
    tw = draw.textlength(write_text, font=font)
    draw.text((1140 - tw, base_y), write_text, font=font, fill=C["write_active"])


# ─── Frame Builder ───────────────────────────────────────────────────────────

def build_frame(phase: dict) -> Image.Image:
    """Build one frame from a phase description."""
    img = Image.new("RGB", (WIDTH, HEIGHT), C["bg"])
    draw = ImageDraw.Draw(img)

    # Title + subtitle
    _draw_text(draw, "Ringbuffer Pipeline - Data Flow Animation", WIDTH // 2 - 320, 15, 28, C["dark_text"])
    _draw_text(draw, phase["subtitle"], WIDTH // 2 - 180, 52, 20, C["gray_text"])

    # Thread boxes (wider for larger fonts, adjusted x spacing)
    draw_thread_box(draw, 50, 85, "Read Thread", C["read_bg"], phase["read_status"], C["read_active"])
    draw_thread_box(draw, 490, 85, "Transform Thread", C["transform_bg"], phase["transform_status"], C["transform_active"])
    draw_thread_box(draw, 930, 85, "Write Thread", C["write_bg"], phase["write_status"], C["write_active"])

    # Slots
    draw_slots_area(draw, phase["active_slot"])

    # Legend
    draw_legend_area(draw)

    # Index counters
    draw_index_counters(draw, phase["read_idx"], phase["transform_idx"], phase["write_idx"])

    return img


# ─── Phase Definitions (45 frames) ──────────────────────────────────────────

def make_phases():
    """Return a list of 45 phase dicts describing the animation sequence.

    The animation cycles through representative pipeline states:
      - Read thread filling slots
      - Transform thread processing slots
      - Write thread draining slots
    """

    phases = []

    # Helper to create a phase entry
    def P(subtitle, read_st, transform_st, write_st, active_slot, ri, ti, wi):
        return {
            "subtitle": subtitle,
            "read_status": read_st,
            "transform_status": transform_st,
            "write_status": write_st,
            "active_slot": active_slot,
            "read_idx": ri,
            "transform_idx": ti,
            "write_idx": wi,
        }

    # ── Read phase: read_index advances 0→4 ─────────────────────────────
    for i in range(5):
        phases.append(P(
            f"Phase {i+1}: Read fills Slot {i}",
            "ACTIVE", "IDLE", "IDLE", i, i, 3, 2
        ))

    # ── Transform phase: transform_index advances 0→4 ───────────────────
    for i in range(5):
        phases.append(P(
            f"Phase {i+6}: Transform processes Slot {i}",
            "IDLE", "ACTIVE", "IDLE", i, 4, i, 2
        ))

    # ── Write phase: write_index advances 0→4 ───────────────────────────
    for i in range(5):
        phases.append(P(
            f"Phase {i+11}: Write drains Slot {i}",
            "IDLE", "IDLE", "ACTIVE", i, 4, 4, i
        ))

    # ── Repeat cycle for visual continuity (frames 21-45) ───────────────
    # Second pass: read → transform → write
    for i in range(5):
        phases.append(P(
            f"Phase {i+21}: Read fills Slot {i}",
            "ACTIVE", "IDLE", "IDLE", i, i, 3, 2
        ))

    for i in range(5):
        phases.append(P(
            f"Phase {i+26}: Transform processes Slot {i}",
            "IDLE", "ACTIVE", "IDLE", i, 4, i, 2
        ))

    for i in range(5):
        phases.append(P(
            f"Phase {i+31}: Write drains Slot {i}",
            "IDLE", "IDLE", "ACTIVE", i, 4, 4, i
        ))

    # Third pass: read → transform (partial cycle)
    for i in range(5):
        phases.append(P(
            f"Phase {i+36}: Read fills Slot {i}",
            "ACTIVE", "IDLE", "IDLE", i, i, 3, 2
        ))

    for i in range(5):
        phases.append(P(
            f"Phase {i+41}: Transform processes Slot {i}",
            "IDLE", "ACTIVE", "IDLE", i, 4, i, 2
        ))

    # Fourth pass: read (partial cycle to reach 45 frames)
    for i in range(5):
        phases.append(P(
            f"Phase {i+46}: Read fills Slot {i}",
            "ACTIVE", "IDLE", "IDLE", i, i, 3, 2
        ))

    return phases


# ─── Main ────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Regenerate pipeline_animation.gif"
    )
    parser.add_argument(
        "--output", "-o", default=DEFAULT_OUTPUT,
        help=f"Output path (default: {DEFAULT_OUTPUT})",
    )
    args = parser.parse_args()

    output_path = os.path.abspath(args.output)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    phases = make_phases()
    print(f"Generating {len(phases)} frames …")

    frames = [build_frame(p) for p in phases]

    frames[0].save(
        output_path,
        save_all=True,
        append_images=frames[1:],
        duration=FRAME_DURATION_MS,
        loop=0,  # infinite loop
    )

    print(f"Saved → {output_path}")
    print(f"  Size: {os.path.getsize(output_path) / 1024:.1f} KB")
    print(f"  Duration: {len(frames) * FRAME_DURATION_MS / 1000:.1f}s")


if __name__ == "__main__":
    main()
