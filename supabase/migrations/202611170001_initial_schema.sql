create extension if not exists pgcrypto;

create table public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  added_at timestamptz not null default now()
);

create schema if not exists private;

create or replace function private.is_jivaio_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_users where user_id = (select auth.uid())
  );
$$;

revoke execute on function private.is_jivaio_admin() from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.is_jivaio_admin() to authenticated;

create table public.feed_versions (
  id uuid primary key default gen_random_uuid(),
  label text not null,
  source_file text,
  effective_from date,
  effective_until date,
  status text not null default 'draft'
    check (status in ('draft', 'active', 'archived')),
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id),
  published_at timestamptz,
  check (effective_until is null or effective_from is null or effective_until >= effective_from)
);

create unique index one_active_feed on public.feed_versions(status) where status = 'active';

create table public.active_feed (
  singleton boolean primary key default true check (singleton),
  feed_id uuid not null references public.feed_versions(id)
);

create table public.routes (
  feed_id uuid not null references public.feed_versions(id) on delete cascade,
  route_id text not null,
  short_name text not null,
  long_name text not null,
  description text,
  color text,
  text_color text,
  sort_order integer not null default 0,
  primary key (feed_id, route_id)
);

create table public.stops (
  feed_id uuid not null references public.feed_versions(id) on delete cascade,
  stop_id text not null,
  code text,
  name text not null,
  latitude double precision,
  longitude double precision,
  primary key (feed_id, stop_id),
  check (latitude is null or latitude between -90 and 90),
  check (longitude is null or longitude between -180 and 180)
);

create table public.service_calendars (
  feed_id uuid not null references public.feed_versions(id) on delete cascade,
  service_id text not null,
  monday boolean not null default false,
  tuesday boolean not null default false,
  wednesday boolean not null default false,
  thursday boolean not null default false,
  friday boolean not null default false,
  saturday boolean not null default false,
  sunday boolean not null default false,
  start_date date not null,
  end_date date not null,
  primary key (feed_id, service_id),
  check (end_date >= start_date)
);

create table public.trips (
  feed_id uuid not null references public.feed_versions(id) on delete cascade,
  trip_id text not null,
  route_id text not null,
  service_id text not null,
  headsign text,
  direction_id smallint check (direction_id in (0, 1)),
  shape_id text,
  primary key (feed_id, trip_id),
  foreign key (feed_id, route_id) references public.routes(feed_id, route_id) on delete cascade
);

create table public.stop_times (
  feed_id uuid not null,
  trip_id text not null,
  stop_sequence integer not null check (stop_sequence >= 0),
  stop_id text not null,
  arrival_time text,
  departure_time text,
  primary key (feed_id, trip_id, stop_sequence),
  foreign key (feed_id, trip_id) references public.trips(feed_id, trip_id) on delete cascade,
  foreign key (feed_id, stop_id) references public.stops(feed_id, stop_id),
  check (arrival_time is null or arrival_time ~ '^[0-9]{1,3}:[0-5][0-9]:[0-5][0-9]$'),
  check (departure_time is null or departure_time ~ '^[0-9]{1,3}:[0-5][0-9]:[0-5][0-9]$')
);

create table public.calendar_dates (
  feed_id uuid not null references public.feed_versions(id) on delete cascade,
  service_id text not null,
  service_date date not null,
  exception_type smallint not null check (exception_type in (1, 2)),
  primary key (feed_id, service_id, service_date)
);

create table public.service_alerts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  summary text not null,
  details text,
  severity text not null default 'info' check (severity in ('info', 'warning', 'critical')),
  starts_at timestamptz not null,
  ends_at timestamptz,
  is_published boolean not null default false,
  source_name text,
  source_url text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at is null or ends_at >= starts_at)
);

create table public.service_alert_routes (
  alert_id uuid not null references public.service_alerts(id) on delete cascade,
  route_id text not null,
  primary key (alert_id, route_id)
);

create table public.service_alert_stops (
  alert_id uuid not null references public.service_alerts(id) on delete cascade,
  stop_id text not null,
  primary key (alert_id, stop_id)
);

create index routes_sort on public.routes(feed_id, sort_order, short_name);
create index trips_route_service on public.trips(feed_id, route_id, service_id, direction_id);
create index stop_times_stop on public.stop_times(feed_id, stop_id, trip_id);
create index service_alerts_window on public.service_alerts(is_published, starts_at, ends_at);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger service_alerts_touch_updated_at
before update on public.service_alerts
for each row execute function public.touch_updated_at();

alter table public.admin_users enable row level security;
alter table public.feed_versions enable row level security;
alter table public.active_feed enable row level security;
alter table public.routes enable row level security;
alter table public.stops enable row level security;
alter table public.service_calendars enable row level security;
alter table public.trips enable row level security;
alter table public.stop_times enable row level security;
alter table public.calendar_dates enable row level security;
alter table public.service_alerts enable row level security;
alter table public.service_alert_routes enable row level security;
alter table public.service_alert_stops enable row level security;

create policy "admins can read admin list" on public.admin_users
  for select to authenticated using ((select private.is_jivaio_admin()));
create policy "admins manage feed versions" on public.feed_versions
  for all to authenticated using ((select private.is_jivaio_admin())) with check ((select private.is_jivaio_admin()));
create policy "public can read active feed pointer" on public.active_feed
  for select to anon, authenticated using (true);
create policy "admins manage active feed pointer" on public.active_feed
  for all to authenticated using ((select private.is_jivaio_admin())) with check ((select private.is_jivaio_admin()));

create policy "public read active routes" on public.routes
  for select to anon, authenticated using (feed_id = (select feed_id from public.active_feed where singleton));
create policy "admins manage routes" on public.routes
  for all to authenticated using ((select private.is_jivaio_admin())) with check ((select private.is_jivaio_admin()));
create policy "public read active stops" on public.stops
  for select to anon, authenticated using (feed_id = (select feed_id from public.active_feed where singleton));
create policy "admins manage stops" on public.stops
  for all to authenticated using ((select private.is_jivaio_admin())) with check ((select private.is_jivaio_admin()));
create policy "public read active calendars" on public.service_calendars
  for select to anon, authenticated using (feed_id = (select feed_id from public.active_feed where singleton));
create policy "admins manage calendars" on public.service_calendars
  for all to authenticated using ((select private.is_jivaio_admin())) with check ((select private.is_jivaio_admin()));
create policy "public read active trips" on public.trips
  for select to anon, authenticated using (feed_id = (select feed_id from public.active_feed where singleton));
create policy "admins manage trips" on public.trips
  for all to authenticated using ((select private.is_jivaio_admin())) with check ((select private.is_jivaio_admin()));
create policy "public read active stop times" on public.stop_times
  for select to anon, authenticated using (feed_id = (select feed_id from public.active_feed where singleton));
create policy "admins manage stop times" on public.stop_times
  for all to authenticated using ((select private.is_jivaio_admin())) with check ((select private.is_jivaio_admin()));
create policy "public read active calendar exceptions" on public.calendar_dates
  for select to anon, authenticated using (feed_id = (select feed_id from public.active_feed where singleton));
create policy "admins manage calendar exceptions" on public.calendar_dates
  for all to authenticated using ((select private.is_jivaio_admin())) with check ((select private.is_jivaio_admin()));

create policy "public read current and upcoming alerts" on public.service_alerts
  for select to anon, authenticated using (is_published and (ends_at is null or ends_at >= now()));
create policy "admins manage alerts" on public.service_alerts
  for all to authenticated using ((select private.is_jivaio_admin())) with check ((select private.is_jivaio_admin()));
create policy "public read routes for visible alerts" on public.service_alert_routes
  for select to anon, authenticated using (
    exists (select 1 from public.service_alerts a where a.id = alert_id and a.is_published and (a.ends_at is null or a.ends_at >= now()))
  );
create policy "admins manage alert routes" on public.service_alert_routes
  for all to authenticated using ((select private.is_jivaio_admin())) with check ((select private.is_jivaio_admin()));
create policy "public read stops for visible alerts" on public.service_alert_stops
  for select to anon, authenticated using (
    exists (select 1 from public.service_alerts a where a.id = alert_id and a.is_published and (a.ends_at is null or a.ends_at >= now()))
  );
create policy "admins manage alert stops" on public.service_alert_stops
  for all to authenticated using ((select private.is_jivaio_admin())) with check ((select private.is_jivaio_admin()));

grant usage on schema public to anon, authenticated;
grant select on public.admin_users to authenticated;
grant select on public.active_feed, public.routes, public.stops, public.service_calendars,
  public.trips, public.stop_times, public.calendar_dates, public.service_alerts,
  public.service_alert_routes, public.service_alert_stops to anon, authenticated;
grant select, insert, update, delete on public.feed_versions, public.routes, public.stops,
  public.service_calendars, public.trips, public.stop_times, public.calendar_dates,
  public.active_feed, public.service_alerts, public.service_alert_routes,
  public.service_alert_stops to authenticated;
