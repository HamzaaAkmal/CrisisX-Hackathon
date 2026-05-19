# Timeout, Refresh, and Card Redesign Plan

The user reported the pipeline completed only two steps before timing out and requested broader skeleton loading, refresh buttons, and consistent 25px-radius cards.

## Proposed Changes

### 1. Timeout Handling

- Increase Supabase function request timeout for `ciro-agent`.
- Treat client timeout as a possible async-running state instead of an immediate dead end.
- Keep heartbeat polling active after timeout.
- Surface user-readable recovery messages.

### 2. Loading States Across Tabs

- Add skeleton loading to dashboard, response plan, simulation outcome, settings, and other data-heavy tabs.
- Use `hasLoadedOnce`, `isLoading`, and `isRefreshing` from `CrisisRepository`.
- Keep refresh buttons in toolbars where users expect them.

### 3. Card Design

- Adjust shared card style for 25px rounded borders where requested.
- Keep card sizing consistent for repeated dashboard/stat elements.
- Preserve the light blue theme and readable contrast.

## Verification Plan

- Trigger an agent run and leave the progress sheet open after timeout.
- Confirm logs continue syncing.
- Confirm tabs show skeletons during initial fetch.
- Confirm refresh buttons call `loadAll()`.
- Confirm repeated cards have identical dimensions and consistent radius.

