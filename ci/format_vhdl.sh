#!/usr/bin/env bash
#
# Check (or fix) trailing whitespace in this repository's VHDL sources.
#
# VHDL has no clang-format equivalent here, so this enforces the one rule worth enforcing
# mechanically. Trailing spaces produce diff noise that hides real changes, and in a course where
# participants diff their work against a reference, noise is expensive.
#
# Sources are discovered rather than configured, because the VHDL lives somewhere different in
# each course repository. Skipped: .git/, libs/ (submodules, not ours to reformat), temp/
# (scratch), and work/ (GHDL's generated artifacts).
#
# Usage:
#   ci/format_vhdl.sh          Strip trailing whitespace in place.
#   ci/format_vhdl.sh --fix    Same, stated explicitly.
#   ci/format_vhdl.sh --check  Fail if any VHDL file has trailing whitespace.
set -euo pipefail

# Explicit dispatch. Anything unrecognized is an error rather than a fall-through to the
# rewriter: a typo in a Makefile target or a CI step would otherwise silently turn the gate
# into a fixer that edits the working tree and always exits 0.
case "${1:-}" in
    "" | --fix ) MODE="fix"   ;;
    --check    ) MODE="check" ;;
    *          ) echo "usage: ci/format_vhdl.sh [--check|--fix]" >&2; exit 2 ;;
esac

# Root directory.
ROOT_DIR="$(dirname "${BASH_SOURCE[0]}")/.."

# Find this repository's VHDL files, sorted, into the array named by $1.
select_vhdl_files() {
    local -n out=$1
    out=()

    # -prune before -name "*.vhd" so the skipped trees are never descended into at all. The sed
    # drops find's leading "./" so the paths print the way a reader would type them.
    mapfile -t out < <(find . \
        -name .git -prune -o \
        -name libs -prune -o \
        -name temp -prune -o \
        -name work -prune -o \
        -name "*.vhd" -print | sed 's|^\./||' | sort)
}

# Strip trailing whitespace from the files in the array named by $2, or report it.
# $1 is the mode: "check" to report and fail, anything else to strip in place.
strip_vhdl_whitespace() {
    local arg="$1"
    local -n files=$2

    if [[ "$arg" == "check" ]]
    then
        # Report every offending line and fail, so CI says exactly what to fix.
        local offenders=0
        for file in "${files[@]}"
        do
            # grep decides, a second pass reports. Testing the pipeline directly would leave
            # correctness resting on pipefail, since the trailing sed always succeeds.
            # The same pattern the fix branch below strips, so the gate and the fixer can never
            # disagree, and POSIX rather than grep -P, so a grep without PCRE support reports
            # trailing whitespace instead of silently returning 2 and passing the file.
            if grep -qE '[[:space:]]+$' "$file"
            then
                # grep -n gives the line number, and the prefix makes it file:line, which is
                # what turns a failure into something the reader can jump straight to.
                grep -nE '[[:space:]]+$' "$file" | sed "s|^|$file:|" >&2
                offenders=$((offenders + 1))
            fi
        done
        if [ "$offenders" -gt 0 ]
        then
            echo "error: trailing whitespace in $offenders VHDL file(s);" \
                 "run ci/format_vhdl.sh." >&2
            return 1
        fi
        echo "Checked ${#files[@]} VHDL file(s); no trailing whitespace."
    else
        # Fix mode. Rewrite only the files that need it, so mtimes stay put everywhere else.
        local count=0
        for file in "${files[@]}"
        do
            if grep -qE '[[:space:]]+$' "$file"
            then
                sed -i 's/[[:space:]]*$//' "$file"
                echo "Stripped trailing whitespace: $file"
                count=$((count + 1))
            fi
        done
        echo "Stripped $count VHDL file(s)."
    fi
}

# Navigate to the root directory.
cd "$ROOT_DIR"

# Select VHDL files.
select_vhdl_files VHDL_FILES

# Nothing to do in a repository that has no VHDL yet, or none written so far.
if [ "${#VHDL_FILES[@]}" -eq 0 ]; then
    echo "No VHDL files to check yet."
    exit 0
fi

# Strip trailing whitespace, or check for it.
strip_vhdl_whitespace "$MODE" VHDL_FILES
