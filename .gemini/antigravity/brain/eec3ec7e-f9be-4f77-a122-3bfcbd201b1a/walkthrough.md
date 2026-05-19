# Stuck Pipeline Recovery Walkthrough

The stuck pipeline investigation focused on preventing the UI from waiting forever when the backend start action, run row, or orchestrator status gets wedged.

## Completed Work

- `PipelineProgressSheet.swift` detects missing run rows and stale run activity.
- The sheet automatically retries orchestrator startup when no run appears after repeated heartbeat checks.
- A manual "Retry Start Now" action exists for recovery.
- `CrisisRepository.swift` includes `ensureProcessingStarted` and focused pipeline refresh methods.
- Recovery SQL exists at `/Users/apple/Desktop/Crisis/fix-orchestrator-status.sql`.
- Follow-up migrations repair fragile status and signal handling.

## Result

The app now has a practical recovery path for stuck agents and blocked pipeline state. Instead of remaining frozen, the UI can retry startup, keep polling, and surface meaningful status.

