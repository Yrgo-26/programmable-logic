# Boken
Kursen satt som bok med LuaLaTeX, i två upplagor med samma innehåll:

```text
sv/    Svenska upplagan, programmerbar-logik.pdf
en/    Engelska upplagan, programmable-logic.pdf
```

Upplagorna är samma bok, kapitel för kapitel och etikett för etikett: tjugo kapitel, ett per pass,
och fem bilagor. Båda sätts ur samma kursmaterial - de genomarbetade exemplen under `lectures/`
inkluderas direkt i båda, och figurerna är samma genererade PNG:er - så en rättelse i prosan behöver
göras i båda, medan en ändring i koden eller en figur slår igenom i båda vid nästa bygge.

All kod, alla kommentarer i koden och all utskrift från verktyg och testbänkar är på engelska i båda
upplagorna, precis som i kursmaterialet.

---

## Att bygga

```bash
sudo apt -y install make texlive-luatex texlive-latex-extra texlive-lang-european \
                    fonts-texgyre fonts-texgyre-math fonts-dejavu-core poppler-utils
make -C book                   # Bygger båda upplagorna.
make -C book sv                # Bara den svenska.
make -C book en                # Bara den engelska.
make -C book VERSION=v1.2.3    # Med versionen på titelsidan.
make -C book clean             # Tar bort build-katalogerna och PDF:erna.
```

Varje upplaga har en egen Makefile och byggs på samma sätt; den här katalogens Makefile skickar bara
vidare arbetet.

Detaljerna står i upplagornas egna README: [`sv/`](./sv/README.md) och [`en/`](./en/README.md).
Där står också konventionerna för hur innehållet redigeras och hålls i takt med kursmaterialet.

---

## Licens
Böckerna är satta ur kursens eget material, och texten i dem är licensierad under
[CC BY 4.0](../LICENSE) precis som resten av kursmaterialet. Koden i dem, och all kod i kursrepot,
får användas under [MIT-licensen](../LICENSE-CODE), och det gäller också byggfilerna i `sv/` och
`en/`.
