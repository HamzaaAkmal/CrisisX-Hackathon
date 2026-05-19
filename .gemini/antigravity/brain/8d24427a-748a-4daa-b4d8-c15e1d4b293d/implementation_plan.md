# Agent Submit Progress UX Plan

The user reported that tapping Submit only showed "Submitting to Agents" while the backend agents continued running. The goal is to expose the real pipeline state with a proper loading screen, heartbeat, live steps, and final agent output.

## User Review Required

> [!IMPORTANT]
> **Realtime and Polling**
> Supabase Realtime should drive updates when connected. Heartbeat polling should continue as a fallback so the user always sees progress even if the websocket is delayed.

## Proposed Changes

### 1. Submit Flow

- Save the report as a `signals` row first.
- Store the active signal id locally.
- Open a pipeline progress sheet immediately after the signal is saved.
- Trigger the Edge Function with `action: "start_processing"`.
- Do not clear useful state until the progress sheet is visible.

### 2. Pipeline Progress Sheet

- Create `/Users/apple/Desktop/Crisis/com.agenticpulse.crisis/com.agenticpulse.crisis/Views/Screens/PipelineProgressSheet.swift`.
- Show a heart-beat loading animation.
- Show expected agent steps:
  - Signal Normalizer Agent
  - Geo Resolver Agent
  - Evidence Agent
  - Crisis Detector Agent
  - Severity Agent
  - Response Planner Agent
  - Simulation Agent
  - Trace Agent
- Bind each step to `agent_logs`.
- Show recent `tool_calls`.
- Show final incident, severity, confidence, evidence count, action count, alerts, and tickets.

### 3. Repository Heartbeat

- Add focused pipeline refresh by signal id.
- Fetch matching signal, normalized signal, agent run, logs, tool calls, and final incident.
- If the function request times out but the backend is still running, keep the sheet open and keep syncing.

## Verification Plan

- Submit a crisis report from Report Crisis.
- Confirm the progress sheet opens immediately.
- Confirm steps change from waiting to running/completed.
- Confirm final incident output renders from Supabase data.

