# Modificare la UI di Master-Lines in VS Code

Questa guida riguarda il progetto web separato da JiVaio Android. La cartella di lavoro su questo computer è:

```text
/home/master/.codex/visualizations/2026/11/17/01a1e8f7-7d59-7571-98e2-ca206a4dd8ed/Master-Lines
```

## Aprire il progetto

1. Apri Visual Studio Code, scegli **File → Apri cartella**, seleziona la cartella qui sopra e conferma. In alternativa, da un terminale puoi eseguire:

   ```bash
   code /home/master/.codex/visualizations/2026/11/17/01a1e8f7-7d59-7571-98e2-ca206a4dd8ed/Master-Lines
   ```

2. Se VS Code lo propone, installa le estensioni **Flutter** e **Dart**.
3. Apri **Terminale → Nuovo terminale**. Controlla che il terminale sia nella cartella Master-Lines ed esegui una volta:

   ```bash
   flutter pub get
   ```

## Avviare e tenere aperta l'anteprima

Nel terminale di VS Code avvia:

```bash
flutter run -d web-server --web-port=8765 --web-hostname=127.0.0.1
```

Aspetta che compaia `lib/main.dart is being served at http://127.0.0.1:8765`, poi apri:

- Sito: `http://127.0.0.1:8765/`
- Gestionale: `http://127.0.0.1:8765/#/admin`

Lascia aperto il terminale mentre lavori. Accedi al gestionale con l’account amministratore autorizzato su Supabase.

Le modifiche salvate nel gestionale sono condivise tramite Supabase e compaiono anche negli altri browser, normalmente entro 20 secondi. I preferiti restano nel singolo browser. Continua a esportare periodicamente un backup dal gestionale prima di interventi importanti.

## Vedere una modifica

1. Modifica un file Dart e salvalo con **Ctrl+S**.
2. Nel terminale dove Flutter è in esecuzione premi **r** per richiedere il *hot reload*. Con il dispositivo `web-server`, l'aggancio del debugger dipende dal browser; se non vedi la modifica, ricarica la pagina del browser.
3. Se un cambiamento non viene applicato con il reload, premi **R** maiuscola per il *hot restart* o ferma e riavvia Flutter, poi ricarica la pagina. Chiudi eventuali moduli solo dopo aver salvato: riavvii e ricariche possono perdere le modifiche non ancora salvate nei moduli.
4. Per arrestare il server seleziona il suo terminale e premi **Ctrl+C**.

Se la porta `8765` è già occupata, usa il server già attivo o chiudilo prima di avviarne un altro. Una porta diversa usa gli stessi dati Supabase, ma richiede eventualmente un nuovo accesso e conserva preferiti separati.

## Dove modificare la grafica

- `lib/theme/jivaio_theme.dart`: colori, testi, pulsanti e stile generale.
- `lib/ui/jivaio_app.dart`: barra di navigazione, elementi comuni e layout della pagina.
- `lib/ui/public_pages.dart`: home, elenco linee, dettaglio di ogni linea e avvisi.
- `lib/ui/admin_page.dart`: schermata del gestionale e moduli di modifica.
- `lib/main.dart`: tema applicato e collegamento tra gli indirizzi e le schermate.

Per esempio, puoi aprire `lib/theme/jivaio_theme.dart`, cambiare il valore esadecimale di `JivaioColors.blue`, salvare e applicare il reload.

La palette principale usa superfici chiare, blu scuro per i testi e blu per azioni e selezioni. Bordi e testi secondari sono sfumature della stessa palette; avvisi ed errori mantengono colori dedicati per essere riconoscibili. Le immagini possono naturalmente contenere altri colori.

## Modificare il banner principale

- I testi del banner (titolo, descrizione e pulsante) sono in `lib/features/home/presentation/home_hero_content.dart`.
- Colori locali, gradiente, bordo, raggi, breakpoint responsive, dimensioni e spaziature sono in `lib/features/home/presentation/home_hero_style.dart`. I colori condivisi arrivano da `lib/theme/jivaio_theme.dart`.
- La composizione del banner e gli stili tipografici basati sul tema sono in `lib/features/home/presentation/widgets/home_hero.dart`.
- Per aggiungere uno sfondo all'intero banner, salva l'immagine in `assets/images/` (per esempio `sfondo.jpg`), aggiungi `- assets/images/sfondo.jpg` sotto `flutter: assets:` in `pubspec.yaml` e sostituisci `null` con `'assets/images/sfondo.jpg'` in `backgroundAssetPath` in `lib/features/home/presentation/home_hero_style.dart`. Esegui `flutter pub get` e riavvia Flutter. `BoxFit.cover` riempie il banner ritagliando le parti esterne; il filtro chiaro in `home_hero.dart` aiuta la leggibilità dei testi.
- La navigazione del pulsante è collegata in `lib/ui/public_pages.dart`, nella chiamata a `HomeHero`.

## Controllare la vista smartphone

Nel browser Chrome sul computer apri gli strumenti sviluppatore con **Ctrl+Shift+I**, poi attiva o disattiva la barra dei dispositivi con **Ctrl+Shift+M** e scegli una dimensione per telefono. Questa è una simulazione: controlla anche la pagina su un telefono reale quando disponibile.

L'indirizzo `127.0.0.1` sul telefono indica il telefono stesso, non il computer. Per una prova esterna puoi aprire l'anteprima [GitHub Pages](https://alexmarinucci99.github.io/Master-Lines/), verificando prima che la versione pubblicata sia stata aggiornata con il nuovo collegamento a Supabase.
