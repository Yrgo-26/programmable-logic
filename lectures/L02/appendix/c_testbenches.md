# Appendix C - Att verifiera din VHDL med en testbänk

Det här appendixet är kursens guide till att **köra** testbänkar, och varje senare föreläsnings
övningar hänvisar tillbaka hit. Du ombeds inte skriva testbänken som verifierar en modul du bygger -
var och en av dem delas ut - men du kör en efter varje VHDL-övning, eftersom det är den som
verifierar din VHDL när du inte har något eget FPGA-kort. Varje genomarbetat exempel och varje
övning har en färdig `<module>_tb.vhd`.

[Referensen för simuleringsflödet](../../../info/simulation_workflow.md) är den fylligare versionen
av det här, skriven för grupprojektet; kom tillbaka hit för introduktionen och gå dit för
detaljerna.

---

## C.1 Det här behöver du
* **GHDL**, den öppna VHDL-analysatorn och -simulatorn. Kontrollera med `ghdl --version`; installera
  på WSL/Ubuntu med `sudo apt -y install ghdl`.

Varje kommando nedan använder `--std=93`, den VHDL-standard kursen riktar in sig på.

---

## C.2 Vad en testbänk är
En testbänk är själv en VHDL-modul, men en speciell sådan:
* Dess entitet har **inga portar**: ingenting kopplas till omvärlden, eftersom den är simuleringens
  topp.
* Dess arkitektur **instansierar din konstruktion**, "device under test", märkt `dut`, och driver
  dess ingångar.
* Den **kontrollerar** varje utgång med ett `assert`. Om en utgång är fel utlöses assertionen med
  ett meddelande och simuleringen stannar.

Så i stället för att du läser av ett vågformsdiagram för att avgöra om utgången är rätt, avgör
testbänken det, och säger bara ifrån när något är fel.

---

## C.3 Att köra en testbänk: analysera -> elaborera -> köra
Tre steg. Skicka med `--std=93` till alla tre, och ge **testbänkens entitetsnamn**, inte ett
filnamn, till de två sista:

```bash
ghdl -a --std=93 <module>.vhd <module>_tb.vhd        # analyze both files (module first)
ghdl -e --std=93 <module>_tb                         # elaborate the testbench
ghdl -r --std=93 <module>_tb --assert-level=error --stop-time=10ms   # run it
```

* `--assert-level=error` gör att en misslyckad kontroll stoppar körningen och returnerar en
  **slutkod skild från noll**, ett riktigt godkänt/underkänt som du kan kontrollera med `echo $?`.
  Testbänkarna här reser fel med `severity failure`, vilket stoppar körningen av sig självt, så du
  får ett riktigt godkänt/underkänt även utan flaggan. Ha den på ändå: det är vanan som också
  fungerar med testbänkar som rapporterar på en lägre severity-nivå.
* `--stop-time=10ms` sätter ett tak för hur länge simuleringen får köra. En testbänk väntar ofta på
  att din modul ska göra något, med en rad som `wait until tx = '0';`. Om din modul aldrig gör det
  blir den väntan aldrig färdig, och utan en stopptid hänger simuleringen: ingen utskrift, inget
  fel, bara en terminal som står och väntar. 10 ms *simulerad* tid är långt mer än någon testbänk
  här behöver, och tar en bra bit under en sekund i verklig tid.
* En godkänd körning skriver ut sin "all checks passed"-notering och avslutar med 0. Varje testbänk
  i den här kursen slutar med den noteringen, så om du inte ser den blev körningen inte färdig: den
  antingen underkände en kontroll eller slog i stopptiden.

---

## C.4 Att kontrollera en övning
Varje VHDL-övning har sin testbänk i sin egen katalog. Den här föreläsningens övning 3 har till
exempel `lectures/L02/exercises/xyz_logic/xyz_logic_tb.vhd`. Skriv din modul i **samma katalog**,
med exakt det namn övningen ber om, och kör sedan de tre kommandona därifrån:

```bash
cd lectures/L02/exercises/xyz_logic
ghdl -a --std=93 xyz_logic.vhd xyz_logic_tb.vhd
ghdl -e --std=93 xyz_logic_tb
ghdl -r --std=93 xyz_logic_tb --assert-level=error --stop-time=10ms
```

Varje testbänks filhuvud listar precis de här kommandona.

Testbänken kopplar till din modul **positionellt**, inte via namn, så din entitet måste deklarera
sina portar i **samma ordning** som övningen listar dem. Namnen är dina att välja, men använd de
angivna ändå, så att din modul och testbänkens felmeddelanden talar om samma signaler.

En port som deklarerats i fel ordning misslyckas på ett av två sätt, varav inget säger "fel
ordning":
* om de felplacerade portarna har **olika** typ eller bredd stannar analysen med
  `can't associate "sel" with port "sel"`, med en pekare på testbänkens `port map`-rad.
* om de har **samma** typ, säg flera `std_logic`-portar, analyseras och elaboreras den alldeles
  utmärkt, och faller sedan vid körning som ett vanligt assertion-fel, vilket läser sig precis som
  en logikbugg i din konstruktion.

Så när en testbänk faller på allra första fallet den kontrollerar: läs om din portordning innan du
letar igenom din arkitektur. Detsamma gäller **generics**: en modul som bär på sådana måste
deklarera exakt de som övningen anger, i ordning.

---

## C.4b När konstruktionen behöver mer än en fil
Vissa övningar bygger en modul av en annan, så `ghdl -a`-raden namnger flera filer i stället för
två. Elaborerings- och körstegen är oförändrade: de tar fortfarande bara testbänkens
**entitetsnamn**.

```bash
ghdl -a --std=93 <subcomponent>.vhd <module>.vhd <module>_tb.vhd
ghdl -e --std=93 <module>_tb
ghdl -r --std=93 <module>_tb --assert-level=error --stop-time=10ms
```

* **Ordningen spelar roll på analysraden**: namnge en modul före allt som instansierar den, så att
  GHDL redan har sett entiteten när det når det `entity work.<name>` som hänvisar till den.
  Subkomponenter först, din toppnivå därefter, testbänken sist.
* Ingen övningskatalog har någon utdelad subkomponent. Varje modul en konstruktion instansierar är
  en du skrev i en tidigare övning och kopierar in själv; övningen säger vilken, och varifrån.
* Övningarna som behöver det här är L02:s `hex_display` (som instansierar din `display`), L04:s
  `led_toggle_sync2`, L07:s `blinker` (`reset_sync` och `timer`) och `walking_led` (de två plus
  `button_sync`), samt alla L08:s, där mottagaren namnger fem filer och sändaren fyra.
* Varje testbänks filhuvud listar det exakta kommandot för sin egen övning.

---

## C.5 Att läsa resultatet
En misslyckad kontroll ser ut så här:

```text
xyz_logic_tb.vhd:38:13:@10ns:(assertion failure): xyz_logic: wrong X with a='0' b='0' c='0' d='0', expected '0' but got '1'!
ghdl:error: assertion failed
```

Läs den i ordning: `file:line` är var assertionen står, `@time` är när den utlöstes, och därefter
kommer meddelandet. Det är samma form som ett kompileringsfel från GHDL, så det avbildas på sådant
du redan kan. Inget fel betyder att varje fall stämde.

---

## C.6 Ett komplett exempel
En kombinatorisk testbänk i den form varje testbänk i den här kursen använder, här för L01:s
`or_gate`:

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity or_gate_tb is
end entity;

architecture behaviour of or_gate_tb is
signal a, b, x: std_logic;
begin
    dut: entity work.or_gate
        port map(a, b, x);   -- positional: same order as or_gate's port clause.

    SIM_PROCESS: process is
    begin
        for i in 0 to 3 loop
            (a, b) <= std_logic_vector(to_unsigned(i, 2));   -- apply inputs
            wait for 10 ns;                                  -- let them settle
            assert x = (a or b)                              -- check AFTER the wait
                report "or_gate: wrong output with a=" & std_logic'image(a)
                     & " b=" & std_logic'image(b)
                     & ", expected " & std_logic'image(a or b)
                     & " but got " & std_logic'image(x) & "!"
                severity failure;
        end loop;
        report "or_gate: all checks passed!" severity note;
        wait;                                                -- end the simulation
    end process;
end architecture;
```

Två regler håller en kombinatorisk testbänk korrekt:
* **Lägg på -> vänta -> kontrollera, i den ordningen.** En signaltilldelning *schemalägger* bara ett
  värde, så ingångarna och utgången uppdateras inte förrän vid `wait`. Att kontrollera före den
  testar föregående varvs värden.
* **Avsluta med `wait;`** så att stimulusprocessen suspenderas och simuleringen stannar av sig
  själv.

Klockade konstruktioner behöver lite mer, en klockgenererande process och ett sätt att stoppa den,
vilket är precis det maskineri de utdelade testbänkarna redan innehåller. Till övningarna skriver du
bara modulen.
