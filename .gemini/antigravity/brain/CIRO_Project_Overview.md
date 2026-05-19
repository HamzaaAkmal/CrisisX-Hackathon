# CrisisAI / CIRO Antigravity Development Overview

## Project Identity

- App name: CrisisAI powered by AgenticPulse
- Package name: `com.agenticpulse.crisis`
- Root path: `/Users/apple/Desktop/Crisis`
- iOS app path: `/Users/apple/Desktop/Crisis/com.agenticpulse.crisis`
- Supabase function path: `/Users/apple/Desktop/Crisis/supabase/functions/ciro-agent/index.ts`
- Supabase migration path: `/Users/apple/Desktop/Crisis/supabase/migrations/202605170001_ciro_schema.sql`
- Primary README: `/Users/apple/Desktop/Crisis/README.md`

## Conversation Map

1. `2c3bbf0e-4ab1-4dc3-9a4d-1d583e81e6c2` - Full CIRO app architecture, SwiftUI screens, Supabase schema, agent workflow.
2. `62f03e88-c7df-4928-b043-c6e4ec7907ee` - Secure API configuration and environment variable setup.
3. `8d24427a-748a-4daa-b4d8-c15e1d4b293d` - Submit flow progress sheet, heartbeat, step-by-step agent output.
4. `afed5fb3-1544-44d6-8491-6a2697e01d88` - Dashboard connection state, skeleton loading, urgency submit behavior.
5. `c2d9b826-7cf5-4c74-8b99-086e2d814df0` - Timeouts, refresh controls, consistent skeletons and 25px-radius card redesign.
6. `eec3ec7e-f9be-4f77-a122-3bfcbd201b1a` - Stuck pipeline investigation, orchestrator recovery, run status repair.

## Current Implementation Summary

The project implements a SwiftUI iOS app backed by Supabase Auth, REST, Realtime subscriptions, migrations, and a Supabase Edge Function orchestrator. The UI includes login/signup, Live Crisis Map, Report Crisis, Signal Inbox, Incident Detail, Response Plan, Agent Trace, Simulation Outcome, and Settings. The data model covers signals, normalized signals, incidents, evidence, agent runs/logs/tool calls, response actions, simulation runs/metrics, mock alerts, tickets, resources, blocked segments, route options, and system status.

