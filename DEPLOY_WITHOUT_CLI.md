# Deploy Groq Update Without Supabase CLI

## Current Status ✅

- ✅ Database status fixed to "healthy"
- ✅ Edge Function code updated to use Groq
- ⚠️ **Still need to deploy the updated function**

## Why You Need to Deploy

The database status is now "healthy", but the Edge Function on Supabase is still using the old DigitalOcean code. The next time someone submits a signal, it will timeout again and set the status back to "degraded".

## Deployment Options

### Option 1: Install Supabase CLI (Recommended)

```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Login
supabase login

# Link your project
cd /Users/apple/Desktop/Crisis
supabase link --project-ref rkxhbbrcrfikbanjvuig

# Set the Groq API key
supabase secrets set GROQ_API_KEY=<your-groq-api-key>

# Deploy the function
supabase functions deploy ciro-agent
```

### Option 2: Use Supabase Dashboard (Manual)

1. **Go to Supabase Dashboard**: https://supabase.com/dashboard/project/rkxhbbrcrfikbanjvuig

2. **Navigate to Edge Functions**:
   - Click "Edge Functions" in the left sidebar
   - Find `ciro-agent` function

3. **Update Environment Variables**:
   - Go to "Settings" or "Configuration"
   - Add new secret:
     - Name: `GROQ_API_KEY`
     - Value: `<your-groq-api-key>`
   - Save

4. **Update Function Code**:
   - Click on the `ciro-agent` function
   - Click "Edit" or "Update"
   - Copy the entire contents of `/Users/apple/Desktop/Crisis/supabase/functions/ciro-agent/index.ts`
   - Paste into the editor
   - Click "Deploy" or "Save"

### Option 3: Use GitHub Integration (If Set Up)

If you have GitHub integration enabled:

```bash
cd /Users/apple/Desktop/Crisis
git add supabase/functions/ciro-agent/index.ts
git commit -m "Switch to Groq API for faster inference"
git push
```

Supabase will automatically deploy the updated function.

## Verify Deployment

After deploying, test it:

1. **In iOS app**, go to **Settings** → **Backend API Signal**
2. Enter a test location (e.g., "Karachi, Pakistan")
3. Select a category
4. Tap **Generate Through Backend**
5. Watch the logs or wait for completion
6. Check **System Status** - should stay "Healthy" ✅

## Check Function Logs

**Via Dashboard:**
1. Go to Edge Functions → `ciro-agent`
2. Click "Logs" tab
3. Look for recent invocations
4. Should see "Groq API" in logs (not "DigitalOcean")

**Via CLI (if installed):**
```bash
supabase functions logs ciro-agent --tail
```

## What to Look For

**Success indicators:**
- ✅ Function completes in 5-10 seconds (not 30+)
- ✅ Logs show "Groq API" calls
- ✅ No timeout errors
- ✅ System Status stays "Healthy"

**Failure indicators:**
- ❌ Still seeing "DigitalOcean GenAI error"
- ❌ Timeouts after 30+ seconds
- ❌ "Missing required environment variable: GROQ_API_KEY"
- ❌ Status goes back to "Degraded"

## Troubleshooting

### "Missing required environment variable: GROQ_API_KEY"

**Fix:** The environment variable wasn't set. Go back to Option 1 or 2 and set it.

### Still using DigitalOcean in logs

**Fix:** The function code wasn't deployed. Try Option 2 (manual dashboard update).

### "Groq API error 401"

**Fix:** API key is wrong. Double-check:
```
<your-groq-api-key>
```

## Quick Install Supabase CLI

If you want to use the CLI (easiest option):

```bash
# macOS with Homebrew
brew install supabase/tap/supabase

# Verify installation
supabase --version

# Login
supabase login

# You're ready to deploy!
```

## Summary

1. ✅ **Database fixed** - Status is now "healthy"
2. ⚠️ **Need to deploy** - Function still has old code
3. 🎯 **Choose an option above** - Deploy the Groq update
4. ✅ **Test thoroughly** - Submit a signal and verify it works

Once deployed, your app will be blazing fast with Groq! 🚀
