"""L06's 4-bit counter: a register, an adder, a constant 1, and the feedback between them.

Drawn at the level A.1 describes it, which is three elements and two buses rather than four
rows of per-bit logic. That matters for more than tidiness: `counter[3:0]` and its sum are
whole-vector names, and they only sit correctly on whole-vector wires.

Element names and signal names are kept apart on purpose, because conflating them is the
thing this figure previously got wrong. The boxes are named for what they *are*
(`register`, `adder`); the wires are named for what they *carry* (`counter[3:0]`, the sum).

Geometry only, as always. Everything visual comes from `style`.
"""

from __future__ import annotations

import schemdraw
import schemdraw.elements as elm

import style

# ----------------------------------------------------------------------------------------
# Layout, in schemdraw units. The gap between the boxes is set by the widest label that has
# to fit inside it, which is `counter[3:0]`.
# ----------------------------------------------------------------------------------------
REG = (0.0, 2.6, 3.4, 5.6)  # (left, bottom, right, top)
ADD = (6.6, 2.9, 9.4, 5.6)
ONE = (4.6, 3.1, 5.2, 3.9)

BUS_Y = 4.9  # The counter bus, and the register's D and adder's sum ports.
ADDEND_Y = 3.5  # The constant into the adder's second input.
FEEDBACK_Y = 0.7  # The return path along the bottom.
FEEDBACK_X = 10.4  # Where the sum turns down.
RETURN_X = -1.4  # Where it turns back up into D.
CARRY_X = 8.9
CARRY_TOP = 6.55

PORT_INSET = 0.3  # Port names sit just inside the boundary, since the outside is wires.
TITLE_GAP = 0.35

COUNTER_CANVAS = (-1.8, 0.35, 10.8, 7.4)


def _box(d, rect: tuple[float, float, float, float]) -> None:
    """One element boundary, from a (left, bottom, right, top) rectangle."""
    left, bottom, right, top = rect
    d.add(
        elm.Rect(corner1=(left, bottom), corner2=(right, top), lw=style.BOX_WIDTH).at((0, 0)))


def _title(ax, rect: tuple[float, float, float, float], name: str) -> None:
    """An element's name, centered above its rectangle."""
    left, _, right, top = rect
    y = top + TITLE_GAP + style.text_height(style.TITLE_SIZE) / 2
    style.title(ax, name, ((left + right) / 2, y))


def _draw_counter(d: schemdraw.Drawing, ax) -> None:
    """The whole figure: two named elements, the constant, and the paths between them."""
    # The two elements the appendix names.
    _box(d, REG)
    _title(ax, REG, "register")
    _box(d, ADD)
    _title(ax, ADD, "adder")

    # Port names inside the boundaries.
    style.text(ax, "D", (REG[0] + PORT_INSET, BUS_Y), halign="left")
    style.text(ax, "Q", (REG[2] - PORT_INSET, BUS_Y), halign="right")
    style.text(ax, "A", (ADD[0] + PORT_INSET, BUS_Y), halign="left")
    style.text(ax, "B", (ADD[0] + PORT_INSET, ADDEND_Y), halign="left")
    style.text(ax, "sum", (ADD[2] - PORT_INSET, BUS_Y), halign="right")

    # The register's own value, on its way to the adder. This is the signal the VHDL calls
    # `counter`, and it is the only place that name belongs.
    d.add(elm.Arrow(lw=style.BUS_WIDTH).at((REG[2], BUS_Y)).to((ADD[0], BUS_Y)))
    style.text(ax, "counter[3:0]", ((REG[2] + ADD[0]) / 2, BUS_Y + 0.35))

    # The constant that makes this an incrementer rather than a register wired to itself.
    _box(d, ONE)
    style.text(ax, "1", ((ONE[0] + ONE[2]) / 2, (ONE[1] + ONE[3]) / 2))
    d.add(elm.Arrow(lw=style.BUS_WIDTH).at((ONE[2], ADDEND_Y)).to((ADD[0], ADDEND_Y)))

    # The fifth bit, which leaves the adder and stops. Discarding it is the wraparound.
    d.add(elm.Arrow().at((CARRY_X, ADD[3])).to((CARRY_X, CARRY_TOP)))
    style.text(ax, "carry_out", (CARRY_X, CARRY_TOP + 0.3))

    # The sum, back round to D. This is the whole circuit: counter <= counter + 1.
    for a, b in (
        ((ADD[2], BUS_Y), (FEEDBACK_X, BUS_Y)),
        ((FEEDBACK_X, BUS_Y), (FEEDBACK_X, FEEDBACK_Y)),
        ((FEEDBACK_X, FEEDBACK_Y), (RETURN_X, FEEDBACK_Y)),
        ((RETURN_X, FEEDBACK_Y), (RETURN_X, BUS_Y)),
    ):
        d.add(elm.Line(lw=style.BUS_WIDTH).at(a).to(b))
    d.add(elm.Arrow(lw=style.BUS_WIDTH).at((RETURN_X, BUS_Y)).to((REG[0], BUS_Y)))
    style.text(ax, "sum = counter + 1", (5.4, FEEDBACK_Y + 0.35))

    # Clock and reset enter from below, so they stay clear of the feedback path.
    for x, name in ((0.9, "clock"), (2.5, "reset_n")):
        d.add(elm.Arrow().at((x, 1.9)).to((x, REG[1])))
        style.text(ax, name, (x, 1.6))


COUNTER = style.Figure(_draw_counter, COUNTER_CANVAS)
