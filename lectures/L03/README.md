# L03 - Sekvensnät

## Agenda
* Varför kombinatorisk logik ensam inte kan minnas något, och vad "tillstånd" betyder i en krets.
* D-låset och D-vippan, och varför synkrona designer byggs av vippan.
* Klockning: period, frekvens, och stigande kontra fallande flank.
* Den synkrona processmallen i VHDL, och när en signaltilldelning faktiskt får effekt.
* Flankdetektering: att göra en nivå till en enda klockcykel lång puls.
* `led_toggle` demonstrerad på DE0-CV: en knapptryckning som växlar en lysdiod och håller kvar den.
* Självstudier: register som vippor parallellt (A.5), och `d_flip_flop` för sig (A.8).

---

## Föreläsningsupplägg
Byggs live, i denna ordning:
1. **Ett D-lås, i CircuitVerse.** Korskopplade grindar, genomsläppligt så länge det är aktiverat.
2. **En D-vippa, av ett par av dem.** Samma krets, nu med förändring bara vid en flank.
3. **En flankdetekterad lysdiodsväxling, i CircuitVerse.** En knapp: en vippa minns knappens
   föregående läge, en andra håller lysdioden, och en fallande flank på knappen växlar den.
4. **Samma krets i VHDL, för två knappar samtidigt.** Den synkrona processmallen, två gånger om,
   med de enskilda ledningarna från steg 3 breddade till 2-bitars vektorer så att en process
   räcker för båda knapparna. Den breddningen är hela skillnaden mellan ritningen och modulen.
5. **Ut på kortet.** `led_toggle` genom Quartus ut på DE0-CV: tryck på knappen, se lysdioden
   hålla sitt nya läge till nästa tryck.

Steg 3 till 5 är beskrivna i
[Appendix A.9](./appendix/a_flip_flops_and_registers.md#a9-genomarbetat-exempel-flankdetekterad-lysdiodsväxling).

Två förutsägelser värda att göra innan respektive simulering körs:
* för låset, vad `Q` gör när `enable` går låg medan `D` fortfarande ändrar sig.
* för vippan, vad `Q` gör när `D` ändrar sig *mellan* två klockflanker.

[`d_flip_flop`](./d_flip_flop/d_flip_flop.vhd) är också beskriven för sig, i
[Appendix A.8](./appendix/a_flip_flops_and_registers.md#a8-genomarbetat-exempel-en-d-vippa-i-vhdl),
med en referenstestbänk. Den läses i stället för att presenteras: passet bygger vippan som en del
av växlingskretsen, vilket är samma modul men med något att göra.

---

## Före föreläsningen
> **Hellre boken?** Den här föreläsningen är också kapitel 3 i kursboken, på
> [svenska](../../book/sv/programmerbar-logik.pdf) och
> [engelska](../../book/en/programmable-logic.pdf). Appendix A är avsnitt 3.1-3.9, och övningarna i
> Appendix B är avsnitt 3.11. Läs antingen appendixen eller kapitlet; innehållet är detsamma.

> **Repetera grunderna?** Låset, vippan, registret och flankdetekteringen står i avsnitt 5.1-5.6 i
> [Digital
> Electronics](https://github.com/qrtech-academy/digital-electronics/blob/main/book/digital-electronics.pdf).

* Läs [Appendix A](./appendix/a_flip_flops_and_registers.md).

## Efter föreläsningen
* Arbeta igenom [Appendix B](./appendix/b_exercises.md). De två första övningarna är låset och
  vippan, vilket är där de två förutsägelserna ovan är värda att bekräfta i stället för att tas
  på förtroende.

---

## Det här ska du kunna efteråt
* Säga varför sekvensnät finns, förklara den funktionella skillnaden mellan ett D-lås och en
  D-vippa, och varför synkrona designer nästan uteslutande byggs av vippan.
* Läsa och skriva den synkrona processmallen, och känna igen ett register som flera vippor som
  delar klocka, reset och enable.
* Säga när en signaltilldelning får effekt: `<=` schemalägger snarare än tillämpar, så två
  tilldelningar i en klockad process bygger en kedja, och deras inbördes ordning spelar ingen roll.
* Bygga en flankdetektor av en vippa och en grind, och säga exakt vilken signal den producerar
  och hur länge.

---

## Frågor att testa dig själv med
* Vad är den funktionella skillnaden mellan ett D-lås och en D-vippa, och under vilket villkor
  ändrar var och en sin utgång?
* Varför uppdaterar synkrona kretsar sitt tillstånd vid en enda klockflank i stället för att
  kontinuerligt reagera på sina ingångar?
* Givet en signal och en vippa som håller dess värde från en cykel tidigare, hur kombinerar du
  dem till en puls som är hög i exakt en klockcykel när signalen går hög?
* Varför måste `clock` vara den enda signalen i en vippprocess känslighetslista, om inte designen
  har en asynkron reset?
* En klockad process innehåller `b <= a;` och därefter `c <= b;`. Vad håller `c` efter en
  klockflank, och varför är det inte `a`? Vad ändras om du byter plats på raderna, och varför?

---

## Referens
* [Appendix A](./appendix/a_flip_flops_and_registers.md) är kursmaterialet.
* [Appendix B](./appendix/b_exercises.md) innehåller övningarna.
* Att köra testbänkarna beskrivs i [L02 Appendix C](../L02/appendix/c_testbenches.md). Det här är
  den första föreläsningen vars övningar behöver det för en klockad design, så det är värt att
  läsa om innan du börjar med `register4`.

---

## Nästa föreläsning
* Varför den råa knappen som matar den här föreläsningens flankdetektor kan driva en vippa in i
  ett odefinierat, instabilt tillstånd, och varför det är ett annat sorts problem än något här.
* Dubbelvippsynkroniseraren, och vad den gör och inte gör åt en studsande knapp.
* Samma lysdiodsväxling, ombyggd så att den faktiskt är säker på riktig hårdvara.

---
