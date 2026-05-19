## Development Phases

### Phase 1: Core Product and Agent Architecture

- Planned a production SwiftUI crisis intelligence app named CrisisAI powered by AgenticPulse.
- Created the Supabase schema, realtime data model, Edge Function orchestrator, and app screens.
- Established the safety boundary for simulated response execution.

### Phase 2: Secure API Configuration

- Mapped app-safe keys to Xcode/build configuration.
- Mapped server-only keys to Supabase Edge Function secrets.
- Kept raw credentials out of source and out of the trace archive.

### Phase 3: Live Submit and Agent Progress UX

- Replaced opaque submit loading with a heartbeat progress sheet.
- Displayed agent steps, logs, tool calls, and final incident output.
- Added fallback heartbeat polling for delayed realtime updates.

### Phase 4: Dashboard and Form Reliability

- Added modern skeleton loading states for the dashboard.
- Kept urgency selection local until explicit Submit.
- Preserved the consistent light blue SwiftUI design language.

### Phase 5: Timeout and Refresh Hardening

- Increased long-running request tolerance.
- Kept pipeline sync alive when the client request times out.
- Added refresh controls and skeleton states across data-heavy tabs.

### Phase 6: Stuck Pipeline Recovery

- Investigated stale run/orchestrator states.
- Added recovery SQL and UI retry behavior.
- Documented the final recovery path for agent pipeline issues.



