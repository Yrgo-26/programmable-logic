#!/usr/bin/env bash
#
# Check that every group of files listed in ci/duplicates.txt is byte-identical.
#
# Two halves. First, each declared group is compared and must match. Second, any .vhd basename
# occurring twice in the tree must be declared here, so a new copy cannot drift unwatched.
#
# Nothing is vendored twice today, so the manifest is empty and only the second half has work
# to do.
#
# Usage:
#   duplicates.sh
set -euo pipefail

# Navigate to the root directory.
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Manifest file, one group of identical files per line.
MANIFEST="ci/duplicates.txt"

if [ ! -f "$MANIFEST" ]; then
    echo "error: $MANIFEST not found" >&2
    exit 1
fi

groups=0  # Declared groups compared.
files=0   # Files across those groups.
drift=0   # Copies that are missing or differ.

# Half one: every declared group, first path is the reference the rest are compared against.
while read -r -a paths; do
    # Skip blank lines and comments.
    [ "${#paths[@]}" -eq 0 ] && continue
    case "${paths[0]}" in \#*) continue ;; esac

    reference="${paths[0]}"
    if [ ! -f "$reference" ]; then
        echo "error: $MANIFEST references a missing file: $reference" >&2
        drift=$((drift + 1))
        continue
    fi

    groups=$((groups + 1))
    files=$((files + 1))

    # Every remaining path in the line is a copy that must match the reference exactly.
    for copy in "${paths[@]:1}"; do
        files=$((files + 1))
        if [ ! -f "$copy" ]; then
            echo "MISSING: $copy (listed as a copy of $reference)" >&2
            drift=$((drift + 1))
        elif ! cmp -s "$reference" "$copy"; then
            echo "DRIFT: $copy differs from $reference" >&2
            # diff exits 1 for "the files differ", and head can SIGPIPE it on a long diff.
            # Under `set -o pipefail` either would abort the script right here, so only the
            # first drifted copy would ever be reported and the summary below would never run.
            diff -u "$reference" "$copy" | head -20 >&2 || true
            drift=$((drift + 1))
        fi
    done
done < "$MANIFEST"

# Half two. A manifest is only a guard if it is complete: a duplicate nobody declared is one
# that drifts silently forever, which is the incident the comment in $MANIFEST describes.
#
# The `|| true` matters. An empty manifest is the normal state while nothing is vendored, and
# grep exits 1 when it matches nothing; under `set -euo pipefail` that would end the run here,
# looking successful, skipping the completeness check entirely.
listed="$(grep -vE '^[[:space:]]*(#|$)' "$MANIFEST" |
          tr -s '[:space:]' '\n' | grep -v '^$' | sort -u || true)"
# Scratch file for the tracked-file list, removed however the script exits.
tracked="$(mktemp)"
trap 'rm -f "$tracked"' EXIT
unlisted=0

# Half two needs git, because "tracked" is what separates a vendored copy from somebody's
# workspace. Outside a git checkout - a downloaded zip, an exported tree - `git ls-files` fails
# and the old `2>/dev/null ... || true` swallowed it whole: the check reported success having
# examined nothing. Since the manifest is empty by design, half two is where all of this
# script's value is, so a skip has to be visible rather than inferred from a silent success.
have_git=0
if command -v git > /dev/null 2>&1 && git rev-parse --git-dir > /dev/null 2>&1; then
    have_git=1
fi

# Report any duplicated basename the manifest does not already cover.
while IFS= read -r path; do
    [ -z "$path" ] && continue
    if ! grep -qxF "$path" <<< "$listed"; then
        echo "UNLISTED: $path shares its filename with another file but is not in $MANIFEST" >&2
        unlisted=$((unlisted + 1))
    fi
done < <(
    # Tracked files only. An exercise directory is also somebody's workspace: a half-written
    # solution or a subcomponent copied in to try something is not a vendored copy, and flagging
    # it would turn their own work into our build failure.
    if [ "$have_git" -eq 1 ]; then
        git ls-files -- 'lectures/**/*.vhd' 'controller/*.vhd' 'bridge/*.vhd' |
            grep -v '/work/' > "$tracked" || true
    fi
    # Reduce to basenames, keep only those occurring more than once (`uniq -d`), then map each
    # back to every path that carries it.
    if [ -s "$tracked" ]; then
        sed 's|.*/||' "$tracked" | sort | uniq -d | while IFS= read -r name; do
            grep -E "(^|/)${name}\$" "$tracked"
        done | sort
    fi
)

if [ "$((drift + unlisted))" -gt 0 ]; then
    echo >&2
    # The two failures are independent, so both are reported when both occurred.
    if [ "$drift" -gt 0 ]; then
        echo "error: $drift copy(ies) out of sync. Reconcile them," \
             "or give the odd one out its" >&2
        echo "       own entity name and drop it from $MANIFEST." >&2
    fi
    if [ "$unlisted" -gt 0 ]; then
        echo "error: $unlisted duplicated file(s) not covered by $MANIFEST." \
             "Add the group, or" >&2
        echo "       rename the odd one out so it is not a copy at all." >&2
    fi
    exit 1
fi

if [ "$have_git" -eq 0 ]; then
    # Not a failure - a downloaded zip is a legitimate way to read this repository - but the
    # summary must not claim a check that did not happen. CI always runs in a git checkout, so
    # the completeness half is always exercised there.
    echo "Duplicate check: manifest groups verified; the unlisted-duplicate half was SKIPPED"
    echo "                 (not a git checkout, so tracked files cannot be enumerated)."
elif [ "$groups" -eq 0 ]; then
    echo "Duplicate check: nothing is vendored twice; no unlisted duplicates."
else
    echo "Duplicate check: $files file(s) in $groups group(s) are identical;" \
         "no unlisted duplicates."
fi
