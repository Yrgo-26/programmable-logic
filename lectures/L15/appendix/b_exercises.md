# Appendix B

## Övningar
De här övningarna befäster [Appendix A](./a_rx_shift_reg.md). Konstruera er egen
`rx_shift_reg.vhd` utifrån specifikationen där; den utdelade testbänken (kör den enligt
[simuleringsflödet](../../../info/simulation_workflow.md)) är kontrollen av att den beter sig
korrekt.

---

## Övning 1 - Implementera om `rx_shift_reg.vhd` utifrån specifikationen
Skriv er egen `rx_shift_reg.vhd` utifrån Appendix A. Verifiera den:

```bash
cd controller
ghdl -a --std=93 can_def.vhd rx_shift_reg.vhd rx_shift_reg_tb.vhd
ghdl -e --std=93 rx_shift_reg_tb
ghdl -r --std=93 rx_shift_reg_tb --assert-level=error
```

Om en kontroll fallerar, läs assertion-meddelandet; det namnger exakt vilket sampel det gäller och
vad som förväntades.

---

## Övning 2 - Ett medvetet stoppbitsbrott
**a)** Konstruera (på papper) en 6-bitars sekvens på ledningen som utgör ett äkta brott mot
stoppbitsregeln: fem lika riktiga bitar i rad, följda av en sjätte lika bit där en stoppbit skulle
ha brutit följden.

**b)** Mata in er sekvens från (a) i `rx_shift_reg` (antingen genom att utöka `rx_shift_reg_tb.vhd`
eller genom att skriva en kort ny testbänk) och bekräfta att `stuff_error` pulsar på exakt den 6:e
biten, inte tidigare.

**c)** `rx_shift_reg` försöker inte återhämta sig eller omsynkronisera efter ett `stuff_error`; den
rapporterar det bara under en cykel och fortsätter att ackumulera som om ingenting hänt. Förklara,
med en eller två meningar, varför det är en godtagbar design här, givet hur `can_controller` (L17)
kommer att reagera på det.

---

## Övning 3 - Högerjusteringen, och det som ligger ovanför den
Appendix A säger att en färdig grupp hamnar **högerjusterad i sina lägsta `bit_count` bitar**,
och att `can_controller` förlitar sig på det när det skivar upp rekonstruerade fält. Test 3 och 4 i
den utdelade testbänken prövar det: en 6-bitars grupp, sedan en 3-bitars grupp, utan reset
emellan, med `bit_count` ändrat mellan grupperna på precis det sätt `can_controller` gör mellan ett
fält och nästa.

Anta en nyss nollställd `rx_shift_reg`, `enable = '1'` och inga stoppbitar någonstans (ingen följd
når någonsin fem). Processen i Appendix A skiftar in varje accepterad bit i registrets minst
signifikanta ände och nollställer aldrig registret mellan grupper; anta att er gör detsamma. Den
utdelade testbänken kräver egentligen inte det, och del (d) återkommer till varför.

**a)** Mata med `bit_count = 6` in de sex bitarna `0 1 0 1 0 1` (i den ordningen, en per `sample`).
Skriv ut alla åtta bitarna i `data` när `valid` pulsar. Vad står i `data(7 downto 6)`, och varför?

**b)** Sätt `bit_count = 3` utan att nollställa, och mata in `0 1 1`. Skriv ut alla åtta bitarna i
`data` när `valid` pulsar igen. Vad står nu i `data(7 downto 3)`?

**c)** Ert svar på (b) visar att bitarna ovanför `bit_count` håller rester från det *föregående*
gruppen. Förklara varför det är ofarligt här, och vad `can_controller` måste göra (och aldrig får
göra) när det läser `rxsr_data` för ett fält som är smalare än 8 bitar.

**d)** `rx_shift_reg` håller två ganska olika sorters tillstånd: skiftregistret som ackumulerar det
aktuella gruppen, och följdräknaren (`consecutive`, `last_bit`) som avgör var stoppbitar hör hemma.
Att nollställa dem är inte lika säkert i båda fallen.

* Anta att modulen nollställde sitt **skiftregister** vid varje `valid`. Vilket av era svar ovan
  skulle ändras, och skulle något fält någonsin bli *felläst* som en följd? Notera att den utdelade
  testbänken bara kontrollerar de lägsta `bit_count` bitarna i `data`, så båda designerna passerar
  den.
* Anta att den nollställde **följdräknaren** i samma ögonblick. Namnge vad som går sönder, och säg
  vilken regel från L14 det speglar.

Skillnaden mellan de två svaren är skälet till att Appendix A säger att följdräknaren nollställs
"bara av reset" och inte säger någonting alls om skiftregistret.

---

