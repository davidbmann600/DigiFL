-- Digi-FL: Accounts & Sync-Schema
-- Einmalig im Supabase SQL Editor ausführen (Dashboard → SQL Editor → New query → Run).

-- Profil pro Nutzer:in (Schule fürs spätere automatische SILP-Matching)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  school text,
  created_at timestamptz default now()
);

-- Der komplette App-Zustand pro Nutzer:in (Planungen + Reihen als JSON,
-- gleiche Struktur wie bisher im localStorage).
create table if not exists public.app_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  sessions jsonb default '[]'::jsonb,
  reihen jsonb default '[]'::jsonb,
  updated_at timestamptz default now()
);

alter table public.profiles enable row level security;
alter table public.app_state enable row level security;

-- Jede:r darf ausschließlich die eigenen Zeilen lesen/schreiben.
create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles_upsert_own" on public.profiles
  for insert with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);

create policy "app_state_select_own" on public.app_state
  for select using (auth.uid() = user_id);
create policy "app_state_upsert_own" on public.app_state
  for insert with check (auth.uid() = user_id);
create policy "app_state_update_own" on public.app_state
  for update using (auth.uid() = user_id);
