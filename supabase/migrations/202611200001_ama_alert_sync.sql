-- AMA synchronization metadata is private; existing line data is untouched.
begin;
create table private.ama_alert_sync (
  external_id bigint primary key,
  alert_id text not null unique,
  source_modified_at timestamptz not null,
  source_payload jsonb not null,
  pending_update boolean not null default false,
  last_seen_at timestamptz not null default now()
);
alter table private.ama_alert_sync enable row level security;
revoke all on private.ama_alert_sync from public, anon, authenticated;

create table private.ama_sync_state (
  singleton boolean primary key default true check (singleton),
  automatic_enabled boolean not null default false,
  last_attempt timestamptz,
  last_success timestamptz,
  last_error text
);
alter table private.ama_sync_state enable row level security;
revoke all on private.ama_sync_state from public, anon, authenticated;
insert into private.ama_sync_state(singleton) values (true);

create function public.jivaio_ama_status()
returns jsonb language plpgsql security definer set search_path = '' as $$
begin
  if coalesce(auth.role(), '') <> 'service_role' and not private.is_jivaio_admin() then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  return (select jsonb_build_object('automatic_enabled', automatic_enabled,
    'last_attempt', last_attempt, 'last_success', last_success, 'last_error', last_error)
    from private.ama_sync_state where singleton);
end $$;
revoke all on function public.jivaio_ama_status() from public, anon;
grant execute on function public.jivaio_ama_status() to authenticated, service_role;

create function public.jivaio_ama_set_enabled(p_enabled boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not private.is_jivaio_admin() then raise exception 'Not authorized' using errcode = '42501'; end if;
  if p_enabled is null then raise exception 'Invalid value'; end if;
  update private.ama_sync_state set automatic_enabled = p_enabled where singleton;
end $$;
revoke all on function public.jivaio_ama_set_enabled(boolean) from public, anon;
grant execute on function public.jivaio_ama_set_enabled(boolean) to authenticated;

create function public.jivaio_ama_record_attempt(p_success boolean, p_error text default null)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if coalesce(auth.role(), '') <> 'service_role' then raise exception 'Not authorized' using errcode = '42501'; end if;
  update private.ama_sync_state set last_attempt = now(),
    last_success = case when p_success then now() else last_success end,
    last_error = case when p_success then null else left(coalesce(p_error, 'Errore di sincronizzazione'), 200) end
    where singleton;
end $$;
revoke all on function public.jivaio_ama_record_attempt(boolean, text) from public, anon, authenticated;
grant execute on function public.jivaio_ama_record_attempt(boolean, text) to service_role;

-- One transaction per batch. An advisory lock serializes overlapping runs.
-- Changed source material is stored for review, never written over local edits.
create function public.jivaio_ingest_ama_alerts(p_posts jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  post jsonb; body jsonb; source_id bigint; local_id text; modified_at timestamptz;
  previous private.ama_alert_sync%rowtype; inserted integer := 0; changed integer := 0;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  if jsonb_typeof(p_posts) is distinct from 'array' or jsonb_array_length(p_posts) > 100 then
    raise exception 'Invalid batch';
  end if;
  perform pg_advisory_xact_lock(hashtext('jivaio-ama-sync'));
  for post in select value from jsonb_array_elements(p_posts) loop
    source_id := (post ->> 'externalId')::bigint;
    modified_at := (post ->> 'modifiedAt')::timestamptz;
    body := post -> 'payload';
    local_id := 'ama-' || source_id::text;
    if source_id is null or source_id <= 0 or modified_at is null
       or jsonb_typeof(body) is distinct from 'object'
       or body ->> 'id' is distinct from local_id
       or body -> 'isPublished' is distinct from 'false'::jsonb
       or coalesce(body ->> 'sourceUrl', '') !~ '^https://www\.ama\.laquila\.it/' then
      raise exception 'Invalid AMA post';
    end if;
    select * into previous from private.ama_alert_sync where external_id = source_id;
    if not found then
      insert into public.app_alerts(id, payload, is_published, ends_at)
        values (local_id, body, false, null)
        on conflict (id) do nothing;
      -- Never attach to a pre-existing record with an identical ID.
      if found then
        insert into private.ama_alert_sync(external_id, alert_id, source_modified_at, source_payload)
          values (source_id, local_id, modified_at, body);
        inserted := inserted + 1;
      end if;
    else
      if previous.source_payload is distinct from body then
        changed := changed + 1;
      end if;
      update private.ama_alert_sync set
        source_modified_at = greatest(source_modified_at, modified_at),
        source_payload = case when modified_at >= source_modified_at then body else source_payload end,
        pending_update = pending_update or (modified_at >= source_modified_at and source_payload is distinct from body),
        last_seen_at = now()
      where external_id = source_id;
    end if;
  end loop;
  return jsonb_build_object('inserted', inserted, 'changed', changed);
end;
$$;
revoke all on function public.jivaio_ingest_ama_alerts(jsonb) from public, anon, authenticated;
grant execute on function public.jivaio_ingest_ama_alerts(jsonb) to service_role;
-- Authenticated administrators can inspect and acknowledge source changes.
create function public.jivaio_ama_pending_updates()
returns table(external_id bigint, alert_id text, source_modified_at timestamptz, source_payload jsonb)
language plpgsql security definer set search_path = '' as $$
begin
  if not private.is_jivaio_admin() then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  return query select s.external_id, s.alert_id, s.source_modified_at, s.source_payload
    from private.ama_alert_sync s where s.pending_update order by s.source_modified_at desc;
end;
$$;
revoke all on function public.jivaio_ama_pending_updates() from public, anon;
grant execute on function public.jivaio_ama_pending_updates() to authenticated;

-- Acknowledge only the version the administrator actually reviewed.
create function public.jivaio_ama_ack_update(p_external_id bigint, p_modified_at timestamptz, p_source_payload jsonb)
returns boolean language plpgsql security definer set search_path = '' as $$
begin
  if not private.is_jivaio_admin() then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  update private.ama_alert_sync set pending_update = false
    where external_id = p_external_id and source_modified_at = p_modified_at and source_payload = p_source_payload and pending_update;
  return found;
end;
$$;
revoke all on function public.jivaio_ama_ack_update(bigint, timestamptz, jsonb) from public, anon;
grant execute on function public.jivaio_ama_ack_update(bigint, timestamptz, jsonb) to authenticated;

commit;
