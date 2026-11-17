# JiVaio Web — design system iniziale

## Riferimenti

- `concepts/line-list-desktop.png`: elenco linee e scheletro delle card originali.
- `concepts/homepage.png`: home pubblica.
- `concepts/line-detail.png`: dettaglio linea, direzione e fermate.
- `concepts/alerts.png`: avvisi attivi.
- `concepts/admin.png`: gestione di linee e orari.

## Token visivi

- Sfondo pagina: azzurro-grigio molto chiaro `#F4F7FC`.
- Superfici: bianco `#FFFFFF`; bordi freddi `#DCE5F2`.
- Testo principale: blu notte `#191970`; testo secondario `#5D6675`.
- Accent e azioni: blu `#0754C5`; pill secondarie `#EAF2FF`.
- Stato attenzione: ambra; disservizio urgente: rosso, usati solo sugli avvisi pertinenti.
- Tipografia sans-serif leggibile, con titoli compatti e controlli ben distinguibili.
- Card bianche arrotondate, bordi sottili, ombre minime; spazio generoso su mobile.

## Componenti

- Navigazione web superiore su desktop; navigazione a fondo pagina su mobile.
- Card linea con codice, capolinea, fermate, prossime partenze e apertura del dettaglio.
- Dettaglio con selettore Andata/Ritorno, calendario di servizio e sequenza fermate.
- Avviso con titolo, fonte, periodo, gravità e linee interessate.
- Gestionale con tabelle editabili, import in bozza, controllo e pubblicazione.

## Responsive

Sotto 760 px: una colonna, card linea impilate e navigazione inferiore. Da 760 px in su: header superiore; l'elenco linee usa due colonne solo quando ogni card mantiene testo e controlli leggibili.
