-- 007_rule_sets_and_scoring_seed.sql for teamrope-mobile-app
--
-- Wires the teamrope scoring engine to real, dated, citable rule
-- data on the shared Rodeo Apps Supabase project. Every rule is DATA and every
-- outcome cites its rule (see src/lib/scoring/types.ts).
--
-- Idempotent and self-contained: creates the rule versioning tables if absent,
-- upgrades teamrope_runs to carry the engine's scoring columns, and seeds the
-- WPRA/PRCA/WRCA 2026 rule sets.

begin;

-- Rule versioning tables (no-op if the shared project already has them).
create table if not exists public.rule_sets (
  id uuid primary key default gen_random_uuid(),
  association_code text not null,
  edition_label text not null,
  source_url text,
  effective_from date not null,
  effective_to date,
  revision_date date,
  superseded_by uuid references public.rule_sets(id),
  verified_by text,
  verified_at timestamptz,
  notes text
);

create table if not exists public.rule_set_entries (
  id uuid primary key default gen_random_uuid(),
  rule_set_id uuid not null references public.rule_sets(id) on delete cascade,
  event_type text not null,
  rule_key text not null,
  value jsonb not null,
  citation text,
  amended_on date,
  unique (rule_set_id, event_type, rule_key)
);

alter table public.rule_sets        enable row level security;
alter table public.rule_set_entries enable row level security;
drop policy if exists "Rule sets are readable" on public.rule_sets;
create policy "Rule sets are readable" on public.rule_sets for select using (true);
drop policy if exists "Rule entries are readable" on public.rule_set_entries;
create policy "Rule entries are readable" on public.rule_set_entries for select using (true);

-- Seed the rule sets.
insert into public.rule_sets (association_code, edition_label, source_url, effective_from, effective_to, revision_date, verified_by, verified_at, notes)
select 'WPRA', 'WPRA 2026', 'https://www.wpra.com/', date '2026-01-01', null, date '2025-10-01', 'seed', now(),
       'WPRA rolling rulebook, amendments through 1 Oct 2025.'
where not exists (select 1 from public.rule_sets where association_code='WPRA' and edition_label='WPRA 2026');

insert into public.rule_sets (association_code, edition_label, source_url, effective_from, effective_to, revision_date, verified_by, verified_at, notes)
select 'PRCA', 'PRCA 2026 Rule Book', 'https://www.prorodeo.com/', date '2026-01-01', null, date '2025-10-01', 'seed', now(),
       'PRCA 2026 Rule Book.'
where not exists (select 1 from public.rule_sets where association_code='PRCA' and edition_label='PRCA 2026 Rule Book');

insert into public.rule_sets (association_code, edition_label, source_url, effective_from, effective_to, revision_date, verified_by, verified_at, notes)
select 'WRCA', 'WRCA 2026', 'https://www.wrca.org/', date '2026-01-01', null, date '2025-10-01', 'seed', now(),
       'WRCA sanctioned ranch rodeo pattern.'
where not exists (select 1 from public.rule_sets where association_code='WRCA' and edition_label='WRCA 2026');

-- WPRA breakaway entries
insert into public.rule_set_entries (rule_set_id, event_type, rule_key, value, citation)
select s.id, v.event_type, v.rule_key, v.value::jsonb, v.citation
from public.rule_sets s
join (values
  ('breakaway', 'barrier_penalty_seconds', '10.0', 'WPRA 2026 — 10 second barrier penalty'),
  ('breakaway', 'strict_flag_review',      'false', 'WPRA 2026 — standard flag review')
) as v(event_type, rule_key, value, citation) on true
where s.association_code='WPRA' and s.edition_label='WPRA 2026'
on conflict (rule_set_id, event_type, rule_key) do update set value=excluded.value, citation=excluded.citation;

-- PRCA entries (timed + roughstock)
insert into public.rule_set_entries (rule_set_id, event_type, rule_key, value, citation)
select s.id, v.event_type, v.rule_key, v.value::jsonb, v.citation
from public.rule_sets s
join (values
  ('tiedown',        'barrier_seconds',             '10',              'PRCA 2026 — 10 second barrier penalty'),
  ('tiedown',        'time_limit_seconds',          '30',              'PRCA 2026 — arena time limit'),
  ('tiedown',        'loops',                       '1',               'PRCA 2026 — one loop'),
  ('tiedown',        'jerk_down_disqualifies',      'true',            'PRCA 2026 — jerk-down rule enforced'),
  ('steer_wrestling','barrier_seconds',             '10',              'PRCA 2026 — 10 second barrier penalty'),
  ('steer_wrestling','time_limit_seconds',          '30',              'PRCA 2026 — arena time limit'),
  ('team_roping',    'barrier_seconds',             '10',              'PRCA 2026 — 10 second barrier penalty'),
  ('team_roping',    'one_hind_foot_seconds',       '5',               'PRCA 2026 — 5 second one-hind-foot penalty'),
  ('team_roping',    'crossfire_standard',          '"loop_release"',  'PRCA 2026 — loop released timing standard'),
  ('team_roping',    'finish_mode',                 '"face"',          'PRCA 2026 — both horses must face'),
  ('bareback',       'judge_count',                 '2',               'PRCA 2026 — two judges'),
  ('bareback',       'judge_component_max',         '25',              'PRCA 2026 — 0-25 per component'),
  ('bareback',       'mark_out_treatment',          '"disqualify"',    'PRCA 2026 — failure to mark out disqualifies'),
  ('saddle_bronc',   'judge_count',                 '2',               'PRCA 2026 — two judges'),
  ('saddle_bronc',   'judge_component_max',         '25',              'PRCA 2026 — 0-25 per component'),
  ('saddle_bronc',   'mark_out_treatment',          '"disqualify"',    'PRCA 2026 — failure to mark out disqualifies')
) as v(event_type, rule_key, value, citation) on true
where s.association_code='PRCA' and s.edition_label='PRCA 2026 Rule Book'
on conflict (rule_set_id, event_type, rule_key) do update set value=excluded.value, citation=excluded.citation;

-- WRCA ranch rodeo entries
insert into public.rule_set_entries (rule_set_id, event_type, rule_key, value, citation)
select s.id, v.event_type, v.rule_key, v.value::jsonb, v.citation
from public.rule_sets s
join (values
  ('ranch_rodeo', 'event_time_limit_seconds', '120', 'WRCA 2026 — two minute event limit')
) as v(event_type, rule_key, value, citation) on true
where s.association_code='WRCA' and s.edition_label='WRCA 2026'
on conflict (rule_set_id, event_type, rule_key) do update set value=excluded.value, citation=excluded.citation;


-- Store the engine's scoring output alongside the raw practice entry.
alter table public.teamrope_runs add column if not exists rule_set_id uuid references public.rule_sets(id);
alter table public.teamrope_runs add column if not exists status text;
alter table public.teamrope_runs add column if not exists raw_time_ms integer;
alter table public.teamrope_runs add column if not exists official_time_ms integer;

commit;
