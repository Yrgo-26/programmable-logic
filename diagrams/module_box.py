"""Draws a module from its entity alone: the boundary, its ports, and its generics.

This is the picture the `or_gate` entity figure makes by hand, generalized. Nothing about
an architecture appears, which is the point: an exercise that asks for a module with given
inputs and outputs is fully specified by this drawing, and the implementation stays the
reader's to work out.

Conventions:

* A thin line is a `std_logic`, labeled with the port's name.
* A thick line is a `std_logic_vector`, labeled `name[hi:0]`.
* Arrows point into the boundary for inputs and away from it for outputs.
* Generics sit in a strip inside the top of the box, above a separator line.
"""

from __future__ import annotations

from dataclasses import dataclass

import schemdraw
import schemdraw.elements as elm

import style
from entity import Entity, Port  # noqa: F401  (re-exported: figure callers use them)

# ----------------------------------------------------------------------------------------
# Layout, in schemdraw units.
# ----------------------------------------------------------------------------------------
MIN_BOX_WIDTH = 6.0  # Boxes share a width unless their generics need more.
BOX_PAD_X = 0.9  # Space either side of the generic text inside the box.
PORT_PITCH = 1.0  # Vertical distance between neighbouring ports.
PORT_PAD = 0.8  # Space above the first port and below the last.
GENERIC_PITCH = 0.7  # Vertical distance between generic lines.
GENERIC_PAD = 0.35  # Space above the first generic and below the last.
STUB = 1.05  # How far a port wire reaches outside the boundary.
LABEL_OFST = 0.30  # Gap between a port wire's outer end and its name.
TITLE_GAP = 0.35  # Gap between the boundary and the module name above it.
MARGIN = 0.35  # Blank canvas around everything.


@dataclass(frozen=True)
class _Layout:
    """Everything the drawing and the canvas are derived from."""

    width: float
    height: float
    ports_top: float  # Where the port area ends and the generic strip begins.
    input_ys: list[float]
    output_ys: list[float]
    title_y: float


def _port_ys(count: int, ports_top: float) -> list[float]:
    """Evenly pitched port positions, centered in the port area.

    Centering rather than top-aligning is what keeps a two-input, one-output module looking
    balanced when one side has fewer ports than the other.
    """
    # Center the run of ports in the port area, then walk down from its top edge.
    span = (count - 1) * PORT_PITCH
    top = (ports_top + span) / 2
    return [top - i * PORT_PITCH for i in range(count)]


def _layout(entity: Entity) -> _Layout:
    """Work out the box's size and every y position in it, from the entity alone."""
    # The port area is set by whichever side has more ports, so the two sides share a pitch.
    ports_top = (max(len(entity.inputs), len(entity.outputs)) - 1) * PORT_PITCH + 2 * PORT_PAD

    # The generic strip sits above the port area, and a module without generics has none.
    lines = entity.generic_lines
    strip = 2 * GENERIC_PAD + len(lines) * GENERIC_PITCH if lines else 0.0
    height = ports_top + strip

    # Boxes share a width so the figures look like a set, widening only for a long generic.
    widest_generic = max((style.text_width(line) for line in lines), default=0.0)
    width = max(MIN_BOX_WIDTH, widest_generic + 2 * BOX_PAD_X)

    return _Layout(
        width=width,
        height=height,
        ports_top=ports_top,
        input_ys=_port_ys(len(entity.inputs), ports_top),
        output_ys=_port_ys(len(entity.outputs), ports_top),
        title_y=height + TITLE_GAP + style.text_height(style.TITLE_SIZE) / 2)


def _canvas(entity: Entity, layout: _Layout) -> tuple[float, float, float, float]:
    """The smallest canvas that holds the box, its port labels, and its title."""
    # The longest label on each side, and the title, are what can overhang the box.
    left = max((style.text_width(p.text) for p in entity.inputs), default=0.0)
    right = max((style.text_width(p.text) for p in entity.outputs), default=0.0)
    title = style.text_width(entity.name, style.TITLE_SIZE)

    # Take whichever reaches further, the labels or a title wider than the box itself.
    xmin = min(-(STUB + LABEL_OFST + left), layout.width / 2 - title / 2) - MARGIN
    xmax = max(layout.width + STUB + LABEL_OFST + right, layout.width / 2 + title / 2) + MARGIN

    # The title is centered on `title_y`, so the canvas clears its top half.
    ymax = layout.title_y + style.text_height(style.TITLE_SIZE) / 2 + MARGIN
    return (xmin, -MARGIN, xmax, ymax)


def _draw(entity: Entity, layout: _Layout, d: schemdraw.Drawing, ax) -> None:
    """Draw the boundary, the generic strip, and every port, onto a prepared drawing."""
    # The boundary, with the module name above it.
    d.add(
        elm.Rect(corner1=(0, 0), corner2=(layout.width, layout.height), lw=style.BOX_WIDTH)
        .at((0, 0)))
    style.title(ax, entity.name, (layout.width / 2, layout.title_y))

    # The generic strip: a separator across the box, then one centered line per generic,
    # filled downwards from the top edge.
    lines = entity.generic_lines
    if lines:
        d.add(elm.Line().at((0, layout.ports_top)).to((layout.width, layout.ports_top)))
        for i, line in enumerate(lines):
            y = layout.height - GENERIC_PAD - GENERIC_PITCH * (i + 0.5)
            style.text(ax, line, (layout.width / 2, y))

    # Inputs: arrows pointing in at the left edge, labeled outside the wire.
    for port, y in zip(entity.inputs, layout.input_ys):
        lw = style.BUS_WIDTH if port.is_bus else style.WIRE_WIDTH
        d.add(elm.Arrow(lw=lw).at((-STUB, y)).to((0, y)))
        style.text(ax, port.text, (-STUB - LABEL_OFST, y), halign="right")

    # Outputs: the same, mirrored, pointing away from the right edge.
    for port, y in zip(entity.outputs, layout.output_ys):
        lw = style.BUS_WIDTH if port.is_bus else style.WIRE_WIDTH
        d.add(elm.Arrow(lw=lw).at((layout.width, y)).to((layout.width + STUB, y)))
        style.text(ax, port.text, (layout.width + STUB + LABEL_OFST, y), halign="left")


def figure(entity: Entity) -> style.Figure:
    """A ready-to-render figure for one entity, sized to its own port list."""
    # Lay out once here rather than inside the builder, so the canvas and the drawing are
    # derived from the same numbers and cannot disagree.
    layout = _layout(entity)
    return style.Figure(
        draw=lambda d, ax: _draw(entity, layout, d, ax),
        canvas=_canvas(entity, layout))
