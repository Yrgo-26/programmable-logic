"""The `or_gate` module figures used by L01's appendix.

Three views of one module, drawn from one geometry so they cannot disagree:

* `entity`       - the boundary and its ports, with nothing inside.
* `architecture` - the same, with the implementation inside and a red rectangle around it.
* `module`       - entity plus architecture: the complete module.
"""

from __future__ import annotations

import schemdraw
import schemdraw.elements as elm
import schemdraw.logic as logic

import style

# ----------------------------------------------------------------------------------------
# Geometry, in schemdraw units. Everything below is derived from these, so moving a port or
# resizing the boundary is a one-line change.
# ----------------------------------------------------------------------------------------
BOX = (0.0, 0.0, 6.6, 4.2)  # Module boundary: (left, bottom, right, top).
TITLE_Y = 4.65  # Module name, just above the boundary.
ARCH_INSET = 0.22  # Gap between the boundary and the architecture rectangle.

PORT_A_Y = 3.10
PORT_B_Y = 1.10
PORT_X_Y = 2.10
STUB = 1.05  # How far the port wires reach outside the boundary.
LABEL_OFST = 0.30  # Gap between a port wire's outer end and its name.

GATE_X = 2.00  # Left edge of the OR gate, where its upper input is.
GATE_Y = PORT_X_Y  # The gate sits on the output's line.
GATE_SCALE = 1.5

CORNER_A_X = 1.10  # Where `a` turns down toward the gate.
CORNER_B_X = 1.50  # Where `b` turns up toward the gate.


def _boundary(d: schemdraw.Drawing, ax) -> None:
    """The module's outside: the boundary rectangle, its name, and its ports."""
    # The boundary, with the module name above it.
    left, bottom, right, top = BOX
    d.add(
        elm.Rect(corner1=(left, bottom), corner2=(right, top), lw=style.BOX_WIDTH)
        .at((0, 0)))
    style.title(ax, "or_gate", ((left + right) / 2, TITLE_Y))

    # Inputs point into the boundary, the output points away from it. Direction is the
    # whole content of an entity, so it is worth an arrowhead.
    for name, y in (("a", PORT_A_Y), ("b", PORT_B_Y)):
        d.add(elm.Arrow().at((left - STUB, y)).to((left, y)))
        style.text(ax, name, (left - STUB - LABEL_OFST, y), halign="right")

    # The single output, mirrored: away from the boundary, labeled to its right.
    d.add(elm.Arrow().at((right, PORT_X_Y)).to((right + STUB, PORT_X_Y)))
    style.text(ax, "x", (right + STUB + LABEL_OFST, PORT_X_Y), halign="left")


def _implementation(d: schemdraw.Drawing) -> None:
    """The module's inside: the OR gate and the wires from the ports to it."""
    left, _, right, _ = BOX

    # Place the gate by its upper input, then read the other two pins off the element
    # itself, so changing GATE_SCALE never leaves a wire hanging in mid-air.
    gate = d.add(
        logic.Or().scale(GATE_SCALE).at((GATE_X, GATE_Y + 0.25 * GATE_SCALE)).anchor("in1"))
    in1 = gate.absanchors["in1"]
    in2 = gate.absanchors["in2"]
    out = gate.absanchors["out"]

    # `a` runs in along its own line, then drops to the gate's upper input; `b` runs in and
    # rises to the lower one. The two turns are at different x so the vertical segments
    # never share a line and read as a short.
    d.add(elm.Line().at((left, PORT_A_Y)).to((CORNER_A_X, PORT_A_Y)))
    d.add(elm.Line().to((CORNER_A_X, in1.y)))
    d.add(elm.Line().to(in1))

    d.add(elm.Line().at((left, PORT_B_Y)).to((CORNER_B_X, PORT_B_Y)))
    d.add(elm.Line().to((CORNER_B_X, in2.y)))
    d.add(elm.Line().to(in2))

    # And the gate's output straight out to the boundary.
    d.add(elm.Line().at(out).to((right, PORT_X_Y)))


def _arch_rect(d: schemdraw.Drawing) -> None:
    """The red rectangle the L01 text points at when it names the architecture."""
    left, bottom, right, top = BOX
    d.add(
        elm.Rect(
            corner1=(left + ARCH_INSET, bottom + ARCH_INSET),
            corner2=(right - ARCH_INSET, top - ARCH_INSET),
            color=style.ACCENT_COLOR,
            lw=style.ACCENT_WIDTH).at((0, 0)))


def _entity(d: schemdraw.Drawing, ax) -> None:
    """Ports only: the entire visible contract, and nothing about how x is produced."""
    _boundary(d, ax)


def _module(d: schemdraw.Drawing, ax) -> None:
    """Entity plus architecture: the complete module."""
    _boundary(d, ax)
    _implementation(d)


def _architecture(d: schemdraw.Drawing, ax) -> None:
    """The implementation, highlighted inside the boundary that declares it."""
    _boundary(d, ax)
    _implementation(d)
    _arch_rect(d)


# All three share style.CANVAS: they are read one after another in the text, so they have to
# line up pixel for pixel.
ENTITY = style.Figure(_entity)
MODULE = style.Figure(_module)
ARCHITECTURE = style.Figure(_architecture)
