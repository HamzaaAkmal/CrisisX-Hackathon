-- Fix degraded Agent Orchestrator status
-- Run this to manually reset the system status to healthy after confirming the model is working

-- Update the agent_orchestrator status to healthy
INSERT INTO public.system_status (status_key, status, message, payload, updated_at)
VALUES (
  'agent_orchestrator',
  'healthy',
  'Model confirmed working - status manually recovered',
  jsonb_build_object(
    'recovery_type', 'manual',
    'previous_error', 'model_timeout',
    'model_test_passed', true,
    'recovered_at', now()
  ),
  now()
)
ON CONFLICT (status_key) 
DO UPDATE SET
  status = 'healthy',
  message = 'Model confirmed working - status manually recovered',
  payload = public.system_status.payload || jsonb_build_object(
    'recovery_type', 'manual',
    'previous_error', 'model_timeout',
    'model_test_passed', true,
    'recovered_at', now()
  ),
  updated_at = now();

-- Verify the update
SELECT status_key, status, message, updated_at 
FROM public.system_status 
WHERE status_key = 'agent_orchestrator';
