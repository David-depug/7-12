# Backend Endpoints Information

## Current Setup

### Backend Type
- **Authentication**: Firebase Auth (already configured)
- **API Backend**: Custom REST API (needs to be configured)

### Endpoint Configuration Location
**File**: `lib/config.dart` (Line 13)

```dart
const String API_BASE_URL = 'https://api.example.com';  // ← PLACEHOLDER - Replace this!
```

## What Endpoints Are Needed

Your backend needs to implement these REST API endpoints:

### Journal Endpoints
1. `POST /journal/entries` - Save journal entry
2. `GET /journal/entries` - Get all journal entries
3. `GET /journal/entries?date=YYYY-MM-DD` - Get entry by date
4. `GET /journal/entries?start=...&end=...` - Get entries in date range
5. `DELETE /journal/entries/{id}` - Delete entry

### Journal AI Analysis Endpoints
6. `GET /journal/entries/analysis` - Get entries for AI analysis
7. `POST /journal/entries/{entryId}/analyze` - Analyze single entry
8. `POST /journal/analyze` - Analyze journal text
9. `GET /journal/entries/analysis/trends` - Analyze trends

### Mood Tracker Endpoints
10. `POST /mood/entries` - Save mood entry
11. `GET /mood/entries` - Get all mood entries
12. `GET /mood/entries?date=YYYY-MM-DD` - Get entry by date
13. `GET /mood/entries?start=...&end=...` - Get entries in date range
14. `DELETE /mood/entries/{id}` - Delete entry

### Mood AI Analysis Endpoints
15. `GET /mood/entries/analysis` - Get entries for AI analysis
16. `POST /mood/entries/{entryId}/analyze` - Analyze single mood entry
17. `GET /mood/entries/analysis/trends` - Analyze mood trends

## Authentication

All API requests should:
- Accept Firebase Auth tokens in the `Authorization` header
- Format: `Authorization: Bearer {firebase_token}`
- The app automatically adds this token to all requests

## How to Set Your Backend URL

1. **Open** `lib/config.dart`
2. **Replace** the placeholder:
   ```dart
   const String API_BASE_URL = 'https://your-actual-backend-url.com';
   ```
   Or if using a local server:
   ```dart
   const String API_BASE_URL = 'http://localhost:3000';  // For development
   ```

## Example Backend URLs

- **Production**: `https://api.mindquest.app`
- **Staging**: `https://staging-api.mindquest.app`
- **Local Development**: `http://localhost:3000` or `http://10.0.2.2:3000` (Android emulator)

## Full Endpoint Examples

Once you set `API_BASE_URL = 'https://api.mindquest.app'`, the app will call:

- `https://api.mindquest.app/journal/entries`
- `https://api.mindquest.app/journal/entries/analysis`
- `https://api.mindquest.app/mood/entries`
- `https://api.mindquest.app/mood/entries/analysis`
- etc.

## Documentation

See `AI_BOT_ENDPOINTS.md` for detailed API specifications including:
- Request/response formats
- Query parameters
- Error handling
- Example payloads

## Current Status

✅ **App is ready** - All code is implemented  
⏳ **Backend needed** - You need to:
1. Set up your REST API backend
2. Implement the endpoints listed above
3. Update `API_BASE_URL` in `lib/config.dart`
4. Ensure backend accepts Firebase Auth tokens

