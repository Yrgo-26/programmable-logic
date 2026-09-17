# Simulation with GHDL
This is this course's permanent simulation-workflow reference. It sits in `info/` for the same
reason [`quartus_workflow.md`](./quartus_workflow.md) does: a toolchain reference belongs beside
the course rather than inside the one lecture that happened to introduce it. Every later lecture
that verifies a module against a testbench points back here rather than repeating these steps.

[L02 Appendix C](../lectures/L02/appendix/c_testbenches.md) is the gentler introduction, written
for the first time you run a testbench at all. This file is the reference you come back to, and
it covers the group project's build in particular.

---

## 1. Why simulate at all
* L01-L08 verify every design by hand in CircuitVerse, or directly on the DE0-CV. That works for
  small circuits with a handful of inputs a person can toggle.
* It stops working once a design's correctness depends on precise multi-cycle timing
  relationships between several modules, which is the group project's situation throughout.
* A **testbench** is a small, provided VHDL program that drives a design's inputs and checks its
  outputs automatically.
* **GHDL** is the tool that compiles and runs it, entirely in software, with no FPGA involved.
* You are never asked to write the testbench that **verifies** a module you build. Every one of
  those is provided; you run it and read what it reports.
* A few exercises do invite you to write a short *scratch* harness, twenty lines that feed your
  own bit sequence into a module and `report` what comes out; the L13 to L15 exercises are where
  this comes up. That is exploration, and always optional in form: nothing you are graded on
  depends on a testbench you wrote.

---

## 2. Installing GHDL
On Ubuntu/WSL:

```bash
sudo apt-get update && sudo apt-get install -y ghdl
```

Confirm it installed:

```bash
ghdl --version
```

GHDL 3.x or later. This course's CI runs the same GHDL commands shown below, so anything that
passes locally will also pass in CI.

---

## 2b. Where the files live
The group project's VHDL lives in **two flat directories at the repository root**: the modules
you write, alongside the provided testbenches (`*_tb.vhd`) that check them. There are no
per-lecture source directories and nothing to copy between them; `can_def.vhd` in particular is
provided, exists once, and every controller module reads that one file.

The split between the two directories is the protocol boundary: everything in `controller/`
knows about CAN and nothing about SPI, and everything in `bridge/` the other way round.

```text
controller/   can_controller.vhd     L11, yours (ports only at first, grown through L17)
              meta_prev.vhd          L12, yours
              bit_timer.vhd          L12, yours
              crc15.vhd              L13, yours
              tx_shift_reg.vhd       L14, yours
              rx_shift_reg.vhd       L15, yours
              + provided can_def.vhd and the six *_tb.vhd

bridge/       register_bank.vhd      L18, yours
              spi_reg_bridge.vhd     L19, yours
              can_spi_node.vhd       L19, yours
              + provided spi_slave.vhd, spi_def.vhd,
                register_bank_tb.vhd, spi_reg_bridge_tb.vhd
```

The two directories start out holding only the provided files: nine testbenches, plus
`can_def.vhd`, `spi_slave.vhd` and `spi_def.vhd`. Each lecture from L11 adds a module, except that
`can_controller.vhd` is written early (L11) as an entity with an empty architecture and then
*grown*: L16 fills in its transmit path and L17 its receive path, with no new file appearing for
either. That is why `can_controller_tb`, the only testbench that exercises the whole controller,
is gated on more than file presence; section 3 comes back to it.

In **this** repository `controller/` and `bridge/` hold only the provided files, so a fresh clone
reports every testbench as skipped. That is the expected state. The modules are yours to write,
in your group's own repository; see [the project specification](../project/README.md).

---

## 3. The three GHDL steps
Every VHDL design (and testbench) goes through the same three steps, in order:
1. **Analyze** (`ghdl -a`): parses one `.vhd` file and checks it for syntax/type errors,
   registering its design units (entities, architectures, packages) into a work library.
   Dependencies must be analyzed before the units that use them, `can_def.vhd` before any
   module that says `use work.can_def.all;`, and a module before its own testbench.
2. **Elaborate** (`ghdl -e`): resolves a specific top-level entity's full instantiation
   hierarchy into something runnable.
3. **Run** (`ghdl -r`): actually simulates it.

For a module with a provided testbench, e.g. L12's `meta_prev`, which reads no package at all
and so needs only its own two files:

```bash
cd controller
ghdl -a --std=93 meta_prev.vhd meta_prev_tb.vhd
ghdl -e --std=93 meta_prev_tb
ghdl -r --std=93 meta_prev_tb --assert-level=error
```

Every other controller module reads `can_def`, so its package comes first:

```bash
ghdl -a --std=93 can_def.vhd bit_timer.vhd bit_timer_tb.vhd
ghdl -e --std=93 bit_timer_tb
ghdl -r --std=93 bit_timer_tb --assert-level=error
```

`bridge/` works the same way, with one wrinkle: `register_bank` reads `can_def`, which lives one
directory over.

```bash
cd bridge
ghdl -a --std=93 ../controller/can_def.vhd register_bank.vhd register_bank_tb.vhd
ghdl -e --std=93 register_bank_tb
ghdl -r --std=93 register_bank_tb --assert-level=error
```

* `--std=93` selects VHDL-93 throughout this course; every provided testbench ends cleanly on
  its own, by setting a `done` signal the clock-generation process checks and then calling
  `wait;`, rather than relying on any later-standard "stop the simulator" procedure.
* `--assert-level=error` tells GHDL to stop the simulation, with a non-zero exit code, on any
  failed check reported at severity `error` or above. **Always pass it when running a project
  testbench.** The next section says why it is not optional here.

### Why `--assert-level=error` matters, and where it does not
GHDL stops on a failed assertion only when the assertion's severity reaches the assert level,
and GHDL's default level is `failure`. The two halves of this repository sit on opposite sides
of that line, which is worth knowing because it explains why the flag looks optional in L01-L08
and is not optional here:

| | Severity used | Without the flag | With the flag |
|---|---|---|---|
| `lectures/` testbenches | `failure` | stops, exit 1 | stops, exit 1 |
| `controller/` and `bridge/` testbenches | `error` | **prints, then runs on and exits 0** | stops, exit 1 |

So for a project testbench, omitting the flag turns a real failure into a message scrolling past
above a zero exit code, which is exactly what a "silent pass" looks like. Pass it every time and
the distinction stops mattering.

`--stop-time=10ms` is worth adding for the same class of reason. A testbench that is waiting on
an event your module never produces does not fail; it hangs. The stop time turns that into a run
that ends. It is not in the commands above because the project testbenches all bound their own
waits, but it costs nothing and L02 Appendix C makes it a habit.

Each testbench reports only pass or fail (and, on failure, the cause), nothing else. A passing
run ends with a line like:

```text
bit_timer_tb.vhd:148:9:@7312ns:(report note): bit_timer: all checks passed!
```

A failing run stops early with an `(assertion error)` message naming exactly which check failed
and why: read that message; it's written to tell you specifically what went wrong.

### Building everything at once
**`make build-project`, from the repository root, does all of this automatically** for every
testbench whose modules you have written (see `ci/build_project.sh`). It is useful for confirming
your whole tree still passes, but understanding the three individual steps above is what lets you
debug a single module quickly during a lecture.

`make build` runs `make build-lectures` (the L01-L08 examples and exercises) and then
`make build-project`. In your group's repository only `build-project` exists.

Because the project is built up a module at a time, `make build-project` **skips** any testbench
whose modules do not exist yet rather than failing on them, and says so:

```text
==> meta_prev_tb
controller/meta_prev_tb.vhd:114:9:@311ns:(report note): meta_prev: all checks passed!
==> bit_timer_tb (skipped: no bit_timer.vhd yet)
```

That is what L12 looks like halfway through: `meta_prev.vhd` written and passing, `bit_timer.vhd`
still to come. `can_def.vhd` is never named as missing, because it is provided.

Skipped is not failed, deliberately. The project runs over ten lectures and most of the tree is
missing for most of them; a build that went red until the last module landed would say nothing
useful on any of the nine before it. So the number of testbenches actually running grows as you
go: none after L10 or L11, two after L12, then one more in each of L13, L14 and L15, one more in
L17, one in L18, and the last in L19.

**`can_controller_tb` is gated on more than file presence**, and it is worth knowing why before
it puzzles you. `can_controller.vhd` is written in L11 as an entity with an empty architecture
and grown through L16 and L17, so from L15 onward every file that testbench needs already exists
while the controller still cannot receive a frame. Running it then would fail, twice over: once
in L15, and again in L16, which can send but not yet receive. Since the testbench works by having
one node receive another's frame, what it actually requires is a **receive path**, and that
arrives in L17. `ci/build_project.sh` therefore looks inside your `can_controller.vhd` for L17's
receive-side CRC gating and reports:

```text
==> can_controller_tb (skipped: can_controller.vhd has no receive path yet; set CI_BUILD_ALL=1 to run it anyway)
```

That check is a heuristic rather than a real dependency, and it has one failure mode worth
naming: if your L17 is correct but spells those expressions differently from the appendix, you
will see this skip message when the testbench should have run. Nothing is broken; run
`CI_BUILD_ALL=1 make build-project` to force every testbench regardless. The check cannot fail
the other way round, since the marker cannot appear before a receive path does.

---

## 4. Cleaning up
GHDL's analysis steps create `work-obj93.cf` and similar files in whichever directory you ran
them from. `ci/build_project.sh` keeps its own `controller/work/` directory instead, so these
files don't clutter the source tree; if you run the three steps by hand in `controller/` or
`bridge/` (not via `make build-project`), clean up with:

```bash
make clean
```

which removes the generated `work/` directories, any stray `work-obj*.cf`, and the waveform and
executable files a hand-run leaves behind (see `ci/clean.sh`).

---

## What's ahead
From here on, every lecture's Genomförande section simply says "run the provided testbench" and
links back here, rather than repeating these steps.
