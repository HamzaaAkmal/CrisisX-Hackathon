# Fix "Agent Orchestrator Degraded" Status

## Problem Identified ✅

The model is **working fine** (tested successfully in 4 seconds), but the `system_status` table in your database still shows "degraded" from a previous timeout error. The status doesn't automatically clear until a successful agent run completes.

## Solution Options

### Option 1: Run a Test Signal (Recommended - Tests Full Pipeline)

This will trigger a full agent pipeline and automatically update the status to "healthy" if successful.

**In your iOS app:**
1. Go to the "Report Crisis" screen
2. Submit a test signal with any location and description
3. Wait for the pipeline to complete
4. Check Settings → System Status
5. Status should now show "Healthy"

**Or use the Backend API Signal in Settings:**
1. Open Settings screen
2. Scroll to "Backend API Signal" section
3. Enter a location (e.g., "Lahore, Pakistan")
4. Select a category
5. Tap "Generate Through Backend"
6. Wait for completion
7. Refresh System Status

### Option 2: Manual Database Fix (Fastest)

Run the SQL script to immediately reset the status:

```bash
# Using Supabase CLI
cd /Users/apple/Desktop/Crisis
supabase db execute --file fix-orchestrator-status.sql

# Or using psql directly
psql "your-database-connection-string" -f fix-orchestrator-status.sql
```

**Or via Supabase Dashboard:**
1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `fix-orchestrator-status.sql`
4. Click "Run"

### Option 3: Use the App's Refresh Button

The app now has a "Refresh" button in the Settings screen when a service is degraded:

1. Open the app
2. Go to Settings
3. Tap the "Refresh" button next to "System Status"
4. This will reload the data from the database

**Note:** This only refreshes the display. If the database still shows "degraded", you need Option 1 or 2.

## Why This Happened

1. A previous agent run timed out (model took > 35 seconds)
2. The Edge Function caught the timeout and set `system_status` to "degraded"
3. The status remains "degraded" until:
   - A new successful agent run completes, OR
   - You manually update the database

## Prevention

The iOS app changes already made will help prevent this:

✅ **Increased timeout from 45s to 120s** - Gives model more time
✅ **Added automatic retry logic** - Retries once if timeout occurs  
✅ **Better error messages** - Clearer feedback to users
✅ **UI improvements** - Shows helpful context when degraded

## Verify the Fix

After applying any solution:

1. Open the iOS app
2. Go to Settings
3. Check "System Status" section
4. "Agent Orchestrator" should show: **Healthy** ✅

## Quick SQL Command (Copy-Paste)

If you have direct database access:

```sql
UPDATE public.system_status 
SET 
  status = 'healthy',
  message = 'Model confirmed working - status manually recovered',
  updated_at = now()
WHERE status_key = 'agent_orchestrator';
```

## Still Showing Degraded?

If the status is still degraded after trying these options:

1. **Check if the app is caching old data:**
   - Force quit the app completely
   - Reopen and check Settings

2. **Verify database was updated:**
   ```sql
   SELECT status_key, status, message, updated_at 
   FROM public.system_status 
   WHERE status_key = 'agent_orchestrator';
   ```

3. **Check for new errors:**
   - Look at the `agent_runs` table for recent failures
   - Check Edge Function logs in Supabase dashboard

## Next Steps

Once the status shows "Healthy":
- The system is fully operational
- You can submit real crisis signals
- The agent pipeline will process them normally
- Status will update automatically with each run
