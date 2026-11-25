-- =============================================================================
-- Zone Hub (PG Service Missionaries) — Complete Supabase Database Setup
-- =============================================================================
-- Run this entire script in the Supabase SQL Editor for your new project.
-- It creates:
--   1. All 11 database tables + foreign keys + defaults
--   2. The `is_admin()` helper function & `add_cookie()` RPC function
--   3. Row Level Security (RLS) policies for site users vs. admins
--   4. The `missionary-photos` public storage bucket + storage RLS policies
--   5. Default rows for `section_settings`
-- =============================================================================

create extension if not exists "pgcrypto";

-- -----------------------------------------------------------------------------
-- 1. TABLES
-- -----------------------------------------------------------------------------

create table if not exists public.missionaries (
    id uuid primary key default gen_random_uuid(),
    auth_user_id uuid references auth.users(id) on delete set null,
    app_role text default 'missionary',
    name text not null,
    emoji text default '',
    color text default '#2f6fed',
    service_role text,
    phone text default '',
    sites text default '',
    birthday text default '',
    start_date date,
    companion text default '',
    district text default '',
    photo_url text,
    cookies integer not null default 0,
    created_at timestamptz not null default now()
);

create table if not exists public.leadership (
    id uuid primary key default gen_random_uuid(),
    role_title text not null default '',
    missionary_id uuid references public.missionaries(id) on delete cascade,
    name text,
    phone text,
    emoji text,
    created_at timestamptz not null default now()
);

create table if not exists public.calendar_events (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    event_type text not null default 'meeting' check (event_type in ('meeting', 'gathering')),
    event_date_iso date,
    repeats_weekly boolean not null default false,
    event_date text default '',
    description text default '',
    address text default '',
    link text default '',
    color text default '',
    created_at timestamptz not null default now()
);

create table if not exists public.event_rsvps (
    id uuid primary key default gen_random_uuid(),
    event_id uuid not null references public.calendar_events(id) on delete cascade,
    missionary_id uuid not null references public.missionaries(id) on delete cascade,
    created_at timestamptz not null default now(),
    unique (event_id, missionary_id)
);

create table if not exists public.service_sites (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    description text default '',
    address text default '',
    contact text default '',
    created_at timestamptz not null default now()
);

create table if not exists public.gatherings (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    date_text text default '',
    description text default '',
    emoji text default '',
    color text default '#2f6fed',
    created_at timestamptz not null default now()
);

create table if not exists public.resources (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    url text not null,
    created_at timestamptz not null default now()
);

create table if not exists public.districts (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    content_html text default '',
    leader1_id uuid references public.missionaries(id) on delete set null,
    leader2_id uuid references public.missionaries(id) on delete set null,
    created_at timestamptz not null default now()
);

create table if not exists public.companionships (
    id uuid primary key default gen_random_uuid(),
    missionary_ids uuid[] default '{}',
    names text default '',
    created_at timestamptz not null default now()
);

create table if not exists public.general_notes (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    content_html text default '',
    color text default '',
    default_open boolean not null default false,
    created_at timestamptz not null default now()
);

create table if not exists public.meetings (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    time_text text default '',
    address text default '',
    details text default '',
    created_at timestamptz not null default now()
);

create table if not exists public.section_settings (
    section_key text primary key,
    default_open boolean not null default false
);

-- Seed default section settings
insert into public.section_settings (section_key, default_open) values
    ('meetings', true),
    ('events', true),
    ('birthdays', true),
    ('leadership', true),
    ('starting_soon', true)
on conflict (section_key) do nothing;

-- -----------------------------------------------------------------------------
-- 2. HELPER & RPC FUNCTIONS
-- -----------------------------------------------------------------------------

-- Checks whether the currently signed-in Supabase Auth user has a row in
-- `missionaries` with app_role = 'admin', or is signed in with the shared admin email.
create or replace function public.is_admin()
returns boolean
language sql
security invoker
stable
set search_path = public
as $$
    select exists (
        select 1
        from public.missionaries
        where auth_user_id = (select auth.uid())
          and app_role = 'admin'
    )
    or coalesce((select auth.jwt()) ->> 'email', '') = 'admin@zonehub.pgmissionaries.internal';
$$;

-- Increments a missionary's cookie count atomically.
create or replace function public.add_cookie(p_missionary_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
    if (select auth.uid()) is null then
        raise exception 'Not authenticated';
    end if;
    update public.missionaries
    set cookies = coalesce(cookies, 0) + 1
    where id = p_missionary_id;
end;
$$;

revoke execute on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

revoke execute on function public.add_cookie(uuid) from public, anon;
grant execute on function public.add_cookie(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- -----------------------------------------------------------------------------

alter table public.missionaries enable row level security;
alter table public.leadership enable row level security;
alter table public.calendar_events enable row level security;
alter table public.event_rsvps enable row level security;
alter table public.service_sites enable row level security;
alter table public.gatherings enable row level security;
alter table public.resources enable row level security;
alter table public.districts enable row level security;
alter table public.companionships enable row level security;
alter table public.general_notes enable row level security;
alter table public.meetings enable row level security;
alter table public.section_settings enable row level security;

-- Read access for all authenticated users across all tables
drop policy if exists "missionaries_select" on public.missionaries;
create policy "missionaries_select" on public.missionaries for select to authenticated using (true);

drop policy if exists "leadership_select" on public.leadership;
create policy "leadership_select" on public.leadership for select to authenticated using (true);

drop policy if exists "calendar_events_select" on public.calendar_events;
create policy "calendar_events_select" on public.calendar_events for select to authenticated using (true);

drop policy if exists "event_rsvps_select" on public.event_rsvps;
create policy "event_rsvps_select" on public.event_rsvps for select to authenticated using (true);

drop policy if exists "service_sites_select" on public.service_sites;
create policy "service_sites_select" on public.service_sites for select to authenticated using (true);

drop policy if exists "gatherings_select" on public.gatherings;
create policy "gatherings_select" on public.gatherings for select to authenticated using (true);

drop policy if exists "resources_select" on public.resources;
create policy "resources_select" on public.resources for select to authenticated using (true);

drop policy if exists "districts_select" on public.districts;
create policy "districts_select" on public.districts for select to authenticated using (true);

drop policy if exists "companionships_select" on public.companionships;
create policy "companionships_select" on public.companionships for select to authenticated using (true);

drop policy if exists "general_notes_select" on public.general_notes;
create policy "general_notes_select" on public.general_notes for select to authenticated using (true);

drop policy if exists "meetings_select" on public.meetings;
create policy "meetings_select" on public.meetings for select to authenticated using (true);

drop policy if exists "section_settings_select" on public.section_settings;
create policy "section_settings_select" on public.section_settings for select to authenticated using (true);

-- Missionaries: any authenticated user can insert/update profiles; only admin can delete
drop policy if exists "missionaries_insert" on public.missionaries;
create policy "missionaries_insert" on public.missionaries for insert to authenticated with check (true);

drop policy if exists "missionaries_update" on public.missionaries;
create policy "missionaries_update" on public.missionaries for update to authenticated using (true) with check (true);

drop policy if exists "missionaries_delete" on public.missionaries;
create policy "missionaries_delete" on public.missionaries for delete to authenticated using (public.is_admin());

-- Calendar events: any authenticated user can insert; only admin can update/delete
drop policy if exists "calendar_events_insert" on public.calendar_events;
create policy "calendar_events_insert" on public.calendar_events for insert to authenticated with check (true);

drop policy if exists "calendar_events_update" on public.calendar_events;
create policy "calendar_events_update" on public.calendar_events for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "calendar_events_delete" on public.calendar_events;
create policy "calendar_events_delete" on public.calendar_events for delete to authenticated using (public.is_admin());

-- Event RSVPs: any authenticated user can add or remove RSVPs
drop policy if exists "event_rsvps_insert" on public.event_rsvps;
create policy "event_rsvps_insert" on public.event_rsvps for insert to authenticated with check (true);

drop policy if exists "event_rsvps_delete" on public.event_rsvps;
create policy "event_rsvps_delete" on public.event_rsvps for delete to authenticated using (true);

-- Gatherings / Ideas: any authenticated user can add, edit, or delete ideas
drop policy if exists "gatherings_insert" on public.gatherings;
create policy "gatherings_insert" on public.gatherings for insert to authenticated with check (true);

drop policy if exists "gatherings_update" on public.gatherings;
create policy "gatherings_update" on public.gatherings for update to authenticated using (true) with check (true);

drop policy if exists "gatherings_delete" on public.gatherings;
create policy "gatherings_delete" on public.gatherings for delete to authenticated using (true);

-- Admin-only write tables: leadership, service_sites, resources, districts, companionships, general_notes, meetings, section_settings
drop policy if exists "leadership_admin_write" on public.leadership;
create policy "leadership_admin_write" on public.leadership for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "service_sites_admin_write" on public.service_sites;
create policy "service_sites_admin_write" on public.service_sites for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "resources_admin_write" on public.resources;
create policy "resources_admin_write" on public.resources for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "districts_admin_write" on public.districts;
create policy "districts_admin_write" on public.districts for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "companionships_admin_write" on public.companionships;
create policy "companionships_admin_write" on public.companionships for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "general_notes_admin_write" on public.general_notes;
create policy "general_notes_admin_write" on public.general_notes for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "meetings_admin_write" on public.meetings;
create policy "meetings_admin_write" on public.meetings for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "section_settings_admin_write" on public.section_settings;
create policy "section_settings_admin_write" on public.section_settings for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- -----------------------------------------------------------------------------
-- 4. STORAGE BUCKET (`missionary-photos`)
-- -----------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('missionary-photos', 'missionary-photos', true)
on conflict (id) do update set public = true;

drop policy if exists "missionary_photos_public_read" on storage.objects;
create policy "missionary_photos_public_read"
on storage.objects for select
using (bucket_id = 'missionary-photos');

drop policy if exists "missionary_photos_auth_insert" on storage.objects;
create policy "missionary_photos_auth_insert"
on storage.objects for insert
to authenticated
with check (bucket_id = 'missionary-photos');

drop policy if exists "missionary_photos_auth_update" on storage.objects;
create policy "missionary_photos_auth_update"
on storage.objects for update
to authenticated
using (bucket_id = 'missionary-photos')
with check (bucket_id = 'missionary-photos');

drop policy if exists "missionary_photos_admin_delete" on storage.objects;
create policy "missionary_photos_admin_delete"
on storage.objects for delete
to authenticated
using (bucket_id = 'missionary-photos' and public.is_admin());
