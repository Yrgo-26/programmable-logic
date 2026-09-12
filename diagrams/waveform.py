"""Timing diagrams for the metastability lecture.

Digital waveforms sharing one time axis, which is the natural language for anything defined
by *when* it happens rather than by what it computes: a setup/hold violation, and the
double-flop synchronizer that contains one.

Like every other figure module here, this one describes geometry only. Colors, line weights
and text sizes all come from `style`.
"""

from __future__ import annotations

from matplotlib.patches import Rectangle

import style

# ----------------------------------------------------------------------------------------
# Trace geometry, in canvas units.
#
# Every canvas below leaves a label column to the left of x = 0, wide enough for the longest
# signal name at FONT_SIZE, so nothing is clipped when the view is pinned to the canvas.
# ----------------------------------------------------------------------------------------
TRACE_HEIGHT = 0.85
ROW_PITCH = 1.75  # Centre-to-centre spacing between traces.
LABEL_X = -0.35  # Right edge of the signal-name column.
DANGER_ALPHA = 0.18  # The shaded setup/hold band.
METASTABLE_ALPHA = 0.28  # The shaded stretch where a signal has not resolved yet.

# Three dash patterns, one per kind of uncertainty, so they stay distinguishable side by side.
DASH = (0, (4, 3))       # A trace that might have gone either way.
FINE_DASH = (0, (2, 2))  # A signal held at neither level, and the UART bit-slot boundaries.
MARK_DASH = (0, (3, 3))  # The vertical marking the clock edge under discussion.


def _row(index: int, top: float) -> tuple[float, float]:
    """(low, high) y of the trace `index` rows below `top`."""
    high = top - index * ROW_PITCH
    return high - TRACE_HEIGHT, high


def _trace(ax, points: list[tuple[float, int]], low: float, high: float,
           dashed: bool = False) -> None:
    """Draw a digital waveform from [(x, level), ...].

    Each point sets the level held from its own x until the next point's x, so the last
    entry only supplies the end of the final segment.
    """
    # Each pair becomes three points: hold the level across the segment, then step to the
    # next one at its x. That vertical step is what makes the trace square rather than ramped.
    xs: list[float] = []
    ys: list[float] = []
    for (x_a, level), (x_b, next_level) in zip(points, points[1:]):
        y = high if level else low
        xs += [x_a, x_b, x_b]
        ys += [y, y, high if next_level else low]

    # Mitred joins keep the corners sharp; clipping is off so a trace may sit on the canvas
    # edge without losing its last segment.
    ax.plot(
        xs,
        ys,
        color=style.LINE_COLOR,
        lw=style.WIRE_WIDTH,
        linestyle=DASH if dashed else "-",
        solid_joinstyle="miter",
        clip_on=False)


def _clock(start: float, period: float, count: int) -> list[tuple[float, int]]:
    """A clock starting low, rising at `start` and every `period` after it."""
    # Begin half a period early, so the trace enters the canvas already low.
    points: list[tuple[float, int]] = [(start - period / 2, 0)]

    # One rise and one fall per cycle, then a final point to end the last segment.
    for i in range(count):
        rise = start + i * period
        points += [(rise, 1), (rise + period / 2, 0)]
    points.append((start + count * period, 0))
    return points


def _label(ax, name: str, low: float, high: float) -> None:
    """A signal name in the label column, vertically centered on its trace."""
    style.text(ax, name, (LABEL_X, (low + high) / 2), halign="right")


def _band(ax, x_a: float, x_b: float, y_a: float, y_b: float, alpha: float) -> None:
    """A translucent accent rectangle, for marking an interval as forbidden or unresolved."""
    # zorder 0 puts it behind the traces, so it reads as shading rather than as a shape.
    ax.add_patch(
        Rectangle(
            (x_a, y_a),
            x_b - x_a,
            y_b - y_a,
            facecolor=style.ACCENT_COLOR,
            edgecolor="none",
            alpha=alpha,
            zorder=0))


def _mark(ax, x: float, y_a: float, y_b: float) -> None:
    """The vertical marking the clock edge under discussion."""
    ax.plot([x, x], [y_a, y_b], color=style.ACCENT_COLOR,
            lw=style.ACCENT_WIDTH, linestyle=MARK_DASH)


def _span(ax, x_a: float, x_b: float, y: float, name: str) -> None:
    """A measured horizontal span, labelled above its own centre."""
    # An empty annotation, so all that is drawn is the double-headed arrow between the points.
    ax.annotate(
        "",
        xy=(x_a, y),
        xytext=(x_b, y),
        arrowprops=dict(arrowstyle="<->", color=style.ACCENT_COLOR,
                        lw=style.ACCENT_WIDTH, shrinkA=0, shrinkB=0))
    style.text(ax, name, ((x_a + x_b) / 2, y + 0.38))


# ----------------------------------------------------------------------------------------
# A.4: the setup/hold window, and what a violation does to Q.
# ----------------------------------------------------------------------------------------
SETUP_HOLD_CANVAS = (-1.8, -1.25, 10.0, 5.95)

_SH_PERIOD = 3.0
_SH_EDGE = 4.0  # The sampling edge that gets violated.
_SH_SETUP = 0.8
_SH_HOLD = 0.5
_SH_END = 9.5


def _draw_setup_hold(drawing, ax) -> None:
    """Clock, D and Q, with D changing inside the window and Q paying for it."""
    # Three traces, stacked from the top of the canvas at one pitch.
    top = 4.4
    clock_low, clock_high = _row(0, top)
    d_low, d_high = _row(1, top)
    q_low, q_high = _row(2, top)

    # The forbidden window, behind everything, spanning all three traces.
    _band(ax, _SH_EDGE - _SH_SETUP, _SH_EDGE + _SH_HOLD,
          q_low - 0.45, clock_high + 0.3, DANGER_ALPHA)

    _trace(ax, _clock(1.0, _SH_PERIOD, 3), clock_low, clock_high)
    _label(ax, "clock", clock_low, clock_high)

    # D changes inside the window, which is the one thing you cannot promise about a button.
    _trace(ax, [(-0.3, 0), (_SH_EDGE - 0.2, 0), (_SH_EDGE - 0.2, 1), (_SH_END, 1)],
           d_low, d_high)
    _label(ax, "D", d_low, d_high)

    # Q: low, then unresolved after the violated edge, then either outcome.
    _trace(ax, [(-0.3, 0), (_SH_EDGE, 0)], q_low, q_high)
    _label(ax, "Q", q_low, q_high)

    # The unresolved stretch: shaded, and drawn at half level because Q is at neither.
    settle = _SH_EDGE + 2.2
    mid = (q_low + q_high) / 2
    _band(ax, _SH_EDGE, settle, q_low, q_high, METASTABLE_ALPHA)
    ax.plot([_SH_EDGE, settle], [mid, mid], color=style.LINE_COLOR,
            lw=style.WIRE_WIDTH, linestyle=FINE_DASH)
    style.text(ax, "metastable", ((_SH_EDGE + settle) / 2, q_high + 0.42))

    # Both outcomes, dashed: settling is guaranteed, but the level it settles to is not.
    for level in (1, 0):
        y = q_high if level else q_low
        ax.plot([settle, settle, _SH_END], [mid, y, y], color=style.LINE_COLOR,
                lw=style.WIRE_WIDTH, linestyle=DASH)

    # Finally the edge itself and the window measurement, on top of everything.
    _mark(ax, _SH_EDGE, q_low - 0.45, clock_high + 0.3)
    _span(ax, _SH_EDGE - _SH_SETUP, _SH_EDGE + _SH_HOLD, clock_high + 0.75,
          "setup/hold window")

    style.text(ax, "Q settles late, and to either level", (4.6, q_low - 0.75))


SETUP_HOLD = style.Figure(_draw_setup_hold, SETUP_HOLD_CANVAS)


# ----------------------------------------------------------------------------------------
# A.3: the double-flop synchronizer, in time.
# ----------------------------------------------------------------------------------------
SYNC_CANVAS = (-2.6, -2.95, 10.4, 5.2)

_SY_PERIOD = 2.2
_SY_FIRST = 1.2
_SY_END = 9.6


def _draw_synchronizer(drawing, ax) -> None:
    """Four traces showing the metastability contained in FF1 and never reaching s2."""
    # The two edges the figure is about: the one that samples, and the one a period later
    # by which FF1 has resolved.
    top = 4.4
    edges = [_SY_FIRST + i * _SY_PERIOD for i in range(4)]
    sample, resolved = edges[1], edges[2]

    clock_low, clock_high = _row(0, top)
    in_low, in_high = _row(1, top)
    s1_low, s1_high = _row(2, top)
    s2_low, s2_high = _row(3, top)

    _trace(ax, _clock(_SY_FIRST, _SY_PERIOD, 4), clock_low, clock_high)
    _label(ax, "clock", clock_low, clock_high)

    # The asynchronous input changes just before an edge, because nothing stops it.
    rise = sample - 0.15
    _trace(ax, [(-0.3, 0), (rise, 0), (rise, 1), (_SY_END, 1)], in_low, in_high)
    _label(ax, "async_in", in_low, in_high)
    _mark(ax, sample, s2_low - 0.15, clock_high + 0.3)
    _mark(ax, resolved, s2_low - 0.15, clock_high + 0.3)

    # FF1 is the one exposed to it, so FF1 is the one that may go metastable.
    _trace(ax, [(-0.3, 0), (sample, 0)], s1_low, s1_high)
    _trace(ax, [(resolved, 1), (_SY_END, 1)], s1_low, s1_high)
    _label(ax, "s1", s1_low, s1_high)

    # The gap between the two traces above is the unresolved stretch: shaded, held at half
    # level, then snapped up to `1` at the edge where it resolves.
    _band(ax, sample, resolved, s1_low, s1_high, METASTABLE_ALPHA)
    s1_mid = (s1_low + s1_high) / 2
    ax.plot([sample, resolved], [s1_mid, s1_mid], color=style.LINE_COLOR,
            lw=style.WIRE_WIDTH, linestyle=FINE_DASH)
    ax.plot([resolved, resolved], [s1_mid, s1_high], color=style.LINE_COLOR,
            lw=style.WIRE_WIDTH)
    style.text(ax, "may go metastable", ((sample + resolved) / 2, s1_high + 0.42))

    # FF2 samples s1 a whole period later, by which time it has almost certainly settled.
    _trace(ax, [(-0.3, 0), (resolved, 0), (resolved, 1), (_SY_END, 1)], s2_low, s2_high)
    _label(ax, "s2", s2_low, s2_high)
    style.text(ax, "clean, safe to use", ((resolved + _SY_END) / 2 + 0.35, s2_high + 0.42))

    _span(ax, sample, resolved, s2_low - 1.05, "one clock period to resolve")


SYNCHRONIZER = style.Figure(_draw_synchronizer, SYNC_CANVAS)


# ----------------------------------------------------------------------------------------
# L03 A.3: a flip-flop samples only at the edge.
# ----------------------------------------------------------------------------------------
DFF_CANVAS = (-1.7, -1.15, 10.2, 5.3)

_FF_PERIOD = 2.0
_FF_FIRST = 1.0
_FF_END = 9.6


def _draw_dff_timing(drawing, ax) -> None:
    """Clock, D and Q, arranged so that one whole excursion of D falls between two edges."""
    top = 4.4
    edges = [_FF_FIRST + i * _FF_PERIOD for i in range(5)]

    clock_low, clock_high = _row(0, top)
    d_low, d_high = _row(1, top)
    q_low, q_high = _row(2, top)

    _trace(ax, _clock(_FF_FIRST, _FF_PERIOD, 5), clock_low, clock_high)
    _label(ax, "clock", clock_low, clock_high)

    # D rises mid-cycle, then dips and recovers entirely between two edges.
    _trace(ax, [(-0.4, 0), (1.5, 0), (1.5, 1), (3.5, 1), (3.5, 0), (4.3, 0), (4.3, 1),
                (5.5, 1), (5.5, 0), (_FF_END, 0)], d_low, d_high)
    _label(ax, "D", d_low, d_high)

    # Q moves only at edges 3 and 7, and never during the dip.
    _trace(ax, [(-0.4, 0), (edges[1], 0), (edges[1], 1), (edges[3], 1), (edges[3], 0),
                (_FF_END, 0)], q_low, q_high)
    _label(ax, "Q", q_low, q_high)

    # Mark the two edges where Q did move, so the reader knows where to look.
    for x in (edges[1], edges[3]):
        _mark(ax, x, q_low - 0.3, clock_high + 0.3)
        style.text(ax, "captured", (x, clock_high + 0.62))

    # The dip is the whole point: D changed twice and Q never noticed. Shade it, caption it,
    # and run an arrow from the caption to the dip so the two are unmistakably connected.
    _band(ax, 3.5, 4.3, d_low - 0.15, d_high + 0.15, METASTABLE_ALPHA)
    style.text(ax, "D dips between edges, so Q never sees it", (4.5, q_low - 0.75))
    ax.annotate("", xy=(3.9, d_low - 0.2), xytext=(4.4, q_low - 0.5),
                arrowprops=dict(arrowstyle="->", color=style.ACCENT_COLOR,
                                lw=style.ACCENT_WIDTH))


DFF_TIMING = style.Figure(_draw_dff_timing, DFF_CANVAS)


# ----------------------------------------------------------------------------------------
# L03 A.2-A.3: the same stimulus into a latch and into a flip-flop.
# ----------------------------------------------------------------------------------------
LATCH_CANVAS = (-3.8, -2.95, 8.8, 4.9)

_LV_PERIOD = 2.0
_LV_FIRST = 1.0
_LV_END = 8.2


def _draw_latch_vs_flipflop(drawing, ax) -> None:
    """One clock and one D, into two different storage elements, on the same time axis."""
    top = 4.4
    clock_low, clock_high = _row(0, top)
    d_low, d_high = _row(1, top)
    lat_low, lat_high = _row(2, top)
    ff_low, ff_high = _row(3, top)

    _trace(ax, _clock(_LV_FIRST, _LV_PERIOD, 4), clock_low, clock_high)
    _label(ax, "clock", clock_low, clock_high)

    # One stimulus, fed to both.
    _trace(ax, [(-0.4, 0), (1.4, 0), (1.4, 1), (2.4, 1), (2.4, 0), (3.6, 0), (3.6, 1),
                (_LV_END, 1)], d_low, d_high)
    _label(ax, "D", d_low, d_high)

    # Transparent whenever the clock is high, so it follows D while shaded.
    for x_a, x_b in ((1.0, 2.0), (3.0, 4.0), (5.0, 6.0), (7.0, 8.0)):
        _band(ax, x_a, x_b, lat_low, lat_high, DANGER_ALPHA)
    _trace(ax, [(-0.4, 0), (1.4, 0), (1.4, 1), (3.0, 1), (3.0, 0), (3.6, 0), (3.6, 1),
                (_LV_END, 1)], lat_low, lat_high)
    _label(ax, "Q (latch)", lat_low, lat_high)
    style.text(ax, "transparent while clock is high", (4.2, lat_high + 0.42))

    # Edge-triggered, so it samples at 1, 3, 5 and 7 and changes once.
    _trace(ax, [(-0.4, 0), (5.0, 0), (5.0, 1), (_LV_END, 1)], ff_low, ff_high)
    _label(ax, "Q (flip-flop)", ff_low, ff_high)
    for x in (1.0, 3.0, 5.0, 7.0):
        _mark(ax, x, ff_low - 0.25, clock_high + 0.3)
    style.text(ax, "changes only on a rising edge", (4.2, ff_low - 0.7))


LATCH_VS_FLIPFLOP = style.Figure(_draw_latch_vs_flipflop, LATCH_CANVAS)


# ----------------------------------------------------------------------------------------
# L08: the UART frame the capstone receiver has to recover.
# ----------------------------------------------------------------------------------------
UART_CANVAS = (-1.5, -0.7, 11.1, 4.1)

_UA_BIT = 0.95
_UA_START = 1.0           # Falling edge that begins the frame.
_UA_DATA = _UA_START + _UA_BIT
_UA_BYTE = "10110010"     # BYTE1 from the capstone testbench, MSB first.
_UA_SLOT_SIZE = 11        # Bit names have to fit one slot, so they set their own size.


def _draw_uart_frame(drawing, ax) -> None:
    """One frame on `rx`: idle, start bit, eight data bits, stop bit, and the sample points."""
    rx_low, rx_high = 2.3, 3.15
    stop = _UA_DATA + 8 * _UA_BIT
    end = stop + 1.5 * _UA_BIT

    # Idle high, the falling edge that starts the frame, then one point per data bit and a
    # return to idle for the stop bit.
    points = [(-0.4, 1), (_UA_START, 1), (_UA_START, 0), (_UA_DATA, 0)]
    for k, bit in enumerate(_UA_BYTE):
        points.append((_UA_DATA + k * _UA_BIT, int(bit)))
    points += [(stop, 1), (end, 1)]
    _trace(ax, points, rx_low, rx_high)
    _label(ax, "rx", rx_low, rx_high)

    # Bit-slot boundaries and names.
    names = ["start"] + [f"D{7 - k}" for k in range(8)] + ["stop"]
    for k, name in enumerate(names):
        x_a = _UA_START + k * _UA_BIT
        ax.plot([x_a, x_a], [rx_low - 0.25, rx_high + 0.25], color=style.LINE_COLOR,
                lw=1.0, linestyle=FINE_DASH, zorder=0)
        style.text(ax, name, (x_a + _UA_BIT / 2, rx_high + 0.45), size=_UA_SLOT_SIZE)
    style.text(ax, "idle", (_UA_START / 2 - 0.2, rx_high + 0.45), size=_UA_SLOT_SIZE)

    # Mid-bit sampling: 1.5 bit periods after the start edge, then one per bit period. The
    # two spans below are the measurements the receiver's counter has to reproduce.
    first = _UA_START + 1.5 * _UA_BIT
    for k in range(8):
        x = first + k * _UA_BIT
        ax.annotate("", xy=(x, rx_low - 0.1), xytext=(x, rx_low - 0.75),
                    arrowprops=dict(arrowstyle="->", color=style.ACCENT_COLOR,
                                    lw=style.ACCENT_WIDTH, shrinkA=0, shrinkB=0))
    style.text(ax, "sampled in the middle of every bit",
               (first + 3.5 * _UA_BIT, rx_low - 1.0))

    _span(ax, _UA_START, first, rx_low - 1.9, "1.5 bit periods")
    _span(ax, first, first + _UA_BIT, rx_low - 2.6, "1 bit period")


UART_FRAME = style.Figure(_draw_uart_frame, UART_CANVAS)
