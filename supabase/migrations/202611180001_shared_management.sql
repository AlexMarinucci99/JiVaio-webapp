-- Shared editable line and alert records for the existing Flutter manager.
-- The previous GTFS tables are left untouched. Each line keeps its complete
-- validated application payload; only its visibility and revision are indexed.
-- Apply after 202611170001_initial_schema.sql.

begin;

do $$
begin
  if to_regprocedure('private.is_jivaio_admin()') is null then
    raise exception 'Apply the initial JiVaio schema before this migration';
  end if;
end
$$;

create table public.app_lines (
  id text primary key,
  payload jsonb not null,
  is_visible boolean not null default false,
  revision bigint not null default 1,
  updated_at timestamptz not null default now(),
  constraint app_lines_object check (jsonb_typeof(payload) = 'object'),
  constraint app_lines_id_matches check ((payload ->> 'id') is not distinct from id),
  constraint app_lines_visibility_matches check (
    jsonb_typeof(payload -> 'isVisible') is not distinct from 'boolean'
    and (payload ->> 'isVisible')::boolean = is_visible
  )
);

create table public.app_alerts (
  id text primary key,
  payload jsonb not null,
  is_published boolean not null default false,
  ends_at timestamptz,
  revision bigint not null default 1,
  updated_at timestamptz not null default now(),
  constraint app_alerts_object check (jsonb_typeof(payload) = 'object'),
  constraint app_alerts_id_matches check ((payload ->> 'id') is not distinct from id),
  constraint app_alerts_publication_matches check (
    jsonb_typeof(payload -> 'isPublished') is not distinct from 'boolean'
    and (payload ->> 'isPublished')::boolean = is_published
  )
);

create function private.bump_jivaio_app_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.revision := old.revision + 1;
  new.updated_at := now();
  return new;
end;
$$;

revoke all on function private.bump_jivaio_app_revision() from public, anon, authenticated;
create trigger app_lines_revision before update on public.app_lines
  for each row execute function private.bump_jivaio_app_revision();
create trigger app_alerts_revision before update on public.app_alerts
  for each row execute function private.bump_jivaio_app_revision();

alter table public.app_lines enable row level security;
alter table public.app_alerts enable row level security;

revoke all on public.app_lines, public.app_alerts from public, anon, authenticated;
grant select on public.app_lines, public.app_alerts to anon, authenticated;
grant insert, update, delete on public.app_lines, public.app_alerts to authenticated;

create policy "public read visible app lines" on public.app_lines
  for select to anon, authenticated using (is_visible);
create policy "admins manage app lines" on public.app_lines
  for all to authenticated
  using ((select private.is_jivaio_admin()))
  with check ((select private.is_jivaio_admin()));
create policy "public read published app alerts" on public.app_alerts
  for select to anon, authenticated
  using (is_published and (ends_at is null or ends_at >= now()));
create policy "admins manage app alerts" on public.app_alerts
  for all to authenticated
  using ((select private.is_jivaio_admin()))
  with check ((select private.is_jivaio_admin()));

create index app_lines_visible on public.app_lines(id) where is_visible;
create index app_alerts_published on public.app_alerts(ends_at) where is_published;

-- A backup import is one transaction and runs with the caller's RLS rights.
-- Revisions prevent a backup from silently overwriting concurrent changes.
create function public.jivaio_import_backup(p_lines jsonb, p_alerts jsonb)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  item jsonb;
  body jsonb;
  expected_revision bigint;
  affected integer;
begin
  if jsonb_typeof(p_lines) is distinct from 'array'
     or jsonb_typeof(p_alerts) is distinct from 'array' then
    raise exception 'Invalid backup payload';
  end if;
  for item in select value from jsonb_array_elements(p_lines) loop
    body := item -> 'payload';
    expected_revision := nullif(item ->> 'expectedRevision', '')::bigint;
    if expected_revision is null then
      insert into public.app_lines (id, payload, is_visible)
      values (body ->> 'id', body, (body ->> 'isVisible')::boolean);
    else
      update public.app_lines
      set payload = body, is_visible = (body ->> 'isVisible')::boolean
      where id = body ->> 'id' and revision = expected_revision;
      get diagnostics affected = row_count;
      if affected <> 1 then
        raise exception 'Line changed during backup import' using errcode = '40001';
      end if;
    end if;
  end loop;
  for item in select value from jsonb_array_elements(p_alerts) loop
    body := item -> 'payload';
    expected_revision := nullif(item ->> 'expectedRevision', '')::bigint;
    if expected_revision is null then
      insert into public.app_alerts (id, payload, is_published, ends_at)
      values (
        body ->> 'id', body, (body ->> 'isPublished')::boolean,
        nullif(body ->> 'endsAt', '')::timestamptz
      );
    else
      update public.app_alerts
      set payload = body, is_published = (body ->> 'isPublished')::boolean,
          ends_at = nullif(body ->> 'endsAt', '')::timestamptz
      where id = body ->> 'id' and revision = expected_revision;
      get diagnostics affected = row_count;
      if affected <> 1 then
        raise exception 'Alert changed during backup import' using errcode = '40001';
      end if;
    end if;
  end loop;
end;
$$;

revoke all on function public.jivaio_import_backup(jsonb, jsonb)
  from public, anon, authenticated;
grant execute on function public.jivaio_import_backup(jsonb, jsonb)
  to authenticated;

commit;
