# Boken, svenska upplagan
Kursen satt som bok med LuaLaTeX: tjugo kapitel, ett per pass, och fem bilagor - de två
verktygsreferenserna ur `info/`, grupprojektets specifikation, de två dokument som utgör kontraktet
mot drivrutinskursen, och en avslutande not om vad man läser härnäst.

Den här upplagan är på svenska. All kod, alla kommentarer i koden och all utskrift från verktyg och
testbänkar är på engelska, precis som i kursmaterialet. Den engelska upplagan ligger i
[`../en/`](../en/README.md) och är samma bok, kapitel för kapitel och etikett för etikett.

---

## Att bygga den

```bash
sudo apt -y install make texlive-luatex texlive-latex-extra texlive-lang-european \
                    fonts-texgyre fonts-texgyre-math fonts-dejavu-core poppler-utils
make -C book/sv                   # Skriver book/sv/programmerbar-logik.pdf, daterad i dag.
make -C book/sv VERSION=v1.2.3    # Detsamma, med versionen på titelsidan.
make -C book/sv clean             # Tar bort book/sv/build/ och PDF:en.
make -C book                      # Bygger båda upplagorna, svenska och engelska.
```

Bygget kör LuaLaTeX två gånger, så att innehållsförteckningen och korsreferenserna sätter sig,
skriver sedan ut de överfulla och underfulla raderna och de LaTeX-varningar det hittade, och
fallerar om en referens lämnats odefinierad. Ett rent bygge skriver ingenting efter de två
`lualatex`-raderna utom en handfull milt underfulla rader.

`texlive-lang-european` är inte valfri: den bär `polyglossia`s svenska stöd, som ger "Kapitel",
"Bilaga", "Innehåll" och den svenska avstavningen.

---

## Vad som ligger var

```text
book.tex                Boken: förtitel, tjugo kapitel i två delar, fem bilagor, i ordning.
vhdlbook.sty            Varje visuellt beslut: sida, typografi, färger, kodblock, övningar.
vhdlbook.lua            Hur \code{...} sätter inline-VHDL (#, radbrytningar efter :: och ,).
front/                  Titelsidor och förord.
chapters/NN/            Kapitel NN: chapter.tex (öppningen), en fil per appendix i pass LNN,
                        summary.tex (repetitionen) och exercises.tex.
back/                   Bilaga A-E: simulering, Quartus, projektet, protokollet, vidare läsning.
```

Varje `.tex`-fil som är satt ur kursmaterial börjar med en kommentar som namnger sin källa, till
exempel:

```tex
% Avsnitt 19.1, ur lectures/L19/appendix/a_system_verification.md.
```

---

## Att uppdatera innehållet
Kursmaterialet är sanningskällan, och boken följer det. **Två sorters innehåll beter sig olika:**
* **De genomarbetade exemplens kod uppdaterar sig själv.** Boken innehåller inte koden; den
  inkluderar filerna under `lectures/` direkt (`\vhdlfile{lectures/...}`, `\cppfile{...}`), så en
  ändring i en av dem är i boken vid nästa bygge, utan något att redigera här. Detsamma gäller
  figurerna, som är kursens egna genererade PNG:er under `lectures/*/appendix/images/`, ritade om
  med `make diagrams` i repots rot.
* **Prosa och kodsnuttarna i texten gör det inte.** Ett kapitels text är en satt översättning av
  passets markdown. Ändrar du ett appendix, gör samma ändring i den `.tex`-fil vars huvud namnger
  det.

Några konventioner, så att en redigering läser som resten av boken:
* Kodblock: `vhdlcode`, `cppcode`, `shell`, `makecode` (Makefiler; receptrader behåller sin tabb),
  `console` (utskrift från verktyg och testbänkar) och `textdrawing`/`widedrawing` (bittabeller,
  trace-tabeller, katalogträd och annat som måste behålla sina kolumner).
* Inline-kod: `\code{...}`, skrivet exakt som i källan; `\file{...}` för sökvägar och filnamn.
  `\code` är matematiksäker, så `$\code{x} = 1$` fungerar.
* Referenser: `\secref{c12:sec:bittimer}` blir "avsnitt 12.2", `\chapref{c16:ch}` blir
  "kapitel 16", och `Övning~\ref{c19:ex:node}` är en övning (boken numrerar om övningarna inom
  varje kapitel, så hänvisa alltid via etikett).
* Övningar: `\exercise{Titel}{Sort}` för en övning, `\xpart{a}` för en del, `\task{Uppgifter}` för
  en rubrik inuti en. Sorten väljer själv sin färg: VHDL, C++, Resonemang, Simulering, Krets.
* Rutor: `aside` (en sidoanmärkning), `warning` (en fälla värd att undvika), `selfcheck`
  (kontrollfrågor) och `chapterbox` ("I det här kapitlet").
* Ett nytt appendix i ett pass är en ny fil i `chapters/NN/`, `\input`:ad från det kapitlets
  `chapter.tex`.

Lösningarna till övningarna står inte i boken. De ligger kvar i kursrepot.

---

## Licens
Boken är satt ur kursens eget material, och dess text är licensierad under
[CC BY 4.0](../../LICENSE) precis som resten av kursmaterialet. Koden i boken, och all kod i
kursrepot, får användas under [MIT-licensen](../../LICENSE-CODE), och det gäller också den här
katalogens byggfiler (`vhdlbook.sty`, `vhdlbook.lua`, `Makefile`).
