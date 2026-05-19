-- CIRO / CrisisAI schema for Challenge 3.
-- Run this in the Supabase SQL editor or with `supabase db push`.

create extension if not exists "pgcrypto";

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  role text not null default 'observer' check (role in ('observer', 'responder', 'coordinator', 'admin')),
  organization text,
  phone text,
  avatar_url text,
  status text not null default 'active' check (status in ('active', 'inactive', 'suspended')),
  location jsonb not null default '{}'::jsonb,
  preferences jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.signals (
  id uuid primary key default gen_random_uuid(),
  submitted_by uuid references public.profiles(id) on delete set null,
  source_type text not null default 'user_report' check (source_type in ('user_report', 'simulated_api', 'weather_api', 'traffic_api', 'news_api', 'system')),
  report_text text not null check (char_length(trim(report_text)) > 0),
  language_hint text,
  category text,
  urgency integer not null default 3 check (urgency between 1 and 5),
  location_text text,
  latitude double precision,
  longitude double precision,
  status text not null default 'submitted' check (status in ('submitted', 'normalizing', 'normalized', 'geocoding', 'enriched', 'clustered', 'failed', 'archived')),
  confidence numeric(5,4) not null default 0 check (confidence between 0 and 1),
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.normalized_signals (
  id uuid primary key default gen_random_uuid(),
  signal_id uuid not null references public.signals(id) on delete cascade,
  normalized_text text not null,
  translated_text text,
  location_text text,
  latitude double precision,
  longitude double precision,
  category text,
  severity_hint integer check (severity_hint between 1 and 5),
  entities jsonb not null default '{}'::jsonb,
  status text not null default 'normalized' check (status in ('normalized', 'geocoded', 'enriched', 'clustered', 'failed')),
  model text,
  confidence numeric(5,4) not null default 0 check (confidence between 0 and 1),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.signals
  add column if not exists normalized_signal_id uuid references public.normalized_signals(id) on delete set null;

create table if not exists public.location_aliases (
  id uuid primary key default gen_random_uuid(),
  alias text not null,
  canonical_name text not null,
  latitude double precision not null,
  longitude double precision not null,
  source text not null default 'agent',
  evidence jsonb not null default '{}'::jsonb,
  status text not null default 'active' check (status in ('active', 'needs_review', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (alias, canonical_name)
);

create table if not exists public.incidents (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  category text not null default 'unknown',
  status text not null default 'detecting' check (status in ('detecting', 'active', 'monitoring', 'mitigating', 'resolved', 'dismissed')),
  severity integer not null default 1 check (severity between 1 and 5),
  confidence numeric(5,4) not null default 0 check (confidence between 0 and 1),
  centroid_lat double precision,
  centroid_lng double precision,
  radius_meters integer not null default 1500,
  started_at timestamptz not null default now(),
  last_signal_at timestamptz not null default now(),
  summary jsonb not null default '{}'::jsonb,
  evidence_summary jsonb not null default '{}'::jsonb,
  assigned_owner uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.incident_evidence (
  id uuid primary key default gen_random_uuid(),
  incident_id uuid not null references public.incidents(id) on delete cascade,
  signal_id uuid references public.signals(id) on delete set null,
  evidence_type text not null check (evidence_type in ('signal', 'weather', 'route', 'news', 'web', 'resource', 'manual', 'system')),
  source_name text not null,
  title text,
  url text,
  observed_at timestamptz not null default now(),
  location jsonb not null default '{}'::jsonb,
  confidence numeric(5,4) not null default 0 check (confidence between 0 and 1),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.agent_runs (
  id uuid primary key default gen_random_uuid(),
  trigger_type text not null check (trigger_type in ('signal', 'incident', 'simulation', 'scheduled', 'manual')),
  trigger_id uuid,
  status text not null default 'running' check (status in ('queued', 'running', 'completed', 'failed', 'cancelled')),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  input_payload jsonb not null default '{}'::jsonb,
  output_payload jsonb not null default '{}'::jsonb,
  error text,
  created_by uuid references public.profiles(id) on delete set null
);

create table if not exists public.agent_logs (
  id uuid primary key default gen_random_uuid(),
  agent_run_id uuid not null references public.agent_runs(id) on delete cascade,
  agent_name text not null,
  step text not null,
  status text not null default 'running' check (status in ('running', 'completed', 'failed', 'skipped')),
  message text,
  input_payload jsonb not null default '{}'::jsonb,
  output_payload jsonb not null default '{}'::jsonb,
  confidence numeric(5,4) check (confidence between 0 and 1),
  error text,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.tool_calls (
  id uuid primary key default gen_random_uuid(),
  agent_run_id uuid not null references public.agent_runs(id) on delete cascade,
  agent_log_id uuid references public.agent_logs(id) on delete set null,
  tool_name text not null,
  status text not null default 'running' check (status in ('running', 'completed', 'failed')),
  arguments jsonb not null default '{}'::jsonb,
  result jsonb not null default '{}'::jsonb,
  error text,
  latency_ms integer,
  created_at timestamptz not null default now()
);

create table if not exists public.response_actions (
  id uuid primary key default gen_random_uuid(),
  incident_id uuid not null references public.incidents(id) on delete cascade,
  action_type text not null check (action_type in ('reroute', 'alert', 'ticket', 'assign_resource', 'monitor', 'field_check', 'public_guidance')),
  title text not null,
  description text,
  priority integer not null default 3 check (priority between 1 and 5),
  status text not null default 'planned' check (status in ('planned', 'simulating', 'ready', 'in_progress', 'completed', 'cancelled', 'failed')),
  assigned_to text,
  due_at timestamptz,
  payload jsonb not null default '{}'::jsonb,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.simulation_runs (
  id uuid primary key default gen_random_uuid(),
  incident_id uuid not null references public.incidents(id) on delete cascade,
  agent_run_id uuid references public.agent_runs(id) on delete set null,
  status text not null default 'running' check (status in ('queued', 'running', 'completed', 'failed', 'cancelled')),
  scenario text not null default 'safe_response_execution',
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  input_payload jsonb not null default '{}'::jsonb,
  output_payload jsonb not null default '{}'::jsonb,
  created_by uuid references public.profiles(id) on delete set null
);

create table if not exists public.simulation_metrics (
  id uuid primary key default gen_random_uuid(),
  simulation_run_id uuid not null references public.simulation_runs(id) on delete cascade,
  incident_id uuid not null references public.incidents(id) on delete cascade,
  metric_name text not null,
  before_value numeric,
  after_value numeric,
  unit text,
  delta numeric,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.mock_alerts (
  id uuid primary key default gen_random_uuid(),
  incident_id uuid not null references public.incidents(id) on delete cascade,
  simulation_run_id uuid references public.simulation_runs(id) on delete cascade,
  audience text not null,
  channel text not null default 'in_app' check (channel in ('in_app', 'sms_mock', 'email_mock', 'push_mock', 'radio_mock')),
  title text not null,
  body text not null,
  status text not null default 'queued' check (status in ('queued', 'sent_mock', 'acknowledged', 'failed')),
  sent_at timestamptz,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.emergency_tickets (
  id uuid primary key default gen_random_uuid(),
  incident_id uuid not null references public.incidents(id) on delete cascade,
  simulation_run_id uuid references public.simulation_runs(id) on delete cascade,
  external_ref text not null,
  ticket_type text not null default 'mock_dispatch',
  priority integer not null default 3 check (priority between 1 and 5),
  status text not null default 'created_mock' check (status in ('created_mock', 'assigned_mock', 'resolved_mock', 'cancelled_mock', 'failed')),
  summary text not null,
  details text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.resources (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  resource_type text not null check (resource_type in ('ambulance_mock', 'fire_unit_mock', 'police_unit_mock', 'relief_team_mock', 'road_crew_mock', 'shelter_mock', 'medical_team_mock')),
  status text not null default 'available' check (status in ('available', 'assigned_mock', 'busy_mock', 'offline')),
  home_lat double precision,
  home_lng double precision,
  current_lat double precision,
  current_lng double precision,
  capacity integer not null default 1,
  assigned_incident_id uuid references public.incidents(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.blocked_segments (
  id uuid primary key default gen_random_uuid(),
  incident_id uuid not null references public.incidents(id) on delete cascade,
  simulation_run_id uuid references public.simulation_runs(id) on delete cascade,
  status text not null default 'simulated' check (status in ('simulated', 'monitoring', 'cleared', 'cancelled')),
  start_lat double precision not null,
  start_lng double precision not null,
  end_lat double precision not null,
  end_lng double precision not null,
  reason text not null,
  severity integer not null default 3 check (severity between 1 and 5),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.route_options (
  id uuid primary key default gen_random_uuid(),
  incident_id uuid not null references public.incidents(id) on delete cascade,
  simulation_run_id uuid references public.simulation_runs(id) on delete cascade,
  origin jsonb not null default '{}'::jsonb,
  destination jsonb not null default '{}'::jsonb,
  provider text not null default 'google_routes',
  status text not null default 'candidate' check (status in ('candidate', 'recommended', 'rejected', 'active_mock', 'expired')),
  eta_seconds integer,
  distance_meters integer,
  polyline text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.system_status (
  status_key text primary key,
  status text not null default 'unknown' check (status in ('healthy', 'degraded', 'offline', 'unknown')),
  message text,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create index if not exists profiles_role_idx on public.profiles(role);
create index if not exists signals_status_created_idx on public.signals(status, created_at desc);
create index if not exists signals_location_idx on public.signals(latitude, longitude);
create index if not exists signals_payload_gin_idx on public.signals using gin(raw_payload);
create index if not exists normalized_signals_signal_idx on public.normalized_signals(signal_id);
create index if not exists normalized_signals_location_idx on public.normalized_signals(latitude, longitude);
create index if not exists normalized_signals_entities_gin_idx on public.normalized_signals using gin(entities);
create index if not exists location_aliases_alias_idx on public.location_aliases(lower(alias));
create unique index if not exists location_aliases_alias_canonical_ci_idx on public.location_aliases(lower(alias), lower(canonical_name));
create index if not exists incidents_status_severity_idx on public.incidents(status, severity desc, updated_at desc);
create index if not exists incidents_location_idx on public.incidents(centroid_lat, centroid_lng);
create index if not exists incident_evidence_incident_idx on public.incident_evidence(incident_id, evidence_type);
create index if not exists agent_runs_trigger_idx on public.agent_runs(trigger_type, trigger_id, started_at desc);
create index if not exists agent_logs_run_idx on public.agent_logs(agent_run_id, agent_name, created_at);
create index if not exists tool_calls_run_idx on public.tool_calls(agent_run_id, tool_name, created_at);
create index if not exists response_actions_incident_idx on public.response_actions(incident_id, status, priority desc);
create index if not exists simulation_runs_incident_idx on public.simulation_runs(incident_id, started_at desc);
create index if not exists simulation_metrics_incident_idx on public.simulation_metrics(incident_id, metric_name);
create index if not exists mock_alerts_incident_idx on public.mock_alerts(incident_id, status, created_at desc);
create index if not exists emergency_tickets_incident_idx on public.emergency_tickets(incident_id, status, created_at desc);
create index if not exists resources_status_idx on public.resources(resource_type, status);
create index if not exists blocked_segments_incident_idx on public.blocked_segments(incident_id, status);
create index if not exists route_options_incident_idx on public.route_options(incident_id, status, created_at desc);
create index if not exists system_status_status_idx on public.system_status(status, updated_at desc);

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
drop trigger if exists signals_updated_at on public.signals;
create trigger signals_updated_at before update on public.signals for each row execute function public.set_updated_at();
drop trigger if exists normalized_signals_updated_at on public.normalized_signals;
create trigger normalized_signals_updated_at before update on public.normalized_signals for each row execute function public.set_updated_at();
drop trigger if exists location_aliases_updated_at on public.location_aliases;
create trigger location_aliases_updated_at before update on public.location_aliases for each row execute function public.set_updated_at();
drop trigger if exists incidents_updated_at on public.incidents;
create trigger incidents_updated_at before update on public.incidents for each row execute function public.set_updated_at();
drop trigger if exists response_actions_updated_at on public.response_actions;
create trigger response_actions_updated_at before update on public.response_actions for each row execute function public.set_updated_at();
drop trigger if exists emergency_tickets_updated_at on public.emergency_tickets;
create trigger emergency_tickets_updated_at before update on public.emergency_tickets for each row execute function public.set_updated_at();
drop trigger if exists resources_updated_at on public.resources;
create trigger resources_updated_at before update on public.resources for each row execute function public.set_updated_at();
drop trigger if exists blocked_segments_updated_at on public.blocked_segments;
create trigger blocked_segments_updated_at before update on public.blocked_segments for each row execute function public.set_updated_at();
drop trigger if exists route_options_updated_at on public.route_options;
create trigger route_options_updated_at before update on public.route_options for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(id, email, full_name)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'full_name', split_part(coalesce(new.email, ''), '@', 1))
  )
  on conflict (id) do update
    set email = excluded.email,
        full_name = coalesce(public.profiles.full_name, excluded.full_name),
        updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.signals enable row level security;
alter table public.normalized_signals enable row level security;
alter table public.location_aliases enable row level security;
alter table public.incidents enable row level security;
alter table public.incident_evidence enable row level security;
alter table public.agent_runs enable row level security;
alter table public.agent_logs enable row level security;
alter table public.tool_calls enable row level security;
alter table public.response_actions enable row level security;
alter table public.simulation_runs enable row level security;
alter table public.simulation_metrics enable row level security;
alter table public.mock_alerts enable row level security;
alter table public.emergency_tickets enable row level security;
alter table public.resources enable row level security;
alter table public.blocked_segments enable row level security;
alter table public.route_options enable row level security;
alter table public.system_status enable row level security;

drop policy if exists "profiles_select_authenticated" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "signals_select_authenticated" on public.signals;
drop policy if exists "signals_insert_own" on public.signals;
drop policy if exists "signals_update_own_draft" on public.signals;
drop policy if exists "normalized_signals_select_authenticated" on public.normalized_signals;
drop policy if exists "location_aliases_select_authenticated" on public.location_aliases;
drop policy if exists "incidents_select_authenticated" on public.incidents;
drop policy if exists "incident_evidence_select_authenticated" on public.incident_evidence;
drop policy if exists "agent_runs_select_authenticated" on public.agent_runs;
drop policy if exists "agent_logs_select_authenticated" on public.agent_logs;
drop policy if exists "tool_calls_select_authenticated" on public.tool_calls;
drop policy if exists "response_actions_select_authenticated" on public.response_actions;
drop policy if exists "response_actions_update_authenticated" on public.response_actions;
drop policy if exists "simulation_runs_select_authenticated" on public.simulation_runs;
drop policy if exists "simulation_metrics_select_authenticated" on public.simulation_metrics;
drop policy if exists "mock_alerts_select_authenticated" on public.mock_alerts;
drop policy if exists "emergency_tickets_select_authenticated" on public.emergency_tickets;
drop policy if exists "resources_select_authenticated" on public.resources;
drop policy if exists "blocked_segments_select_authenticated" on public.blocked_segments;
drop policy if exists "route_options_select_authenticated" on public.route_options;
drop policy if exists "system_status_select_authenticated" on public.system_status;
drop policy if exists "system_status_update_admins" on public.system_status;

create policy "profiles_select_authenticated" on public.profiles for select to authenticated using (true);
create policy "profiles_insert_own" on public.profiles for insert to authenticated with check (id = auth.uid());
create policy "profiles_update_own" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy "signals_select_authenticated" on public.signals for select to authenticated using (true);
create policy "signals_insert_own" on public.signals for insert to authenticated with check (submitted_by = auth.uid());
create policy "signals_update_own_draft" on public.signals for update to authenticated using (submitted_by = auth.uid()) with check (submitted_by = auth.uid());

create policy "normalized_signals_select_authenticated" on public.normalized_signals for select to authenticated using (true);
create policy "location_aliases_select_authenticated" on public.location_aliases for select to authenticated using (true);
create policy "incidents_select_authenticated" on public.incidents for select to authenticated using (true);
create policy "incident_evidence_select_authenticated" on public.incident_evidence for select to authenticated using (true);
create policy "agent_runs_select_authenticated" on public.agent_runs for select to authenticated using (true);
create policy "agent_logs_select_authenticated" on public.agent_logs for select to authenticated using (true);
create policy "tool_calls_select_authenticated" on public.tool_calls for select to authenticated using (true);
create policy "response_actions_select_authenticated" on public.response_actions for select to authenticated using (true);
create policy "response_actions_update_authenticated" on public.response_actions for update to authenticated using (true) with check (true);
create policy "simulation_runs_select_authenticated" on public.simulation_runs for select to authenticated using (true);
create policy "simulation_metrics_select_authenticated" on public.simulation_metrics for select to authenticated using (true);
create policy "mock_alerts_select_authenticated" on public.mock_alerts for select to authenticated using (true);
create policy "emergency_tickets_select_authenticated" on public.emergency_tickets for select to authenticated using (true);
create policy "resources_select_authenticated" on public.resources for select to authenticated using (true);
create policy "blocked_segments_select_authenticated" on public.blocked_segments for select to authenticated using (true);
create policy "route_options_select_authenticated" on public.route_options for select to authenticated using (true);
create policy "system_status_select_authenticated" on public.system_status for select to authenticated using (true);

create policy "system_status_update_admins" on public.system_status
for update to authenticated
using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'))
with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

insert into public.system_status(status_key, status, message, payload)
values
  ('agent_orchestrator', 'unknown', 'Awaiting first backend run', '{}'::jsonb),
  ('supabase_realtime', 'healthy', 'Realtime tables configured by migration', '{}'::jsonb),
  ('simulation_safety', 'healthy', 'All response execution is simulated in app-owned tables', '{"real_emergency_services_contacted": false}'::jsonb)
on conflict (status_key) do nothing;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'profiles',
    'signals',
    'normalized_signals',
    'location_aliases',
    'incidents',
    'incident_evidence',
    'agent_runs',
    'agent_logs',
    'tool_calls',
    'response_actions',
    'simulation_runs',
    'simulation_metrics',
    'mock_alerts',
    'emergency_tickets',
    'resources',
    'blocked_segments',
    'route_options',
    'system_status'
  ] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', table_name);
    exception
      when duplicate_object then null;
      when undefined_object then null;
    end;
  end loop;
end $$;
