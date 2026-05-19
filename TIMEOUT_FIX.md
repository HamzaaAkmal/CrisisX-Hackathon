# Agent Orchestrator Timeout Fix

## Problem
The Agent Orchestrator was showing as "Degraded" with a "model_timeout" error. This occurred when the AI model on the backend took longer than the configured timeout to respond.

## Changes Made

### 1. Increased Timeout Values (`SupabaseService.swift`)
- **Edge Function timeout**: Increased from 45s to 120s
- **Request timeout**: Increased from 20s to 30s  
- **Resource timeout**: Increased from 45s to 120s

This gives the AI model more time to process complex requests, especially during high load periods.

### 2. Added Retry Logic (`CrisisRepository.swift`)
- Added automatic retry for timeout errors in `processSignal()`
- Will retry once after a 2-second delay if the first attempt times out
- Provides user feedback during retry: "Agent orchestrator timed out, retrying..."

### 3. Improved Error Messages (`SupabaseService.swift`)
- Changed timeout error message to be more user-friendly
- Now says: "Request timed out after Xs. The AI model may be under heavy load. Please try again in a moment."

### 4. Enhanced UI Feedback (`SettingsScreen.swift`)
- Added a "Refresh" button next to System Status when any service is degraded
- Added helpful explanation text when Agent Orchestrator is degraded
- Message explains: "The AI model may be experiencing high load. The system will automatically retry. You can also try submitting a new signal."

### 5. Added Helper Properties (`CrisisRepository.swift`)
- `isAgentOrchestratorHealthy`: Quick check if orchestrator is working
- `agentOrchestratorMessage`: Get current status message

## How It Helps

1. **Prevents premature timeouts**: Longer timeouts accommodate legitimate processing delays
2. **Automatic recovery**: Retry logic handles transient issues without user intervention
3. **Better user experience**: Clear messaging helps users understand what's happening
4. **Easy monitoring**: Enhanced UI makes it simple to check system health

## Testing
After these changes:
1. The app will be more resilient to backend delays
2. Users will see clearer feedback when issues occur
3. Temporary timeouts will often resolve automatically via retry
4. The Settings screen provides actionable information

## Next Steps (Optional Backend Improvements)
If timeouts persist, consider backend optimizations:
- Implement request queuing for high load periods
- Add caching for frequently accessed data
- Optimize AI model inference time
- Scale backend resources during peak usage
