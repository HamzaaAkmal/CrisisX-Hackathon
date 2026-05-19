# Stuck Agent Pipeline Recovery Plan

The user reported that the pipeline stayed stuck for more than five minutes and agents were not working. The goal is to identify the culprit, repair orchestration state, and add recovery behavior.

## Proposed Changes

### 1. Investigate Pipeline Culprit

- Inspect the Edge Function start action and background task behavior.
- Inspect run status updates in `agent_runs`.
- Inspect `agent_logs` and `system_status`.
- Check for stale running rows that block new runs.
- Check for environment variable mismatches between app, README, and Edge Function code.

### 2. Recovery Behavior

- Add stale run detection based on latest log activity.
- If no run row appears after repeated heartbeat refreshes, retry orchestrator start.
- If a run is stale, allow a forced recovery start.
- Add system status repair SQL for broken orchestrator state.

### 3. Database Fixes

- Add migration for agent orchestrator status recovery.
- Add SQL script for manual repair if needed.
- Make status fields and signal report validation less fragile.

## Verification Plan

- Submit a report and observe run row creation.
- Confirm every agent writes at least one log.
- Confirm stale runs do not keep the UI stuck forever.
- Confirm `fix-orchestrator-status.sql` can repair a blocked status record.

