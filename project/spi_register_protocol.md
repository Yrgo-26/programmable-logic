# SPI Register Protocol

This is the contract at the centre of the project, and it is written for **two classes at once**:
this course builds the FPGA side as an SPI slave, in [L18](../lectures/L18/README.md) and
[L19](../lectures/L19/README.md), and a parallel class builds the MCU side as a master. Both
halves are written against this document, not against each other's code - if an implementation
and this document disagree, the implementation is wrong.

Lecture numbers in this file are **this** course's. The driver class has its own numbering, and
where the two need to agree the agreement is here, in this file and in
[`register_map.md`](./register_map.md), and nowhere else.

The register map is the same one [`register_map.md`](./register_map.md) gives; this protocol only
defines how those registers are reached over SPI instead of a CPU bus.

---

## Electrical & Framing Parameters

| Parameter | Value |
|---|---|
| Roles | MCU is the SPI master, FPGA the slave. |
| Mode | SPI mode 0 (CPOL = 0, CPHA = 0): SCK idles low, both sides sample on the rising edge. |
| Bit order | MSB first, in every byte. |
| SCK frequency | <= 1 MHz (the AVR32DB28 runs at 4 MHz and divides by 4). See "Timing" below for why. |
| SS | Active low. Framing signal: one transaction per low period. |
| Voltage | The AVR32DB28 core runs at 5 V, the DE0-CV at 3.3 V, and no line crosses a level shifter. The four SPI lines sit on `PORTC`, the AVR DB's second supply domain, with `VDDIO2` fed from the DE0-CV's 3.3 V rail (L19). |

### Pin assignment

Both sides are pinned down here. The MCU side uses `SPI0`'s **ALT1** pin mux on the AVR32DB28,
which routes the peripheral to `PC0`-`PC3`; the FPGA side is free, and this section spends that
freedom on making boards interchangeable.

ALT1 is not an arbitrary choice. `PORTC` is the AVR DB's **MVIO** domain: it is supplied from
`VDDIO2` instead of `VDD`, so tying `VDDIO2` to the DE0-CV's 3.3 V rail puts all four SPI lines in
a 3.3 V domain while the core keeps running at 5 V. Every level the FPGA sees is then a level it is
specified for, and the 3.3 V the FPGA drives back is read against a 3.3 V threshold rather than a
5 V one. On `SPI0`'s default mux the same four signals would sit on `PA4`-`PA7` in the `VDD`
domain, and the bench would need a level shifter to be safe. That is why the mux is part of this
contract rather than each group's choice.

The MCU side therefore owes two things beyond the pin numbers, and both belong to the driver class:
`PORTMUX.SPIROUTEA` must select `ALT1`, and `VDDIO2` must be powered before `PORTC` does anything
at all. `MVIO.STATUS` reports whether it is.

**This constrains the board, not only the firmware.** The hat carrying the AVR32DB28 is built for
this system, and the pin table below makes three demands of its layout. `PC0`-`PC3` carry SPI0 and
nothing else - no LED, no button, and above all no debounce capacitor on `SS`, which at 1 MHz would
make the framing edge unusable. Nothing else sits anywhere on `PORTC`, because the whole port is a
3.3 V domain once `VDDIO2` is. And `VDDIO2` is routed as its own net out to a pin, decoupled with
100 nF close to the package, rather than tied to `VDD` on the board. None of the three can be
corrected in firmware once the board is etched.

**One fuse decides whether any of the above is true.** MVIO's dual-supply mode is selected by
`MVSYSCFG` in `FUSE.SYSCFG1`. In single-supply mode `VDDIO2` is tied internally to `VDD`, `PORTC`
becomes a 5 V port, and the wiring in this section then drives 5 V into FPGA inputs that are not
5 V tolerant - while the bench looks exactly the same as a correct one. Confirm the fuse against
the datasheet before the first node is wired, not after the first board misbehaves.

| Signal | AVR32DB28 | DE0-CV port | DE0-CV pin |
|---|---|---|---|
| `SCK` | `PC2` | `sclk` | `GPIO_0(4)` |
| `MOSI` | `PC0` | `mosi` | `GPIO_0(5)` |
| `MISO` | `PC1` | `miso` | `GPIO_0(6)` |
| `SS` | `PC3` | `ss` | `GPIO_0(7)` |
| I/O supply | `VDDIO2` | - | `3.3 V` |
| Ground | `GND` | - | `GND` |

`GPIO_0(0)` through `GPIO_0(2)` are reserved for the CAN side - `tx_bus`, `bus_en`, and the
wired-AND bus line (L19 Appendix B) - and `GPIO_0(3)` is deliberately left unused as a gap
between the two groups, so that a bundle seated one pin off shorts nothing across domains.

**Why fix these at all, when Quartus does not care.** Nothing in the design breaks if a group
picks other pins; the point is what happens at the bench. With one assignment shared by both
classes, any MCU node plugs into any FPGA board: a harness can be built once instead of per pair,
and a software group whose partner board is not finished can borrow a working one instead of
falling back on simulation. That last case is not hypothetical - the two courses hold their
bring-up and their final presentations in the same week.

**Deviating.** A group may use other pins, but only if the board and the MCU node it pairs with
agree, and only if it is written down where the other class can see it. An undocumented pin swap
presents as a node that answers register reads and never transmits a frame, which is an expensive
way to discover a wiring convention.

---

## Transactions
Every transaction is exactly **5 bytes** long: one command byte, then four data bytes. `SS`
falls before the command byte and rises after the fifth byte; it must stay low for the whole
transaction.

### The command byte

```text
Bit:      7    6    5    4    3    2    1    0
        +----+----+----+----+----+----+----+----+
        | W  | 0  | 0  | 0  |   register index  |
        +----+----+----+----+----+----+----+----+
```

* **Bit 7 (`W`)**: `1` = write, `0` = read.
* **Bits 6-4**: reserved, must be `0`.
* **Bits 3-0**: the register index, `offset / 4` from the register map below (0-12).

### Write (`W = 1`)
The master sends the register value in the four data bytes, **MSB first** (bits 31-24 in the
first data byte). The slave commits the assembled value to the addressed register only when the
fifth byte completes. Whatever the slave drives on `MISO` during a write is meaningless; the
master discards it.

### Read (`W = 0`)
At the end of the command byte, the slave **latches the addressed register's current value
once**, into its response shifter. The four data bytes then clock that value out on `MISO`,
MSB first, while the master sends dummy `0x00` bytes. The latch-once rule is not an
implementation detail but part of the contract: the four bytes always belong to one coherent
sample of the register, taken at one instant - `STATUS` in particular must never be a stitch of
two different moments.

### Aborts
If `SS` rises before the fifth byte completes, the transaction is abandoned with **no side
effects**: nothing is committed, no trigger fires, and the slave returns to idle, ready for the
next falling edge of `SS`. This is what makes the slave self-recovering after a glitch or a
master reset.

### Invalid commands
A read of a reserved index (13-15) returns `0x00000000`; a write to one is ignored. A command
byte with any reserved bit (6-4) set is void in the same way: no read is latched and no write is
committed, and the slave still consumes the full 5-byte frame before returning to idle. Neither
case is an error the slave reports - there is no error channel at this layer. Enforcing the
reserved-*command*-bit rule is `spi_reg_bridge`'s job (L19); `register_bank` only ever sees a
4-bit index, never a reserved command.

---

## Register Map
The same map as [`register_map.md`](./register_map.md), repeated here with the SPI index column.
That file is the fuller description, with the byte-order diagram and the reasoning behind each
register; this table exists so that a driver author reading the protocol never has to leave it to
find an index.

| Index | Register | Offset | Access | Description |
|---|---|---|---|---|
| 0 | `STATUS` | 0x00 | R | Bit 0: TX ready. Bit 1: RX valid. Bit 2: Error. |
| 1 | `TX_ID` | 0x04 | R/W | 11-bit transmit identifier (bits 10-0). |
| 2 | `TX_DLC` | 0x08 | R/W | Data Length Code (bits 3-0, value 0-8). |
| 3 | `TX_DATA_LO` | 0x0C | R/W | Transmit data bytes 0-3 (byte 0 = MSB). |
| 4 | `TX_DATA_HI` | 0x10 | R/W | Transmit data bytes 4-7 (byte 4 = MSB). |
| 5 | `TX_SEND` | 0x14 | W | Write `0x1` to trigger transmission. |
| 6 | `RX_ID` | 0x18 | R | Received identifier (bits 10-0). |
| 7 | `RX_DLC` | 0x1C | R | Received DLC (bits 3-0). |
| 8 | `RX_DATA_LO` | 0x20 | R | Received data bytes 0-3. |
| 9 | `RX_DATA_HI` | 0x24 | R | Received data bytes 4-7. |
| 10 | `RX_ACK` | 0x28 | W | Write `0x1` to acknowledge and clear the RX buffer. |
| 11 | `ERROR_FLAGS` | 0x2C | R/W | Error register; write `0x0` to clear. |
| 12 | `TX_ABORT` | 0x30 | W | Write `0x1` to force TX ready back after an aborted transmission. |

---

## Register Semantics (what the register bank must implement)
`can_controller`'s status outputs are single-cycle pulses or levels (L11); the register map
promises sticky, poll-able bits. Bridging the two is `register_bank`'s whole job (L18):

* **`STATUS` bit 0 (TX ready)**: high after reset; cleared when a `TX_SEND` write triggers
  `tx_req`. While it is low, the bank is mid-transmission and further `TX_SEND` writes are
  ignored. It is set again by any of three things, and a driver need not care which:
  * the controller's `tx_done` pulse - the ordinary path, and note that the controller pulses it
    for an *aborted* transmission too, so a lost arbitration also lands here;
  * a rising edge of the controller's `error` while this bit is already low, which can only mean
    a transmission ended badly, since a node is never transmitting and receiving at once;
  * an accepted `TX_ABORT` write.
* **`TX_ABORT`**: a write of `0x1` sets `STATUS` bit 0 back to `1` and does nothing else. Any
  other written value is ignored, and a read returns `0x00000000`. It is an escape hatch for a
  driver that has waited longer than it is willing to: the two automatic paths above should make
  it unnecessary, and a driver that finds itself needing it has found a bug worth reporting.
* **`STATUS` bit 1 (RX valid)**: set by the controller's `rx_valid` pulse, at which instant the
  bank also latches `rx_id`/`rx_dlc`/`rx_data` into the `RX_*` registers; cleared only by an
  `RX_ACK` write. The `RX_*` registers hold stable while the bit is set - a frame arriving
  before the previous one is acknowledged overwrites them: `can_controller` holds exactly one
  received frame and has no receive buffering (L11), and the bank does not add any. One frame
  held, newest wins - see [`register_map.md`](./register_map.md) for why that is a documented
  decision rather than an oversight.
* **`STATUS` bit 2 (Error)** and **`ERROR_FLAGS`**: the bank latches a rising edge of the
  controller's `error` level. `ERROR_FLAGS` bit 0 is that latch (mirroring `STATUS` bit 2); bits
  31-1 read `0`. Only a write of `0x0` clears the latch - any non-zero write is ignored, so
  despite the map's `R/W` column it is a clear-on-zero latch, not a general-purpose store.
* **`TX_SEND`**: a write with bit 0 set (while TX ready) produces a single-cycle `tx_req` pulse;
  the upper bits are ignored. Writes are edge events at this layer, so a repeated write is a
  repeated request, never a held level. A held `tx_req` would re-request the instant each frame
  ended and wipe `error` on the way past; L18 Appendix A works that failure through.
* **Write masking**: `TX_ID` stores bits 10-0, `TX_DLC` bits 3-0; upper write-data bits are
  ignored and read back as zero.
* **Write-only registers**: a read of `TX_SEND` or `RX_ACK` returns `0x00000000`; they hold no
  readable state of their own.
* **Read-only registers**: a write to `STATUS`, `RX_ID`, `RX_DLC` or `RX_DATA_LO`/`HI` is
  silently ignored. The transaction still completes normally; there is no error channel here.

[`register_map.md`](./register_map.md) carries the rest of what a driver needs and this document
does not repeat: register widths, which bits read back as zero, the accepted write value for each
write-triggered register, and - importantly - that `RX_DATA` above `RX_DLC` reads as `0x00`
because the controller clears its data accumulator at every frame start, and should be masked
against `RX_DLC` anyway.

**A note on what "the transmission ended" means here.** `STATUS` bit 0 returning to `1` says the
transmit port is free again, not that the frame was delivered. A lost arbitration gets you the
same bit back as a clean send. `ERROR_FLAGS` is what distinguishes them, and the ordinary polling
loop is therefore: wait for bit 0, then read `ERROR_FLAGS` to learn whether to re-send. See
[the project specification, section 6.7](./README.md) for the other simplifications against real
CAN.

---

## Timing
* The slave never uses `SCK` as a clock. All three inputs (`SCK`, `MOSI`, `SS`) are synchronized
  into the 50 MHz domain by two flip-flops each, and `SCK` edges are *detected*, not clocked on
  (L04 for why, L18 for the module that does it). `spi_slave` rolls its own synchronizer inline
  rather than instantiating `meta_prev`, so that `spi_slave` itself depends on nothing in
  `controller/`. (`register_bank` is the one file in `bridge/` that does read `can_def`, and only
  for its port types.)
* Two-flop synchronization plus edge detection costs a few 50 MHz cycles per edge; at
  SCK <= 1 MHz there are >= 50 system cycles per SPI bit, leaving an order-of-magnitude margin.
  The protocol therefore guarantees correct operation only up to 1 MHz; faster may work, and is
  deliberately not promised.
* `MISO` changes on the falling edge of `SCK` and is sampled by the master on the rising edge,
  per mode 0.
* The master must raise `SS` between transactions; back-to-back transactions under one `SS` low
  are not supported, and trying it is harmless: **a transaction begins only on the first byte
  after `SS` falls**, so a sixth byte arriving while `SS` is still low is discarded rather than
  taken for a new command byte. Being idle is not on its own enough to start one.

### Setup and hold around `SS`
Because `SS` is synchronized and then edge-detected rather than used directly, it needs a few
system clock cycles to take effect. At 50 MHz one cycle is 20 ns, and the numbers are:

| Parameter | Minimum | Why |
|---|---|---|
| `SS` low before the first `SCK` rising edge | **60 ns** (3 cycles) | the frame-start edge is detected on the third system clock edge after `SS` falls |
| `SS` high between transactions | **60 ns** (3 cycles) | the same detector has to see the line return before it can arm again |
| `SS` low after the last `SCK` edge | **60 ns** (3 cycles) | so the final byte is registered before the frame is torn down |

Allow 100 ns for each in a driver and none of this is close. An AVR toggling `SS` through
`PORTC.OUTCLR` and `PORTC.OUTSET` around a byte written to `SPI0.DATA` is already far slower than
that, so these limits matter only if the master drives `SS` from hardware, or runs much faster than
the AVR32DB28 does.

There is **no minimum inter-byte gap**: bytes may be back-to-back within one transaction, and the
slave does not care how long the master pauses between them, as long as `SS` stays low.

### `MISO` outside a read
* `MISO` is driven **low** while the slave is deselected, not released to high-impedance. The
  design assumes a single slave on the bus. Adding a second one would require making this a
  tri-state output.
* The byte the master clocks out **during the command byte** is meaningless: the slave loads its
  response shifter at the *end* of the command byte, so what leaves during it is whatever was
  left over. Discard it.
* During a write, all four `MISO` data bytes are meaningless too.

---

## Worked Example
Sending one frame (`id 0x123`, `dlc 2`, data `AA BB`) is five transactions, then a poll:

```text
Write TX_ID      : 81 00 00 01 23
Write TX_DLC     : 82 00 00 00 02
Write TX_DATA_LO : 83 AA BB 00 00
Write TX_DATA_HI : 84 00 00 00 00
Write TX_SEND    : 85 00 00 00 01
Read  STATUS     : 00 xx xx xx xx   -> MISO returns 00 00 00 00 while sending,
                                       then 00 00 00 01 once tx_done set TX ready again.
```

Note `83 AA BB 00 00`: byte 0 in the most significant position. That is the packing on both
sides of the wire - the driver assembles it, `register_bank` presents `TX_DATA_LO` as the *first*
four bytes, and `can_controller` reads `tx_data` with byte 0 in bits 63-56. The byte-order
diagram in [`register_map.md`](./register_map.md) is the picture of it, and
`bridge/register_bank_tb.vhd` asserts it.

Also worth reading off this example: the first four MISO bytes of a write are meaningless, and so
is the MISO byte returned *during* any command byte - the slave loads its response shifter at the
end of the command byte, so the first byte a master clocks out carries whatever was left over.
Discard it.

---
