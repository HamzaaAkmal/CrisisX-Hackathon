# Timeout and Skeleton UX Walkthrough

The pipeline and dashboard were hardened for longer-running agent work.

## Completed Work

- `SupabaseService.swift` uses longer resource timing for requests and path-specific timeout behavior.
- `ReportCrisisScreen.swift` treats a timeout as "still syncing" where appropriate and keeps the progress sheet available.
- `CrisisRepository.swift` tracks `isLoading`, `isRefreshing`, and `hasLoadedOnce` so screens can distinguish first load from refresh.
- Data-heavy screens include refresh affordances and skeleton states.
- Cards were aligned around a consistent modern rounded style.

## Result

Long-running agent work does not strand the user after two steps; the UI continues syncing and gives users a way to refresh current Supabase state.

