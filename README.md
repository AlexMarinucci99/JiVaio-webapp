# Master-Lines · JiVaio Web

Nuova app Flutter Web autonoma per consultare le linee del trasporto pubblico dell'Aquila e pubblicare avvisi di servizio. Il progetto è separato dalla app Flutter mobile.

## Stack proposto

- Flutter Web per la UI pubblica e il gestionale.
- Supabase Auth per l'accesso dell'amministratore.
- PostgreSQL su Supabase per linee, fermate, corse, orari e avvisi.
- Supabase Realtime per aggiornare gli avvisi pubblicati nei browser aperti.

Gli orari seguono il modello GTFS. Un import da PDF o Excel produrrà una bozza da controllare prima della pubblicazione. Le credenziali cloud saranno fornite in locale o nell'ambiente di hosting; non vanno committate.

## Prima versione

- Home con ricerca di linee e avviso in evidenza.
- Elenco completo delle linee e dettaglio per direzione.
- Avvisi di servizio con periodo di validità e linee coinvolte.
- Gestionale protetto per modificare orari e pubblicare avvisi.

## Stato della demo locale

- Le pagine Home, Linee, Dettaglio, Avvisi e Gestionale sono realizzate in Flutter Web.
- La schermata Linee legge i file GTFS JSON copiati da JiVaio e li trasforma in linee, direzioni, partenze e fermate.
- I dati iniziali sono una **anteprima storica incompleta**; non rappresentano l'elenco AMA aggiornato.
- `/admin` è separato dalla navigazione pubblica e richiede un account Supabase presente in `admin_users`; senza configurazione Supabase mostra solo la schermata di configurazione.
- Le modifiche del gestionale restano ancora nel `localStorage` del browser corrente: Auth e autorizzazione sono predisposte, ma i dati non sono ancora sincronizzati con il database condiviso.
- È disponibile l'esportazione di un backup JSON del contenuto locale.
- La migrazione Supabase definisce il modello GTFS e gli avvisi, ma non è stata eseguita su un progetto cloud. `supabase/bootstrap_admin.sql` mostra come autorizzare manualmente il proprio utente.

Gli avvisi inseriti a mano si aggiornano subito nel sito. Posizione dei mezzi e ritardi automatici richiedono un feed realtime dell'operatore.

## Avvio locale

```sh
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL='https://YOUR-PROJECT.supabase.co' \
  --dart-define=SUPABASE_PUBLISHABLE_KEY='YOUR-PUBLISHABLE-KEY'
```

La publishable key è destinata al client; non inserire mai una secret/service-role key nella app. Prima dell'accesso: applicare la migrazione, creare il proprio utente Auth e autorizzarne l'UUID con `supabase/bootstrap_admin.sql`. Prossime attività: collegare le schermate del gestionale alle tabelle cloud, importare e controllare i dati AMA aggiornati, poi distribuire il sito.

## Concept grafici

Le immagini di riferimento sono in [`design/concepts/`](design/concepts/). La lista linee riprende la schermata Android condivisa e la adatta a desktop e mobile.
