# JiVaio Web

Web app per consultare linee, fermate e orari del trasporto pubblico dell’Aquila, con un gestionale per aggiornare dati e avvisi di servizio.

**[Apri JiVaio Web](https://alexmarinucci99.github.io/JiVaio-webapp/)**

## Funzionalità

- Ricerca delle linee, percorsi per direzione e prossime partenze.
- Avvisi di servizio e linee preferite, salvate nel browser.
- Gestionale riservato per modificare orari, linee e avvisi e gestire backup JSON.
- Acquisizione degli avvisi AMA come bozze da verificare prima della pubblicazione.

Gli orari disponibili sono un’anteprima storica incompleta e devono essere verificati. Posizione dei mezzi e ritardi automatici richiedono un feed in tempo reale dell’operatore.

## Lingue e avvisi

Il selettore della lingua conserva la scelta nel browser. Per tradurre un avviso nuovo o già pubblicato, aprilo nel gestionale, espandi **Traduzioni**, scegli la lingua e compila titolo, riepilogo e dettagli. Salva l’avviso. Se modifichi un campo italiano, ricontrolla e reinserisci le traduzioni di quel campo.

Il sito cerca prima la traduzione salvata nell’avviso, poi una corrispondenza esatta nel catalogo degli avvisi inclusi. Se entrambe mancano mostra il testo italiano originale. Le bozze provenienti da AMA seguono lo stesso flusso di revisione.

## Tecnologie

Flutter Web · Supabase Auth · PostgreSQL · Row Level Security

## Avvio locale

```sh
flutter pub get
flutter run -d web-server --web-port=8765 --web-hostname=127.0.0.1
```

Apri `http://127.0.0.1:8765/`; il gestionale è disponibile su `/#/admin` per gli utenti autorizzati. Per i dettagli sullo sviluppo dell’interfaccia consulta la [guida a VS Code](docs/guida-ui-vscode.md).

## Pubblicazione

Per GitHub Pages, compila con `flutter build web --release --base-href /JiVaio-webapp/` e pubblica il contenuto di `build/web` sul ramo `gh-pages`.

## Sicurezza e privacy

Consulta [SECURITY.md](SECURITY.md) per le segnalazioni di sicurezza e [PRIVACY.md](PRIVACY.md) per la bozza dell’informativa. Le chiavi segrete e service-role non devono essere inserite nel client o nel repository.
