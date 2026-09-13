#!/usr/bin/env bash
#
# Check that every relative Markdown link resolves: the file exists, and where the link
# carries a #fragment, some heading in that file generates the matching anchor.
#
# The course is a web of cross-references between lecture READMEs, appendices and exercise
# directories, so renaming one file silently breaks links in three others.
#
# External http(s) links are not fetched: this runs offline and should not go stale because
# somebody else's site is down.
#
# Usage:
#   links.sh
set -euo pipefail
shopt -s nullglob globstar

# Navigate to the root directory.
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# GitHub's anchor rules: lowercase, strip anything that is not a word character, a space or a
# hyphen, then turn spaces into hyphens.
#
# "Word character" has to mean more than [a-z0-9] here, because the headings are Swedish. GitHub
# keeps å, ä and ö in an anchor; an ASCII-only class silently deletes them, so `#förkunskaper`
# would be compared against "frkunskaper" and every heading carrying one of those letters would
# be unlinkable. Hence bash's ${x,,} rather than tr, which lowercases outside ASCII, and
# [:alnum:] under a UTF-8 locale rather than a literal a-z range.
anchor_of() {
    local lowered="${1,,}"
    printf '%s' "$lowered" \
        | LC_ALL=C.UTF-8 sed -e 's/[^[:alnum:] _-]//g' -e 's/ /-/g'
}

checked=0
broken=0

for file in **/*.md; do
    # Skip libs/: those are submodules, somebody else's repo to keep linkable. They are also
    # absent in CI, which does not check out submodules, so scanning them here would let a
    # local "make lint" go red over a file CI never sees.
    case "$file" in libs/*) continue ;; esac

    # Links are relative to the file that contains them, not to the repo root.
    dir="$(dirname "$file")"

    # Pull the target out of every inline [text](target) link.
    while IFS= read -r target; do
        # Skip external links and mailto:; those are somebody else's to keep working.
        case "$target" in
            http://*|https://*|mailto:*|'') continue ;;
        esac

        if [[ "$target" == \#* ]]; then
            # A bare "#fragment" names a heading in this same file. These used to be skipped
            # outright, so renaming a heading broke every same-page link to it silently - the
            # one case where the link and the thing it points at are in the file being edited.
            fragment="${target#\#}"
            resolved="$file"
        else
            # Split "path#fragment". With no "#", the second expansion returns the whole string,
            # which is how a fragment-less link is told apart from one with an empty fragment.
            path="${target%%\#*}"
            fragment="${target#*\#}"
            [ "$fragment" = "$target" ] && fragment=""
            resolved="$dir/$path"
        fi

        checked=$((checked + 1))
        if [ ! -e "$resolved" ]; then
            echo "BROKEN $file -> $target (no such file: $resolved)" >&2
            broken=$((broken + 1))
            continue
        fi

        # Where the link names a heading, check that some heading generates that anchor.
        if [ -n "$fragment" ] && [ -f "$resolved" ]; then
            found=0
            while IFS= read -r heading; do
                if [ "$(anchor_of "$heading")" = "$fragment" ]; then
                    found=1
                    break
                fi
            # Every ATX heading in the target file, with its leading #s stripped. Lines inside a
            # fenced code block are skipped: a shell or YAML comment there starts with a # too,
            # and counting it as a heading would let a broken anchor resolve against a listing.
            done < <(awk '/^[[:space:]]*```/ { fence = !fence; next }
                          !fence && /^#{1,6} / { sub(/^#{1,6} +/, ""); print }' "$resolved")
            if [ "$found" -eq 0 ]; then
                echo "BROKEN $file -> $target (no heading matching #$fragment)" >&2
                broken=$((broken + 1))
            fi
        fi
    # Every inline link target in the file: match "](...)", then strip the delimiters. Reference
    # -style links are not used in this course, so the inline form is the whole of it.
    #
    # Fenced code blocks are stripped first, for the same reason the heading scan below skips
    # them: a link inside a listing is illustrative text, not a link. Checking them anyway
    # reported a BROKEN for every deliberately-nonexistent example path, which is why
    # diagrams/README.md spells a Markdown image out in prose instead of showing it.
    done < <(awk '/^[[:space:]]*```/ { fence = !fence; next } !fence' "$file" \
             | grep -oE '\]\([^)]+\)' | sed -e 's/^](//' -e 's/)$//')
done

if [ "$broken" -gt 0 ]; then
    echo >&2
    echo "error: $broken broken link(s) out of $checked checked." >&2
    exit 1
fi

echo "Link check: $checked relative link(s) resolve."
