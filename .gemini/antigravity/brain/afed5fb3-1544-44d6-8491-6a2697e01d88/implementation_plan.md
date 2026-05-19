# Dashboard Skeleton and Urgency Submit Fix Plan

The user reported the dashboard stuck at "connecting" and a bug where selecting urgency caused an auto-submit. The goal is to separate form changes from submission and make loading states feel modern and intentional.

## Proposed Changes

### 1. Dashboard Loading State

- Add skeleton cards to the Live Crisis Map dashboard while the initial Supabase load is in progress.
- Add a deadline fallback so the skeleton does not hide empty or failed states forever.
- Keep realtime connection text visible but avoid making "connecting" look like a frozen screen.

### 2. Urgency Behavior

- Ensure urgency uses a `Slider` bound only to local `urgency` state.
- Ensure the backend request starts only from the explicit Submit button action.
- If an active run exists, button opens progress instead of starting a new report.

### 3. Visual Consistency

- Reuse app card styling and skeleton shimmer helpers.
- Keep the light/blue theme consistent with existing SwiftUI screens.

## Verification Plan

- Open dashboard with no cached data and confirm skeletons render.
- Change urgency several times and confirm no signal is created.
- Tap Submit and confirm only then the request is sent and progress opens.

