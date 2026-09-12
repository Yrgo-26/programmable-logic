# Appendix B

## Övningar
De här övningarna befäster [Appendix A](./a_can_controller.md). Ni bygger sändningsvägen, och
`can_controller_tb` driver två noder genom ett komplett utbyte, så den kan inte passera förrän L17
lägger till mottagningshalvan. `make build-project` vet det och rapporterar den som *överhoppad* i
stället för att köra den och misslyckas:

```text
==> can_controller_tb (skipped: can_controller.vhd has no receive path yet; ...)
```

Så bygget förblir grönt den här föreläsningen, och de här övningarna resonerar sig igenom
sändningsvägen och analyserar den i GHDL i stället. Testbänken blir domen om en föreläsning.

---

## Övning 1 - Följ en kort ram för hand

Skriv, utifrån ramformatet i L10 Appendix A och den här föreläsningens fälttabell, ut hela följden
av tillstånd som `can_controller` passerar (i TX-rollen) för att sända en ram med ID `0x001`, DLC
`0` (inget datafält), från `STATE_IDLE` tillbaka till `STATE_IDLE`. Notera för varje tillstånd
ungefär hur många bitperioder det upptar (med hänvisning till L10:s fältbredder).

---

## Övning 2 - Varför tillståndet `STATE_LOAD_*` finns

**a)** Förklara med egna ord vad som skulle gå fel om ett stoppat fält sekvenserades med ett enda
tillstånd som gav `tx_shift_reg`:s `load` *och* väntade på `done`, i stället för ett separat
`STATE_LOAD_*` på en cykel följt av skifttillståndet.

**b)** Peka ut den specifika tajmingregeln från L14 (att `tx_shift_reg`:s `load` presenterar direkt,
och dess `done` som kommer ett skift extra) som gör uppdelningen i två tillstånd nödvändig.

---

## Övning 3 - Vad som når `crc15`, och vad som inte gör det

**a)** Sortera för en sänd ram de här kategorierna av bitar i "matas in i `crc15`" och "utesluts":
SOF-biten, riktiga bitar ur ID, kontrollfält och data, instoppade stoppbitar, CRC-fältets egna
bitar, och den ostoppade svansen (CRC-avgränsare, ACK-plats, ACK-avgränsare, EOF). Säg för varje
utesluten kategori vad som utesluter den: antingen en term i
`crc_enable <= txsr_bit_valid and not txsr_stuff and role;`, eller det faktum att fältet aldrig
passerar genom `tx_shift_reg` över huvud taget.

**b)** En av de kategorierna kan överraska er: CRC-fältets egna bitar går tillbaka in i motorn.
Säg, med L13:s egenskap att generering och kontroll är samma operation, vilket värde registret
håller efter att den sista CRC-biten matats in, och namnge den kontroll i L17 som beror på precis
det värdet. Förklara sedan varför sändningsvägen, tagen för sig, inte beror på det: vad garanterar
`STATE_START`:s `clear` redan om den andra ram en nod sänder?

**c)** Anta att ni i stället hade grindat bort `crc_enable` under `STATE_CRC_HI` och `STATE_CRC_LO`.
Skulle den första ram en nod sänder bära en korrekt CRC? Skulle den andra? Var noga: att `crc15`
nollställs är en del av svaret. Säg sedan om någon simulering i den här kursen skulle fånga
ändringen, och vad det säger er om var det återmatade CRC-fältet faktiskt gör nytta.

---

## Övning 4 - Hur lång är en ram, exakt?

Att svara på det kräver att hela fälttabellen och stoppbitsregeln hålls i huvudet samtidigt, vilket
är själva poängen. Ta ramen `can_controller` sänder för ID `0x123`, DLC `3`, databytesen `FF 00 00`.

**a)** Skriv ut det stoppade området bit för bit, SOF till och med datafältets slut, med Appendix
A:s fälttabell. (Det ska bli 43 bitar: `1 + 11 + 1 + 2 + 4 + 24`.) Identifieraren är `0x123`; kom
ihåg att RTR, IDE och r0 alla är `0` och att DLC är `0011`.

**b)** CRC-15 över de 43 bitarna är `0x0FEE`, alltså `000111111101110` (ni kan bekräfta det mot er
`crc15` från L13 om ni vill). Lägg till den, vilket ger hela det stoppade området på 58 bitar, SOF
till och med CRC.

**c)** Tillämpa stoppbitsregeln över alla 58 bitarna och räkna de instoppade stoppbitarna. Håll koll
på gränsen mellan datafältets avslutande nollor och CRC:ns inledande nollor: följdräknaren
nollställs inte vid fältgränser (L10 Appendix A).

**d)** Lägg till den ostoppade svansen (CRC-avgränsare, ACK-plats, ACK-avgränsare, EOF) och ange det
totala antalet bitar som faktiskt drivs ut på ledningen. Hur många mikrosekunder är det vid
1 Mbit/s?

**e)** Samma ram med datan `11 22 33` behöver bara en stoppbit i stället för antalet ni fick i (c).
Förklara med en mening varför en rams varaktighet på en CAN-buss beror på *nyttolastens värde* och
inte bara på dess längd, och vad det innebär för den som försöker räkna ut värsta fallets
bustajming.

---

