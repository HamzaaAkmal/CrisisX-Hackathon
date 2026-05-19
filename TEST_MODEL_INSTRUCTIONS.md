# Test DigitalOcean AI Model

## Quick Test

To test if the model is working, you need your `MODEL_ACCESS_KEY` from your environment variables.

### Option 1: Using the test script

```bash
cd /Users/apple/Desktop/Crisis
export MODEL_ACCESS_KEY='your-actual-api-key-here'
./test-model.sh
```

### Option 2: Direct curl command

Replace `YOUR_API_KEY` with your actual DigitalOcean AI API key:

```bash
curl -X POST "https://inference.do-ai.run/v1/chat/completions" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "glm-5",
    "messages": [
      {
        "role": "system",
        "content": "You are a helpful assistant. Respond with a brief greeting."
      },
      {
        "role": "user",
        "content": "Hello, are you working?"
      }
    ],
    "temperature": 0.15
  }'
```

### Option 3: Test with timeout monitoring

```bash
time curl --max-time 35 -X POST "https://inference.do-ai.run/v1/chat/completions" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "glm-5",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Say hello"}
    ],
    "temperature": 0.15
  }'
```

## What to look for:

### ✅ Success (HTTP 200)
```json
{
  "id": "...",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "glm-5",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Hello! Yes, I'm working properly..."
      },
      "finish_reason": "stop"
    }
  ]
}
```

### ❌ Timeout (takes > 35 seconds)
```
curl: (28) Operation timed out after 35000 milliseconds
```
**This is your problem!** The model is taking too long.

### ❌ Authentication Error (HTTP 401)
```json
{
  "error": {
    "message": "Invalid API key",
    "type": "invalid_request_error"
  }
}
```
**Fix:** Check your MODEL_ACCESS_KEY environment variable.

### ❌ Rate Limit (HTTP 429)
```json
{
  "error": {
    "message": "Rate limit exceeded",
    "type": "rate_limit_error"
  }
}
```
**Fix:** Wait a few minutes and try again.

## Finding your API key

Your API key should be in your Supabase Edge Function secrets. To check:

```bash
# If using Supabase CLI
supabase secrets list

# Or check your deployment platform's environment variables
```

## Next Steps

1. Run the test to see if the model responds
2. Check the response time - if it's consistently > 35 seconds, that's the issue
3. If timing out, you may need to:
   - Contact DigitalOcean support about model performance
   - Switch to a faster model
   - Increase the timeout (already done in the iOS app to 120s)
