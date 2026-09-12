#!/usr/bin/env python3
"""Regenerate the lecture diagrams.

    python3 diagrams/build.py                     # every figure, into the lecture trees
    python3 diagrams/build.py or_gate_entity      # one figure
    python3 diagrams/build.py --outdir /tmp/x     # preview, without touching the repo

Adding a figure: write a builder in a module next to this one, then add an entry to
FIGURES below naming every path that should receive it.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import counter  # noqa: E402
import kmap  # noqa: E402
import exercises  # noqa: E402
import module_box  # noqa: E402
import or_gate  # noqa: E402
import style  # noqa: E402
import waveform  # noqa: E402

# Root directory.
ROOT = Path(__file__).resolve().parent.parent


def images(lecture: str) -> Path:
    """The image directory of one lecture's appendix, e.g. `images("L01")`."""
    return ROOT / "lectures" / lecture / "appendix/images"


# figure name -> (figure, output paths). A figure with several paths is one that several
# lectures embed; listing them here is what keeps those copies identical.
FIGURES: dict[str, tuple[style.Figure, list[Path]]] = {
    "or_gate_entity": (
        or_gate.ENTITY,
        [images("L01") / "or_gate_entity.png"]),
    "or_gate_arch": (
        or_gate.ARCHITECTURE,
        [images("L01") / "or_gate_arch.png"]),
    "or_gate_module": (
        or_gate.MODULE,
        [images("L01") / "or_gate_module.png"]),
    "setup_hold": (
        waveform.SETUP_HOLD,
        [images("L04") / "setup_hold.png"]),
    "synchronizer_waveform": (
        waveform.SYNCHRONIZER,
        [images("L04") / "synchronizer_waveform.png"]),
    "dff_timing": (
        waveform.DFF_TIMING,
        [images("L03") / "dff_timing.png"]),
    "latch_vs_flipflop": (
        waveform.LATCH_VS_FLIPFLOP,
        [images("L03") / "latch_vs_flipflop.png"]),
    "uart_frame": (
        waveform.UART_FRAME,
        [images("L08") / "uart_frame.png"]),
    "counter_circuit": (
        counter.COUNTER,
        [images("L06") / "counter_circuit.png"]),
    # Three frames of one map, in the order A.1 reads them. Same canvas, so the grid does not
    # move between frames and the reader compares the marking rather than the drawing.
    "karnaugh_filled": (
        kmap.FILLED,
        [images("L02") / "karnaugh_filled.png"]),
    "karnaugh_group_c": (
        kmap.GROUP_C_ONLY,
        [images("L02") / "karnaugh_group_c.png"]),
    "karnaugh_groups": (
        kmap.BOTH_GROUPS,
        [images("L02") / "karnaugh_groups.png"]),
}

# One module figure per exercise module, in the appendix that sets the exercise. Generated
# rather than listed above, so adding an exercise entity is enough to get its figure.
for _lecture, _entities in exercises.BY_LECTURE.items():
    for _entity in _entities:
        FIGURES[_entity.name] = (
            module_box.figure(_entity),
            [images(_lecture) / f"{_entity.name}.png"])


def main() -> int:
    """Build the figures named on the command line, or all of them.

    Exit code 0 on success; argparse exits 2 on an unknown figure or a bad option.
    """
    # The summary line of this file is the usage description.
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "figures",
        nargs="*",
        metavar="FIGURE",
        help="Figures to build. Default: all of them.")
    parser.add_argument(
        "--outdir",
        type=Path,
        help="Write <FIGURE>.png here instead of into the lecture trees.")
    parser.add_argument(
        "--list", action="store_true", help="List the known figures and exit.")
    args = parser.parse_args()

    if args.list:
        for name in FIGURES:
            print(name)
        return 0

    # Check every name before drawing anything, so a typo fails at once instead of halfway
    # through a rebuild with some figures already written.
    names = args.figures or list(FIGURES)
    unknown = [name for name in names if name not in FIGURES]
    if unknown:
        parser.error(
            f"unknown figure(s): {', '.join(unknown)}\nknown: {', '.join(FIGURES)}")

    for name in names:
        # --outdir replaces the lecture paths with one preview file, which is what makes it
        # safe to look at a change before it lands in the lecture trees.
        figure, paths = FIGURES[name]
        if args.outdir:
            paths = [args.outdir / f"{name}.png"]

        # Report paths relative to the repo where they are inside it, absolute otherwise.
        style.render(figure, paths)
        for path in paths:
            print(f"wrote {path.relative_to(ROOT) if ROOT in path.parents else path}")

    return 0


# Run only when executed as a script, never on import, and hand the return value to the
# shell as the exit status.
if __name__ == "__main__":
    raise SystemExit(main())
