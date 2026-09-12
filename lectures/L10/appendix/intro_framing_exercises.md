# Introduktion - ramningsövningar

## Övningar
De här övningarna befäster begreppen från
[ramningsintroduktionen](./intro_framing.md). Del I bygger ramar för hand, på papper. Del II gör om
samma ram till en fungerande C++-implementation. Appendix A tar upp ramen igen och ställer den mot
CAN. Ingen VHDL ännu; den börjar i Appendix B, med paketet `can_def`.

---

## Ramen, som referens
Utgå från ramstrukturen ur ramningsintroduktionen:

```text
Fält   Storlek   Beskrivning
------ --------- -------------------------------------------
SOF    2 byte    0xA5F7
LEN    1 byte    Nyttolastens längd
TYPE   1 byte    Meddelandetyp
DST    1 byte    Destinationsadress
SRC    1 byte    Källadress
SEQ    2 byte    Sekvensnummer
DATA   N byte    Nyttolast
CHK    2 byte    Checksumma (summan av föregående byte)
```

Checksumman är summan av varje byte från SOF till och med den sista nyttolastbyten, som en
`std::uint16_t` (så den slår runt vid overflow). Fält bredare än en byte (SOF, SEQ, CHK) är
big-endian.

Ramtyperna är:

```text
Ping       = 0x00
Pong       = 0x01
StatusReq  = 0x02
StatusResp = 0x03
```

---

## Del I - Att konstruera ramar för hand
En enhet på adress `0x17` skickar en statusförfrågan till en sensor på adress `0x25`, med
sekvensnummer `0x7F05`. Det ger:
* `TYPE = 0x02`
* `DST = 0x25`
* `SRC = 0x17`
* `SEQ = 0x7F05`
* `DATA` är tom (0 byte)

**a)** Rita motsvarande `StatusReq`-ram på papper, och fyll i varje fält:
* SOF
* LEN
* TYPE
* DST
* SRC
* SEQ
* CHK

Räkna ut checksumman för hand.

**b)** Sensorn svarar med ett 16-bitars sensorvärde, `0x3201`, buret i nyttolasten. Rita motsvarande
`StatusResp`-ram på papper.

Regler:
* TYPE ändras till `StatusResp`.
* DST och SRC byter plats.
* SEQ är oförändrat.
* DATA är `0x3201` (2 byte).

Räkna ut även den här ramens checksumma för hand.

---

## Del II - Att implementera ramen i C++
Implementera ramen i C++ som en struct `comm::Frame`. Er implementation valideras av en befintlig
uppsättning enhetstester.

### 1. Undersök filstrukturen
Gå igenom [`code`](./code/):
* [`test/frame_test.cpp`](./code/test/frame_test.cpp):
  * Innehåller enhetstesterna som validerar er ramimplementation.
  * Dem skriver ni inte; ni får dem att passera.
* [`include/comm/def.hpp`](./code/include/comm/def.hpp):
  * Innehåller ramfältens offset (indexpositioner), fältstorlekarna med mera.
  * Uppräkningsklassen `comm::FrameType` ska implementeras här, enligt specifikationen ovan.
* [`include/comm/frame.hpp`](./code/include/comm/frame.hpp):
  * Innehåller deklarationen av structen `comm::Frame`.
* [`source/comm/frame.cpp`](./code/source/comm/frame.cpp):
  * Ska innehålla implementationsdetaljerna för structen `comm::Frame`, alltså dess
    metoddefinitioner.

### 2. Skapa ramtyperna
Implementera uppräkningsklassen `comm::FrameType` i [`comm/def.hpp`](./code/include/comm/def.hpp),
och ge var och en av de fyra typerna det id som listas ovan. Lägg till en avslutande uppräknare
`Unknown`, ett steg bortom den sista riktiga typen, så att en typ utanför intervallet kan avvisas
vid deserialisering med en enda jämförelse.

### 3. Skapa ramstructen
Lägg till medlemsvariablerna för structen `comm::Frame` i
[`comm/frame.hpp`](./code/include/comm/frame.hpp), där `@todo` markerar stället:
* `std::uint8_t data[MaxDataLen]`
* `std::uint16_t seq`
* `std::uint8_t dst`
* `std::uint8_t src`
* `std::uint8_t len`
* `FrameType type`

Värdeinitiera var och en med klammerparenteser: de numeriska medlemmarna med `{}`, och `type` med
`{FrameType::Unknown}`, så att en default-konstruerad ram aldrig håller en typ som råkar vara
giltig.

Bredderna är ingen smaksak. Enhetstesterna jämför en medlem mot en literal av fältets egen bredd
genom en mall som härleder **en** typ ur båda argumenten, så ett `len` deklarerat som `std::size_t`
eller ett `seq` deklarerat som `std::uint32_t` slösar inte bara utrymme; testerna slutar kompilera.

`serialize()` och `deserialize()` är **redan deklarerade** i den filen, dokumenterade och korrekt
kvalificerade (`const noexcept` respektive `noexcept`). Låt de deklarationerna vara; ni skriver
deras definitioner i steg 4 och 5.

### 4. Implementera serialiseringsmetoden
Ramningsintroduktionens `checksum16()`, `writeToBuf()` och `readFromBuf()` ingår **inte** i den
utdelade koden, och båda metoderna nedan behöver alla tre. Kopiera in dem i
[`comm/frame.cpp`](./code/source/comm/frame.cpp), i en anonym namnrymd ovanför metoddefinitionerna,
så att de förblir privata för den filen:

```cpp
namespace
{
// checksum16(), writeToBuf() and readFromBuf() from the framing introduction go here.
} // namespace
```

Två saker om den kopieringen, som kompilatorn båda berättar för er först i efterhand:
* `writeToBuf()` och `readFromBuf()` är begränsade med `std::is_unsigned`, och ingenting i
  inkluderingskedjan för `frame.cpp` (`comm/frame.hpp` → `comm/def.hpp` → `<cstddef>`, `<cstdint>`)
  drar in `<type_traits>`. Lägg till den inkluderingen högst upp i filen.
* Ha ramningsintroduktionens varning i åtanke när ni anropar dem: `writeToBuf()` skriver `sizeof(T)`
  byte härledda ur *argumentet*, inte ur fältet, så casta till fältets egen bredd vid varje
  anropsställe.

Implementera sedan metoden `comm::Frame::serialize()` så att den skriver följande till den givna
bufferten:
* `SOF = 0xA5F7` (big-endian).
* LEN: nyttolastens längd.
* TYPE: ramtypen.
* DST: destinationsadressen.
* SRC: källadressen.
* SEQ: sekvensnumret (big-endian).
* DATA: nyttolasten, i samma ordning som den ligger i ramens nyttolastbuffert.
* CHK: checksumman, beräknad över alla föregående fält, byte för byte.

Returnera:
* Ramens totala längd om serialiseringen lyckades.
* `0U` vid fel, vilket betyder en `buf` som är null eller en `bufLen` som är mindre än ramen som ska
  skrivas (`HeaderLen + len + FooterLen`). Båda har ett eget test; ingen av dem är valfri.

### 5. Implementera deserialiseringsmetoden
Implementera i samma fil metoden `comm::Frame::deserialize()` så att den:
* Validerar den givna datan, **i den här ordningen**, eftersom varje kontroll gör nästa säker att
  utföra:
  * `buf` är inte null, och `bufLen` är minst `MinFrameLen`. Ingenting har lästs ännu vid den här
    punkten, så det är det här som över huvud taget gör det tillåtet att läsa huvudet. Hoppa över
    det och läsningarna av SOF och LEN nedan springer utanför en för kort buffert innan någon annan
    kontroll får en chans.
  * SOF är korrekt.
  * LEN ligger inom gränserna, alltså högst `MaxDataLen` (10 byte, ur `comm/def.hpp`).
  * Den givna bufferten rymmer **hela** ramen som huvudet utger sig för, alltså
    `bufLen >= HeaderLen + len + FooterLen`. Det här är en andra, striktare längdkontroll, och den
    första ersätter den inte: en buffert som kapats efter nyttolasten lämnar ändå *något* där CHK
    borde ligga, och att läsa det som checksumman får en trunkerad ram att se hel ut.
  * Ramtypen är giltig, alltså att den mottagna byten ligger under `Unknown` (se
    ramningsintroduktionens avsnitt om ramtyper: det är hela skälet till att `Unknown` ligger ett
    steg bortom den sista riktiga typen).
  * Checksumman stämmer.
* Lagrar den givna datan i ramen, men först när allt av den är giltigt.

Två av de punkterna är kontroller som testerna straffar hårdast. En saknad null-kontroll får inget
test att fallera, den **kraschar hela körningen**, så ni ser en segfault och inget testnamn. En
buffertlängdskontroll som stannar vid huvudet fäller `DeserializeRejectsShortBuffer` och
`DeserializeRejectsTruncatedPayload` och ingenting annat, vilket är ett betydligt vänligare sätt att
få det sagt.

### 6. Validera er implementation
Enhetstesterna ligger bakom makrot `L01`, så ingenting körs förrän ni slår på det. Lägg till `-DL01`
i `CXX_FLAGS` i makefilen, där en `Todo`-kommentar markerar stället:

```makefile
CXX_FLAGS := -Wall -Werror -std=c++17 -Iinclude -DL01
```

Bygg och kör dem sedan från en Linuxterminal:

```bash
cd lectures/L10/appendix/code
make
```

Tills ni gör det rapporterar programmet att testerna är avstängda och avslutas med lyckat resultat,
oavsett om er implementation fungerar eller inte.

**Om bygget avbryts direkt med det här, är det inte er kod:**

```text
make[1]: *** No rule to make target 'lib'.  Stop.
make: *** [Makefile:26: ../../../../libs/test/libqacademy_test.a] Error 2
```

Testramverket ligger som en submodul i `libs/test`, och en klon utan `--recurse-submodules` lämnar
katalogen tom. Att den ändå *finns* är varför felet handlar om ett saknat make-mål och inte om en
saknad katalog: det är ramverkets makefil som inte är hämtad än. Hämta den en gång, från repots
rot:

```bash
git submodule update --init
```

Övningen behöver också en C++-kompilator: `sudo apt -y install g++` på WSL/Ubuntu. Se
[förkunskaperna i README](../../../README.md#att-bygga).

Testerna kontrollerar båda metoderna mot ramarna ni byggde för hand i del I:
* PING-bytesen ur ramningsintroduktionen, och båda ramarna ur del I, byte för byte.
* En rundtur genom serialisering och deserialisering som måste bevara varje fält.
* Avvisningsfallen: felaktig SOF, felaktig checksumma, ogiltig typ, trunkerad buffert,
  nullpekare.

Varje test som passerar skrivs ut i grönt; ett som fallerar skrivs ut i rött och namnger uttrycket,
båda värdena och raden, så att ni kan jämföra direkt mot er egen pappersuträkning. Räkna med att se
alla fallera först, och gå gröna en grupp i taget medan ni arbetar er igenom steg 2-5.

Två saker som är värda att veta i förväg:
* Testerna läser `frame.type`, `frame.dst`, `frame.src`, `frame.seq`, `frame.len` och `frame.data`
  direkt, så de medlemsnamnen måste stämma. Har ni döpt era till något annat står det er fritt att
  ändra testerna så att de matchar.
* `DeserializeLeavesFrameUntouchedOnFailure` ger `deserialize()` en korrupt buffert och kontrollerar
  sedan att ramens fält är *oförändrade*. En `deserialize()` som kopierar in fält i ramen medan den
  parsar dem passerar alla andra tester och fäller det här.

---

