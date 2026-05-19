# Deploy Groq API Update

## Changes Made ✅

Switched from DigitalOcean AI to **Groq API** for faster, more reliable AI inference:

- **Old Model**: DigitalOcean `glm-5` (slow, timing out)
- **New Model**: Groq `qwen/qwen3-32b` (blazing fast, reliable)
- **API Endpoint**: `https://api.groq.com/openai/v1/chat/completions`
- **Timeout**: Reduced to 30s (Groq is much faster)

## Why Groq?

- ⚡ **Much faster inference** - Typically responds in 1-3 seconds
- 🎯 **Better reliability** - Industry-leading uptime
- 🛠️ **Full tool calling support** - Compatible with OpenAI API format
- 💰 **Cost effective** - Competitive pricing

## Deployment Steps

### Step 1: Test Groq API (Optional but Recommended)

```bash
cd /Users/apple/Desktop/Crisis
./test-groq.sh
```

This will verify:
- ✅ API key is valid
- ✅ Model responds quickly
- ✅ Tool calling works

### Step 2: Set Environment Variable

You need to add the `GROQ_API_KEY` to your Supabase Edge Function secrets.

**Using Supabase CLI:**

```bash
cd /Users/apple/Desktop/Crisis

# Set the Groq API key
supabase secrets set GROQ_API_KEY=<your-groq-api-key>

# Verify it was set
supabase secrets list
```

**Using Supabase Dashboard:**

1. Go to your Supabase project dashboard
2. Navigate to **Edge Functions** → **Settings** (or **Project Settings** → **Edge Functions**)
3. Find **Environment Variables** or **Secrets**
4. Add new secret:
   - **Name**: `GROQ_API_KEY`
   - **Value**: `<your-groq-api-key>`
5. Save

### Step 3: Deploy the Updated Edge Function

```bash
cd /Users/apple/Desktop/Crisis

# Deploy the updated function
supabase functions deploy ciro-agent

# Or if you need to link your project first
supabase link --project-ref your-project-ref
supabase functions deploy ciro-agent
```

### Step 4: Verify Deployment

**Check the function logs:**

```bash
supabase functions logs ciro-agent --tail
```

**Or via Dashboard:**
1. Go to Edge Functions in Supabase dashboard
2. Click on `ciro-agent`
3. Check the **Logs** tab

### Step 5: Test in iOS App

1. Open your iOS app
2. Go to **Settings** → **Backend API Signal**
3. Enter a test location (e.g., "Lahore, Pakistan")
4. Select a category
5. Tap **Generate Through Backend**
6. Wait for completion (should be much faster now!)
7. Check **System Status** - should show **Healthy** ✅

## Troubleshooting

### Error: "Missing required environment variable: GROQ_API_KEY"

**Fix:** The environment variable wasn't set properly. Repeat Step 2.

### Error: "Groq API error 401"

**Fix:** Invalid API key. Double-check the key:
```
<your-groq-api-key>
```

### Error: "Groq API error 429"

**Fix:** Rate limit exceeded. Wait a minute and try again, or check your Groq account limits.

### Still timing out?

1. Check Groq API status: https://status.groq.com/
2. Verify the model name is correct: `qwen/qwen3-32b`
3. Check Edge Function logs for detailed errors

## Rollback (If Needed)

If you need to rollback to DigitalOcean:

```bash
cd /Users/apple/Desktop/Crisis
git checkout HEAD -- supabase/functions/ciro-agent/index.ts
supabase functions deploy ciro-agent
```

## Environment Variables Summary

After deployment, your Edge Function should have these secrets:

- ✅ `GROQ_API_KEY` - Groq API key (NEW)
- ✅ `iSUPABASE_URL` - Your Supabase URL
- ✅ `iSUPABASE_ANON_KEY` - Supabase anon key
- ✅ `iSUPABASE_SERVICE_ROLE_KEY` - Supabase service role key
- ✅ `GOOGLE_MAPS_API_KEY` - Google Maps key
- ✅ `OPENWEATHER_API_KEY` - OpenWeather key
- ✅ `EXA_API_KEY` - Exa AI key
- ⚠️ `MODEL_ACCESS_KEY` - DigitalOcean key (no longer needed, but safe to keep)

## Expected Performance

With Groq, you should see:

- **Response time**: 1-5 seconds (vs 30+ seconds with DigitalOcean)
- **Timeout rate**: Near zero
- **System status**: Consistently "Healthy"
- **User experience**: Much snappier, more reliable

## Monitoring

After deployment, monitor for 24 hours:

1. Check **System Status** in app regularly
2. Watch Edge Function logs for errors
3. Test signal processing multiple times
4. Verify agent runs complete successfully

## Cost Comparison

**Groq Pricing** (as of 2024):
- Very competitive, often cheaper than alternatives
- Check current pricing: https://groq.com/pricing/

**DigitalOcean AI Pricing**:
- Variable based on usage
- May have been causing timeouts due to capacity

## Support

If issues persist after switching to Groq:

1. Check Groq documentation: https://console.groq.com/docs
2. Review Edge Function logs in detail
3. Test the API directly with `test-groq.sh`
4. Contact Groq support if API issues
