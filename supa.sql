create table public.habits (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  type          text not null,
  daily_units   float8 not null,
  cost_per_unit float8 not null,
  quit_date     timestamptz not null,
  is_active     boolean not null default true,
  created_at    timestamptz default now()
);

alter table public.habits enable row level security;

create policy "Users can manage own habits"
  on public.habits for all
  using (auth.uid() = user_id);

-- ── Check-ins ──────────────────────────────────────────────────────────────────

create table public.checkins (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references auth.users(id) on delete cascade,
  date              timestamptz not null default now(),
  is_clean          boolean not null,
  mood              int2 not null check (mood between 1 and 5),
  craving_intensity int2 check (craving_intensity between 1 and 5),
  craving_trigger   text check (craving_trigger in ('stress', 'boredom', 'social', 'other')),
  craving_time      time,
  note              text,
  created_at        timestamptz default now()
);

alter table public.checkins enable row level security;

create policy "Users can manage own checkins"
  on public.checkins for all
  using (auth.uid() = user_id);

-- ── User stats (streak tracking) ─────────────────────────────────────────────

create table public.user_stats (
  user_id           uuid primary key references auth.users(id) on delete cascade,
  current_streak    int4 not null default 0,
  longest_streak    int4 not null default 0,
  total_clean_days  int4 not null default 0,
  last_checkin_date date,
  updated_at        timestamptz default now()
);

alter table public.user_stats enable row level security;

create policy "Users can manage own stats"
  on public.user_stats for all
  using (auth.uid() = user_id);

-- ── Migration for existing databases ─────────────────────────────────────────
-- alter table public.checkins
--   add column craving_trigger text check (craving_trigger in ('stress','boredom','social','other')),
--   add column craving_time time,
--   drop constraint checkins_craving_intensity_check,
--   add constraint checkins_craving_intensity_check check (craving_intensity between 1 and 5);