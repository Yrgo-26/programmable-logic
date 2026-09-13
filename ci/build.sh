#!/usr/bin/env bash
#
# Build every lecture VHDL example in the repo with GHDL.
#
# This is the L01-L08 half: the worked examples and exercise directories under lectures/. The
# group project, which lives in controller/ and bridge/ and is laid out completely differently,
# is built by ci/build_project.sh instead.
#
# A complete example is analyzed, elaborated, and its testbench is run. An exercise directory
# ships only a testbench, because the module is the reader's to write, so it gets the strongest
# check its contents allow: run against a published body if there is one, otherwise analyzed
# against a generated stub entity, otherwise parse-checked.
#
# Convention: each example lives in its own directory, and its top-level entity is in a file
# named <directory-name>.vhd. Any other *.vhd there, or the design file of an immediate
# subdirectory (<sub>/<sub>.vhd), is a subcomponent. A subcomponent's own testbench is not
# pulled into the parent. Analysis order is worked out by GHDL, not by this script.
#
# Every line printed says which check ran. A design that stopped being simulated must never
# read like one that passed.
#
# Usage:
#   build.sh              Build everything.
#   build.sh fsm_led      Build only directories whose path contains "fsm_led".
set -euo pipefail
shopt -s nullglob

# VHDL standard and simulation stop time, overridable from the environment.
STD="${GHDL_STD:-93}"
STOP_TIME="${GHDL_STOP_TIME:-10ms}"

# Optional substring filter on the directory path.
FILTER="${1:-}"

# Absolute path to the repo root, resolved before the cd below. The helper scripts are invoked
# through it rather than through $BASH_SOURCE, which survives the cd only when this script was
# itself called by an absolute path; when it is not, every exercise quietly drops to a weaker
# check and the build still exits 0.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Navigate to the root directory.
cd "$ROOT"

# Without this, the first example prints its header and the run dies on "ghdl: command not
# found" with exit 127, which reads like that example failed rather than like a missing tool.
if ! command -v ghdl > /dev/null 2>&1; then
    echo "error: ghdl not found. Install it with:" >&2
    echo "           sudo apt -y update && sudo apt -y install ghdl" >&2
    echo "       See info/simulation_workflow.md, section 2." >&2
    exit 1
fi

built=0            # Examples elaborated and simulated.
parsed=0           # Exercise directories checked without a body to run.
parsed_examples=0  # Complete designs that could only be parsed, counted apart from the above.
no_testbench=0     # Examples elaborated but never simulated, because they ship no testbench.

# python3 is optional (see the root README), but without it every exercise directory drops from
# "testbench checked against its declared entity" to a bare syntax check. That is most of this
# script's value, so its absence is decided once, here, and reported in the summary rather than
# being inferred per directory from a failed command that could equally mean something else.
have_python=0
if command -v python3 > /dev/null 2>&1; then
    have_python=1
fi

# Collect an example's design files into the global array SOURCES: every .vhd in the directory,
# plus <sub>/<sub>.vhd for each immediate subdirectory.
#
# Empty files are skipped: a zero-byte .vhd is a placeholder somebody is about to write into, it
# declares nothing, and failing on it would turn a workspace into a build error. The entity it
# will eventually declare is then simply missing, which the check below reports by name.
collect_sources() {
    local dir="$1" sub subname file
    SOURCES=()

    # The directory's own files.
    for file in "$dir"/*.vhd; do
        if [ -s "$file" ]; then
            SOURCES+=("$file")
        fi
    done

    # Then one design file per subdirectory, by the <sub>/<sub>.vhd convention. A subcomponent's
    # own testbench is deliberately not picked up. `work` is GHDL's library, not a subcomponent.
    for sub in "$dir"/*/; do
        subname="$(basename "$sub")"
        if [ "$subname" != "work" ] && [ -s "$sub$subname.vhd" ]; then
            SOURCES+=("$sub$subname.vhd")
        fi
    done
}

# Modules a design instantiates that nothing here can supply: not in the directory and not a
# subcomponent of it. These are the modules the reader writes as exercises, which no lecture
# directory ships a second time. Echoes a space-separated list, empty when everything binds.
unresolved_subcomponents() {
    local dir="$1" name missing=""

    # Every `entity work.<name>` the sources mention, lowercased and deduplicated, since VHDL
    # identifiers are case-insensitive and the same module may be instantiated many times.
    # Comments are stripped first: a commented-out instantiation is not a dependency, and
    # counting one would demote a worked example to "parse-checked only" for good.
    for name in $(sed 's/--.*//' "${SOURCES[@]}" |
                  grep -hoiE "entity[[:space:]]+work\.[a-z0-9_]+" |
                  sed 's|.*\.||' | tr 'A-Z' 'a-z' | sort -u); do
        # Bound if it is this design itself, a sibling file, or a subcomponent directory.
        if [ "$name" = "$(basename "$dir")" ] ||
           [ -s "$dir/$name.vhd" ] ||
           [ -s "$dir/$name/$name.vhd" ]; then
            continue
        fi
        missing="$missing $name"
    done
    echo "$missing"
}

# Try to supply bodies for the named modules from published Markdown, via ci/extract_vhdl.py.
# Written into the work library, never into a lecture directory. Fills the global array SUPPLIED.
#
# Returns 0 only when every name, and everything those bodies in turn instantiate, could be
# supplied: a half-supplied design still cannot be elaborated, so a partial result is thrown
# away rather than built on.
supply_bodies() {
    local pending="$1" round name out sup="$work_dir/supplied"
    SUPPLIED=()
    command -v python3 > /dev/null 2>&1 || return 1

    # Start from an empty directory, so a previous attempt cannot contribute a stale body.
    rm -rf "$sup"
    mkdir -p "$sup"

    # Three rounds is depth, not breadth: it resolves a module whose body needs a module whose
    # body needs a third. Nothing in this course nests deeper, and a bound means a cycle in the
    # published sources cannot spin here forever.
    for round in 1 2 3; do
        [ -n "$pending" ] || break

        # Extract this round's names. One failure means the design cannot be completed, so give
        # up at once rather than accumulating a partial set.
        for name in $pending; do
            out="$sup/$name.vhd"
            if [ -f "$out" ]; then
                continue
            fi
            if ! "$ROOT/ci/extract_vhdl.py" "$name" > "$out" 2>> "$work_dir/extract.log"; then
                rm -rf "$sup"
                return 1
            fi
        done

        # Then look at what those bodies themselves instantiate, and queue whatever is still
        # unbound for the next round.
        pending=""
        for name in $(cat "$sup"/*.vhd | grep -hoiE "entity[[:space:]]+work\.[a-z0-9_]+" |
                      sed 's|.*\.||' | tr 'A-Z' 'a-z' | sort -u); do
            if [ -s "$dir/$name.vhd" ] || [ -s "$dir/$name/$name.vhd" ] ||
               [ -f "$sup/$name.vhd" ]; then
                continue
            fi
            pending="$pending $name"
        done
    done

    # Anything still pending means the nesting ran deeper than the bound above.
    if [ -n "$pending" ]; then
        rm -rf "$sup"
        return 1
    fi

    # Succeed only if something was actually extracted, so the caller never elaborates an
    # unchanged design believing it was completed.
    SUPPLIED=("$sup"/*.vhd)
    [ "${#SUPPLIED[@]}" -gt 0 ]
}

# Elaborate and run an example's self-checking testbench, if it has one. --stop-time bounds a
# design that never reaches the condition the testbench waits on, so a wrong implementation
# fails with output instead of hanging.
run_testbench() {
    local dir="$1" tb="$2" run_log

    # Not every example ships a testbench; that is not a failure, but it is not a simulation
    # either, so say so and let the caller count it apart. Silently returning success here is
    # how a design whose testbench was renamed or deleted keeps reading as one that passed.
    if [ ! -f "$dir/$tb.vhd" ]; then
        echo "    (no $tb.vhd: elaborated only, nothing simulated)"
        no_testbench=$((no_testbench + 1))
        return 0
    fi

    ghdl -m --std="$STD" --workdir="$work_dir" "$tb"
    run_log="$work_dir/run.log"
    ghdl -r --std="$STD" --workdir="$work_dir" "$tb" \
         --assert-level=error --stop-time="$STOP_TIME" | tee "$run_log"

    # The run must reach its own pass line. GHDL exits 0 when --stop-time cuts a simulation
    # short, so exit status alone cannot tell a finished run from a stalled one, and without
    # this a testbench that hangs forever would report a clean build.
    if ! grep -q 'all checks passed' "$run_log"; then
        echo "error: $tb never reached its pass line: it either failed, or ran to" >&2
        echo "       --stop-time=$STOP_TIME without finishing." >&2
        exit 1
    fi
}

# Every directory holding at least one .vhd file, deepest path component first.
while IFS= read -r -d '' dir; do
    dir="${dir#./}"
    if [ -n "$FILTER" ] && [[ "$dir" != *"$FILTER"* ]]; then
        continue
    fi

    top="$(basename "$dir")"
    tb="${top}_tb"

    # A lecture's solutions/ is a body library, not an example: a pile of modules with no top
    # level to elaborate and no testbench of its own. It is consumed through supply_bodies,
    # which binds each module to the testbench that lecture already ships, so building it here
    # would prove nothing that is not proved better one directory later.
    if [ "$top" = "solutions" ]; then
        continue
    fi

    # A fresh work library per example. Removing it first keeps the build hermetic: a design
    # unit whose source file was deleted must not survive into the next run.
    work_dir="$dir/work"
    rm -rf "$work_dir"
    mkdir -p "$work_dir"

    collect_sources "$dir"

    # An example directory owns a module named after it, and that module declares its entity.
    has_entity=0
    if [ -s "$dir/$top.vhd" ] &&
       grep -qiE "^[[:space:]]*entity[[:space:]]+${top}[[:space:]]+is" "$dir/$top.vhd"; then
        has_entity=1
    fi

    # Is this module specified as an exercise? ci/entity_stub.py answers by looking it up in
    # diagrams/exercises.py, and emits its entity if so. An empty architecture, not a solution.
    #
    # Exit 3 means "not an exercise", which is a normal answer for a worked example. Any other
    # non-zero status means the manifest itself is unreadable, and that must stop the build:
    # this is the only check standing behind 29 handed-out testbenches, and when it silently
    # degraded to a parse check the summary line did not change by a single byte.
    stub="$work_dir/${top}_stub.vhd"
    specified=0
    if [ "$have_python" -eq 1 ]; then
        if "$ROOT/ci/entity_stub.py" "$top" > "$stub" 2> "$work_dir/entity_stub.log"; then
            specified=1
        else
            stub_status=$?
            rm -f "$stub"
            if [ "$stub_status" -ne 3 ]; then
                echo "error: ci/entity_stub.py failed for '$top' (exit $stub_status):" >&2
                sed 's/^/       /' "$work_dir/entity_stub.log" >&2
                echo "       diagrams/exercises.py is the single source of truth for every" >&2
                echo "       exercise entity. While it is broken, nothing checks the handed-out" >&2
                echo "       testbenches against their ports." >&2
                exit 1
            fi
        fi
    else
        rm -f "$stub"
    fi

    # A module file declaring no entity of its own name is normal in an exercise directory: a
    # reader part-way through writing it. Anywhere else it is a mistake, and falling through to
    # the parse-check branch would exit 0 for an example that silently stopped being simulated.
    if [ -s "$dir/$top.vhd" ] && [ "$has_entity" -eq 0 ] && [ "$specified" -eq 0 ]; then
        echo "error: $dir/$top.vhd exists but declares no entity named '$top'." >&2
        echo "       Parse-checking it here would report a green build for an example that" >&2
        echo "       was never simulated." >&2
        exit 1
    fi

    # Modules this design instantiates that nothing here can supply, which only a design with
    # an entity of its own can have.
    missing=""
    if [ "$has_entity" -eq 1 ]; then
        missing="$(unresolved_subcomponents "$dir")"
    fi

    # Four cases follow, strongest check first.

    # Complete: everything binds, so elaborate and simulate it.
    if [ "$has_entity" -eq 1 ] && [ -z "$missing" ]; then
        echo "==> $dir"
        ghdl -i --std="$STD" --workdir="$work_dir" "${SOURCES[@]}"
        ghdl -m --std="$STD" --workdir="$work_dir" "$top"
        run_testbench "$dir" "$tb"
        built=$((built + 1))
    elif [ -n "$missing" ] && supply_bodies "$missing"; then
        # Composes modules the reader writes, but their bodies have been published, so the
        # design becomes elaborable and is simulated like any other example.
        rm -f "$stub"
        echo "==> $dir (composed with published bodies for$missing)"
        ghdl -i --std="$STD" --workdir="$work_dir" "${SOURCES[@]}" "${SUPPLIED[@]}"
        ghdl -m --std="$STD" --workdir="$work_dir" "$top"
        run_testbench "$dir" "$tb"
        built=$((built + 1))
    elif [ -n "$missing" ]; then
        # Same, but nothing is published yet, so nothing binds and nothing can be elaborated.
        # Naming the missing modules is the whole point: "parse-checked only" with no reason
        # given is exactly how a design that stopped being simulated reads like one that passed.
        rm -f "$stub"
        echo "==> $dir (parse-checked only: needs your own$missing)"
        ghdl -i --std="$STD" --workdir="$work_dir" "${SOURCES[@]}"
        parsed_examples=$((parsed_examples + 1))
    else
        # An exercise directory: the module is the reader's to write, so there is nothing of
        # ours to elaborate. What can still be checked is the testbench we hand out, and the
        # three branches below are that check in descending order of strength.
        #
        # All three name only our own files. Anything else in an exercise directory is the
        # reader's work, half-written or empty as often as not, and dragging it in would turn
        # their workspace into our build failure.

        # Strongest: the body has been published, so the testbench runs for real. This is what
        # catches a wrong expected value or an off-by-one, which no amount of analysis can see.
        if [ -f "$dir/$tb.vhd" ] && supply_bodies "$top"; then
            rm -f "$stub"
            echo "==> $dir (module not yet written, testbench run against the published body)"
            ghdl -i --std="$STD" --workdir="$work_dir" "${SUPPLIED[@]}" "$dir/$tb.vhd"
            run_testbench "$dir" "$tb"
            built=$((built + 1))
            continue
        fi

        # Otherwise analyze the testbench against the stub entity, which verifies port names,
        # order, widths, types and generics: does the file we ship bind to the entity we specify.
        if [ -f "$dir/$tb.vhd" ] && [ "$specified" -eq 1 ]; then
            echo "==> $dir (module not yet written, testbench checked against its entity)"
            ghdl -a --std="$STD" --workdir="$work_dir" "$stub" "$dir/$tb.vhd"
        else
            # No python3, or not specified as an exercise: fall back to a syntax check.
            rm -f "$stub"
            echo "==> $dir (module not yet written, parse-checked only)"
            ghdl -i --std="$STD" --workdir="$work_dir" "${SOURCES[@]}"
        fi
        parsed=$((parsed + 1))
    fi
    # -printf '%h' gives each match's directory, so `sort -zu` reduces the file list to one
    # entry per example. NUL separators keep paths containing spaces in one piece.
    #
    # controller/ and bridge/ are excluded: they are the group project, not lecture examples.
    # They are flat directories of modules and testbenches with no <dir>/<dir>.vhd top level, so
    # this script's conventions do not describe them at all. ci/build_project.sh builds those.
done < <(find . -mindepth 2 -name '*.vhd' -not -path '*/work/*' \
              -not -path './controller/*' -not -path './bridge/*' \
              -printf '%h\0' | sort -zu)

# A discovery loop that silently matches nothing looks exactly like a clean build. It is not.
if [ "$((built + parsed + parsed_examples))" -eq 0 ]; then
    if [ -n "$FILTER" ]; then
        echo "error: no example directory matches '$FILTER'" >&2
    else
        echo "error: no VHDL examples discovered" >&2
    fi
    exit 1
fi

echo
echo "Built and simulated $((built - no_testbench)) example(s); checked $parsed exercise directory(ies)."
if [ "$no_testbench" -gt 0 ]; then
    # Same reasoning as below: an example that is elaborated but never simulated has had no
    # expected value checked, and must not be counted alongside the ones that were.
    echo "$no_testbench example(s) were elaborated but not simulated: they ship no testbench."
fi
if [ "$parsed_examples" -gt 0 ]; then
    # Reported on their own line: folding these in with the exercise directories is how a worked
    # example that stopped being simulated hides in the one line a reader scans.
    echo "$parsed_examples worked example(s) were parse-checked only: nothing binds their"
    echo "subcomponents yet, so no testbench was elaborated or run for them."
fi
if [ "$have_python" -eq 0 ]; then
    # The one downgrade that is allowed to pass, because the README calls python3 optional. It
    # still has to be said out loud: without it the exercise count above means "analyzes", not
    # "analyzes against the ports the exercise promises".
    echo
    echo "warning: python3 not found, so no exercise testbench was checked against its entity."
    echo "         The $parsed exercise directory(ies) above were syntax-checked only."
fi
