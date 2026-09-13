#!/usr/bin/env python3
"""Print the VHDL body of one module, extracted from published course Markdown.

An exercise ships a testbench but not the module, so `ci/build.sh` can only analyze it
against a generated stub (`ci/entity_stub.py`). Once the body is published the testbench
can be elaborated and run against it for real. Sources, in order:

  1. `lectures/L0N/solutions/<module>.vhd`, the published solution modules, one file per
     module, sitting beside that lecture's `appendix/` and `exercises/`. This is the normal
     source, and it needs no configuration: a module is picked up the moment its file lands.
  2. The listings named in `ci/listings.txt`, for the few modules an appendix prints in
     full ahead of the solutions.

(2) is a manifest and not a search because some appendices print a module twice, once
broken and once fixed; see `ci/listings.txt`. A file offering two architectures for one
module is refused rather than guessed at. Nothing is written into a lecture directory.

A module reaching (1) makes any (2) entry for it dead weight: drop the manifest line when
its solution lands, so there is one source of truth rather than two that can drift.

    ci/extract_vhdl.py timer > timer.vhd
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# Root directory.
ROOT = Path(__file__).resolve().parent.parent

# Manifest file.
MANIFEST = ROOT / "ci" / "listings.txt"

# A ```vhdl fenced block, capturing its body.
FENCE = re.compile(r"^```vhdl\n(.*?)^```$", re.S | re.M)

# A `library ieee;` clause, so one is not prepended to a listing that already has it.
LIBRARY = re.compile(r"^\s*library\s+ieee\s*;", re.M | re.I)


def _entity_re(module: str) -> re.Pattern[str]:
    """Matches the `entity` declaration of `module`."""
    return re.compile(rf"^\s*entity\s+{re.escape(module)}\s+is\b", re.M | re.I)


def _architecture_re(module: str) -> re.Pattern[str]:
    """Matches any `architecture ... of <module>` declaration, whatever the architecture name."""
    return re.compile(rf"^\s*architecture\s+\w+\s+of\s+{re.escape(module)}\s+is\b", re.M | re.I)


class Ambiguous(Exception):
    """The file offers more than one architecture for the module, so none can be chosen."""


def extract(text: str, module: str) -> str | None:
    """Return complete VHDL for `module` from one Markdown document, or None.

    The entity and its architecture may share a fenced block or sit in separate ones; both
    shapes occur in the appendices. A `library` clause is prepended when the listing omits
    it, which most do. Raises `Ambiguous` if the document declares two architectures.
    """
    wants_entity, wants_architecture = _entity_re(module), _architecture_re(module)
    entity_block = None
    architecture_blocks = []

    # Sort every VHDL block into the one holding the architecture and the one holding the
    # entity. Only the first entity is kept; the architectures are all collected, so that
    # a document offering two of them can be spotted below rather than silently resolved.
    architecture_count = 0
    for match in FENCE.finditer(text):
        block = match.group(1)
        found = wants_architecture.findall(block)
        if found:
            architecture_blocks.append(block)
            architecture_count += len(found)
        elif wants_entity.search(block) and entity_block is None:
            entity_block = block
    # No architecture means this document does not publish the module at all.
    if not architecture_blocks:
        return None

    # Two means it publishes the module twice, and choosing between them is not ours to do.
    # Counted over architectures rather than over blocks: a document that prints the broken
    # and the fixed version inside one fence is the same hazard, and counting blocks would
    # wave it through and then let GHDL bind whichever was analyzed last.
    if architecture_count > 1:
        raise Ambiguous(module)

    # Take the entity from the architecture's own block if it is there, otherwise from the
    # separate block found above. Neither means the architecture is published without its
    # entity, which is not something that can be compiled.
    architecture = architecture_blocks[0]
    if wants_entity.search(architecture):
        source = architecture
    elif entity_block is not None:
        source = entity_block.rstrip() + "\n\n" + architecture
    else:
        return None

    # Supply the library clause the prose established but the listing left out.
    if not LIBRARY.search(source):
        source = "library ieee;\nuse ieee.std_logic_1164.all;\n\n" + source
    return source


def sources() -> list[Path]:
    """Every Markdown document the manifest authorizes as a source of bodies.

    Published solutions are .vhd files rather than prose, so they never reach here; `main`
    checks for those first. A malformed or dangling manifest line warns and is skipped.
    """
    found: list[Path] = []
    if MANIFEST.exists():
        for line in MANIFEST.read_text().splitlines():
            # Drop the comment and skip the blank lines separating the entries.
            line = line.split("#", 1)[0].strip()
            if not line:
                continue

            # Every remaining line is "<module> <path>". Warn on anything else and carry on.
            fields = line.split()
            if len(fields) != 2:
                print(f"{MANIFEST}: expected '<module> <path>', got: {line}", file=sys.stderr)
                continue

            # The path is relative to the repo root. A dangling one warns rather than fails,
            # so a listing that outlived its file cannot break the whole build.
            path = ROOT / fields[1]
            if path.exists():
                found.append(path)
            else:
                print(f"{MANIFEST}: no such file: {fields[1]}", file=sys.stderr)
    return found


def listed(module: str) -> set[Path]:
    """Paths the manifest explicitly authorizes for this module."""
    allowed: set[Path] = set()
    if not MANIFEST.exists():
        return allowed

    # Same "<module> <path>" lines as in `sources`, but keeping only this module's paths.
    # Malformed lines are simply not matched here; `sources` is where they are reported.
    for line in MANIFEST.read_text().splitlines():
        line = line.split("#", 1)[0].strip()
        fields = line.split()
        if len(fields) == 2 and fields[0] == module:
            allowed.add(ROOT / fields[1])
    return allowed


def main() -> int:
    """Print the first published body found for the module named in argv.

    Exit code 0 on success, 1 if no body exists or a document is ambiguous, 2 on bad usage.
    """
    # Exactly one argument, the module name. The summary line of this file is the usage text.
    if len(sys.argv) != 2:
        print(__doc__.strip().splitlines()[0], file=sys.stderr)
        return 2
    module = sys.argv[1]

    # A published solution module is the authoritative body, so it is checked before any prose
    # listing and copied through verbatim: it is already VHDL, with nothing to extract. Sorted so
    # the choice is deterministic if the same module is ever published by two lectures, which
    # would be a mistake worth reporting rather than silently resolving.
    published = sorted(ROOT.glob(f"lectures/*/solutions/{module}.vhd"))
    if len(published) > 1:
        names = ", ".join(str(q.relative_to(ROOT)) for q in published)
        print(f"'{module}' is published by more than one lecture: {names}", file=sys.stderr)
        return 1
    if published:
        sys.stdout.write(published[0].read_text())
        return 0

    allowed = listed(module)

    # Search in the order `sources` returns, and stop at the first document with a body.
    for path in sources():
        # An appendix is searched only for what it was listed for, so a listing of the same name
        # elsewhere in the course cannot be picked up.
        if path not in allowed:
            continue

        # An ambiguous document is an error, not a miss: it does hold the module, and going
        # on to the next source would quietly build against a version nobody chose.
        try:
            source = extract(path.read_text(), module)
        except Ambiguous:
            print(
                f"{path}: declares more than one architecture of '{module}'; "
                "refusing to guess which is the one to build against",
                file=sys.stderr)
            return 1

        # Name the source in the output, so the build log says where the body came from.
        if source is not None:
            sys.stdout.write(
                f"-- Extracted by ci/extract_vhdl.py from {path.relative_to(ROOT)}.\n")
            sys.stdout.write(source if source.endswith("\n") else source + "\n")
            return 0

    # Not an error in itself: `ci/build.sh` falls back to the generated stub entity.
    print(f"no published body for '{module}'", file=sys.stderr)
    return 1


# Run only when executed as a script, never on import, and hand the return value to the
# shell as the exit status: `ci/build.sh` tests it.
if __name__ == "__main__":
    raise SystemExit(main())
