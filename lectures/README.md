# Föreläsningsmaterial

Kursen består av tjugo pass om tre timmar. De åtta första bygger upp VHDL från grunden, det
nionde är den första praktiska tentamen, de tio därpå är grupprojektet, och det tjugonde är den
andra praktiska tentamen.

---

## Del 1 - Digital konstruktion i VHDL
* [L01](./L01/README.md): Kombinatorik och första VHDL - grindar, sanningstabeller, boolesk
  algebra, CircuitVerse, och en komplett `entity`/`architecture`-modul.
* [L02](./L02/README.md): Större nät, multiplexrar och submoduler - en 4-till-1-mux som
  introducerar `process` och `case`, Karnaughdiagram, designer av mer än en entitet, och hur du
  kontrollerar ditt arbete med en testbänk.
* [L03](./L03/README.md): Sekvensnät - register, D-vippor, klockning och flankdetektering.
* [L04](./L04/README.md): Metastabilitet och synkronisering - asynkrona ingångar,
  synkroniserare, studsfiltrering och generics.
* [L05](./L05/README.md): Variabler och hårdvaran under - `signal` kontra `variable`, och vad
  syntesen faktiskt bygger på FPGA:n.
* [L06](./L06/README.md): Räknare och skiftregister - överslag, SIPO och PISO, och en 8-bitars
  seriemottagare.
* [L07](./L07/README.md): Timers - byggd för hand i CircuitVerse, sedan i VHDL, som taktar en
  vandrande lysdiod på FPGA:n.
* [L08](./L08/README.md): Tillståndsmaskiner - konstruerade för hand, sedan i VHDL, Moore och
  Mealy, med demonstration på kort.

---

## Examination 1
* [L09](./L09/README.md): **Praktisk tentamen 1** - sekvensnät. Individuell, tre timmar.

---

## Del 2 - Grupprojektet: en CAN-kontroller
* [L10](./L10/README.md): Projektstart: CAN-bussen, ramen och `can_def`.
* [L11](./L11/README.md): Arkitektur, toppnivån, registerkartan och simulering.
* [L12](./L12/README.md): Synkronisering och bittimern.
* [L13](./L13/README.md): CRC-15-motorn.
* [L14](./L14/README.md): Sändningsskiftregister och bitstoppning.
* [L15](./L15/README.md): Mottagningsskiftregister och avstoppning, samt
  kodgranskningsseminariet.
* [L16](./L16/README.md): CAN-kontrollern I: tillståndsmaskinen och sändvägen.
* [L17](./L17/README.md): CAN-kontrollern II: mottagning och arbitrering.
* [L18](./L18/README.md): Registerbanken och SPI från vågformen.
* [L19](./L19/README.md): SPI-bryggan, `can_spi_node` och bring-up mot AVR32DB28.

Projektets uppgift, arbetsform och bedömning finns i
[projektspecifikationen](../project/README.md).

---

## Examination 2
* [L20](./L20/README.md): **Praktisk tentamen 2** - CAN-moduler. Individuell, tre timmar.

---
