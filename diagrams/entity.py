"""What a module looks like from outside: its name, its ports, and its generics.

Kept separate from the drawing code so that anything needing the entities can import them
with a plain interpreter. `ci/entity_stub.py` does exactly that, which is what lets the
build check an exercise's testbench against the entity the figure and the exercise text
promise, without the CI job needing matplotlib or schemdraw.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Sequence


@dataclass(frozen=True)
class Port:
    """One port of an entity.

    `width` is the number of bits: 1 for a `std_logic`, more for a `std_logic_vector`. A
    vector whose width comes from a generic gives the range as a string instead, e.g.
    `Port("button_n", "COUNT-1:0")`. `label` overrides the drawn text for the rare port that
    is neither, and `bus` then says whether to draw it thick. `vhdl` gives the declared type
    outright, for the ports that are neither `std_logic` nor `std_logic_vector`.
    """

    name: str
    width: int | str = 1
    label: str | None = None
    bus: bool = False
    vhdl: str | None = None

    @property
    def is_bus(self) -> bool:
        """Whether to draw this port as a thick line: anything carrying more than one bit."""
        # A string width is a generic range, so its bit count is unknown here but never 1.
        return self.bus or isinstance(self.width, str) or self.width > 1

    @property
    def text(self) -> str:
        """The label drawn next to the port, e.g. `clk` or `counter[3:0]`."""
        # An explicit label wins outright; it exists for the ports that fit no pattern.
        if self.label is not None:
            return self.label

        # A generic range is already written "hi:0", so it goes in the brackets as it is.
        if isinstance(self.width, str):
            return f"{self.name}[{self.width}]"

        # Otherwise a single bit is bare, and a vector gets its range spelled out.
        return self.name if self.width == 1 else f"{self.name}[{self.width - 1}:0]"

    @property
    def vhdl_type(self) -> str:
        """The type this port is declared with, for a stub entity."""
        # Same order as `text`: explicit override, then generic range, then plain width.
        if self.vhdl is not None:
            return self.vhdl
        if isinstance(self.width, str):
            return f"std_logic_vector({self.width.replace(':', ' downto ')})"
        if self.width == 1:
            return "std_logic"
        return f"std_logic_vector({self.width - 1} downto 0)"


@dataclass(frozen=True)
class Entity:
    """A module's outside: its name, its ports in declaration order, and its generics."""

    name: str
    inputs: Sequence[Port]
    outputs: Sequence[Port]
    # (name, type, default). The default is written as VHDL, e.g. "1" or "'0'", and is what a
    # `generic map` omitting this generic would get. It is carried for the stub entity only:
    # the figures deliberately do not draw it, for the same reason they do not draw a range,
    # which is that it widens the box past every other module's.
    generics: Sequence[tuple[str, str, str]] = field(default=())

    @property
    def generic_lines(self) -> list[str]:
        """The generics as declaration text, one line each, for the strip inside the box."""
        return [f"{name}: {kind}" for name, kind, _ in self.generics]

    @property
    def generic_decls(self) -> list[str]:
        """The generics as VHDL declarations, defaults included, for a stub entity."""
        return [f"{name}: {kind} := {default}" for name, kind, default in self.generics]
