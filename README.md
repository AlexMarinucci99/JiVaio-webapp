# Master-Lines · JiVaio Web

Nuova app Flutter Web autonoma per consultare le linee del trasporto pubblico dell'Aquila e pubblicare avvisi di servizio. Il progetto è separato dalla app Flutter mobile.

## Stack

- Flutter Web per la UI pubblica e il gestionale.
- Supabase Auth per l'accesso dell'amministratore.
- PostgreSQL su Supabase per linee, fermate, corse, orari e avvisi.
- Controllo delle revisioni ogni 20 secondi per aggiornare linee e avvisi nei browser aperti.
- Consultazione pubblica senza registrazione; le policy RLS consentono la lettura anonima dei soli dati pubblicati.

Gli orari seguono il modello GTFS. Un import da PDF o Excel produrrà una bozza da controllare prima della pubblicazione. La publishable key Supabase è pubblica e può essere inclusa nel client; le chiavi secret e service-role non devono mai essere inserite nel codice o nella repository.

## Prima versione

- Home con ricerca di linee e avviso in evidenza.
- Elenco completo delle linee e dettaglio per direzione.
- Avvisi di servizio con periodo di validità e linee coinvolte.
- Gestionale protetto per modificare orari e pubblicare avvisi.

## Funzioni disponibili

- Le pagine Home, Linee, Dettaglio, Avvisi e Gestionale sono realizzate in Flutter Web.
- La schermata Linee legge i dati condivisi da Supabase. I vecchi file GTFS rimangono disponibili solo per la modalità locale esplicita.
- Il gestionale permette di modificare ogni partenza come una corsa autonoma, con fermate e orari intermedi specifici; una corsa può iniziare da una fermata diversa dalle altre.
- Ogni corsa può avere una nota facoltativa, visibile nel dettaglio della linea quando si seleziona quella partenza e inclusa nei backup.
- Gli orari intermedi possono essere contrassegnati come stimati: nel gestionale usa il selettore «Orario stimato» oppure `~` prima dell'orario; la pagina pubblica mostra la dicitura «stimato».
- Le linee circolari, come A e B, non richiedono andata e ritorno: il percorso si definisce per ciascuna partenza.
- I vecchi dati locali restano leggibili: per le linee circolari, le sezioni Andata/Ritorno vengono unite in un solo circuito per calendario. Il percorso generico resta sulla prima partenza; le altre richiedono la verifica delle fermate e degli orari intermedi.
- I dati iniziali sono una **anteprima storica incompleta**; non rappresentano l'elenco AMA aggiornato.
- `/admin` è separato dalla navigazione pubblica e richiede un account Supabase presente in `admin_users`; senza configurazione Supabase mostra solo la schermata di configurazione.
- Le modifiche salvate nel gestionale sono condivise tramite Supabase. I preferiti restano specifici del browser.
- Il gestionale esporta un backup JSON completo (linee e avvisi) oppure di una singola linea.
- Ogni linea può essere mostrata o nascosta agli utenti: la scelta è salvata su Supabase e applicata anche tramite le policy di accesso.
- Da un backup si può importare tutto il contenuto oppure una singola linea, anche se il file contiene più linee. L'importazione unisce i dati: gli ID presenti nella selezione aggiornano i record corrispondenti; gli altri record e i preferiti locali restano.
- Le migrazioni in `supabase/migrations/` definiscono il database; quelle iniziali sono state applicate via SQL Editor, quindi la cronologia CLI non è inizializzata: non eseguire `supabase db push` prima di sincronizzarla. `supabase/bootstrap_admin.sql` mostra come autorizzare manualmente il proprio utente.

Gli avvisi inseriti a mano si aggiornano subito nel sito. Posizione dei mezzi e ritardi automatici richiedono un feed realtime dell'operatore.

## Avvio locale

Per una guida passo passo a VS Code, al reload e alla simulazione smartphone, vedi [Modificare la UI in VS Code](docs/guida-ui-vscode.md).

```sh
flutter pub get
flutter run -d web-server --web-port=8765 --web-hostname=127.0.0.1
```

Apri `http://127.0.0.1:8765/` per il sito e `http://127.0.0.1:8765/#/admin` per accedere al gestionale con l'account autorizzato. Le modifiche salvate su Supabase sono condivise tra i browser; i preferiti sono locali. Un controllo leggero delle revisioni viene eseguito ogni 20 secondi. Non vengono usati dati locali come ripiego se il database non è raggiungibile.

URL del progetto e publishable key sono configurati per l'app. In un altro ambiente si possono sostituire con `--dart-define=SUPABASE_URL=...` e `--dart-define=SUPABASE_PUBLISHABLE_KEY=...`. Non inserire mai una secret/service-role key nell'app. Per una demo isolata esclusivamente locale, eseguire in debug con entrambi i valori vuoti e `--dart-define=JIVAIO_LOCAL_ADMIN_PREVIEW=true`; questa demo non sincronizza i dati.

Prima di un nuovo deployment, applicare le migrazioni, creare il proprio utente Auth e autorizzarne l'UUID con `supabase/bootstrap_admin.sql`. Verificare gli orari prima di presentarli come definitivi. Gli avvisi non vengono acquisiti automaticamente da AMA: vengono gestiti dall'amministratore.

## Anteprima pubblica per smartphone

La versione web può essere compilata con `flutter build web --release --base-href /Master-Lines/` e pubblicata su GitHub Pages dal ramo `gh-pages`. Il ramo contiene i file compilati di anteprima e va aggiornato a ogni pubblicazione: il push su `main` non aggiorna automaticamente il sito. La versione già pubblicata potrebbe essere precedente al codice locale: occorre ricompilarla e aggiornare il ramo per utilizzare Supabase. Prima della pubblicazione definitiva completare la privacy e verificare gli orari.

## Sicurezza e privacy

- [Segnalazioni di sicurezza](SECURITY.md): istruzioni per comunicare vulnerabilità in privato.
- [Privacy](PRIVACY.md): bozza da completare con titolare, recapiti e dettagli dei fornitori prima della pubblicazione.

## Concept grafici

Le immagini di riferimento sono in [`design/concepts/`](design/concepts/). La lista linee riprende la schermata Android condivisa e la adatta a desktop e mobile.
