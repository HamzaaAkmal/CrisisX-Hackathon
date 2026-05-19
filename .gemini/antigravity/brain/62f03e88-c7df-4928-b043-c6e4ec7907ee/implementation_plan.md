# Secure API Configuration Plan

The user provided Supabase, Exa, OpenWeather, and Google Maps keys and asked to add them to the code. The correct implementation is to wire configuration points without hardcoding secrets in source files.

## User Review Required

> [!WARNING]
> **Credential Handling**
> The raw API keys are not written into this trace archive. They must be inserted through local ignored config, Xcode build settings, and Supabase secrets.

## Proposed Changes

### 1. iOS Client Keys

- Keep `SUPABASE_ANON_KEY` and `GOOGLE_MAPS_IOS_API_KEY` resolved by `AppConfig.swift`.
- Allow local developer setup through `/Users/apple/Desktop/Crisis/Config/Local.xcconfig`.
- Map build settings into Info.plist keys `SupabaseAnonKey` and `GoogleMapsAPIKey`.

### 2. Server-Side Secrets

- Use Supabase secrets for:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `SUPABASE_SERVICE_ROLE_KEY`
  - `MODEL_ACCESS_KEY`
  - `GOOGLE_MAPS_API_KEY`
  - `EXA_API_KEY`
  - `OPENWEATHER_API_KEY`
- Do not put service role keys in the iOS app.

### 3. Documentation

- Update README examples to show placeholder values only.
- Explain that server-only keys belong in Supabase Edge Function secrets.
- Keep trace logs redacted because they may be zipped for hackathon submission.

## Verification Plan

- Search for raw keys in source files before final delivery.
- Confirm README documents secret setup using placeholders.
- Confirm `AppConfig.swift` rejects placeholder values.

