#!/usr/bin/env python3
"""Draw can_demo, the optional DE0-CV debug wrapper (L19 Appendix B).

This is not the project's top level - that is can_spi_node, and the group writes it in L19.
This wrapper is the buttons-and-LEDs alternative Appendix B offers for debugging a board when
the SPI link itself is what is not working.

Regenerate with:  python3 can_demo.py <output.png>
Data-driven from CHAINS/OUTPUTS below, so a spec change is a text edit.

The three details that must stay true, asserted by check() at the bottom of this file:
  * neither rx_bus nor reset_n is synchronized here; can_controller does both itself (L12).
  * KEY(1) is synchronized, then debounced, then edge-detected, in that order.
  * meta_prev appears twice, at WIDTH 1 and 10.
"""
import sys

from PIL import Image, ImageDraw, ImageFont

Color = tuple[int, int, int]
Fill = Color | str
Point = tuple[float, float]
Bounds = tuple[int, int, int, int]
# (title, subtitle, fill)
Stage = tuple[str, str, Color]
# (port label, y, stages, signal name into can_controller)
Chain = tuple[str, int, list[Stage], str]
# (signal name, y, pin label)
Output = tuple[str, int, str]

S: int = 3                               # supersample factor
W: int = 1760                            # final canvas width
H: int = 1200                            # final canvas height

FONT: str = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD: str = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

INK: Color = (26, 26, 26)
GREY: Color = (238, 238, 238)
BLUE: Color = (207, 226, 243)
GREEN: Color = (217, 234, 211)
YELLOW: Color = (255, 242, 204)

BOX: Bounds = (200, 60, 1520, 1010)      # the can_demo boundary
CTRL: Bounds = (1060, 130, 1330, 960)    # the can_controller instance

BW: int = 180                            # standard small-block width
BH: int = 74                             # standard small-block height

CHAINS: list[Chain] = [
    ("CLOCK_50", 190, [], "clock"),
    ("KEY(1)", 330, [("meta_prev", "WIDTH = 1", GREY),
                     ("debounce", "~10 ms", BLUE),
                     ("edge detect", "one press, one pulse", BLUE)], "tx_req"),
    ("KEY(0)", 490, [], "reset_n"),
    ("SW(9:0)", 640, [("meta_prev", "WIDTH = 10", GREY)], "tx_id(9:0)"),
    ("GPIO_0(2)", 790, [], "rx_bus"),
    ("", 920, [("constants", "tx_dlc = 2, tx_data", GREEN)], "tx_dlc, tx_data"),
]

OUTPUTS: list[Output] = [("tx_bus, bus_en", 300, "GPIO_0(1:0)"),
                         ("tx_done, rx_valid, error", 780, "LEDR(2:0)")]

NOTES: list[str] = [
    "meta_prev (L04) appears twice here, at WIDTH 1 and 10. One module, no copies.",
    "reset_n and rx_bus are deliberately NOT synchronized here: can_controller does both itself.",
    "KEY(1): synchronize, then debounce, then edge-detect. Both orderings matter.",
    "tx_id(10) is tied to '0', so the ten switches set the low bits of an 11-bit identifier.",
    "tx_done and rx_valid are latched onto LEDR(0) and LEDR(1); error is already a level.",
]


def main(out: str) -> None:
    img: Image.Image = Image.new("RGB", (W * S, H * S), "white")
    d: ImageDraw.ImageDraw = ImageDraw.Draw(img)
    f_t: ImageFont.FreeTypeFont = ImageFont.truetype(BOLD, 19 * S)
    f_ct: ImageFont.FreeTypeFont = ImageFont.truetype(BOLD, 22 * S)
    f_s: ImageFont.FreeTypeFont = ImageFont.truetype(FONT, 14 * S)
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

    def head(p: Point, size: int = 9) -> None:
        px, py = p[0] * S, p[1] * S
        s = size * S
        d.polygon([(px, py), (px - s, py - s * 0.55), (px - s, py + s * 0.55)], fill=INK)

    def arrow(x0: float, x1: float, y: float) -> None:
        d.line([(x0 * S, y * S), (x1 * S, y * S)], fill=INK, width=2 * S)
        head((x1, y))

    # ---- boundary and the controller ---------------------------------------
    rect(*BOX, fill="white", radius=10, width=3)
    ctext(BOX[0] + 24, BOX[1] + 34, "can_demo", f_ct, anchor="lm")
    ctext(BOX[0] + 24, BOX[1] + 62, "DE0-CV board wrapper", f_s, anchor="lm")

    rect(*CTRL, fill=YELLOW)
    ctext((CTRL[0] + CTRL[2]) / 2, CTRL[1] + 34, "can_controller", f_ct)

    # ---- chains ------------------------------------------------------------
    for port, y, stages, sig in CHAINS:
        x: float = 300
        if port:
            ctext(BOX[0] - 30, y, port, f_p, anchor="rm")
            arrow(BOX[0] - 20, x if stages else CTRL[0], y)
        for i, (title, sub, fill) in enumerate(stages):
            rect(x, y - BH / 2, x + BW, y + BH / 2, fill)
            ctext(x + BW / 2, y - 11, title, f_t)
            ctext(x + BW / 2, y + 13, sub, f_s)
            nxt = x + BW + 60 if i < len(stages) - 1 else CTRL[0]
            arrow(x + BW, nxt, y)
            x += BW + 60
        ctext(CTRL[0] - 16, y - 15, sig, f_e, anchor="rm")

    # ---- outputs -----------------------------------------------------------
    for sig, y, pins in OUTPUTS:
        arrow(CTRL[2], BOX[2] + 90, y)
        ctext((CTRL[2] + BOX[2]) / 2, y - 15, sig, f_e)
        ctext(BOX[2] + 102, y, pins, f_p, anchor="lm")

    # ---- notes -------------------------------------------------------------
    ny = BOX[3] + 40
    rect(BOX[0], ny, BOX[2], ny + 146, (252, 252, 252), radius=7)
    ctext(BOX[0] + 22, ny + 24, "Notes", f_nb, anchor="lm")
    for i, note in enumerate(NOTES):
        ctext(BOX[0] + 22, ny + 50 + i * 19, "•  " + note, f_n, anchor="lm")

    # Palettize before saving. This is flat fills plus antialiased text, so 256
    # colours is visually lossless and cuts the file to roughly a third.
    final = img.resize((W, H), Image.LANCZOS).quantize(colors=256, dither=Image.NONE)
    final.save(out, "PNG", optimize=True)
    print("wrote", out)


def check() -> None:
    """Guard what this wrapper must and must not synchronize."""
    chain: dict[str, Chain] = {c[0]: c for c in CHAINS}
    assert chain["GPIO_0(2)"][2] == [], "rx_bus must not be synchronized in can_demo"
    assert chain["KEY(0)"][2] == [], "reset_n must not be synchronized in can_demo"
    key1 = [stage[0] for stage in chain["KEY(1)"][2]]
    assert key1 == ["meta_prev", "debounce", "edge detect"], "KEY(1) order is sync, debounce, edge"
    widths = [stage[1] for c in CHAINS for stage in c[2] if stage[0] == "meta_prev"]
    assert widths == ["WIDTH = 1", "WIDTH = 10"], "two meta_prev instances"


if __name__ == "__main__":
    check()
    main(sys.argv[1] if len(sys.argv) > 1 else "can_demo.png")
