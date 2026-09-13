# L01 - Kombinatorik och första VHDL

## Agenda
* Logiska grindar och sanningstabeller, och varför digital logik tål brus som analog inte gör.
* Boolesk algebra: att läsa en summa-av-produkter direkt ur en sanningstabell.
* Att bygga och simulera ett grindnät för hand i CircuitVerse.
* VHDL redan från första föreläsningen: `entity`, `architecture`, `std_logic` och den
  konkurrenta tilldelningen.
* Bromsassistenten demonstrerad på ett DE0-CV-kort, från Quartus till strömbrytare och en lysdiod.
* Självstudier: `or_gate`, från sanningstabell till komplett modul i A.4 och A.5.

---

## Föreläsningsupplägg
Byggs live, i denna ordning:
1. **En bromsassistent som grindnät, i CircuitVerse.** Fyra grindar, härledda ur ett krav och
   dess sanningstabell, och därefter simulerade mot den.
2. **Samma nät i VHDL.** `entity`, `architecture`, en intern `signal` och två konkurrenta
   tilldelningar.
3. **Assistenten demonstrerad på kortet.** Genom Quartus och pinnplacering ut på ett DE0-CV, med
   de fyra ingångarna på strömbrytare och bromsutgången på en lysdiod: slå om strömbrytarna och
   se bilen bestämma sig för att bromsa.
4. **Dess testbänk**, om tiden räcker: vad en testbänk är, och varför nästan varje katalog här
   har en.

En krets, från krav till fungerande hårdvara, beskriven i
[Appendix A.6](./appendix/a_combinational_logic.md#a6-föreläsningens-krets-en-bromsassistent).
Allt annat är läsning eller övningar, däribland [`or_gate`](./or_gate/or_gate.vhd), som
[A.4](./appendix/a_combinational_logic.md#a4-precis-så-mycket-vhdl-att-du-kan-läsa-och-skriva-ett-grindnät) och
[A.5](./appendix/a_combinational_logic.md#a5-den-kompletta-modulen-or_gate) tar hela vägen i skrift.

> **Om språket.** All text i kursen är på svenska, appendixen inräknade; all kod, alla kommentarer
> i koden och all utskrift från testbänkarna är på engelska.

---

## Före föreläsningen
> **Hellre boken?** Den här föreläsningen är också kapitel 1 i kursboken, på
> [svenska](../../book/sv/programmerbar-logik.pdf) och
> [engelska](../../book/en/programmable-logic.pdf). Appendix A är avsnitt 1.1-1.6, och övningarna i
> Appendix B är avsnitt 1.8. Läs antingen appendixen eller kapitlet; innehållet är detsamma.

> **Repetera grunderna?** Grindar, sanningstabeller och boolesk algebra står i avsnitt 1.1-1.4 och
> 2.1-2.7 i [Digital
> Electronics](https://github.com/qrtech-academy/digital-electronics/blob/main/book/digital-electronics.pdf),
> och CircuitVerse i dess bilaga B.

Läs [Appendix A](./appendix/a_combinational_logic.md). Inget behöver installeras för själva
föreläsningen; till övningarna behöver du GHDL, enligt
[L02 Appendix C](../L02/appendix/c_testbenches.md).

## Efter föreläsningen
Arbeta igenom [Appendix B](./appendix/b_exercises.md).

---

## Det här ska du kunna efteråt
* Härleda en summa-av-produkter ur en sanningstabell, och sedan bygga och simulera nätet i
  CircuitVerse.
* Tillämpa De Morgan för att flytta en inversion genom en grind, och använda det för att
  realisera en funktion i en grinduppsättning som saknar operatorn du utgick från.
* Läsa och skriva en kombinatorisk VHDL-modul, en `entity` med `std_logic`-portar och en
  `architecture` som driver dess utgång, och säga varför VHDL skiljer de två åt.
* Förklara varför en konkurrent tilldelning beskriver en ledning snarare än en sats som körs en
  gång, och varför en signal som ligger kvar på `'U'` eller `'X'` är ett fel och inte ett värde.
* Köra en utdelad testbänk och avgöra om din modul klarade den.

---

## Frågor att testa dig själv med
* Vad är skillnaden mellan en `entity` och en `architecture`, och varför skiljer VHDL på dem?
* Varför är `x <= a or b;` inte "en sats som körs en gång"? Vad beskriver den i stället?
* I bromsassistenten läggs förarens pedal in med OR sist, i stället för att gå genom
  felhanteringslogiken. Vad går sönder om du kopplar den tvärtom?

---

## Referens
* [Appendix A](./appendix/a_combinational_logic.md) är kursmaterialet.
* [Appendix B](./appendix/b_exercises.md) innehåller övningarna.
* [CircuitVerse](https://circuitverse.org/simulator): den webbläsarbaserade simulatorn som
  används genom hela kursen för att bygga och testa varje krets för hand innan den skrivs i VHDL.
* [info/quartus_workflow.md](../../info/quartus_workflow.md): verktygskedjan för Quartus och
  DE0-CV. Kortarbetet demonstreras för dig; du behöver varken Quartus eller hårdvara.

---

## Nästa föreläsning
* Karnaughdiagram: att hitta det *minsta* grindnätet, inte bara ett korrekt.
* `std_logic_vector`, `process` och `case`.
* Submoduler, demonstrerade på en tvåsiffrig hexadecimal display driven av åtta strömbrytare.
* Självkontrollerande testbänkar: att verifiera din egen VHDL utan kort.

---
