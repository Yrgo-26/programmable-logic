#!/usr/bin/env python3
"""Draw can_controller's internal block architecture (L11 Appendix A).

Regenerate with:  python3 architecture.py <output.png>
Everything is data-driven from BLOCKS/LINKS/INPUTS/OUTPUTS below, so a spec change is a text edit.

Three details are easy to get wrong and are asserted by check(), at the bottom of this file:
  * crc15's two links run in opposite directions, and the returned signal is "valid".
  * rx_shift_reg has three lines arriving: sample, rx_bus, and bit_count/enable.
  * tx_shift_reg and rx_shift_reg never connect to each other, and neither touches crc15.
"""
import sys

from PIL import Image, ImageDraw, ImageFont

Color = tuple[int, int, int]
Fill = Color | str
Point = tuple[float, float]
Bounds = tuple[int, int, int, int]
# (x0, y0, x1, y1, title, subtitle lines, fill)
Block = tuple[int, int, int, int, str, list[str], Color]
# (from, to, x, label lines, label side)
Link = tuple[str, str, int, list[str], str]
# (port name, y)
Port = tuple[str, int]

S: int = 3                               # supersample factor
W: int = 1700                            # final canvas width
H: int = 1345                            # final canvas height

FONT: str = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD: str = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

INK: Color = (26, 26, 26)
GREY: Color = (238, 238, 238)
BLUE: Color = (207, 226, 243)
GREEN: Color = (217, 234, 211)
PURPLE: Color = (217, 210, 233)
YELLOW: Color = (255, 242, 204)

# The can_controller boundary.
BOX: Bounds = (250, 60, 1440, 1100)

BLOCKS: dict[str, Block] = {
    "BT":  (360, 130, 710, 255, "bit_timer",
            ["divides the 50 MHz clock", "into CAN bit periods"], BLUE),
    "CRC": (1010, 130, 1360, 255, "crc15",
            ["bit-serial CRC-15,", "one bit at a time"], GREEN),
    "FSM": (530, 430, 1160, 730, "frame FSM",
            ["sequences SOF, ID, control, data,",
             "CRC, ACK, EOF; slices received",
             "fields; detects arbitration loss"], GREY),
    "TX":  (360, 890, 710, 1015, "tx_shift_reg",
            ["serialize +", "insert stuff bits"], PURPLE),
    "RX":  (1010, 890, 1360, 1015, "rx_shift_reg",
            ["deserialize +", "remove stuff bits"], YELLOW),
    "MP":  (292, 540, 455, 620, "meta_prev", ["rx_bus_sync"], GREY),
    "MPR": (292, 300, 455, 380, "meta_prev", ["reset_sync"], GREY),
}

# Straight links between a sub-block and the frame FSM.  "u" runs upward, "d" downward.
LINKS: list[Link] = [
    ("FSM", "BT",  580, ["enable, resync"], "l"),
    ("BT",  "FSM", 680, ["sample, bit_done"], "r"),
    ("FSM", "CRC", 1020, ["clear, enable, data", "(one real bit at a time)"], "l"),
    ("CRC", "FSM", 1120, ["crc, valid"], "r"),
    ("FSM", "TX",  580, ["load, data,", "bit_count, shift"], "l"),
    ("TX",  "FSM", 680, ["tx_bit, stuff,", "done, bit_valid"], "r"),
    ("FSM", "RX",  1060, ["bit_count, enable"], "l"),
    ("RX",  "FSM", 1140, ["data, valid, stuff_error,", "real_bit, real_bit_valid"], "r"),
]

# Input ports, top to bottom.  rx_bus is routed by hand: it is the only one that
# continues inside the boundary.
INPUTS: list[Port] = [("clock", 150), ("reset_n", 340), ("tx_req", 420), ("tx_id", 460),
                      ("tx_dlc", 500), ("tx_data", 540), ("rx_bus", 580)]

# Output ports, top to bottom.  Every one of them is driven by the frame FSM.
OUTPUTS: list[Port] = [("tx_done", 460), ("tx_bus", 495), ("bus_en", 530), ("rx_id", 565),
                       ("rx_dlc", 600), ("rx_data", 635), ("rx_valid", 670), ("error", 705)]

NOTES: list[str] = [
    "clock reaches every sub-block, and reset_s2_n all but the two meta_prev instances;",
    "     both left undrawn, as usual.",
    "Every output port is driven by the frame FSM and by nothing else.",
    "reset_n and rx_bus are the only asynchronous inputs; each is synchronized once, here.",
    "crc15 connects to neither shift register: the frame FSM carries every bit between them.",
    "A dot marks a junction; lines that merely cross are not connected.",
]

# Left-hand routing lanes for the links that cannot run straight.
TRUNK_SAMPLE: int = 268                  # bit_timer.sample, down the far left
LANE_SAMPLE: int = 1075
RISE_SAMPLE: int = 1185
RXBUS_JUNCTION: int = 495                # where the synchronized bus level forks
RXBUS_BRANCH_Y: int = 850
RXBUS_BRANCH_X: int = 318
LANE_RXBUS: int = 1045
RISE_RXBUS: int = 1105


def main(out: str) -> None:
    img: Image.Image = Image.new("RGB", (W * S, H * S), "white")
    d: ImageDraw.ImageDraw = ImageDraw.Draw(img)
    f_t: ImageFont.FreeTypeFont = ImageFont.truetype(BOLD, 20 * S)
    f_s: ImageFont.FreeTypeFont = ImageFont.truetype(FONT, 15 * S)
    f_e: ImageFont.FreeTypeFont = ImageFont.truetype(FONT, 15 * S)
    f_p: ImageFont.FreeTypeFont = ImageFont.truetype(FONT, 17 * S)
    f_nb: ImageFont.FreeTypeFont = ImageFont.truetype(BOLD, 16 * S)
    f_n: ImageFont.FreeTypeFont = ImageFont.truetype(FONT, 15 * S)

    def rect(x0: float, y0: float, x1: float, y1: float, fill: Fill,
             radius: int = 8, width: int = 2) -> None:
        d.rounded_rectangle([x0 * S, y0 * S, x1 * S, y1 * S],
                            radius=radius * S, fill=fill, outline=INK, width=width * S)

    def ctext(cx: float, cy: float, txt: str, font: ImageFont.FreeTypeFont,
              anchor: str = "mm") -> None:
        d.text((cx * S, cy * S), txt, font=font, fill=INK, anchor=anchor)

    def poly(pts: list[Point], width: int = 2) -> None:
        d.line([(px * S, py * S) for px, py in pts], fill=INK, width=width * S, joint="curve")

    def head(p: Point, direction: str, size: int = 9) -> None:
        px, py = p[0] * S, p[1] * S
        s = size * S
        m = {"r": [(px, py), (px - s, py - s * 0.55), (px - s, py + s * 0.55)],
             "l": [(px, py), (px + s, py - s * 0.55), (px + s, py + s * 0.55)],
             "d": [(px, py), (px - s * 0.55, py - s), (px + s * 0.55, py - s)],
             "u": [(px, py), (px - s * 0.55, py + s), (px + s * 0.55, py + s)]}[direction]
        d.polygon(m, fill=INK)

    def arrow(pts: list[Point], direction: str, width: int = 2) -> None:
        poly(pts, width)
        head(pts[-1], direction)

    def dot(x: float, y: float, r: int = 6) -> None:
        d.ellipse([(x - r) * S, (y - r) * S, (x + r) * S, (y + r) * S], fill=INK)

    def label(cx: float, cy: float, lines: list[str], font: ImageFont.FreeTypeFont,
              anchor: str = "mm") -> None:
        for i, line in enumerate(lines):
            ctext(cx, cy + (i - (len(lines) - 1) / 2) * 21, line, font, anchor)

    # ---- boundary ----------------------------------------------------------
    rect(*BOX, fill="white", radius=10, width=3)
    ctext(BOX[0] + 22, BOX[1] + 32, "can_controller", f_t, anchor="lm")

    # ---- blocks ------------------------------------------------------------
    for x0, y0, x1, y1, title, subs, fill in BLOCKS.values():
        rect(x0, y0, x1, y1, fill)
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        top = cy - (len(subs) * 21) / 2
        ctext(cx, top - 6, title, f_t)
        for i, sub in enumerate(subs):
            ctext(cx, top + 20 + i * 21, sub, f_s)

    # ---- straight sub-block <-> frame FSM links ----------------------------
    for src, dst, x, lines, side in LINKS:
        sy0, sy1 = BLOCKS[src][1], BLOCKS[src][3]
        dy0, dy1 = BLOCKS[dst][1], BLOCKS[dst][3]
        if dy0 > sy1:                                  # destination sits below
            arrow([(x, sy1), (x, dy0)], "d")
            mid = (sy1 + dy0) / 2
        else:                                          # destination sits above
            arrow([(x, sy0), (x, dy1)], "u")
            mid = (dy1 + sy0) / 2
        label(x + 14 if side == "r" else x - 14, mid, lines, f_e,
              anchor="lm" if side == "r" else "rm")

    # ---- input ports -------------------------------------------------------
    fx0, fx1 = BLOCKS["FSM"][0], BLOCKS["FSM"][2]
    for name, y in INPUTS:
        ctext(BOX[0] - 90, y, name, f_p, anchor="rm")
        if name in ("rx_bus", "reset_n"):                          # into a meta_prev
            block = "MP" if name == "rx_bus" else "MPR"
            arrow([(BOX[0] - 80, y), (BLOCKS[block][0], y)], "r")
        else:
            arrow([(BOX[0] - 80, y), (BOX[0], y)], "r")

    # ---- output ports ------------------------------------------------------
    for name, y in OUTPUTS:
        arrow([(fx1, y), (BOX[2] + 80, y)], "r")
        ctext(BOX[2] + 92, y, name, f_p, anchor="lm")

    # ---- reset_sync's output: reset_s2_n, distributed to every block but undrawn
    # No stub: its fan-out really is undrawn, like clock's, so a caption is honester
    # than an arrow that stops in mid-air.
    mpr = BLOCKS["MPR"]
    ctext((mpr[0] + mpr[2]) / 2, mpr[3] + 22, "reset_s2_n, to every block", f_e)

    # ---- rx_bus_sync's output: on into the FSM, and branched down to rx_shift_reg
    rxy = dict(INPUTS)["rx_bus"]
    ry1 = BLOCKS["RX"][3]
    arrow([(BLOCKS["MP"][2], rxy), (fx0, rxy)], "r")
    dot(RXBUS_JUNCTION, rxy)
    arrow([(RXBUS_JUNCTION, rxy), (RXBUS_JUNCTION, RXBUS_BRANCH_Y),
           (RXBUS_BRANCH_X, RXBUS_BRANCH_Y), (RXBUS_BRANCH_X, LANE_RXBUS),
           (RISE_RXBUS, LANE_RXBUS), (RISE_RXBUS, ry1)], "u")
    ctext(RISE_RXBUS - 16, LANE_RXBUS - 4, "rx_bus_s2", f_e, anchor="rb")

    # ---- bit_timer.sample -> rx_shift_reg ----------------------------------
    btx0, bty0, bty1 = BLOCKS["BT"][0], BLOCKS["BT"][1], BLOCKS["BT"][3]
    bty = (bty0 + bty1) / 2
    arrow([(btx0, bty), (TRUNK_SAMPLE, bty), (TRUNK_SAMPLE, LANE_SAMPLE),
           (RISE_SAMPLE, LANE_SAMPLE), (RISE_SAMPLE, ry1)], "u")
    ctext(RISE_SAMPLE + 16, LANE_SAMPLE - 4, "sample", f_e, anchor="lb")

    # ---- notes -------------------------------------------------------------
    ny = BOX[3] + 40
    rect(BOX[0], ny, BOX[2], ny + 167, (252, 252, 252), radius=7)
    ctext(BOX[0] + 22, ny + 24, "Notes", f_nb, anchor="lm")
    for i, note in enumerate(NOTES):
        ctext(BOX[0] + 22, ny + 52 + i * 19, "•  " + note, f_n, anchor="lm")

    # Palettize before saving. This is flat fills plus antialiased text, so 256
    # colours is visually lossless and cuts the file to roughly a third.
    final = img.resize((W, H), Image.LANCZOS).quantize(colors=256, dither=Image.NONE)
    final.save(out, "PNG", optimize=True)
    print("wrote", out)


def check() -> None:
    """Guard the three details every hand-drawn attempt has got wrong."""
    pairs = {(a, b) for a, b, *_ in LINKS}
    assert ("FSM", "CRC") in pairs and ("CRC", "FSM") in pairs, "crc15 needs both directions"
    assert any(a == "CRC" and b == "FSM" and "crc, valid" in ls[0] for a, b, _, ls, _ in LINKS), \
        "crc15 returns 'valid' (its own port name), not 'crc_valid'"
    assert ("TX", "RX") not in pairs and ("RX", "TX") not in pairs, "shift regs never connect"
    for sr in ("TX", "RX"):
        assert (sr, "CRC") not in pairs and ("CRC", sr) not in pairs, "no shift reg touches crc15"
    assert any(a == "FSM" and b == "BT" and "resync" in ls[0] for a, b, _, ls, _ in LINKS), \
        "the bit_timer link carries resync as well as enable"


if __name__ == "__main__":
    check()
    main(sys.argv[1] if len(sys.argv) > 1 else "can_controller_diagram.png")
