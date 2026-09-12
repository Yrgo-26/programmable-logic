#!/usr/bin/env python3
"""Draw can_controller's transmit-path state machine (L16 Appendix A).

Regenerate with:  python3 fsm.py <output.png>
Everything is data-driven from STATES/EDGES below, so a spec change is a text edit.
"""
import sys
from typing import Any

from PIL import Image, ImageDraw, ImageFont

Color = tuple[int, int, int]
Point = tuple[float, float]
# (key, row, col, title, subtitle lines, fill)
State = tuple[str, int, int, str, list[str], Color]

S: int = 3                               # supersample factor
W: int = 1680                            # final canvas width
H: int = 1150                            # final canvas height
BW: int = 235                            # box width
BH: int = 96                             # box height
GX: int = 32                             # horizontal gap
GY: int = 126                            # vertical gap
X0: int = 64                             # top-left of the grid, x
Y0: int = 132                            # top-left of the grid, y

# Explicit routing lanes (y), so no two long links share a corridor.
L_NEXT: int = 24
L_LOSS: int = 66
L_R1WRAP: int = 268
L_YES: int = 314
L_R2WRAP: int = 484
L_DLC0: int = 524
L_R3WRAP: int = 712

FONT: str = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD: str = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

INK: Color = (26, 26, 26)
GREY: Color = (238, 238, 238)
BLUE: Color = (207, 226, 243)
GREEN: Color = (217, 234, 211)
PURPLE: Color = (217, 210, 233)
RED: Color = (244, 204, 204)
YELLOW: Color = (255, 242, 204)

STATES: list[State] = [
    ("IDLE",      0, 0, "STATE_IDLE",         ["waiting for bus idle"],        GREY),
    ("START",     0, 1, "STATE_START",        ["latch role,",
                                            "init counters"],              GREY),
    ("SOF",       0, 2, "STATE_SOF",          ["send SOF = 0"],                GREY),
    ("LARBHI",    0, 3, "STATE_LOAD_ARB_HI",  ["load ID[10:3]"],               BLUE),
    ("ARBHI",     0, 4, "STATE_ARB_HI",       ["shift 8 bits"],                BLUE),
    ("LARBLO",    0, 5, "STATE_LOAD_ARB_LO",  ["load ID[2:0] + RTR"],          BLUE),

    ("ARBLO",     1, 0, "STATE_ARB_LO",       ["shift 4 bits"],                BLUE),
    ("LCTRL",     1, 1, "STATE_LOAD_CTRL",    ["load IDE + r0 + DLC"],         GREEN),
    ("CTRL",      1, 2, "STATE_CTRL",         ["shift 6 bits"],                GREEN),
    ("LDATA",     1, 3, "STATE_LOAD_DATA",    ["load next data byte"],         PURPLE),
    ("DATA",      1, 4, "STATE_DATA",         ["shift 8 bits"],                PURPLE),

    ("CRCWAIT",   2, 0, "STATE_CRC_WAIT",     ["wait 1 clock cycle"],          RED),
    ("LCRCHI",    2, 1, "STATE_LOAD_CRC_HI",  ["load CRC[14:7]"],              RED),
    ("CRCHI",     2, 2, "STATE_CRC_HI",       ["shift 8 bits"],                RED),
    ("LCRCLO",    2, 3, "STATE_LOAD_CRC_LO",  ["load CRC[6:0]"],               RED),
    ("CRCLO",     2, 4, "STATE_CRC_LO",       ["shift 7 bits"],                RED),
    ("CRCLOW",    2, 5, "STATE_CRC_LO_WAIT",  ["wait 1 clock cycle"],          RED),

    ("DELIM",     3, 0, "STATE_CRC_DELIM",    ["send recessive = 1"],          YELLOW),
    ("ACKSLOT",   3, 1, "STATE_ACK_SLOT",     ["release the bus"],             YELLOW),
    ("ACKDELIM",  3, 2, "STATE_ACK_DELIM",    ["send recessive = 1"],          YELLOW),
    ("EOF",       3, 3, "STATE_EOF",          ["send 7 recessive bits"],       YELLOW),
]

# (key, row, col, first line, second line)
DIAMOND: tuple[str, int, int, str, str] = ("MORE", 1, 5, "More data", "bytes?")

LEGEND: list[tuple[str, Color]] = [
    ("Idle / Start", GREY), ("Arbitration (ID + RTR)", BLUE), ("Control (DLC)", GREEN),
    ("Data field", PURPLE), ("CRC generate & send", RED), ("ACK & EOF", YELLOW)]

NOTES: list[str] = [
    "STATE_LOAD_* states pulse tx_shift_reg.load for one cycle; no shift pulse.",
    "Shifting states advance on tx_shift_reg.done; bit stuffing is handled inside tx_shift_reg.",
    "The arbitration field (ID + RTR) is monitored bit by bit in STATE_ARB_HI and STATE_ARB_LO; losing arbitration raises error.",
    "Node role (TX/RX) is latched in STATE_START and held until STATE_EOF completes.",
    "crc15 is cleared in STATE_START, then returned to zero by feeding the CRC field back through it.",
]


def box(key: str) -> tuple[int, int]:
    """Return the top-left corner of the state (or diamond) with this key."""
    for k, r, c, *_ in STATES:
        if k == key:
            return X0 + c * (BW + GX), Y0 + r * (BH + GY)
    k, r, c, _, _ = DIAMOND
    if key == k:
        return X0 + c * (BW + GX), Y0 + r * (BH + GY)
    raise KeyError(key)


def edges(key: str) -> dict[str, Any]:
    """Return this box's four edge midpoints, plus its top-left corner."""
    x, y = box(key)
    return {"l": (x, y + BH // 2), "r": (x + BW, y + BH // 2),
            "t": (x + BW // 2, y), "b": (x + BW // 2, y + BH),
            "x": x, "y": y}


def main(out: str) -> None:
    img: Image.Image = Image.new("RGB", (W * S, H * S), "white")
    d: ImageDraw.ImageDraw = ImageDraw.Draw(img)
    f_t: ImageFont.FreeTypeFont = ImageFont.truetype(BOLD, 17 * S)
    f_s: ImageFont.FreeTypeFont = ImageFont.truetype(FONT, 15 * S)
    f_e: ImageFont.FreeTypeFont = ImageFont.truetype(FONT, 15 * S)
    f_n: ImageFont.FreeTypeFont = ImageFont.truetype(FONT, 15 * S)
    f_nb: ImageFont.FreeTypeFont = ImageFont.truetype(BOLD, 16 * S)

    def rect(x: float, y: float, w: float, h: float, fill: Color) -> None:
        d.rounded_rectangle([x * S, y * S, (x + w) * S, (y + h) * S],
                            radius=7 * S, fill=fill, outline=INK, width=2 * S)

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

    # ---- boxes -------------------------------------------------------------
    for k, r, c, title, subs, fill in STATES:
        x, y = box(k)
        rect(x, y, BW, BH, fill)
        if len(subs) == 1:
            ctext(x + BW / 2, y + BH / 2 - 11, title, f_t)
            ctext(x + BW / 2, y + BH / 2 + 15, subs[0], f_s)
        else:
            ctext(x + BW / 2, y + BH / 2 - 20, title, f_t)
            ctext(x + BW / 2, y + BH / 2 + 6, subs[0], f_s)
            ctext(x + BW / 2, y + BH / 2 + 27, subs[1], f_s)

    dk, dr, dc, d1, d2 = DIAMOND
    dx, dy = box(dk)
    cx, cy = dx + BW / 2, dy + BH / 2
    d.polygon([(cx * S, (dy - 12) * S), ((dx + BW) * S, cy * S),
               (cx * S, (dy + BH + 12) * S), (dx * S, cy * S)],
              fill="white", outline=INK, width=2 * S)
    ctext(cx, cy - 11, d1, f_s)
    ctext(cx, cy + 10, d2, f_s)

    # ---- straight in-row links --------------------------------------------
    for a, b in [("IDLE", "START"), ("START", "SOF"), ("SOF", "LARBHI"),
                 ("LARBHI", "ARBHI"), ("ARBHI", "LARBLO"),
                 ("ARBLO", "LCTRL"), ("LCTRL", "CTRL"), ("CTRL", "LDATA"),
                 ("LDATA", "DATA"), ("DATA", "MORE"),
                 ("CRCWAIT", "LCRCHI"), ("LCRCHI", "CRCHI"), ("CRCHI", "LCRCLO"),
                 ("LCRCLO", "CRCLO"), ("CRCLO", "CRCLOW"),
                 ("DELIM", "ACKSLOT"), ("ACKSLOT", "ACKDELIM"), ("ACKDELIM", "EOF")]:
        arrow([edges(a)["r"], edges(b)["l"]], "r")
    ei = edges("IDLE")
    ctext((ei["r"][0] + edges("START")["l"][0]) / 2, Y0 - 15, "bus idle & tx_req", f_e)

    # ---- row wraps ---------------------------------------------------------
    def wrap(a: str, b: str, lane: int, dx: int = 0,
             label: str | None = None, lx: float = 0) -> None:
        ea, eb = edges(a), edges(b)
        tx = eb["t"][0] + dx
        arrow([ea["b"], (ea["b"][0], lane), (tx, lane), (tx, eb["t"][1])], "d")
        if label:
            ctext(lx, lane - 15, label, f_e)

    wrap("LARBLO", "ARBLO", L_R1WRAP, dx=-50)
    wrap("MORE", "CRCWAIT", L_R2WRAP, dx=45, label="No",
         lx=edges("MORE")["b"][0] - 26)
    wrap("CRCLOW", "DELIM", L_R3WRAP)

    # ---- decision loop back to STATE_LOAD_DATA --------------------------------
    em, el = edges("MORE"), edges("LDATA")
    arrow([(em["t"][0], em["t"][1] - 12), (em["t"][0], L_YES),
           (el["t"][0], L_YES), el["t"]], "d")
    ctext((em["t"][0] + el["t"][0]) / 2, L_YES - 15, "Yes, next data byte", f_e)

    # ---- DLC = 0 shortcut, STATE_CTRL -> STATE_CRC_WAIT (dashed) -----------------
    ec, ew = edges("CTRL"), edges("CRCWAIT")
    tx = ew["t"][0] - 45
    d.line([(ec["b"][0] * S, ec["b"][1] * S), (ec["b"][0] * S, L_DLC0 * S)],
           fill=INK, width=2 * S)
    x = ec["b"][0]
    while x > tx:                                     # dashed run leftwards
        d.line([(x * S, L_DLC0 * S), (max(x - 10, tx) * S, L_DLC0 * S)],
               fill=INK, width=2 * S)
        x -= 18
    arrow([(tx, L_DLC0), (tx, ew["t"][1])], "d")
    ctext(ec["b"][0] - 92, L_DLC0 - 15, "DLC = 0", f_e)

    # ---- arbitration loss -> STATE_IDLE ---------------------------------------
    eh, ea2 = edges("ARBHI"), edges("ARBLO")
    arrow([eh["t"], (eh["t"][0], L_LOSS), (ei["t"][0] + 48, L_LOSS),
           (ei["t"][0] + 48, ei["t"][1])], "d")
    arrow([(ea2["t"][0] + 50, ea2["t"][1]), (ea2["t"][0] + 50, ei["b"][1])], "u")
    ctext((eh["t"][0] + ei["t"][0]) / 2 + 40, L_LOSS - 15,
          "arbitration lost: raise error, stop driving", f_e)

    # ---- next frame, STATE_EOF -> STATE_IDLE ------------------------------------
    ee = edges("EOF")
    backx = X0 + 5 * (BW + GX) + BW + 34
    arrow([ee["r"], (backx, ee["r"][1]), (backx, L_NEXT), (ei["t"][0] - 48, L_NEXT),
           (ei["t"][0] - 48, ei["t"][1])], "d")
    ctext(backx - 340, L_NEXT - 15, "next frame", f_e)

    # ---- reset in, and the bus-busy self loop ------------------------------
    arrow([(ei["t"][0], Y0 - 40), (ei["t"][0], ei["t"][1])], "d")
    ctext(ei["t"][0] + 12, Y0 - 30, "reset", f_e, anchor="lm")
    loopy = ei["b"][1] + 24                       # own lane, clear of L_R1WRAP
    arrow([(ei["x"], ei["l"][1] + 24), (ei["x"] - 34, ei["l"][1] + 24),
           (ei["x"] - 34, loopy), (ei["x"] + 40, loopy),
           (ei["x"] + 40, ei["b"][1])], "u")
    ctext(ei["x"] + 56, loopy, "bus busy", f_e, anchor="lm")

    # ---- legend + notes ----------------------------------------------------
    ly = Y0 + 3 * (BH + GY) + BH + 74
    rect(X0, ly, 470, 178, (252, 252, 252))
    ctext(X0 + 20, ly + 22, "Legend", f_nb, anchor="lm")
    for i, (label, fill) in enumerate(LEGEND):
        yy = ly + 52 + i * 22
        d.rounded_rectangle([(X0 + 22) * S, (yy - 8) * S, (X0 + 52) * S, (yy + 8) * S],
                            radius=3 * S, fill=fill, outline=INK, width=2 * S)
        ctext(X0 + 64, yy, label, f_n, anchor="lm")

    nx = X0 + 512
    ctext(nx, ly + 22, "Notes", f_nb, anchor="lm")
    for i, note in enumerate(NOTES):
        ctext(nx, ly + 52 + i * 24, "•  " + note, f_n, anchor="lm")

    final = img.resize((W, H), Image.LANCZOS).quantize(colors=256, dither=Image.NONE)
    final.save(out, "PNG", optimize=True)
    print("wrote", out)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "fsm.png")
