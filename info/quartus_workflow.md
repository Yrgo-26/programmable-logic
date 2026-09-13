# Quartus Prime Lite: Installation and Workflow

This is the toolchain reference for the course. Through L01-L18 it is **instructor-facing**: the
Quartus and DE0-CV work is demonstrated from the front, starting with the braking assistant in
L01, and no participant needs Quartus or a board of their own. It lives here rather than in a
lecture appendix because for most of the course nobody following it has to execute it.

**[L19](../lectures/L19/README.md) is the exception, and it is the one that matters.** The
bring-up is demonstrated first and then handed over: each group synthesizes and programs its own
`can_spi_node` and demonstrates its own two-node link. So read sections 3 to 7 as
participant-facing - you need 3 and 4 to create the project and add the sources, and 6 is the
compilation that produces the `.sof` file section 7 programs - and read section 8b before you plug
anything in, since it is the section that decides whether the Programmer can see the board at all.

Nothing that is **graded** requires the hardware; see
[examination.md](./examination.md). The bring-up is assessed on the simulation behind it, not on
whether the wire worked on the day.

It covers:
* installing Quartus Prime Lite.
* once installed, taking a VHDL file from source to a running FPGA:
  * new project.
  * adding sources.
  * assigning pins.
  * compiling.
  * programming the board.

This workflow is demonstrated from the front during the lectures; you don't need Quartus or a board
of your own to follow the course. Everything described here ends on real FPGA hardware, verified by
hand. That is a separate layer from the exercises, which you verify on your own laptop by running a
self-checking testbench under GHDL (see
[L02 Appendix C](../lectures/L02/appendix/c_testbenches.md)).

---

## 1. What you need
* **Quartus Prime Lite** (free edition): Intel/Altera's FPGA design software, covering:
  * synthesis.
  * placement and routing ("fitting").
  * programming file generation.
* **Cyclone V device support**: a separate add-on package.
  * The DE0-CV's FPGA, `5CEBA4F23C7N`, is a Cyclone V part.
  * Quartus doesn't include every device family's support by default.
* **USB-Blaster driver**: the DE0-CV programs over USB using Altera's USB-Blaster protocol.
  * the driver usually installs alongside Quartus.
  * it occasionally needs a manual nudge (section 8).
* A **Terasic DE0-CV board** and a USB cable.

Quartus Prime Lite is available for both Windows and Linux; the design steps below are the same
regardless of host OS. **Getting the board visible to the Programmer is not**, and that is where
every host-specific problem in this course lives: section 8b covers Linux and WSL, section 8
covers Windows.

One recommendation up front, because it saves an evening: this course's GHDL toolchain runs on
WSL/Ubuntu, but **WSL2 cannot see a USB device at all without extra work** (section 8b). If you
are on Windows, install Quartus natively on Windows and keep WSL for GHDL. The two never need to
see each other; they share only the `.vhd` files, which live in the Windows filesystem either
way.

---

## 2. Installing Quartus Prime Lite
1. Download **Quartus Prime Lite Edition** from the vendor's download portal.
   * Search for "Quartus Prime Lite download". Intel's FPGA business became **Altera** again in
     2024, so the pages have moved from `intel.com` to `altera.com` and older deep links rot;
     the product name is the stable thing to search for, not the URL.
   * Pick the **Lite** edition, which is the free one and needs no licence file. Standard and Pro
     do not cover Cyclone V for free.
   * Any recent Lite release works; this course doesn't depend on a specific point version.
   * Choose the Windows or Linux installer to match where you will run it - and see the note at
     the end of section 1 if you are on Windows with WSL.
2. During installation, make sure **Cyclone V** is selected under the device family options.
   * If Quartus is already installed without it, add Cyclone V support afterwards by either:
     * re-running the installer.
     * using Quartus's own "Additional Software" / device installer.
3. On first connecting the DE0-CV board over USB, Windows should detect the USB-Blaster and either:
   * install its driver automatically.
   * prompt you to point it at Quartus's own driver files (typically under the Quartus installation
     directory).
   * If Windows can't find a driver automatically, see section 8.

**Windows 11 gotcha:** a couple of Windows 11's security defaults can interfere with this install
or with programming the board later:
* If the installer itself won't open:
  * check Windows Security's `Smart App Control` (search for it in the Start menu).
  * turn it off, then restart.
* If everything installs cleanly but the board still won't program (section 7):
  * go to `Windows Security → Device security → Core isolation`.
  * disable **Memory integrity**:

![`Memory integrity` option under Windows 11's Core isolation settings](./images/mem_integrity.png)

Neither setting affects Quartus itself; both are general Windows 11 hardening defaults that
happen to be strict enough to interfere with driver-level USB access.

---

## 3. Creating a new project
1. Open Quartus and start the **New Project Wizard** (`File → New Project Wizard`).
2. Choose a working directory and a project name.
   * Quartus uses the project name as the default top-level entity name too.
   * Keep them matching your VHDL entity's name to avoid having to override it later (for
     `or_gate.vhd`, name the project `or_gate`).
3. Choose **Empty Project** as the project type.
   * This course doesn't use Quartus's IP catalog or any project templates.
4. Skip adding files at this step (section 4 covers it) unless you already know the exact file; either is
   fine.
5. On the device selection page, select the exact part on the DE0-CV board:
   * filter by family **Cyclone V**.
   * then locate and select the exact device `5CEBA4F23C7N`.
6. Skip the EDA tool settings page (leave it on "none"); this course runs its simulations directly
   in GHDL rather than through Quartus.
7. Finish the wizard.

---

## 4. Adding your VHDL source
* Add your source file:
  * `Project → Add/Remove Files in Project...`, then browse to your `.vhd` file and add it (for
    example, [L01's `or_gate.vhd`](../lectures/L01/or_gate/or_gate.vhd) or L05's
    [`parity_gen.vhd`](../lectures/L05/parity_gen/parity_gen.vhd)). `or_gate` stands in for L01's
    braking assistant throughout this document because the assistant is built live in the lecture
    and deliberately not committed; the steps are identical either way.
* If your design has more than one file (a top-level entity plus one or more subcomponents):
  * add all of them.
  * Quartus resolves the instantiation hierarchy automatically as long as every file is in the
    project.
* Confirm the top-level entity is set correctly:
  * `Project → Set as Top-Level Entity`, with your main file selected.
  * For a single-file design like `or_gate` or `parity_gen`, this is automatic.

---

## 5. Assigning pins with the Pin Planner
Every port in your entity needs a physical pin on the FPGA before Quartus can produce a working
programming file, otherwise there's no way to connect your design's `a`/`b`/`x` (or `bits`/
`parity`) to an actual switch or LED on the board.

1. Run `Processing → Start → Start Analysis & Elaboration` first, then open the Pin Planner:
   * open it via `Assignments → Pin Planner`.
   * on a brand-new project the port list is empty until Quartus has elaborated the design and knows
     its ports.
2. Each of your entity's ports appears as a row.
   * for each one, fill in the **Location** column with the pin identifier for the physical switch or
     LED you want to use.
3. **A switch or an LED is free choice. A clock is not.**
   * For `SW`, `KEY` and `LEDR`, use whichever ones are convenient: the design does not care
     which switch drives which input, only that each port reaches one.
   * `CLOCK_50` is one specific pad on the device and cannot be reassigned. On the DE0-CV it is
     **`PIN_M9`**, the 50 MHz oscillator. Every design from L03 onward is clocked (L05's
     combinational `parity_gen` aside), so from that lecture on this is the one pin number worth
     knowing without looking it up. Confirm it
     against your own board's files (step 4) before you rely on it.
4. **Do not transcribe the pin table by hand.** Ten `LEDR` pins typed from a PDF is ten chances to
   swap two digits, and the failure that produces is the nastiest one in section 8: a clean
   compile that behaves nonsensically.
   * The DE0-CV System CD ships a `DE0_CV.qsf` with every board pin already named and assigned.
   * `Assignments → Import Assignments…`, point it at that file, and every `CLOCK_50`, `SW[n]`,
     `KEY[n]`, `LEDR[n]` and `GPIO_0[n]` assignment lands at once.
   * Name your entity's ports to match those signal names and there is nothing left to assign.
     This is why the L19 bring-up appendix names its ports `CLOCK_50`, `KEY`, `SW`, `LEDR` and
     `GPIO_0` rather than anything prettier.
   * The Pin Planner (and the board's user-manual pinout tables) remain the way to check an
     individual pin, or to assign one the `.qsf` does not cover.
5. Set the **I/O Standard** column if Quartus doesn't infer a sensible default for the pin you chose.
   * the DE0-CV's general-purpose I/O is 3.3 V LVTTL/LVCMOS.
   * consult the pin's entry in the Pin Planner if in doubt.
   * importing the board's `.qsf` (step 4) sets this too, which is another reason to prefer it.
6. Save the assignments (they're written into the project's `.qsf` file).
   * any change here requires recompiling (section 6) before it takes effect.
   * Quartus won't retroactively patch a `.sof` that was compiled before the pin assignment changed.

### A clock needs a timing constraint too
Assigning `CLOCK_50` to a pin tells Quartus where the clock enters. It does not tell Quartus how
fast it runs, and until you say so the timing analyzer has nothing to check against and reports
an unconstrained design. Add a `.sdc` file to the project with one line:

```tcl
create_clock -name CLOCK_50 -period 20.000 [get_ports CLOCK_50]
```

20 ns is 50 MHz. With that in place, `Processing → Start Compilation`'s timing analysis becomes
meaningful and the TimeQuest report gives you a real Fmax, which is the number
[L05 Appendix A](../lectures/L05/appendix/a_variables_and_hardware.md) sends you here to read.
Without it, an Fmax figure is either missing or not to be trusted.

---

## 6. Compiling the design
* `Processing → Start Compilation` (or the ▶ toolbar button) runs the full flow:
  * analysis and synthesis.
  * placement and routing ("fit").
  * timing analysis.
  * assembly into a programming file.
* Read the compilation report once it finishes, especially the **Warnings**:
  * an unconnected port, an incomplete sensitivity list, or a latch inferred where you meant
    combinational logic all show up here as warnings rather than errors.
  * they're easy to miss if you only check for a green checkmark.
* A successful compile produces a `.sof` file (SRAM Object File) in the project's `output_files`
  directory.
  * this is what section 7 loads onto the board.
  * it's volatile: it configures the FPGA's SRAM directly and is lost on power-down; there's no
    persistent flashing step in this course.

---

## 7. Programming the DE0-CV board
1. Connect the DE0-CV to your computer via USB and power it on.
2. Open the Programmer: `Tools → Programmer`.
3. Under **Hardware Setup**, select the USB-Blaster.
   * it should be auto-detected if the driver installed correctly (see section 8 if not).
4. Make sure the `.sof` file produced in section 6 is listed, and its **Program/Configure** checkbox is
   ticked.
   * if it's not listed, use `Auto Detect` or add the file manually.
5. Click **Start**.
   * the progress bar should reach 100% and report success.
6. Test the design directly on the board:
   * flip the switches you assigned in section 5 and confirm the LED matches your entity's truth table:
     * for `or_gate`: lit whenever either switch is on.
     * for `parity_gen`: toggles every time exactly one switch changes.

---

## 8. Troubleshooting
* **USB-Blaster not detected in the Programmer**:
  * check Windows Device Manager for an unknown device or one flagged with a driver error.
  * point it manually at the USB-Blaster driver under the Quartus installation directory.
* **Board won't program, no obvious error**:
  * on Windows 11, disable `Memory integrity` under `Core isolation` (section 2).
  * this is the single most common cause once the driver itself is installed.
* **Installer won't run or open**: check `Smart App Control` under Windows Security (section 2).
* **Compilation succeeds but the design doesn't behave correctly on the board**:
  * re-check the Pin Planner assignments (section 5) before suspecting the VHDL.
  * a swapped or missing pin assignment produces a board that compiles cleanly but behaves
    nonsensically, since it isn't wired the way you think it is.
* **Fitter reports unassigned pins as errors**:
  * some project settings treat this as fatal rather than a warning.
  * either assign every port in the Pin Planner or, for a stray unused port during early development,
    set how Quartus should treat the rest: `Assignments → Device → Device and Pin Options… →
    Unused Pins`.
  * For the DE0-CV, **"As input tri-stated (with weak pull-up)"** is the safe value. The default
    on some flows drives unused pins low, which on a board where pins reach headers and
    peripherals is a way to fight another driver.
  * Don't leave ports silently unassigned and expect Quartus to guess.

---

## 8b. Programming from Linux and from WSL
Section 8 is Windows. On Linux the driver is not a driver at all: the Programmer talks to the
USB-Blaster through libusb, and it needs permission to do so.

**Linux, native.** Out of the box the Programmer shows no hardware, because the device node is
owned by root. Give it a udev rule:

```bash
sudo tee /etc/udev/rules.d/51-usbblaster.rules > /dev/null <<'EOF'
# Altera USB-Blaster
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6001", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6002", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6003", MODE="0666"
# USB-Blaster II
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6010", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6810", MODE="0666"
EOF
sudo udevadm control --reload-rules && sudo udevadm trigger
```

Then unplug and replug the board. Quartus caches its hardware list in a background daemon, so if
the Programmer still shows nothing, restart it:

```bash
killall jtagd 2> /dev/null
jtagconfig            # should now list the USB-Blaster and the device chain
```

`jtagconfig` is the fastest way to tell a permissions problem from a cable problem: if it lists
the board, the hardware is fine and the issue is inside Quartus; if it does not, stop and fix
this before touching the Programmer.

**WSL2.** This is the case the course's own toolchain walks into, so it is worth stating plainly:
**WSL2 has no USB passthrough.** The board is invisible to a WSL2 Linux install no matter what
udev rules you write, because the kernel never sees the device. There is no setting to change.
Two ways out:

* **Run Quartus natively on Windows** (recommended). Keep WSL for GHDL, which needs no hardware
  at all. Your `.vhd` files sit in the Windows filesystem and both tools read them. This is the
  path the course assumes, and it is the one with the fewest moving parts.
* **Forward the device with `usbipd-win`**, if you specifically want Quartus inside WSL. From an
  administrator PowerShell on the Windows side:

  ```powershell
  winget install usbipd
  usbipd list                      # find the USB-Blaster's BUSID
  usbipd bind   --busid <BUSID>    # once per device, persists
  usbipd attach --wsl --busid <BUSID>
  ```

  The device then appears inside WSL and the udev rule above applies. It must be re-attached
  after every unplug and every WSL restart, and the Quartus GUI additionally needs WSLg or an X
  server. Workable, but three more things to go wrong on a demo day.

---
