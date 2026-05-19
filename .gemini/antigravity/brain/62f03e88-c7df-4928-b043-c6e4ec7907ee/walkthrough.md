# Secure API Configuration Walkthrough

The API configuration phase established where each credential belongs.

## Completed Work

- Confirmed the app reads `SUPABASE_ANON_KEY` and `GOOGLE_MAPS_IOS_API_KEY` through `/Users/apple/Desktop/Crisis/com.agenticpulse.crisis/com.agenticpulse.crisis/Core/AppConfig.swift`.
- Confirmed server-only keys are documented as Supabase Edge Function secrets in `/Users/apple/Desktop/Crisis/README.md`.
- Preserved Prompt 2 in the Antigravity-style log with credential values redacted.

## Security Decision

The raw service role key and third-party API keys were intentionally not written into these files. This keeps the trace archive safe to zip and share.

