# Master-Lines · JiVaio Web

Nuova app Flutter Web autonoma per consultare le linee del trasporto pubblico dell'Aquila e pubblicare avvisi di servizio. Il progetto è separato dalla app Flutter mobile.

## Stack proposto

- Flutter Web per la UI pubblica e il gestionale.
- Supabase Auth per l'accesso dell'amministratore.
- PostgreSQL su Supabase per linee, fermate, corse, orari e avvisi.
- Supabase Realtime per aggiornare gli avvisi pubblicati nei browser aperti.
- Consultazione pubblica senza registrazione; le policy RLS consentono la lettura anonima dei soli dati pubblicati.

Gli orari seguono il modello GTFS. Un import da PDF o Excel produrrà una bozza da controllare prima della pubblicazione. Le credenziali cloud saranno fornite in locale o nell'ambiente di hosting; non vanno committate.

## Prima versione

- Home con ricerca di linee e avviso in evidenza.
- Elenco completo delle linee e dettaglio per direzione.
- Avvisi di servizio con periodo di validità e linee coinvolte.
- Gestionale protetto per modificare orari e pubblicare avvisi.

## Stato della demo locale

- Le pagine Home, Linee, Dettaglio, Avvisi e Gestionale sono realizzate in Flutter Web.
- La schermata Linee legge i file GTFS JSON copiati da JiVaio e li trasforma in linee, direzioni, partenze e fermate.
- Il gestionale permette di modificare ogni partenza come una corsa autonoma, con fermate e orari intermedi specifici; una corsa può iniziare da una fermata diversa dalle altre.
- Ogni corsa può avere una nota facoltativa, visibile nel dettaglio della linea quando si seleziona quella partenza e inclusa nei backup.
- Gli orari intermedi possono essere contrassegnati come stimati: nel gestionale usa il selettore «Orario stimato» oppure `~` prima dell'orario; la pagina pubblica mostra la dicitura «stimato».
- Le linee circolari, come A e B, non richiedono andata e ritorno: il percorso si definisce per ciascuna partenza.
- I vecchi dati locali restano leggibili: per le linee circolari, le sezioni Andata/Ritorno vengono unite in un solo circuito per calendario. Il percorso generico resta sulla prima partenza; le altre richiedono la verifica delle fermate e degli orari intermedi.
- I dati iniziali sono una **anteprima storica incompleta**; non rappresentano l'elenco AMA aggiornato.
- `/admin` è separato dalla navigazione pubblica e richiede un account Supabase presente in `admin_users`; senza configurazione Supabase mostra solo la schermata di configurazione.
- Le modifiche del gestionale restano ancora nel `localStorage` del browser corrente: Auth e autorizzazione sono predisposte, ma i dati non sono ancora sincronizzati con il database condiviso.
- Il gestionale esporta un backup JSON completo (linee e avvisi) oppure di una singola linea.
- Da un backup si può importare tutto il contenuto oppure una singola linea, anche se il file contiene più linee. L'importazione unisce i dati: gli ID presenti nella selezione aggiornano i record corrispondenti; gli altri record e i preferiti locali restano.
- Lo schema iniziale è stato applicato al progetto Supabase `Master-Lines`; tutte le 12 tabelle hanno RLS attivo e sono configurate 22 policy. Il bootstrap di Supabase è stato eseguito dal SQL Editor, quindi la cronologia CLI delle migrazioni non è ancora inizializzata: non eseguire `supabase db push` prima di sincronizzarla. `supabase/bootstrap_admin.sql` mostra come autorizzare manualmente il proprio utente.

Gli avvisi inseriti a mano si aggiornano subito nel sito. Posizione dei mezzi e ritardi automatici richiedono un feed realtime dell'operatore.

## Avvio locale

```sh
flutter pub get
flutter run -d web-server --web-port=8765 --web-hostname=127.0.0.1 \
  --dart-define=JIVAIO_LOCAL_ADMIN_PREVIEW=true
```

Apri `http://127.0.0.1:8765/#/admin` per usare il gestionale di anteprima. In questa modalità le modifiche sono salvate soltanto nel `localStorage` del browser corrente. Il bypass di accesso è disponibile solo in debug e non funziona nelle build di produzione. Gli utenti pubblici non devono registrarsi.

Per avviare la versione collegata a Supabase:

```sh
flutter run -d chrome \
  --dart-define=SUPABASE_URL='https://YOUR-PROJECT.supabase.co' \
  --dart-define=SUPABASE_PUBLISHABLE_KEY='YOUR-PUBLISHABLE-KEY'
```

La publishable key è destinata al client; non inserire mai una secret/service-role key nella app. Prima dell'accesso: applicare la migrazione, creare il proprio utente Auth e autorizzarne l'UUID con `supabase/bootstrap_admin.sql`. Prossime attività: collegare le schermate del gestionale alle tabelle cloud, importare e controllare i dati AMA aggiornati, poi distribuire il sito.

## Sicurezza e privacy

- [Segnalazioni di sicurezza](SECURITY.md): istruzioni per comunicare vulnerabilità in privato.
- [Privacy](PRIVACY.md): bozza da completare con titolare, recapiti e dettagli dei fornitori prima della pubblicazione.

## Concept grafici

Le immagini di riferimento sono in [`design/concepts/`](design/concepts/). La lista linee riprende la schermata Android condivisa e la adatta a desktop e mobile.
