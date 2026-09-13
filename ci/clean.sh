#!/usr/bin/env bash
#
# Remove every generated file the build and the by-hand GHDL workflow leave behind.
#
# That is more than build.sh's own work libraries: Appendix C has you run GHDL directly in an
# example directory, and its --wave option writes a waveform next to the source.
#
# Usage:
#   clean.sh
set -euo pipefail

# Navigate to the root directory.
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Collect first, delete afterwards: removing a work directory while find is still walking it
# makes find complain about the path it was about to descend into. -print0 and the -d '' read
# keep paths containing spaces in one piece.
targets=()
while IFS= read -r -d '' path; do
    targets+=("$path")

# Version-control and third-party trees are pruned before anything is matched. .venv in
# particular is full of files these patterns would otherwise claim, and libs/ holds submodules
# whose build artifacts are theirs to clean, not ours.
#
# Then: GHDL work libraries, stray libraries from running GHDL by hand, waveforms, and the
# object files and elaborated binaries the llvm/gcc backends leave behind.
done < <(find . \
        -name .git   -prune -o \
        -name .venv  -prune -o \
        -name libs   -prune -o \
        -name temp   -prune -o \
        \( \
        \( -type d -name work \) -o \
        \( -type d -name __pycache__ \) -o \
        \( -type f \( -name 'work-obj*.cf' \
                      -o -name '*.vcd' \
                      -o -name '*.fst' \
                      -o -name '*.ghw' \
                      -o -name '*.o' \
                      -o -name 'e~*' \
                      -o \( -name '*_tb' -type f -executable \) \) \) \
    \) -prune -print0 | sort -z)

# A clean tree is a success, not a failure.
if [ "${#targets[@]}" -eq 0 ]; then
    echo "Nothing to clean."
    exit 0
fi

# Name each one as it goes, so `make clean` can be read afterwards to see what it took.
for path in "${targets[@]}"; do
    echo "==> $path"
    rm -rf "$path"
done

echo
echo "Removed ${#targets[@]} generated file(s) and director(ies)."
