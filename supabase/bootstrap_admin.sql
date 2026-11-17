-- 1. Crea il tuo utente in Supabase Auth (Dashboard > Authentication > Users).
-- 2. Copia il suo UUID dalla tabella auth.users e sostituisci il valore qui sotto.
-- 3. Esegui questo script nel SQL Editor del progetto Supabase.
-- Non aggiungere policy di INSERT a admin_users: l'abilitazione deve restare manuale.

insert into public.admin_users (user_id)
values ('SOSTITUISCI-CON-UUID-DA-auth.users'::uuid)
on conflict (user_id) do nothing;
