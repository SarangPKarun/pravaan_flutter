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

-- ── Goal wallets ──────────────────────────────────────────────────────────────

create table public.goal_wallets (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users(id) on delete cascade,
  habit_id         uuid not null references public.habits(id) on delete cascade,
  goal_name        text not null,
  target_amount    float8 not null,
  current_balance  float8 not null default 0,
  target_date      timestamptz not null,
  is_locked        boolean not null default true,
  withdrawn_at      timestamptz,
  created_at       timestamptz default now()
);

alter table public.goal_wallets enable row level security;

create policy "Users can manage own goal wallets"
  on public.goal_wallets for all
  using (auth.uid() = user_id);

-- ── Daily wallet credit (habit-clean-day → goal wallet) ─────────────────────────

alter table public.goal_wallets
  add column if not exists last_credited_date date;

create table public.wallet_credits (
  id          uuid primary key default gen_random_uuid(),
  habit_id    uuid not null references public.habits(id) on delete cascade,
  wallet_id   uuid not null references public.goal_wallets(id) on delete cascade,
  user_id     uuid not null references auth.users(id) on delete cascade,
  amount      float8 not null,
  credit_date date not null,
  created_at  timestamptz default now(),
  unique (wallet_id, credit_date)
);

alter table public.wallet_credits enable row level security;

create policy "Users can view own wallet credits"
  on public.wallet_credits for select
  using (auth.uid() = user_id);
-- Deliberately no insert/update/delete policy — rows are only ever written by
-- credit_habit_wallet(), which runs via the service-role Edge Function and bypasses RLS.

create or replace function public.credit_habit_wallet(
  p_habit_id uuid,
  p_amount float8,
  p_credit_date date
) returns boolean
language plpgsql
as $$
declare
  v_wallet_id uuid;
  v_user_id uuid;
begin
  update public.goal_wallets
  set current_balance = current_balance + p_amount,
      last_credited_date = p_credit_date
  where habit_id = p_habit_id
    and (last_credited_date is null or last_credited_date < p_credit_date)
  returning id, user_id into v_wallet_id, v_user_id;

  if v_wallet_id is null then
    return false;
  end if;

  insert into public.wallet_credits (habit_id, wallet_id, user_id, amount, credit_date)
  values (p_habit_id, v_wallet_id, v_user_id, p_amount, p_credit_date)
  on conflict (wallet_id, credit_date) do nothing;

  return true;
end;
$$;

-- Prerequisite (run once, dashboard or SQL editor): enable "pg_cron" and "pg_net" extensions,
-- and store the service-role key as a Vault secret named 'edge_function_service_role_key'.

select cron.schedule(
  'daily-wallet-credit',
  '31 18 * * *', -- 00:01 IST == 18:31 UTC (previous day)
  $$
  select net.http_post(
    url := '<YOUR_PROJECT_URL>/functions/v1/daily-wallet-credit',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'edge_function_service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);

-- ── Multi-wallet: enforce one wallet per habit ──────────────────────────────────

alter table public.goal_wallets
  add constraint goal_wallets_habit_id_unique unique (habit_id);

-- ── Razorpay withdrawal demo: capture UPI ID at withdrawal time ─────────────────

alter table public.goal_wallets
  add column upi_id text;

-- ── AI dashboard messages (cache) ───────────────────────────────────────────────

create table public.ai_messages (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  message      text not null,
  generated_at timestamptz not null default now()
);

create index ai_messages_user_id_generated_at_idx
  on public.ai_messages (user_id, generated_at desc);

alter table public.ai_messages enable row level security;

create policy "Users can manage own ai messages"
  on public.ai_messages for all
  using (auth.uid() = user_id);

-- ── Realtime: live balance updates on the dashboard ─────────────────────────────
-- Required for Supabase Realtime Postgres Changes to fire for this table at all —
-- RLS alone does not enable Realtime; a table must also be added to this
-- publication. Existing RLS policy ("Users can manage own goal wallets") already
-- scopes which rows each subscribed user receives change events for.
alter publication supabase_realtime add table public.goal_wallets;

-- ── Device tokens (FCM push targets) ────────────────────────────────────────────

create table public.device_tokens (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  token      text not null unique,
  platform   text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.device_tokens enable row level security;

create policy "Users can manage own device tokens"
  on public.device_tokens for all
  using (auth.uid() = user_id);

-- ── Morning notification (personalized AI message push at 7 AM IST) ────────────
-- Prerequisite: same pg_cron/pg_net/Vault setup as daily-wallet-credit above,
-- plus the FIREBASE_SERVICE_ACCOUNT_JSON secret set on the Edge Function itself
-- (supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON="$(cat serviceAccountKey.json)").

select cron.schedule(
  'morning-notification',
  '30 1 * * *', -- 07:00 IST == 01:30 UTC
  $$
  select net.http_post(
    url := '<YOUR_PROJECT_URL>/functions/v1/morning-notification',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'edge_function_service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);

-- ── Migration for existing databases ─────────────────────────────────────────
-- alter table public.checkins
--   add column craving_trigger text check (craving_trigger in ('stress','boredom','social','other')),
--   add column craving_time time,
--   drop constraint checkins_craving_intensity_check,
--   add constraint checkins_craving_intensity_check check (craving_intensity between 1 and 5);