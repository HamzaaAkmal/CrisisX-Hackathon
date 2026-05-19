-- Clears stale orchestrator degradation caused by the old single-row incident update bug.
-- New runs will set this row to running/healthy/degraded from the Edge Function.
insert into public.system_status (status_key, status, message, payload, updated_at)
values (
  'agent_orchestrator',
  'healthy',
  'Agent orchestrator async pipeline fix installed; waiting for next live run',
  jsonb_build_object(
    'fix', 'async_start_processing_and_incident_maybe_single',
    'safe_execution', true
  ),
  now()
)
on conflict (status_key) do update
set
  status = case
    when public.system_status.message ilike '%Cannot coerce the result to a single JSON object%'
      or public.system_status.message ilike '%Request idle timeout limit%'
      or public.system_status.status = 'degraded'
    then excluded.status
    else public.system_status.status
  end,
  message = case
    when public.system_status.message ilike '%Cannot coerce the result to a single JSON object%'
      or public.system_status.message ilike '%Request idle timeout limit%'
      or public.system_status.status = 'degraded'
    then excluded.message
    else public.system_status.message
  end,
  payload = public.system_status.payload || excluded.payload,
  updated_at = now();
