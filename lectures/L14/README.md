# L14 - Sändningsskiftregister och bitstoppning

Att serialisera ut på bussen, med samma stoppbitsregel som i [L10](../L10/README.md), nu i VHDL.

---

## Agenda
* `tx_shift_reg` på tavlan: serialisering med mest signifikanta biten först, och insättning av
  stoppbitar.
* Varför en laddad grupps första bit måste presenteras omedelbart vid omladdning, och varför
  `done` väntar en extra skiftning.
* Varför stoppningstillståndet lever kvar över omladdningar.
* Verifiering mot den utdelade testbänken.
* Att instansiera `tx_shift_reg` inuti `can_controller`.

---

## Mål
Efter den här föreläsningen ska ni kunna:
* Implementera ett skiftregister som serialiserar MSB först och sätter in stoppbitar enligt
  femregeln.
* Förklara varför stoppningsräknaren inte får nollställas när en ny grupp laddas.
* Skilja på `bit_valid` och `bit_done`, och säga vilken av dem CRC-motorn ska grindas på.
* Säga vad `stuff` är till för, och varför den behövs utanför modulen.

---

## Förkunskaper
* [L10](../L10/README.md): stoppbitsregeln, tillämpad på papper på en hel bitföljd.
* [L13](../L13/README.md): `crc15`, som ska matas med exakt de bitar som *inte* är stoppbitar.
* [L06](../L06/README.md): PISO-skiftregister.

---

## Genomförande

### Förberedelse
> **Hellre boken?** Den här föreläsningen är också kapitel 14 i kursboken, på
> [svenska](../../book/sv/programmerbar-logik.pdf) och
> [engelska](../../book/en/programmable-logic.pdf). Appendix A är avsnitt 14.1-14.6, och övningarna
> i Appendix B är avsnitt 14.8. Läs antingen appendixen eller kapitlet; innehållet är detsamma.

* Läs [Appendix A](./appendix/a_tx_shift_reg.md). Den är lång, och gränssnittstabellen plus
  avsnittet om vad testbänken låser fast är de delar som lönar sig mest före passet.

### Under föreläsningen
* Stoppningsregeln som tillståndsmaskin på tavlan: `last_bit` och `consecutive`, och varför de
  två tillsammans är hela regelns minne.
* `tx_shift_reg` på tavlan: blocket med sina tio portar, och tidsdiagrammet för en laddning, en
  instoppad bit och `done`.
* Ett par av testbänkens fall lästa i detalj: de säger mer om kontraktet än appendixet gör.

### Handledd grupptid
* Implementera `tx_shift_reg.vhd` utifrån specifikationen i Appendix A och få `tx_shift_reg_tb`
  att passera.
* Det här är den första modulen där det lönar sig att rita tidsdiagrammet innan ni skriver koden.
  Ta tid till det; de flesta fel här är tajmingfel med en cykel, inte logikfel.

### Efter föreläsningen
* [Appendix B](./appendix/b_exercises.md) innehåller övningarna.

---

## Riktvärde
Ungefär halvvägs genom projektet. Tre av fyra lövmoduler brukar vara klara här, och det är också
ungefär nu det blir tydligt vilken grupp som faktiskt granskar varandras kod och vilken som bara
klickar "Approve".

---

## Kontrollfrågor
* Varför måste den första biten i en nyladdad grupp ligga ute direkt, i stället för vid nästa
  `shift`?
* Varför nollställs inte stoppningsräknaren vid omladdning?
* Vad skulle gå fel om `can_controller` matade CRC-motorn på `bit_done` i stället för på
  `bit_valid and not stuff`?
* En stoppbit har alltid motsatt värde mot de fem föregående. Varför räcker inte "sätt in en nolla"?
* Varför väntar `done` en extra skiftning i stället för att gå hög direkt när sista databiten
  skiftats ut?

---

## Nästa föreläsning
[L15](../L15/README.md): mottagningsskiftregistret, sändarens spegelbild, plus projektets
**obligatoriska kodgranskningsseminarium**.

---
