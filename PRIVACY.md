# Privacy · bozza per Master-Lines / JiVaio Web

**Stato: bozza da completare prima della pubblicazione del servizio.** Questo documento descrive quanto emerge dal progetto in sviluppo e non costituisce ancora l'informativa definitiva per gli utenti.

## Dati da completare

- Titolare del trattamento e recapiti: **da indicare**.
- Indirizzo di contatto per le richieste privacy: **da indicare**.
- Hosting effettivo, eventuali fornitori e relativi trattamenti: **da verificare**.
- Finalità, basi giuridiche, tempi di conservazione, destinatari e possibili trasferimenti fuori dallo Spazio economico europeo: **da determinare per il servizio effettivamente distribuito**.
- Modalità per esercitare i diritti e presentare reclamo: **da completare con i recapiti applicabili**.

## Funzioni attuali del progetto

La consultazione pubblica delle linee e degli avvisi è prevista senza registrazione. Nella preview attuale, dati di anteprima e preferiti sono memorizzati nel `localStorage` del browser utilizzato. Un backup JSON esportato viene salvato dall'utente sul proprio dispositivo; le informazioni contenute dipendono dai dati inseriti. L'importazione legge il file scelto dall'utente nel browser.

L'accesso al gestionale configurato usa Supabase Auth e richiede un account amministratore abilitato; l'autenticazione comporta il trattamento dei dati dell'account e della sessione. I dati del gestionale della preview sono locali e non sono ancora sincronizzati con il database condiviso.

Il progetto non include al momento un sistema applicativo di pubblicità o statistiche. Gli eventuali log e trattamenti dell'hosting, le richieste a fornitori esterni e le impostazioni effettive di Supabase devono essere verificati nella configurazione distribuita prima di descriverli nell'informativa definitiva.

## Prima della pubblicazione

Completare l'informativa sulla base della configurazione effettiva e delle informazioni previste dall'[articolo 13 del GDPR](https://www.garanteprivacy.it/documents/10160/0/Regolamento%20UE%202016%20679.%20Arricchito%20con%20riferimenti%20ai%20Considerando%20Aggiornato%20alle%20rettifiche%20pubblicate%20sulla%20Gazzetta%20Ufficiale%20%20dell%27Unione%20europea%20127%20del%2023%20maggio%202018). Se si aggiungono pubblicità, statistiche o altri strumenti di tracciamento, valutarne l'informativa e gli eventuali obblighi di consenso secondo le [indicazioni del Garante](https://garanteprivacy.it/web/guest/home/docweb/-/docweb-display/docweb/9687505) prima di attivarli.
