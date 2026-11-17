# Politica di sicurezza

## Versioni supportate

Le segnalazioni vengono valutate rispetto alla versione più recente del ramo `main`. Il progetto è ancora in fase di sviluppo e l'anteprima locale non è un servizio di produzione.

## Segnalare una vulnerabilità

Segnala le vulnerabilità in privato tramite [GitHub Security Advisories](https://github.com/AlexMarinucci99/Master-Lines/security/advisories/new), usando **Report a vulnerability**. Non inserire dettagli sfruttabili, credenziali o dati personali nelle issue pubbliche.

Nella segnalazione indica i passaggi per riprodurre il problema, la versione interessata e l'impatto osservato. Includi solo i dati minimi necessari. Il manutentore esaminerà la segnalazione e potrà chiedere ulteriori informazioni attraverso GitHub.

## Gestione del progetto

- Non inserire nel repository password, token, chiavi segrete Supabase o backup contenenti informazioni sensibili. La chiave pubblicabile Supabase è destinata al client; le chiavi secret e service role devono restare sul server.
- La modalità `JIVAIO_LOCAL_ADMIN_PREVIEW` disabilita l'accesso al gestionale nelle sole build debug: utilizzala in locale, senza esporla pubblicamente.
- Verifica le autorizzazioni e le policy RLS di Supabase prima di collegare e pubblicare i dati. Il semplice nascondimento dei controlli nell'interfaccia non protegge il database.
- Aggiorna le dipendenze e controlla le segnalazioni di sicurezza prima della distribuzione.
