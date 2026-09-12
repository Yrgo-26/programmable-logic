#!/usr/bin/env python3
"""Draw the standard CAN frame format diagram (L10 Appendix A).

Regenerate with:  python3 standard_can_frame_format.py <output.png>
Everything is data-driven from FIELDS/BRACES below, so a spec change is a text edit.
"""
import sys

from PIL import Image, ImageDraw, ImageFont

Color = tuple[int, int, int]
# (name lines, size label, relative width, table description)
Field = tuple[list[str], str, float, str]

S: int = 3                               # supersample factor
W: int = 1500                            # final canvas width
H: int = 1200                            # final canvas height
X0: int = 40                             # left edge of the field row
Y0: int = 190                            # top edge of the field row
BH: int = 120                            # field box height
ROW_H: int = 56                          # table row height
TAB_Y: int = 470                         # top edge of the table
TAB_X: int = 90                          # left edge of the table
TAB_W: int = 1320                        # table width
COL_FIELD: int = 220                     # width of the Field column
COL_SIZE: int = 200                      # width of the Size column

FONT: str = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD: str = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

INK: Color = (26, 26, 26)
BLUE: Color = (31, 73, 156)
HEADER: Color = (31, 73, 156)
FILL: Color = (231, 240, 253)
WHITE: Color = (255, 255, 255)

FIELDS: list[Field] = [
    (["SOF"], "(1 bit)", 1.0, "Start of frame bit; synchronizes all nodes."),
    (["ID"], "(11 bits)", 2.0, "Base identifier; also determines arbitration priority."),
    (["RTR"], "(1 bit)", 1.0, "Remote Transmission Request; always dominant here."),
    (["IDE/r0"], "(2 bits)", 1.2, "Control bits: standard frame indicator and reserved bit."),
    (["DLC"], "(4 bits)", 1.2, "Data Length Code; indicates payload size in bytes."),
    (["Data"], "(0-64 bits)", 2.0, "Payload field; carries 0 to 8 data bytes."),
    (["CRC"], "(15 bits)", 1.6, "Cyclic Redundancy Check for error detection."),
    (["CRC", "delim"], "(1 bit)", 1.0, "Delimiter bit following the CRC field."),
    (["ACK", "slot"], "(1 bit)", 1.0, "Receivers acknowledge a valid frame here."),
    (["ACK", "delim"], "(1 bit)", 1.0, "Delimiter bit following the ACK slot."),
    (["EOF"], "(7 bits)", 1.0, "End of frame sequence."),
]

# (label, index of first field, index of last field), drawn under the field row
BRACES: list[tuple[str, int, int]] = [
    ("Arbitration field (12 bits)", 1, 2),
    ("Control field (6 bits)", 3, 4),
]

# Bit stuffing spans SOF through the CRC field (indices 0..6).
STUFF_LO: int = 0
STUFF_HI: int = 6


def main(out: str) -> None:
    img: Image.Image = Image.new("RGB", (W * S, H * S), "white")
    d: ImageDraw.ImageDraw = ImageDraw.Draw(img)
    f_title: ImageFont.FreeTypeFont = ImageFont.truetype(BOLD, 40 * S)
    f_name: ImageFont.FreeTypeFont = ImageFont.truetype(BOLD, 22 * S)
    f_size: ImageFont.FreeTypeFont = ImageFont.truetype(FONT, 17 * S)
    f_lab: ImageFont.FreeTypeFont = ImageFont.truetype(BOLD, 20 * S)
    f_cell: ImageFont.FreeTypeFont = ImageFont.truetype(FONT, 18 * S)
    f_cellb: ImageFont.FreeTypeFont = ImageFont.truetype(BOLD, 18 * S)

    def text(cx: float, cy: float, txt: str, font: ImageFont.FreeTypeFont,
             fill: Color = INK, anchor: str = "mm") -> None:
        d.text((cx * S, cy * S), txt, font=font, fill=fill, anchor=anchor)

    def line(pts: list[tuple[float, float]], width: int = 2, fill: Color = INK) -> None:
        d.line([(px * S, py * S) for px, py in pts], fill=fill, width=width * S)

    def head(px: float, py: float, size: int = 8) -> None:
        s = size * S
        d.polygon([(px * S, py * S), (px * S - s * 0.55, py * S - s),
                   (px * S + s * 0.55, py * S - s)], fill=BLUE)

    # ---- field boxes -------------------------------------------------------
    unit: float = (W - 2 * X0) / sum(w for _, _, w, _ in FIELDS)
    xs: list[float] = [X0]
    for _, _, w, _ in FIELDS:
        xs.append(xs[-1] + w * unit)
    for i, (names, size, _, _) in enumerate(FIELDS):
        x0, x1 = xs[i], xs[i + 1]
        d.rectangle([x0 * S, Y0 * S, x1 * S, (Y0 + BH) * S],
                    fill=FILL, outline=INK, width=2 * S)
        cx = (x0 + x1) / 2
        if len(names) == 1:
            text(cx, Y0 + BH / 2 - 14, names[0], f_name, BLUE)
        else:
            text(cx, Y0 + BH / 2 - 26, names[0], f_name, BLUE)
            text(cx, Y0 + BH / 2 - 2, names[1], f_name, BLUE)
        text(cx, Y0 + BH / 2 + 26, size, f_size)

    # ---- bit stuffing span -------------------------------------------------
    sx0, sx1 = xs[STUFF_LO], xs[STUFF_HI + 1]
    sy: float = Y0 - 55
    line([(sx0, Y0 - 10), (sx0, sy), (sx1, sy), (sx1, Y0 - 10)], width=2, fill=BLUE)
    head(sx0, Y0 - 10)
    head(sx1, Y0 - 10)
    text((sx0 + sx1) / 2, sy - 22, "Bit stuffing applies", f_lab, BLUE)

    # ---- braces under the row ----------------------------------------------
    for label, lo, hi in BRACES:
        bx0, bx1 = xs[lo] + 4, xs[hi + 1] - 4
        by: float = Y0 + BH + 26
        line([(bx0, by - 12), (bx0, by), (bx1, by), (bx1, by - 12)], width=2, fill=BLUE)
        text((bx0 + bx1) / 2, by + 22, label, f_lab, BLUE)

    # ---- title -------------------------------------------------------------
    text(W / 2, 70, "Standard CAN Frame Format", f_title)

    # ---- table -------------------------------------------------------------
    col_x: list[float] = [TAB_X, TAB_X + COL_FIELD, TAB_X + COL_FIELD + COL_SIZE,
                          TAB_X + TAB_W]
    y: float = TAB_Y
    d.rectangle([col_x[0] * S, y * S, col_x[3] * S, (y + ROW_H) * S], fill=HEADER)
    for cx, header in zip([(col_x[0] + col_x[1]) / 2, (col_x[1] + col_x[2]) / 2,
                           (col_x[2] + col_x[3]) / 2], ["Field", "Size", "Description"]):
        text(cx, y + ROW_H / 2, header, f_cellb, WHITE)
    y += ROW_H
    for names, size, _, desc in FIELDS:
        text((col_x[0] + col_x[1]) / 2, y + ROW_H / 2, " ".join(names), f_cellb, BLUE)
        text((col_x[1] + col_x[2]) / 2, y + ROW_H / 2,
             size.strip("()").replace("-", "–"), f_cell)
        text(col_x[2] + 18, y + ROW_H / 2, desc, f_cell, INK, anchor="lm")
        y += ROW_H
    for i in range(len(FIELDS) + 2):
        ly = TAB_Y + i * ROW_H
        line([(col_x[0], ly), (col_x[3], ly)], width=1)
    for cx in col_x:
        line([(cx, TAB_Y), (cx, y)], width=1)

    img = img.resize((W, H), Image.LANCZOS)
    img.save(out)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "standard_can_frame_format.png")
