"""The entity of every exercise module a student is asked to write.

Each one is the module's outside and nothing more, which is exactly what the exercise
specifies: the architecture is the reader's to work out.

Ports are listed in **declaration order**, because the testbenches instantiate by position.
Every entity here is checked against two sources that have to agree: the "Self-check" line
in the lecture's `b_exercises.md`, and the `port map` in the exercise's testbench. Change
one and this file has to change too.
"""

from __future__ import annotations

from entity import Entity, Port as P

# ----------------------------------------------------------------------------------------
# L01 - Truth tables and gates
# ----------------------------------------------------------------------------------------
XOR3 = Entity("xor3", [P("a"), P("b"), P("c")], [P("x")])
MAJORITY3 = Entity("majority3", [P("a"), P("b"), P("c")], [P("x")])
OR_FROM_NAND = Entity("or_from_nand", [P("a"), P("b")], [P("x")])
AND_GATE = Entity("and_gate", [P("a"), P("b")], [P("x")])
NAND_GATE = Entity("nand_gate", [P("a"), P("b")], [P("x")])
HALF_ADDER = Entity("half_adder", [P("a"), P("b")], [P("sum"), P("carry")])
ADAS = Entity(
    "adas",
    [P("driver_brake"), P("sensor"), P("radar"), P("error")],
    [P("engine_brake")])

# ----------------------------------------------------------------------------------------
# L02 - Larger networks and multiplexers
# ----------------------------------------------------------------------------------------
XYZ_LOGIC = Entity(
    "xyz_logic",
    [P("a"), P("b"), P("c"), P("d")],
    [P("x"), P("y"), P("z")])
MUX2 = Entity("mux2", [P("d0"), P("d1"), P("sel")], [P("x")])
MUX4 = Entity(
    "mux4",
    [P("d0"), P("d1"), P("d2"), P("d3"), P("sel", 2)],
    [P("x")])
COMBO_LOGIC = Entity("combo_logic", [P("a"), P("b"), P("c"), P("d")], [P("x")])
DISPLAY = Entity("display", [P("number", 4)], [P("hex", 7)])
HEX_DISPLAY = Entity(
    "hex_display",
    [P("input", 8)],
    [P("hex1", 7), P("hex0", 7)])

# ----------------------------------------------------------------------------------------
# L03 - Registers and edge detection
# ----------------------------------------------------------------------------------------
REGISTER4 = Entity(
    "register4",
    [P("clock"), P("reset_n"), P("enable"), P("d", 4)],
    [P("q", 4)])
# `reset` is active-high here, unlike every other module in the course.
LED_TOGGLE_SINGLE = Entity(
    "led_toggle_single",
    [P("clock"), P("reset"), P("button")],
    [P("led")])

# ----------------------------------------------------------------------------------------
# L04 - Metastability and synchronization
# ----------------------------------------------------------------------------------------
LED_TOGGLE_SYNC2 = Entity(
    "led_toggle_sync2",
    [P("clock"), P("reset_n"), P("button_n", 2)],
    [P("led", 2)])
RESET_SYNC = Entity(
    "reset_sync",
    [P("clock"), P("reset_n")],
    [P("reset_s2_n")])
# Both button vectors are COUNT bits wide, so their width is a generic, not a number. The
# generic's `range 1 to 3` is left to the exercise text: spelling it out here widens the
# figure by a third, and it would then render smaller than every other module box. The
# default is carried, though, because unlike the range it changes what a testbench binds to
# when it leaves the generic out of its `generic map`; `Entity.generic_lines` keeps it out
# of the figure.
BUTTON_SYNC = Entity(
    "button_sync",
    [P("clock"), P("reset_s2_n"), P("button_n", "COUNT-1:0")],
    [P("button_edge_s2", "COUNT-1:0")],
    generics=[("COUNT", "natural", "1")])

# ----------------------------------------------------------------------------------------
# L05 - Variables and what the hardware builds
# ----------------------------------------------------------------------------------------
MIN_OF_TWO = Entity("min_of_two", [P("a", 4), P("b", 4)], [P("m", 4)])
# `ones` is a natural, like counter's `count` below, so it carries its type rather
# than a bit range. The exercise text beside the figure gives the range.
ONES_COUNT8 = Entity(
    "ones_count8",
    [P("bits", 8)],
    [P("ones", label="ones (natural)", bus=True, vhdl="natural range 0 to 8")])
# The double-flop synchronizer of L04, extracted here as a reusable module. Two generics, one of
# them a std_logic rather than a natural, which is the point of putting it in this lecture.
SYNC = Entity(
    "sync",
    [P("clock"), P("reset_s2_n"), P("async_in", "SIZE-1:0")],
    [P("sync_out", "SIZE-1:0")],
    generics=[("SIZE", "natural", "1"), ("PRESET", "std_logic", "'0'")])

# ----------------------------------------------------------------------------------------
# L06 - Counters and shift registers
# ----------------------------------------------------------------------------------------
# `count` is the one port in the course that is neither std_logic nor std_logic_vector, so
# it is labeled with its type instead of a bit range. The exercise text beside the figure
# gives the range, so the label does not repeat it.
COUNTER = Entity(
    "counter",
    [P("clock"), P("reset_s2_n")],
    [P("count", label="count (natural)", bus=True, vhdl="natural range 0 to RADIX-1"),
     P("tick")],
    generics=[("RADIX", "natural", "10")])
SIPO8 = Entity(
    "sipo8",
    [P("clock"), P("reset_s2_n"), P("serial_in")],
    [P("parallel_out", 8)])
PISO8 = Entity(
    "piso8",
    [P("clock"), P("reset_s2_n"), P("load"), P("shift"), P("serial_in"), P("parallel_in", 8)],
    [P("serial_out")])

# ----------------------------------------------------------------------------------------
# L07 - Timers
# ----------------------------------------------------------------------------------------
TIMER = Entity(
    "timer",
    [P("clock"), P("reset_s2_n"), P("enable")],
    [P("timeout")],
    generics=[("TICK_COUNT", "natural", "50_000_000")])
# `led` is LED_COUNT bits wide, so its width is a generic rather than a number, the same way
# button_sync's vectors are. The exercise text beside the figure gives the defaults.
WALKING_LED = Entity(
    "walking_led",
    [P("clock"), P("reset_n"), P("button_n")],
    [P("led", "LED_COUNT-1:0")],
    generics=[("LED_COUNT", "natural", "8"), ("TICK_COUNT", "natural", "25_000_000")])
BLINKER = Entity(
    "blinker",
    [P("clock"), P("reset_n")],
    [P("led")],
    generics=[("TICK_COUNT", "natural", "25_000_000")])

# ----------------------------------------------------------------------------------------
# L08 - State machines
# ----------------------------------------------------------------------------------------
SEQ_DETECT_101_MEALY = Entity(
    "seq_detect_101_mealy",
    [P("clock"), P("reset_n"), P("din")],
    [P("y")])
UART_RX8 = Entity(
    "uart_rx8",
    [P("clock"), P("reset_n"), P("rx")],
    [P("data_out", 8), P("byte_valid"), P("frame_err")],
    generics=[("OVERSAMPLE_TICK_COUNT", "natural", "325")])
UART_TX8 = Entity(
    "uart_tx8",
    [P("clock"), P("reset_n"), P("data_in", 8), P("send")],
    [P("tx"), P("busy")],
    generics=[("BIT_TICK_COUNT", "natural", "5207")])

# Which lecture's appendix each module's figure belongs to.
BY_LECTURE: dict[str, list[Entity]] = {
    "L01": [XOR3, MAJORITY3, OR_FROM_NAND, AND_GATE, NAND_GATE, HALF_ADDER, ADAS],
    "L02": [XYZ_LOGIC, MUX2, MUX4, COMBO_LOGIC, DISPLAY, HEX_DISPLAY],
    "L03": [REGISTER4, LED_TOGGLE_SINGLE],
    "L04": [RESET_SYNC, BUTTON_SYNC, LED_TOGGLE_SYNC2],
    "L05": [MIN_OF_TWO, ONES_COUNT8, SYNC],
    "L06": [COUNTER, SIPO8, PISO8],
    "L07": [TIMER, BLINKER, WALKING_LED],
    "L08": [SEQ_DETECT_101_MEALY, UART_RX8, UART_TX8]}
