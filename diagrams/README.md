# Diagrams

The lecture figures under `lectures/*/appendix/images/` used to be hand-assembled from
Quartus RTL Viewer screenshots. The ones listed in `build.py` are now drawn from code, so
changing a port name or a gate is an edit and a rebuild rather than a redraw.

The generated PNGs stay committed. GitHub renders the lectures straight from the repo, so
nothing here runs in CI; this is an authoring tool you run when a figure changes.

## Setup

```bash
python3 -m venv .venv
.venv/bin/pip install -r diagrams/requirements.txt
```

## Rebuilding

```bash
make diagrams                                  # every figure, into the lecture trees
.venv/bin/python diagrams/build.py --list      # what can be built
.venv/bin/python diagrams/build.py or_gate_arch
.venv/bin/python diagrams/build.py --outdir /tmp/preview   # look before overwriting
```

`--outdir` writes `<figure>.png` flat into a directory of your choice and leaves the repo
untouched, which is the sane way to iterate on a figure.

## Layout

| File | What it holds |
| --- | --- |
| `style.py` | Every color, line weight, font, and the output scale. Restyling all figures is one edit here. |
| `module_box.py` | Draws any module from its entity alone: boundary, ports, generics. |
| `entity.py` | The `Entity`/`Port` types the other modules describe a module with. |
| `exercises.py` | The entity of every exercise module a student is asked to write. |
| `or_gate.py` | The `or_gate` entity/architecture/module figures. |
| `kmap.py` | L02 A.1's worked Karnaugh map, as three frames of one grid. |
| `counter.py` | The counter and timer circuit figures for L06 and L07. |
| `waveform.py` | The timing diagrams: setup/hold, the synchronizer, the flip-flop, and the UART frame. |
| `build.py` | Figure name to figure plus output paths, and the command line. |

## Adding an exercise module

Add an `Entity` to `exercises.py` and list it under its lecture in `BY_LECTURE`. `build.py`
picks it up automatically and writes `lectures/<lecture>/appendix/images/<name>.png`. Embed
that in the exercise just above its **Self-check** paragraph, copying the line already there
in the neighbouring exercises: a Markdown image with alt text ``Module `<name>` `` pointing
at `./images/<name>.png`. (Spelled out rather than shown, because `ci/links.sh` checks the
links in this file too and would try to resolve the placeholder.)

Ports go in **declaration order**, since the testbenches instantiate by position. Every
entity has to match two things that already agree: the "Self-check" line in the lecture's
`b_exercises.md`, and the `port map` in the exercise's testbench.

```python
UART_TX8 = Entity(
    "uart_tx8",
    [P("clock"), P("reset_n"), P("data_in", 8), P("send")],   # P(name, width)
    [P("tx"), P("busy")],
    generics=[("BIT_TICK_COUNT", "natural")],
)
```

A port's width is its bit count: 1 draws a thin `std_logic` line labeled with the name, more
draws a thick line labeled `name[hi:0]`. A port that is neither takes a `label` override and
`bus=` to say how thick to draw it; `counter`'s `natural` output is the only one.

## Adding a figure of another kind

1. Write a builder in a module next to `build.py`. It takes `(drawing, ax)`: a
   `schemdraw.Drawing` for the schematic, and the matplotlib axes, which `style.text` and
   `style.title` use for labels. Wrap it in a `style.Figure` with the canvas it needs.
2. Put the figure's geometry in named constants at the top of the module, the way
   `or_gate.py` does. That is what makes a figure cheap to adjust later.
3. Add an entry to `FIGURES` in `build.py` listing every path the figure is written to. A
   figure embedded by more than one lecture gets more than one path, and writing all the
   copies from one source is what keeps them identical.

## Compressing a hand-made export

Figures built here are already palette PNGs. A screenshot exported from CircuitVerse is not, and is
usually several times larger than it needs to be. This is visually lossless on line art:

```bash
.venv/bin/python -c "
from PIL import Image
import numpy as np
p = 'path/to/image.png'
im = Image.open(p).convert('RGB')
a = np.asarray(im).astype(np.int16)
if np.mean((a.max(2) - a.min(2)) > 12) < 0.001:   # greyscale line art
    g = np.asarray(im.convert('L')).copy()
    g[g >= 248] = 255                             # snap noisy background to true white
    im = Image.fromarray(g)
im.quantize(colors=256).save(p, 'PNG', optimize=True)"
```

The background snap is what does the work. An exported near-white background is often *noisy*
rather than uniform, and noise is incompressible: PNG cannot help until the pixels are actually
equal. On `fsm_state_diagram.png` that was the difference between 535 KB and 103 KB.

Never run it on a figure this directory generates. Those are already quantized, and re-encoding
them breaks the byte-identical rebuild the CI job checks. Regenerate instead.

## Notes

* A figure declares the canvas it is drawn onto rather than being cropped to its contents.
  The three `or_gate` figures share one canvas on purpose, because they are read one after
  another in the text and auto-cropping would make the empty entity box a different size
  from the box with a gate in it. Module boxes size their own canvas, but always at the same
  units-per-inch, so a label in a tall box is exactly as big as one in a short box.
* Figures are written as palette PNGs (`style.PALETTE_COLORS`), not RGBA. Line art on white
  uses a few hundred colors at most, so this costs nothing visually and roughly halves what
  gets committed. Median cut is deterministic, so a rebuild stays byte-identical.
* The figures are black on white, which is hard to read in GitHub's dark theme. So is every
  other image in this repo. If that ever needs fixing, it is a change to the colors in
  `style.py`.
