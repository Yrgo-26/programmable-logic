"""L02's worked Karnaugh map, as three frames of one grid.

A.1 walks the reader through a single map twice: first filled in from the truth table, then
gaining one group, then another. Drawing all three from one source is the whole point. The
grid, the labels and the `1`s are computed once and rendered onto one shared canvas, so the
map lands on the same pixels in every frame and only the marking changes. Three separate
drawings of the same map cannot do that, and a reader comparing them ends up checking
whether the grid moved instead of reading the group.

The two groups overlap in one cell, which the appendix makes a point of. They are told apart
by colour *and* by line style, so the distinction survives a greyscale print.

Geometry only, as always. Everything visual comes from `style`.
"""

from __future__ import annotations

import schemdraw
import schemdraw.elements as elm

import style

# ----------------------------------------------------------------------------------------
# The map itself, straight from A.1's truth table.
#
# Rows are `AB` in Gray code top to bottom, columns are `C`. Both orders are Gray code, which
# is what makes horizontally and vertically adjacent cells differ in exactly one input.
# ----------------------------------------------------------------------------------------
ROW_LABELS = ("00", "01", "11", "10")
COL_LABELS = ("0", "1")

# X, indexed [row][column]. A blank cell is a `0`, left empty so the `1`s carry the shape.
ONES = (
    (False, True),   # AB = 00
    (False, True),   # AB = 01
    (True, True),    # AB = 11
    (False, True),   # AB = 10
)

# A group is (first row, first column, row count, column count).
GROUP_C = (0, 1, 4, 1)    # The whole C = 1 column: four cells, reduces to `C`.
GROUP_AB = (2, 0, 1, 2)   # The AB = 11 row: two cells, reduces to `AB`.

ROWS = len(ROW_LABELS)
COLS = len(COL_LABELS)

# ----------------------------------------------------------------------------------------
# Layout, in schemdraw units. The grid hangs from (GRID_X, GRID_Y), rows running downwards.
# ----------------------------------------------------------------------------------------
CELL_W = 1.7
CELL_H = 1.3
GRID_X = 0.0
GRID_Y = 0.0

GRID_RIGHT = GRID_X + COLS * CELL_W
GRID_BOTTOM = GRID_Y - ROWS * CELL_H

COL_LABEL_GAP = 0.45   # `0`/`1`, above the top edge.
ROW_LABEL_GAP = 0.45   # `00`/`01`/..., left of the left edge.
AXIS_LABEL_GAP = 1.5   # `C` above the column labels, `AB` left of the row labels.
GROUP_LABEL_GAP = 0.35  # The term a group reduces to, right of the grid.

# Group outlines sit inside the cell border rather than on it, so a grouped cell still reads
# as a cell and the two marks never lie on top of each other.
GROUP_INSET = 0.17

KMAP_CANVAS = (-2.4, -5.7, 4.7, 2.0)


def _cell_center(row: int, col: int) -> tuple[float, float]:
    """The middle of one cell, for placing a `1`. Rows run downwards from the grid's top."""
    return (GRID_X + (col + 0.5) * CELL_W, GRID_Y - (row + 0.5) * CELL_H)


def _map(d: schemdraw.Drawing, ax) -> None:
    """The grid, its axis labels, and the `1`s. Identical in all three frames."""
    # The grid, as one line per boundary: ROWS + 1 across and COLS + 1 down.
    for i in range(ROWS + 1):
        y = GRID_Y - i * CELL_H
        d.add(elm.Line(lw=style.BOX_WIDTH).at((GRID_X, y)).to((GRID_RIGHT, y)))
    for j in range(COLS + 1):
        x = GRID_X + j * CELL_W
        d.add(elm.Line(lw=style.BOX_WIDTH).at((x, GRID_Y)).to((x, GRID_BOTTOM)))

    # The Gray-code labels: `C` values above the columns, `AB` values left of the rows.
    for j, label in enumerate(COL_LABELS):
        style.text(ax, label, (GRID_X + (j + 0.5) * CELL_W, GRID_Y + COL_LABEL_GAP))
    for i, label in enumerate(ROW_LABELS):
        style.text(
            ax,
            label,
            (GRID_X - ROW_LABEL_GAP, GRID_Y - (i + 0.5) * CELL_H),
            halign="right")

    # Which input each axis is, set further out again so it does not crowd the values.
    style.title(ax, "C", ((GRID_X + GRID_RIGHT) / 2, GRID_Y + AXIS_LABEL_GAP))
    style.title(ax, "AB", (GRID_X - AXIS_LABEL_GAP, (GRID_Y + GRID_BOTTOM) / 2))

    # The `1`s. A `0` cell is left blank, so the shape of the function carries itself.
    for i in range(ROWS):
        for j in range(COLS):
            if ONES[i][j]:
                style.text(ax, "1", _cell_center(i, j))


def _group(
    d: schemdraw.Drawing,
    ax,
    group: tuple[int, int, int, int],
    term: str,
    color: str,
    linestyle: str,
) -> None:
    """Outline a group of cells and name the AND-term it reduces to."""
    # The group's outer bounds, pulled inside the cell border by GROUP_INSET.
    row, col, height, width = group
    left = GRID_X + col * CELL_W + GROUP_INSET
    right = GRID_X + (col + width) * CELL_W - GROUP_INSET
    top = GRID_Y - row * CELL_H - GROUP_INSET
    bottom = GRID_Y - (row + height) * CELL_H + GROUP_INSET

    # Four Lines rather than a Rect: a Rect places itself relative to the drawing cursor, so
    # after the grid has been drawn it lands nowhere near the corners it was given. A Line
    # takes two absolute points and is the same primitive the grid itself is built from.
    # Walk the corners and join each to the next, wrapping the last back to the first.
    corners = [(left, top), (right, top), (right, bottom), (left, bottom)]
    for start, end in zip(corners, corners[1:] + corners[:1]):
        d.add(
            elm.Line(lw=style.ACCENT_WIDTH)
            .at(start)
            .to(end)
            .color(color)
            .linestyle(linestyle))

    # Beside the group's first row, so the two terms never crowd each other vertically.
    style.text(
        ax,
        term,
        (GRID_RIGHT + GROUP_LABEL_GAP, GRID_Y - (row + 0.5) * CELL_H),
        halign="left",
        color=color)


# ----------------------------------------------------------------------------------------
# The three frames, in the order A.1 reads them. Each adds one mark to the same map.
# ----------------------------------------------------------------------------------------


def _draw_filled(d: schemdraw.Drawing, ax) -> None:
    """Frame 1: the map filled in from the truth table, with nothing grouped yet."""
    _map(d, ax)


def _draw_group_c(d: schemdraw.Drawing, ax) -> None:
    """Frame 2: the first group, the whole `C = 1` column."""
    _map(d, ax)
    _group(d, ax, GROUP_C, "C", style.ACCENT_COLOR, "-")


def _draw_groups(d: schemdraw.Drawing, ax) -> None:
    """Frame 3: both groups. The second is dashed as well as blue, for a greyscale print."""
    _map(d, ax)
    _group(d, ax, GROUP_C, "C", style.ACCENT_COLOR, "-")
    _group(d, ax, GROUP_AB, "AB", style.ACCENT_COLOR_2, "--")


# All three share KMAP_CANVAS, so the grid lands on the same pixels in every frame.
FILLED = style.Figure(_draw_filled, KMAP_CANVAS)
GROUP_C_ONLY = style.Figure(_draw_group_c, KMAP_CANVAS)
BOTH_GROUPS = style.Figure(_draw_groups, KMAP_CANVAS)
