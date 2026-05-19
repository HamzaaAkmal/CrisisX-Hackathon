# Agent Submit Progress Walkthrough

The submit flow was upgraded from a single loading label into a live pipeline view.

## Completed Work

- `ReportCrisisScreen.swift` now stores `activeSignalId`, presents `PipelineProgressSheet`, and distinguishes submit from "View Agent Progress".
- `PipelineProgressSheet.swift` shows heartbeat loading, realtime/polling status, submitted signal details, normalized output, eight agent steps, live logs, tool calls, and final incident output.
- `CrisisRepository.swift` includes signal-specific pipeline state loading and timeout recovery behavior.

## Result

When the user submits a report, they see the backend work as it happens instead of waiting on an opaque spinner.

