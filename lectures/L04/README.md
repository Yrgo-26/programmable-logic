# L04 - Metastabilitet och synkronisering

## Agenda
* Varför en asynkron ingång kan förstöra de rena flankdetektorer och register som byggdes i L03.
* Metastabilitet: vad det är, och varför det inte helt enkelt går att konstruera bort.
* Dubbelvippsynkroniseraren, och mönstret "aktivera asynkront, släpp synkront" för reset.
* Att återanvända samma kedja för flankdetektering, och vad den gör och inte gör åt studs.
* Generics: en modul som betjänar flera storlekar.
* `led_toggle_sync` demonstrerad på DE0-CV, driven av en riktig, studsande tryckknapp.
* Självstudier: setup/hold-tider i detalj (A.4), och vad en riktig studsfiltrering tillför (A.7).

---

## Föreläsningsupplägg
Byggs live, i denna ordning:
1. **Samma lysdiodsväxling som i L03, nu med synkroniserare, i CircuitVerse.** Två vippor framför
   knappen, två framför reset, och flankdetektorn bakom dem.
2. **`reset_sync` i VHDL.** Aktivera asynkront, släpp synkront.
3. **`button_sync` i VHDL.** Trevippskedjan, med en `generic` så att en fil räcker både för en
   design med en knapp och en med två.
4. **`led_toggle_sync`.** De två subkomponenterna hopkopplade, och växlingslogiken som är allt
   som återstår av den ursprungliga kretsen.
5. **Ut på kortet.**

Innan synkroniseraren sätts in: förutsäg vad en riktig, asynkron knapp gör med L03:s
flankdetektor. Den förutsägelsen är skälet till hela föreläsningen.

Genomgången som inleder passet är metastabiliteten själv. Argumentet som är värt att hålla fast
vid är varför två vippor gör felet *osannolikt* snarare än omöjligt: det är den delen som inte
överlever att bli ihågkommen som en tumregel.

Två delar av materialet läses i stället för att presenteras. Setup/hold-detaljerna i
[A.4](./appendix/a_metastability_and_synchronization.md#a4-intuition-för-tidsförhållandena-varför-nästan-säkert-duger),
utöver att fönstret finns och att det är överträdelser av det som ställer till besvär; och
[A.7](./appendix/a_metastability_and_synchronization.md#a7-vad-en-riktig-studsfiltrering-i-hårdvara-tillför), om
vad en riktig studsfiltreringskrets tillför. Båda examineras nedan och drillas av övning 2 och 7,
så de är inte valfria.

---

## Före föreläsningen
* Läs [Appendix A](./appendix/a_metastability_and_synchronization.md).
* Var bekväm med D-vippor, klockning och flankdetektering från [L03](../L03/README.md); den här
  föreläsningen förutsätter allt det.
* Föreläsningen bygger också på
  [L02 A.6](../L02/appendix/a_larger_networks.md#a6-att-bygga-en-design-av-submoduler): dess
  genomarbetade exempel är sammansatt av två subkomponenter, och A.8 lägger till den `generic`
  som låter en av dem betjäna designer med olika antal knappar.

## Efter föreläsningen
* Arbeta igenom [Appendix B](./appendix/b_exercises.md).
* Läs [`led_toggle_sync`](./led_toggle_sync/led_toggle_sync.vhd). Dess subkomponenter
  `reset_sync` och `button_sync` är övning 8 och 9 snarare än filer i repot, så gör dem först,
  kopiera in dina egna i `led_toggle_sync/`, och kör sedan dess testbänk.

---

## Det här ska du kunna efteråt
* Förklara vad metastabilitet är, varför en asynkron ingång kan orsaka det, och varför två vippor
  gör det osannolikt snarare än omöjligt.
* Tillämpa dubbelvippsynkroniseraren på vilken asynkron ingång som helst, inklusive mönstret
  "aktivera asynkront, släpp synkront" som används för reset.
* Säga varför den kedjan dessutom fungerar som en praktisk men ofullständig studsfiltrering, och
  vad en riktig sådan skulle tillföra.
* Ge en modul en `generic`, åsidosätta den med en `generic map`, skriva en ports bredd i termer
  av den, och bedöma när en generic gör rätt för sig i stället för att läggas till av princip.

---

## Frågor att testa dig själv med
* Vad händer exakt när en asynkron ingång till en vippa ändras för nära en aktiv klockflank?
* Hur hanterar dubbelvippsynkroniseraren det, och varför är det den *andra* vippans utgång som är
  säker att använda?
* Varför beter sig kedjan som används här som en studsfiltrering i CircuitVerse men inte
  studsfiltrerar en riktig knapp fullt ut vid `50 MHz`, och varför är det en egenskap hos
  klockperioden snarare än hos kretsen? Vad skulle du lägga till för att åtgärda det?
* `button_sync` har en generic och `reset_sync` har ingen. Vad är regeln, och vad vore fel med
  att ge `reset_sync` en `WIDTH`-generic "för symmetrins skull"?

---

## Referens
* [Appendix A](./appendix/a_metastability_and_synchronization.md) är kursmaterialet.
* [Appendix B](./appendix/b_exercises.md) innehåller övningarna.
* Erik Pihls videogenomgång av metastabilitet och dubbelvippsynkroniseraren finns på
  [YouTube](https://www.youtube.com/watch?v=KrssJRgF13I) som ytterligare, frivillig visning.
* [nandland: Metastability](https://nandland.com/lesson-13-metastability/) och
  [VHDLwhiz: Metastability](https://vhdlwhiz.com/terminology/metastability/) täcker samma begrepp
  från en något annan vinkel, användbart om Appendix A inte sitter vid första läsningen.

---

## Nästa föreläsning
* `variable`: den enda konstruktion du ännu inte mött, och den skarpa skillnaden mellan hur den
  uppdateras och hur en `signal` gör det.
* Varför samma ackumulering skriven med en `signal` och med en `variable` ger två olika svar, och
  vilket av de två som är felet.
* Vad verktygskedjan faktiskt bygger: LUT:ar och vippor, vad som begränsar en klockas hastighet,
  och låset du råkar beskriva av misstag.

---
