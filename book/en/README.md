# The book, English edition
The course typeset as a book with LuaLaTeX: twenty chapters, one per session, and five appendices -
the two tool references from `info/`, the group project's specification, the two documents that form
the contract with the driver course, and a closing note on where to read next.

This edition is in English, and so are all the code, all the comments in the code and all the output
from tools and testbenches, exactly as in the course material. The Swedish edition is in
[`../sv/`](../sv/README.md) and is the same book, chapter for chapter and label for label: both
editions read the same worked examples out of `lectures/` and the same generated figures, so a
correction to either has to be made in both.

---

## Building it

```bash
sudo apt -y install make texlive-luatex texlive-latex-extra texlive-lang-european \
                    fonts-texgyre fonts-texgyre-math fonts-dejavu-core poppler-utils
make -C book/en                   # Writes book/en/programmable-logic.pdf, dated today.
make -C book/en VERSION=v1.2.3    # The same, with the release's version on the title page.
make -C book/en clean             # Removes book/en/build/ and the PDF.
make -C book                      # Builds both editions, Swedish and English.
```

The build runs LuaLaTeX twice, so that the contents and the cross-references settle, then prints the
overfull and underfull lines and the LaTeX warnings it found, and fails if a reference has been left
undefined. A clean build writes nothing after the two `lualatex` lines except a handful of mildly
underfull lines.

`texlive-lang-european` is not optional even here: `polyglossia` is loaded with Swedish as a second
language, for the title of the companion volume's Swedish edition, which stays in Swedish.

---

## What lives where

```text
book.tex                The book: half-title, twenty chapters in two parts, five appendices, in order.
vhdlbook.sty            Every visual decision: page, typography, colours, code blocks, exercises.
vhdlbook.lua            How \code{...} typesets inline VHDL (#, line breaks after :: and ,).
front/                  Title pages and preface.
chapters/NN/            Chapter NN: chapter.tex (the opening), one file per appendix in session LNN,
                        summary.tex (the review) and exercises.tex.
back/                   Appendix A-E: simulation, Quartus, the project, the protocol, further reading.
```

Every `.tex` file typeset from course material opens with a comment naming its source, for example:

```tex
% Section 19.1, from lectures/L19/appendix/a_system_verification.md.
```

---

## Updating the content
The course material is the source of truth, and the book follows it. **Two kinds of content behave
differently:**
* **The worked examples' code updates itself.** The book does not contain the code; it includes the
  files under `lectures/` directly (`\vhdlfile{lectures/...}`, `\cppfile{...}`), so a change to one
  of them is in the book at the next build, with nothing to edit here. The same goes for the figures,
  which are the course's own generated PNGs under `lectures/*/appendix/images/`, redrawn with
  `make diagrams` at the repository root.
* **The prose and the code snippets in the text do not.** A chapter's text is a typeset translation
  of the session's markdown. If you change an appendix, make the same change in the `.tex` file whose
  header names it - and in the Swedish edition's matching file.

A few conventions, so that an edit reads like the rest of the book:
* Code blocks: `vhdlcode`, `cppcode`, `shell`, `makecode` (makefiles; recipe lines keep their tab),
  `console` (output from tools and testbenches) and `textdrawing`/`widedrawing` (bit tables, trace
  tables, directory trees and anything else that has to keep its columns).
* Inline code: `\code{...}`, written exactly as in the source; `\file{...}` for paths and file names.
  `\code` is maths-safe, so `$\code{x} = 1$` works. Neither is robust in a moving argument, so a
  section heading uses `\code`, never `\file`.
* References: `\secref{c12:sec:bittimer}` becomes "section 12.2", `\chapref{c16:ch}` becomes
  "chapter 16", and `Exercise~\ref{c19:ex:node}` is an exercise (the book renumbers the exercises
  within every chapter, so always refer via the label).
* Exercises: `\exercise{Title}{Kind}` for an exercise, `\xpart{a}` for a part, `\task{Tasks}` for a
  heading inside one. The kind picks its own colour: VHDL, C++, Reasoning, Simulation, Circuit.
* Boxes: `aside` (a remark to the side), `warning` (a trap worth avoiding), `selfcheck` (self-check
  questions) and `chapterbox` ("In this chapter").
* A new appendix in a session is a new file in `chapters/NN/`, `\input` from that chapter's
  `chapter.tex`.

Every `\label` matches the Swedish edition's, so a cross-reference added in one edition can be
copied verbatim into the other.

The solutions to the exercises are not in the book. They stay in the course repository.

---

## Licence
The book is typeset from the course's own material, and its text is licensed under
[CC BY 4.0](../../LICENSE) like the rest of the course material. The code in the book, and all the
code in the course repository, may be used under the [MIT licence](../../LICENSE-CODE), and that
applies to this directory's build files too (`vhdlbook.sty`, `vhdlbook.lua`, `Makefile`).
