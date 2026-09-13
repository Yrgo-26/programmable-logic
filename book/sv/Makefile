# Build the book: two LuaLaTeX passes, the second for the contents and the references.
#
#   make                   build programmerbar-logik.pdf, dated today
#   make VERSION=v1.2.3    the same, with the release's version on the title page
#   make clean             remove everything the build writes
#
# The English edition is in ../en and builds the same way. The worked examples in the chapters are
# typeset straight from their files under lectures/, so a change to one of those is a change to the
# book on the next build. The figures are the course's own generated PNGs under
# lectures/*/appendix/images/, redrawn with `make diagrams` at the repository root, so a redrawn
# figure needs no edit here either.

ROOT    := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../..)
BOOK    := $(ROOT)/book/sv
BUILD   := $(BOOK)/build
VERSION ?=
LATEX   := lualatex -interaction=nonstopmode -halt-on-error -file-line-error \
           -output-directory=$(BUILD)
# The book, with its version defined before anything is read; -jobname keeps the output book.pdf.
BOOKTEX := $(LATEX) -jobname=book '\def\bookversion{$(VERSION)}\input{book.tex}'

SOURCES := book.tex vhdlbook.sty vhdlbook.lua \
           $(wildcard front/*.tex chapters/*/*.tex back/*.tex figures/*.tex)
CODE    := $(shell cd $(ROOT) && git ls-files 'lectures/*.vhd' 'lectures/*.png' \
             'lectures/*.cpp' 'lectures/*.hpp' | sed 's|^|$(ROOT)/|')

.PHONY: all clean FORCE

all: programmerbar-logik.pdf

# The version the last build was made for. The file is rewritten only when VERSION changes, so a
# new version, or none after one, rebuilds the title page and nothing else does.
$(BUILD)/version: FORCE
	@mkdir -p $(BUILD)
	@echo '$(VERSION)' | cmp -s - $@ || echo '$(VERSION)' > $@

programmerbar-logik.pdf: $(SOURCES) $(CODE) $(BUILD)/version
	@mkdir -p $(BUILD)
	cd $(BOOK) && $(BOOKTEX) >/dev/null || (tail -40 $(BUILD)/book.log; exit 1)
	cd $(BOOK) && $(BOOKTEX) >/dev/null || (tail -40 $(BUILD)/book.log; exit 1)
	@grep -E "^(Overfull|Underfull)|Warning" $(BUILD)/book.log | sort | uniq -c | sort -rn | head -20 || true
	@! grep -q "There were undefined references" $(BUILD)/book.log || \
	    (echo "error: undefined references; see $(BUILD)/book.log"; exit 1)
	cp $(BUILD)/book.pdf $@

clean:
	rm -rf $(BUILD) programmerbar-logik.pdf
