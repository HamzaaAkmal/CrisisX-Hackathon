-- Fix PostgREST relationship ambiguity between signals and normalized_signals.
--
-- The original schema had two FK paths:
--   normalized_signals.signal_id -> signals.id
--   signals.normalized_signal_id -> normalized_signals.id
--
-- PostgREST cannot infer `normalized_signals(..., signals!inner(...))`
-- when more than one relationship exists between the same two tables.
-- Keep the denormalized pointer column for app convenience, but remove
-- its FK constraint so the canonical relationship is normalized_signals.signal_id.

do $$
declare
  constraint_name text;
begin
  for constraint_name in
    select c.conname
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    join pg_attribute a on a.attrelid = t.oid and a.attnum = any(c.conkey)
    where n.nspname = 'public'
      and t.relname = 'signals'
      and c.contype = 'f'
      and a.attname = 'normalized_signal_id'
  loop
    execute format('alter table public.signals drop constraint if exists %I', constraint_name);
  end loop;
end $$;

comment on column public.signals.normalized_signal_id is
  'Denormalized pointer to the latest normalized signal row. Intentionally not a foreign key to avoid PostgREST relationship ambiguity; canonical FK is normalized_signals.signal_id -> signals.id.';

update public.system_status
set
  status = 'healthy',
  message = 'Agent relationship ambiguity migration applied',
  payload = coalesce(payload, '{}'::jsonb) || jsonb_build_object(
    'fixed_relationship', 'signals.normalized_signal_id foreign key removed',
    'canonical_relationship', 'normalized_signals.signal_id -> signals.id',
    'applied_at', now()
  ),
  updated_at = now()
where status_key = 'agent_orchestrator'
  and message ilike '%more than one relationship%';
