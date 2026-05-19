# CIRO Production App Implementation Plan

The goal is to build a production-quality SwiftUI mobile app called CrisisAI powered by AgenticPulse for CIRO: Crisis Intelligence & Response Orchestrator.

## User Review Required

> [!WARNING]
> **Secrets and API Keys**
> The Supabase anon key, service role key, DigitalOcean model key, Exa key, OpenWeather key, and Google Maps key must be configured through Xcode build settings, local ignored configuration, or Supabase Edge Function secrets. They must not be hardcoded in committed Swift, SQL, TypeScript, README examples, or trace exports.

> [!IMPORTANT]
> **Safety Boundary**
> The app can simulate emergency tickets, alerts, resource assignment, route overlays, and before-vs-after metrics. It must never claim to contact real emergency services or modify live Google Maps traffic.

## Proposed Changes

### 1. SwiftUI App Shell

- Create app target `com.agenticpulse.crisis`.
- Add a light blue design system in `AppTheme.swift`.
- Add login/signup through Supabase email auth.
- Add bottom-tab UX through `MainShellView.swift`.
- Implement screens for Live Crisis Map, Report Crisis, Signal Inbox, Incident Detail, Response Plan, Agent Trace, Simulation Outcome, and Settings.

### 2. Secure Configuration

- Add `AppConfig.swift` to resolve `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `GOOGLE_MAPS_IOS_API_KEY` from environment/build settings.
- Add ignored local config support through `Config/Local.xcconfig`.
- Keep server-only secrets in Supabase Edge Function environment variables.

### 3. Supabase Schema

- Create migration `supabase/migrations/202605170001_ciro_schema.sql`.
- Include profiles, signals, normalized_signals, location_aliases, incidents, incident_evidence, agent_runs, agent_logs, tool_calls, response_actions, simulation_runs, simulation_metrics, mock_alerts, emergency_tickets, resources, blocked_segments, route_options, and system_status.
- Add RLS, indexes, timestamps, JSONB payloads, and realtime-friendly status fields.

### 4. Agent Backend

- Create Supabase Edge Function `supabase/functions/ciro-agent/index.ts`.
- Implement an OpenAI-compatible chat completion provider.
- Define structured tool calls for geocoding, weather, web/news search, route alternatives, incident upsert, response actions, simulations, mock tickets, mock alerts, and agent logging.
- Run the multi-agent workflow: Signal Normalizer, Geo Resolver, Evidence, Crisis Detector, Severity, Response Planner, Simulation, and Trace.

### 5. Realtime Data Layer

- Create Supabase REST and Realtime services.
- Subscribe to signals, normalized_signals, incidents, evidence, agent runs/logs/tool calls, response actions, simulations, alerts, tickets, resources, blocked segments, route options, and system status.
- Ensure UI refreshes without manual reload.

## Verification Plan

- Run `deno check supabase/functions/ciro-agent/index.ts`.
- Run `xcodebuild -project com.agenticpulse.crisis/com.agenticpulse.crisis.xcodeproj -scheme com.agenticpulse.crisis -destination 'generic/platform=iOS Simulator' build`.
- Verify the README documents setup, keys, migration, deployment, agent workflow, assumptions, and demo flow.

