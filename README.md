# CrisisAI powered by AgenticPulse

CrisisAI is a SwiftUI iOS app and Supabase backend for CIRO: Crisis Intelligence & Response Orchestrator. It implements a real-time, agentic crisis intelligence flow for Challenge 3 without hardcoded incident outputs or static UI fixtures.

The app lets authenticated users submit crisis reports, watches Supabase Realtime for live state changes, and displays incidents, evidence, response actions, traces, mock alerts, mock tickets, route options, and simulation metrics.

## Architecture

- **iOS app:** SwiftUI, light blue design system, bottom tab UX, Google Maps SDK for iOS, Keychain-backed Supabase email auth, Supabase REST, and Supabase Realtime WebSocket subscriptions.
- **Supabase database:** Migration at `supabase/migrations/202605170001_ciro_schema.sql`.
- **Agent backend:** Supabase Edge Function at `supabase/functions/ciro-agent/index.ts`.
- **AI provider:** DigitalOcean GenAI OpenAI-compatible chat completions at `https://inference.do-ai.run/v1/chat/completions`, model `kimi-k2.6`, `tool_choice: "auto"`.
- **External context tools:** Google Geocoding/Routes, Exa search/news, and OpenWeather.
- **Safety boundary:** Response execution is simulated only in app-owned Supabase tables. The system never claims to contact real emergency services or change real Google Maps traffic.

## Screens

- Login / Signup through Supabase email auth
- Live Crisis Map
- Report Crisis
- Signal Inbox
- Incident Detail
- Response Plan
- Agent Trace
- Simulation Outcome
- Settings

## Required Keys

Do not commit secrets. The app reads client config from Xcode build settings / environment / generated Info.plist keys.

### iOS app

- `SUPABASE_ANON_KEY`
- `GOOGLE_MAPS_IOS_API_KEY`
- `SUPABASE_URL` is optional; the app defaults to `https://rkxhbbrcrfikbanjvuig.supabase.co`.

In Xcode, add user-defined build settings for `SUPABASE_ANON_KEY` and `GOOGLE_MAPS_IOS_API_KEY` on the app target. The project maps those into `SupabaseAnonKey` and `GoogleMapsAPIKey` Info.plist keys.

For local development this repo also supports `Config/Local.xcconfig`, which is ignored by git and wired into the app target. Put only client-safe values there: `SUPABASE_ANON_KEY` and `GOOGLE_MAPS_IOS_API_KEY`.

### Supabase Edge Function

Set these with Supabase secrets:

```bash
supabase secrets set \
  SUPABASE_URL=https://rkxhbbrcrfikbanjvuig.supabase.co \
  SUPABASE_ANON_KEY=your-supabase-anon-key \
  SUPABASE_SERVICE_ROLE_KEY=your-service-role-key \
  MODEL_ACCESS_KEY=your-digitalocean-genai-key \
  GOOGLE_MAPS_API_KEY=your-google-server-api-key \
  EXA_API_KEY=your-exa-api-key \
  OPENWEATHER_API_KEY=your-openweather-key
```

Use separate Google keys if you restrict iOS bundle identifiers and server API access differently.

## Supabase Setup

1. Enable Supabase Auth email provider in the Supabase dashboard.
2. Run the schema migration:

```bash
supabase link --project-ref rkxhbbrcrfikbanjvuig
supabase db push
```

Or paste `supabase/migrations/202605170001_ciro_schema.sql` into the Supabase SQL editor.

3. Deploy the Edge Function:

```bash
supabase functions deploy ciro-agent --project-ref rkxhbbrcrfikbanjvuig
```

4. Confirm Realtime is enabled. The migration adds all CIRO tables to `supabase_realtime` where available.

## Agent Workflow

When a user submits a report:

1. The app inserts a row into `signals`.
2. Supabase Realtime updates the UI.
3. The app invokes `ciro-agent` with `action: "process_signal"`.
4. The backend creates an `agent_runs` row.
5. Agents run in order:
   - Signal Normalizer Agent
   - Geo Resolver Agent
   - Evidence Agent
   - Crisis Detector Agent
   - Severity Agent
   - Response Planner Agent
   - Simulation Agent
   - Trace Agent
6. Every agent writes to `agent_logs`; every tool call writes to `tool_calls`.
7. Incidents, evidence, actions, mock alerts, mock emergency tickets, blocked segments, route options, and metrics are persisted in Supabase and streamed back into the app.

## Structured Tools

The backend defines OpenAI-compatible tools for:

- `geocode_locations`
- `fetch_weather`
- `search_latest_web_news`
- `compute_route_alternatives`
- `upsert_incident`
- `create_response_action`
- `run_simulation`
- `create_mock_emergency_ticket`
- `create_mock_alert`
- `write_agent_log`

## Google Antigravity Usage

Open the repository folder in Google Antigravity and use it as a reviewable agent workspace:

1. Ask the agent to inspect `README.md`, the migration, and `supabase/functions/ciro-agent/index.ts`.
2. Keep destructive command approval on; database changes should be limited to `supabase db push` after reviewing the SQL.
3. Use Antigravity’s browser/dev workflow to open the Supabase dashboard, verify tables and Realtime, then run the iOS app in Xcode.
4. Use the Agent Trace screen as the app-side audit trail for each backend run.

Official starting point: [Google Antigravity codelab](https://codelabs.developers.google.com/getting-started-google-antigravity).

## Demo Steps

1. Run the Supabase migration and deploy the function.
2. Set all Edge Function secrets.
3. Add `SUPABASE_ANON_KEY` and `GOOGLE_MAPS_IOS_API_KEY` to Xcode build settings.
4. Build and run CrisisAI.
5. Signup or login with email/password.
6. Submit a real report from **Report Crisis**.
7. Watch **Signal Inbox** and **Live Crisis Map** update through Realtime.
8. Open the incident and inspect **Response Plan**, **Agent Trace**, and **Simulation Outcome**.
9. In **Settings**, use Backend API Signal to create a test signal through live backend tools.

## Assumptions

- The mobile app calls Supabase directly with the anon key and user JWT.
- Secret AI/API keys live only in Supabase Edge Function environment variables.
- The Edge Function uses service role access for server-side orchestration and writes.
- Response actions are operational recommendations and mock execution records, not real dispatch.
- Google Maps displays app-owned overlays; real traffic is read through Routes API but never modified.

## Verification

Local checks run:

```bash
deno check supabase/functions/ciro-agent/index.ts
xcodebuild -project com.agenticpulse.crisis/com.agenticpulse.crisis.xcodeproj \
  -scheme com.agenticpulse.crisis \
  -destination 'generic/platform=iOS Simulator' build
```

The Xcode build succeeds with the Google Maps iOS Swift package pinned to `10.13.0`.

## References

- [Google Maps SDK for iOS Swift Package Manager setup](https://developers.google.com/maps/documentation/ios-sdk/map-with-marker)
- [Google Maps SDK for iOS SwiftUI guidance](https://developers.google.com/maps/documentation/ios-sdk/map)
- [Exa Search API](https://docs.exa.ai/reference/search)
- [Google Antigravity codelab](https://codelabs.developers.google.com/getting-started-google-antigravity)
