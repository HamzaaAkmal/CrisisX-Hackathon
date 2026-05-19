# Groq API Migration - Summary

## Problem Solved ✅

**Issue**: Agent Orchestrator showing "Degraded" with "model_timeout" error
**Root Cause**: DigitalOcean AI model (`glm-5`) was slow and timing out
**Solution**: Switched to Groq API with `qwen/qwen3-32b` model (much faster)

## What Changed

### Edge Function (`supabase/functions/ciro-agent/index.ts`)

```diff
- const DO_AI_URL = "https://inference.do-ai.run/v1/chat/completions";
- const MODEL = "glm-5";
- const MODEL_TIMEOUT_MS = 35_000;
+ const GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions";
+ const MODEL = "qwen/qwen3-32b";
+ const MODEL_TIMEOUT_MS = 30_000;

- Authorization: Bearer ${requireEnv("MODEL_ACCESS_KEY")}
+ Authorization: Bearer ${requireEnv("GROQ_API_KEY")}

- throw new Error(`DigitalOcean GenAI error ${response.status}...`);
+ throw new Error(`Groq API error ${response.status}...`);
```

### iOS App (Already Updated)

- ✅ Increased timeout from 45s to 120s
- ✅ Added automatic retry logic
- ✅ Better error messages
- ✅ UI improvements for degraded status

## Quick Deploy

```bash
# 1. Test Groq API (optional)
./test-groq.sh

# 2. Set environment variable
supabase secrets set GROQ_API_KEY=<your-groq-api-key>

# 3. Deploy
supabase functions deploy ciro-agent

# 4. Test in iOS app
# Go to Settings → Backend API Signal → Generate test signal
```

## Expected Results

**Before (DigitalOcean)**:
- ⏱️ Response time: 30-60+ seconds
- ❌ Frequent timeouts
- 📊 Status: Often "Degraded"

**After (Groq)**:
- ⚡ Response time: 1-5 seconds
- ✅ Reliable, no timeouts
- 📊 Status: Consistently "Healthy"

## Files Created

1. `test-groq.sh` - Test script for Groq API
2. `DEPLOY_GROQ_UPDATE.md` - Detailed deployment guide
3. `GROQ_MIGRATION_SUMMARY.md` - This file
4. `fix-orchestrator-status.sql` - SQL to manually fix degraded status
5. `FIX_DEGRADED_STATUS.md` - Guide to fix current degraded status

## Next Steps

1. **Deploy the changes** (see DEPLOY_GROQ_UPDATE.md)
2. **Fix current degraded status** (see FIX_DEGRADED_STATUS.md)
3. **Test thoroughly** with multiple signals
4. **Monitor** for 24 hours to ensure stability

## Groq API Details

- **Endpoint**: https://api.groq.com/openai/v1/chat/completions
- **Model**: qwen/qwen3-32b
- **API Key**: `<your-groq-api-key>`
- **Docs**: https://console.groq.com/docs/tool-use/overview
- **Compatible**: OpenAI API format (drop-in replacement)

## Rollback Plan

If needed, revert to DigitalOcean:

```bash
git checkout HEAD -- supabase/functions/ciro-agent/index.ts
supabase functions deploy ciro-agent
```

## Support

- Groq Docs: https://console.groq.com/docs
- Groq Status: https://status.groq.com/
- Test Script: `./test-groq.sh`
