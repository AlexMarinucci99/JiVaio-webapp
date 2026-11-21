-- Apply only after the AMA migration and Edge Function have been deployed and
-- verified. The project URL and legacy service-role JWT must already exist in
-- Supabase Vault as jivaio_project_url and jivaio_ama_service_role.
-- Do not paste actual secrets into this file or commit them to the repository.
begin;
create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;
do $$
begin
  if not exists (select 1 from vault.decrypted_secrets where name = 'jivaio_project_url')
     or not exists (select 1 from vault.decrypted_secrets where name = 'jivaio_ama_service_role') then
    raise exception 'AMA scheduler secrets missing from Vault';
  end if;
end;
$$;
select cron.schedule(
  'jivaio-ama-sync', '*/15 * * * *',
  $job$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'jivaio_project_url') || '/functions/v1/ama-sync',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', (select decrypted_secret from vault.decrypted_secrets where name = 'jivaio_ama_service_role'),
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'jivaio_ama_service_role')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 30000
  );
  $job$
);
commit;
