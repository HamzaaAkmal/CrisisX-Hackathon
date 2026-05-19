# Dashboard Skeleton and Urgency Fix Walkthrough

The dashboard loading state was redesigned so initial Supabase fetches show modern skeleton placeholders instead of appearing stuck at connection.

## Completed Work

- `LiveCrisisMapScreen.swift` uses skeleton stat tiles and a skeleton incident list while the first load is active.
- The Report Crisis urgency control remains local-only; backend submission starts only from the Submit button.
- A refresh control remains available so users can force a latest-data load.

## Result

The dashboard no longer looks frozen during first load, and urgency selection is safely separated from form submission.

