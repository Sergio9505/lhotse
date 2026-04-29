-- ============================================================================
-- Migration: user_onboarding
-- Principles applied: #2 (user-scoped data), #5 (RLS on every user table)
-- Consumers (Flutter providers reading new/changed views):
--   - user_onboarding table → OnboardingRepository (write-only from Flutter)
-- Co-loaded pairs: n/a (new standalone table, not co-loaded with any view)
-- Dead fields dropped: none
-- New fields added: all (new table) — consumer: OnboardingHost / onboarding flow
-- Denormalization justifications: n/a
-- Rollback: DROP TABLE public.user_onboarding CASCADE;
-- RLS test: user can only read/write own row (auth.uid() = user_id)
-- ============================================================================

create table public.user_onboarding (
  user_id              uuid primary key references auth.users(id) on delete cascade,
  primary_goal         text,
  investor_profile     text,
  asset_experience     text[] not null default '{}',
  ticket_size          text,
  risk_appetite        text,
  time_horizon         text,
  decision_drivers     text[] not null default '{}',
  involvement_level    text,
  lifestyle_interests  text[] not null default '{}',
  completed_at         timestamptz,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

alter table public.user_onboarding enable row level security;

create policy "users read own onboarding"
  on public.user_onboarding for select
  using (auth.uid() = user_id);

create policy "users insert own onboarding"
  on public.user_onboarding for insert
  with check (auth.uid() = user_id);

create policy "users update own onboarding"
  on public.user_onboarding for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

notify pgrst, 'reload schema';
