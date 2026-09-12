# L02 - Större nät, multiplexrar och submoduler

## Agenda
* `process` och `case`: sekventiella satser inuti i övrigt parallell hårdvara.
* `std_logic_vector`: att bunta ihop flera ledningar under ett namn, indexering och slicing.
* Multiplexrar: en 4-till-1-mux, det minsta som är värt ett `case`.
* Karnaughdiagram: varför en summa-av-produkter läst direkt ur sanningstabellen sällan ger det
  minsta nätet.
* Submoduler: att skriva ett block en gång och instansiera det mer än en gång.
* `hex_display` demonstrerad på DE0-CV: åtta strömbrytare in, två hexadecimala siffror ut.
* Självstudier: multiplexrar i andra storlekar (A.4, A.5), och 4-till-1-muxen härledd på nytt för
  hand i övning 4 till 6.

---

## Föreläsningsupplägg
Byggs live, i denna ordning:
1. **En 4-till-1-multiplexer i VHDL.** Fyra ingångar, en tvåbitars väljare, fyra grenar: det
   minsta som är värt att skriva ett `case` för. `process`, `case` och vektorindexering dyker
   alla upp här.
2. **Ett Karnaughdiagram, taget hela vägen i CircuitVerse.** A.1:s exempel med tre variabler: fem
   `1`-rader ur sanningstabellen, två grupper i diagrammet, och `X = AB + C` byggd som två
   grindar. Litet nog att härleda och kontrollera live; övning 9 skalar upp samma teknik till en
   segmentavkodare.
3. **`display` i VHDL.** Steg 1:s `case`, med sexton grenar i stället för fyra. Det enda nya på
   skärmen är segmenttabellen.
4. **`hex_display`.** Två instanser av `display`, åtta strömbrytare delade i två halvor.
5. **Ut på kortet.** Ställ strömbrytarna, läs av hexsiffrorna.

Multiplexrar i andra storlekar läses i stället för att presenteras, i
[A.4](./appendix/a_larger_networks.md#a4-multiplexrar) och
[A.5](./appendix/a_larger_networks.md#a5-multiplexrar-i-vhdl-process-och-case). Övning 5 bygger
2-till-1-muxen; övning 4 och 6 härleder 4-till-1-muxen du såg skrivas här på nytt, först för hand
och sedan i VHDL, i stället för att kopiera den.

---

## Före föreläsningen
* Läs [Appendix A](./appendix/a_larger_networks.md).
* Installera GHDL enligt [Appendix C](./appendix/c_testbenches.md), om du inte redan gjort det.
  L01:s övningar behövde det också, och varje övning härifrån och framåt gör det.

## Efter föreläsningen
* Arbeta igenom [Appendix B](./appendix/b_exercises.md).

---

## Det här ska du kunna efteråt
* Härleda en minimerad ekvation ur ett Karnaughdiagram och göra en VHDL-arkitektur av den.
* Läsa och skriva portar och signaler av typen `std_logic_vector`.
* Skriva en `process` med korrekt känslighetslista och ett `case` som täcker varje indatavärde.
* Bygga en design av mer än en `entity` med positionell `port map`, och säga varför två
  instanser av samma modul lägger två kopior av dess grindar på FPGA:n.
* Verifiera en modul genom att köra dess testbänk, och läsa ett misslyckat `assert`.

---

## Frågor att testa dig själv med
* Kan du, givet en sanningstabell, härleda dess ekvation både direkt och via ett
  Karnaughdiagram? Vad skiljer de två resultaten?
* Varför kan ett `case` inte stå direkt i en arkitekturkropp?
* Vad skyddar `when others` dig mot, när väljaren "bara kan" vara `0` eller `1`?
* I `display1: entity work.display`, vad namnger `display1`, och vad namnger `work.display`?
  Skulle en andra instans kunna återanvända samma etikett?
* `hex_display`s arkitektur innehåller ingen logik alls. Var kommer grindarna i den färdiga
  designen ifrån?
* Du instansierade `display` två gånger i stället för att skriva dess `case` två gånger. Får
  FPGA:n en eller två kopior av den logiken? Vad vann du alltså egentligen?
* Kursen skriver alltid `port map` positionellt. Vad går sönder om en entitets portar deklareras
  i en annan ordning än den testbänken förväntar sig, och när märker du det?

---

## Referens
* [Appendix A](./appendix/a_larger_networks.md) är kursmaterialet; submoduler ligger i
  [A.6](./appendix/a_larger_networks.md#a6-att-bygga-en-design-av-submoduler), och det mönstret
  används av varje design med flera entiteter i resten av kursen.
* [Appendix B](./appendix/b_exercises.md) innehåller övningarna.
* [Appendix C](./appendix/c_testbenches.md) är kursens guide till att köra testbänkar, som varje
  senare föreläsning hänvisar tillbaka till.
* [`gate_network`](./gate_network/gate_network.vhd) är A.2:s minimerade nät i sin hopslagna
  enradsform; A.2 visar också versionen som namnger mellansignalen.
* [`mux_8to1`](./mux_8to1/mux_8to1.vhd) är A.5:s genomarbetade multiplexer. Passet går inte
  igenom den, så läs den vid sidan av A.5 innan du börjar med övning 5 och 6. Båda har en
  referenstestbänk.

---

## Nästa föreläsning
* Sekvensnät: kretsar som minns.
* D-låset, och D-vippan byggd av ett par av dem.
* Klockning, och när en signaltilldelning faktiskt får effekt.
* Flankdetektering: en knapptryckning som växlar en lysdiod.

---
