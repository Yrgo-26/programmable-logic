#!/usr/bin/env bash
#
# Analyze, elaborate, and simulate the group project with GHDL: the CAN controller and the SPI
# register bridge in front of it.
#
# The project's VHDL lives in two flat directories. controller/ holds the CAN controller itself -
# the modules the group writes, alongside the provided testbenches that check them and the
# provided can_def.vhd package they all read - and bridge/ holds the SPI-facing half, plus the two
# files that are handed out rather than written (spi_slave.vhd and spi_def.vhd). Nothing is copied
# between lecture directories.
#
# In this repository controller/ and bridge/ ship only the provided files, so a fresh clone
# reports every testbench as skipped. That is the expected state: the modules are the group's
# to write, in their own repository. Copy this script's two directories into that repository, or
# drop the modules in beside the testbenches here, and each testbench starts running as soon as
# every source it names exists.
#
# Skipped is not failed, deliberately. The project is built over ten lectures and most of the
# tree is missing for most of them; a build that went red until the last module landed would say
# nothing useful on any of the nine before it.
#
# can_controller_tb is the exception and is gated differently: can_controller.vhd is written
# early as an entity with an empty architecture, so its presence says nothing about whether it
# works yet. See the comment on RX_PATH below for what is checked instead, and how that
# heuristic fails.
#
# Set CI_BUILD_ALL=1 to attempt every testbench regardless, e.g. to validate a complete
# reference set and catch a file that is present but does not analyze.
#
# Usage:
#   build_project.sh
set -euo pipefail

# Navigate to the root directory.
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Fail on the missing tool rather than partway through the first testbench that needs it.
if ! command -v ghdl > /dev/null 2>&1; then
    echo "error: ghdl not found. Install it with:" >&2
    echo "           sudo apt -y update && sudo apt -y install ghdl" >&2
    echo "       See info/simulation_workflow.md, section 2." >&2
    exit 1
fi

# The two source directories, searched in this order for any module named below.
SRC_DIRS=(controller bridge)

# Work library directory, kept out of the source tree so GHDL's artifacts don't clutter it.
WORK_DIR="controller/work"

# Simulation stop time, overridable from the environment, as in ci/build.sh. A testbench waiting
# on an event a wrong module never produces does not fail; it hangs until CI's job timeout kills
# it with no diagnostic.
STOP_TIME="${GHDL_STOP_TIME:-10ms}"

# Every module, in dependency order. Each is analyzed on its own before any testbench runs, so a
# module written early is syntax- and type-checked immediately rather than staying unproven until
# the testbench that finally exercises it can run.
MODULES="can_def meta_prev bit_timer crc15 tx_shift_reg rx_shift_reg can_controller \
         spi_def spi_slave register_bank spi_reg_bridge can_spi_node"

# Each testbench and the sources it needs, in analysis order (dependencies before dependents).
# can_def is the shared package every controller module reads from, so it always comes first.
TESTBENCHES=(
    "meta_prev_tb:meta_prev"
    "bit_timer_tb:can_def bit_timer"
    "crc15_tb:can_def crc15"
    "tx_shift_reg_tb:can_def tx_shift_reg"
    "rx_shift_reg_tb:can_def rx_shift_reg"
    "can_controller_tb:can_def meta_prev bit_timer crc15 tx_shift_reg rx_shift_reg can_controller"
    "register_bank_tb:can_def register_bank"
    "spi_reg_bridge_tb:spi_def spi_reg_bridge"
    "can_spi_node_tb:can_def meta_prev bit_timer crc15 tx_shift_reg rx_shift_reg can_controller \
                     spi_def spi_slave register_bank spi_reg_bridge can_spi_node"
)

# Echo the path to <name>.vhd in whichever source directory holds it, or nothing if no directory
# does. A module is named once here and found wherever the group happened to put it, so moving a
# file between controller/ and bridge/ does not become a build edit.
find_src() {
    local name="$1" dir
    for dir in "${SRC_DIRS[@]}"; do
        if [ -f "$dir/$name.vhd" ]; then
            echo "$dir/$name.vhd"
            return 0
        fi
    done
    return 1
}

checked=0
for src in $MODULES; do
    if path="$(find_src "$src")"; then
        mkdir -p "$WORK_DIR"
        ghdl -a --std=93 --workdir="$WORK_DIR" "$path"
        echo "--> $path analyzes cleanly"
        checked=$((checked + 1))
    fi
done
if [ "$checked" -gt 0 ]; then
    echo
fi

ran=0
skipped=0

for entry in "${TESTBENCHES[@]}"; do
    tb="${entry%%:*}"
    sources="${entry#*:}"

    # The testbench itself ships with the course, so its absence is a real problem.
    if ! tb_path="$(find_src "$tb")"; then
        echo "==> $tb (missing ${tb}.vhd!)" >&2
        exit 1
    fi

    # Skip until every module this testbench exercises has been written.
    missing=()
    for src in $sources; do
        if ! find_src "$src" > /dev/null; then
            missing+=("$src.vhd")
        fi
    done
    if [ "${#missing[@]}" -gt 0 ] && [ "${CI_BUILD_ALL:-0}" != "1" ]; then
        echo "==> $tb (skipped: no ${missing[*]} yet)"
        skipped=$((skipped + 1))
        continue
    fi

    # can_controller.vhd is the one file whose presence does not mean it is ready, so the
    # file-existence test above cannot gate the two system testbenches on its own. Both
    # can_controller_tb and can_spi_node_tb need a controller that can receive, so both are
    # gated the same way.
    #
    # The file is written early as an entity with an empty architecture and then grown for six
    # lectures. Once the last sub-block file appears, every source can_controller_tb lists
    # exists, and it would run against a controller that cannot yet send a frame, and then
    # against one that can send but not receive. Both fail, so the build would be red for two
    # lectures with nothing wrong.
    #
    # The testbench puts two nodes on one bus and has one receive the other's frame, so what it
    # really needs is a controller with a *receive* path. No new file appears when that is
    # written, so this looks inside can_controller.vhd for the receive-side CRC gating instead:
    #
    #     crc_enable  <= (txsr_bit_valid and not txsr_stuff and role) or
    #                    (rxsr_real_bit_valid and not role);
    #     crc_data_in <= txsr_tx_bit when role = '1' else rxsr_real_bit;
    #
    # Either half is enough to match. This is a heuristic, not a dependency, and it is worth
    # being honest about how it fails: a *correct* receive path spelled differently is reported
    # as "skipped" when it should have run. That is a confusing message rather than a wrong one,
    # and CI_BUILD_ALL=1 overrides it. It cannot fail the other way: the marker cannot appear
    # before a receive path exists.
    RX_PATH='else[[:space:]]\+rxsr_real_bit\|rxsr_real_bit_valid[[:space:]]\+and[[:space:]]\+not[[:space:]]\+role'
    if { [ "$tb" = "can_controller_tb" ] || [ "$tb" = "can_spi_node_tb" ]; } \
        && [ "${CI_BUILD_ALL:-0}" != "1" ] \
        && ! grep -q "$RX_PATH" "$(find_src can_controller)"; then
        echo "==> $tb (skipped: can_controller.vhd has no receive path yet; set CI_BUILD_ALL=1 to run it anyway)"
        skipped=$((skipped + 1))
        continue
    fi

    echo "==> $tb"
    mkdir -p "$WORK_DIR"

    # Analyze the modules in dependency order, then the testbench that drives them.
    #
    # find_src can fail here only under CI_BUILD_ALL=1, which deliberately skips the skip. Say
    # so: without this the command substitution expands to nothing and GHDL is invoked with an
    # empty filename, so the documented escape hatch is the one path that reports a confusing
    # error instead of a clear one.
    for src in $sources; do
        if ! src_path="$(find_src "$src")"; then
            echo "error: $tb needs $src.vhd, which does not exist in ${SRC_DIRS[*]}." >&2
            echo "       CI_BUILD_ALL=1 forces every testbench to be attempted; unset it to" >&2
            echo "       go back to skipping the ones whose modules are not written yet." >&2
            exit 1
        fi
        ghdl -a --std=93 --workdir="$WORK_DIR" "$src_path"
    done
    ghdl -a --std=93 --workdir="$WORK_DIR" "$tb_path"

    # Elaborate and run. --assert-level=error makes a failed check stop the simulation with a
    # non-zero exit code, rather than printing and running on to a misleading "pass": these
    # testbenches report at severity error, which is below GHDL's default assert level, so
    # without the flag a failed check prints and the run exits 0.
    ghdl -e --std=93 --workdir="$WORK_DIR" -o "$WORK_DIR/$tb" "$tb"
    run_log="$WORK_DIR/$tb.run.log"
    ghdl -r --std=93 --workdir="$WORK_DIR" "$tb" \
         --assert-level=error --stop-time="$STOP_TIME" | tee "$run_log"

    # The run must reach its own pass line, exactly as in ci/build.sh. GHDL exits 0 when
    # --stop-time cuts a simulation short, so exit status alone cannot tell a finished run from
    # a stalled one. These testbenches wait on events a half-written module may never produce,
    # so without this a module that simply never responds reports a clean build.
    if ! grep -q 'all checks passed' "$run_log"; then
        echo "error: $tb never reached its pass line: it either failed, or ran to" >&2
        echo "       --stop-time=$STOP_TIME without finishing." >&2
        exit 1
    fi

    ran=$((ran + 1))
done

echo
echo "$ran testbench(es) run, $skipped skipped."

# "Skipped" cannot distinguish "not written yet" from "written, but the file is named something
# this build never looks for" - both are just an absent path, and both are silent. That second
# case is the dangerous one: rename meta_prev.vhd to metaprev.vhd and its testbench stops being
# a passing check and becomes a skipped line, with a green exit code either way.
#
# What *is* unambiguous is a .vhd sitting in controller/ or bridge/ that is neither a module this
# script builds nor a testbench it runs. Nothing legitimately lives there, so every such file is
# either a typo, a stray copy, or a module in the wrong directory - and each of those is exactly
# the case a skip would otherwise hide.
stray=0
for dir in "${SRC_DIRS[@]}"; do
    [ -d "$dir" ] || continue
    for path in "$dir"/*.vhd; do
        [ -e "$path" ] || continue
        name="$(basename "$path" .vhd)"

        # A module this script analyzes, or a testbench it runs?
        if [[ " $MODULES " == *" $name "* ]]; then
            continue
        fi
        known_tb=0
        for entry in "${TESTBENCHES[@]}"; do
            if [ "${entry%%:*}" = "$name" ]; then
                known_tb=1
                break
            fi
        done
        [ "$known_tb" -eq 1 ] && continue

        if [ "$stray" -eq 0 ]; then
            echo >&2
            echo "error: file(s) in ${SRC_DIRS[*]} that this build never looks at:" >&2
        fi
        echo "       $path" >&2
        stray=$((stray + 1))
    done
done
if [ "$stray" -gt 0 ]; then
    echo "       Every module has one expected filename, listed in MODULES at the top of" >&2
    echo "       this script. A module whose file is named anything else is not built and" >&2
    echo "       its testbench is reported as skipped, which is never reported as failed." >&2
    exit 1
fi
