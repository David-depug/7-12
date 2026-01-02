# AI Bot Endpoints Documentation

## Overview
This document describes the API endpoints that need to be implemented on your backend for the AI bot to analyze journal entries.

## Data Flow
```
App → Saves to Local (Hive) → Syncs to Backend → AI Bot analyzes from Backend
```

## Required Endpoints

### 1. Get Journal Entries for AI Analysis
**Endpoint:** `GET /journal/entries/analysis`

**Purpose:** Allows the AI bot to fetch journal entries for analysis.

**Query Parameters:**
- `userId` (optional, string): Filter entries by user ID
- `startDate` (optional, ISO 8601 string): Start date for date range filter
- `endDate` (optional, ISO 8601 string): End date for date range filter
- `limit` (optional, integer): Maximum number of entries to return

**Example Request:**
```
GET /journal/entries/analysis?userId=user123&startDate=2024-01-01T00:00:00Z&limit=50
```

**Response:**
```json
[
  {
    "id": "entry-123",
    "date": "2024-01-15T00:00:00Z",
    "answers": [
      {
        "question": "How did you feel today?",
        "answer": "I felt great today!"
      }
    ],
    "mood": "happy",
    "timestamp": "2024-01-15T10:30:00Z",
    "xpAwarded": 10
  }
]
```

---

### 2. Analyze Single Journal Entry
**Endpoint:** `POST /journal/entries/{entryId}/analyze`

**Purpose:** Sends a specific journal entry to the AI bot for analysis and returns insights.

**Path Parameters:**
- `entryId` (required, string): The ID of the journal entry to analyze

**Request Body:**
```json
{
  "id": "entry-123",
  "date": "2024-01-15T00:00:00Z",
  "answers": [
    {
      "question": "How did you feel today?",
      "answer": "I felt great today!"
    }
  ],
  "mood": "happy",
  "timestamp": "2024-01-15T10:30:00Z",
  "xpAwarded": 10
}
```

**Response:**
```json
{
  "analysis": "Based on your journal entry, you seem to be in a positive mood. Your responses indicate...",
  "insights": "You showed enthusiasm and positivity today.",
  "sentiment": "positive",
  "recommendations": ["Keep up the good work!", "Consider journaling about what made you happy"]
}
```

**Note:** The response should include at least one of: `analysis` or `insights` field.

---

### 3. Analyze Journal Text (Alternative)
**Endpoint:** `POST /journal/analyze`

**Purpose:** Alternative endpoint that accepts plain text for analysis (useful for quick analysis).

**Request Body:**
```json
{
  "text": "How did you feel today?\nI felt great today!\n\nWhat are you grateful for?\nI'm grateful for my family."
}
```

**Response:**
```json
{
  "analysis": "Your journal entry shows...",
  "insights": "Key insights here..."
}
```

---

### 4. Analyze Multiple Entries (Trend Analysis)
**Endpoint:** `GET /journal/entries/analysis/trends`

**Purpose:** Allows the AI bot to analyze patterns across multiple journal entries over time.

**Query Parameters:**
- `userId` (optional, string): Filter entries by user ID
- `startDate` (optional, ISO 8601 string): Start date for analysis period
- `endDate` (optional, ISO 8601 string): End date for analysis period

**Example Request:**
```
GET /journal/entries/analysis/trends?userId=user123&startDate=2024-01-01T00:00:00Z&endDate=2024-01-31T00:00:00Z
```

**Response:**
```json
{
  "trends": {
    "moodTrend": "improving",
    "sentiment": "mostly positive",
    "patterns": [
      "You tend to feel better on weekends",
      "Your mood improves after exercise"
    ]
  },
  "summary": "Overall analysis of the period...",
  "recommendations": [
    "Consider journaling more consistently",
    "Focus on gratitude practices"
  ]
}
```

---

## Implementation Notes

### Authentication
All endpoints should require authentication. The app will send authentication tokens in the request headers.

### Error Handling
- Return appropriate HTTP status codes (401 for unauthorized, 404 for not found, 500 for server errors)
- Include error messages in the response body:
```json
{
  "message": "Error description here"
}
```

### Response Format
- All dates should be in ISO 8601 format
- Use consistent JSON structure
- Include meaningful error messages

### AI Bot Integration
The AI bot should:
1. Fetch journal entries from the database using these endpoints
2. Process the entries using your AI/ML model
3. Return insights and analysis in the response

---

## Current App Implementation

The Flutter app already has:
- ✅ `JournalApiService.getEntriesForAnalysis()` - Calls endpoint #1
- ✅ `JournalApiService.analyzeEntry()` - Calls endpoint #2
- ✅ `AiAnalysisService.analyzeJournalEntry()` - Uses endpoint #2
- ✅ `AiAnalysisService.analyzeJournalText()` - Uses endpoint #3
- ✅ `AiAnalysisService.analyzeMultipleEntries()` - Uses endpoint #4

**The app is ready to use these endpoints once they're implemented on the backend!**

---

## Mood Tracker AI Analysis Endpoints

### 5. Get Mood Entries for AI Analysis
**Endpoint:** `GET /mood/entries/analysis`

**Purpose:** Allows the AI bot to fetch mood entries for analysis.

**Query Parameters:**
- `userId` (optional, string): Filter entries by user ID
- `startDate` (optional, ISO 8601 string): Start date for date range filter
- `endDate` (optional, ISO 8601 string): End date for date range filter
- `limit` (optional, integer): Maximum number of entries to return

**Example Request:**
```
GET /mood/entries/analysis?userId=user123&startDate=2024-01-01T00:00:00Z&limit=50
```

**Response:**
```json
[
  {
    "id": "mood-123",
    "mood": "Happy",
    "date": "2024-01-15T00:00:00Z",
    "timestamp": "2024-01-15T09:30:00Z"
  }
]
```

---

### 6. Analyze Single Mood Entry
**Endpoint:** `POST /mood/entries/{entryId}/analyze`

**Purpose:** Sends a specific mood entry to the AI bot for analysis and returns insights.

**Path Parameters:**
- `entryId` (required, string): The ID of the mood entry to analyze

**Request Body:**
```json
{
  "id": "mood-123",
  "mood": "Happy",
  "date": "2024-01-15T00:00:00Z",
  "timestamp": "2024-01-15T09:30:00Z"
}
```

**Response:**
```json
{
  "analysis": "Your mood today is positive. This is great for your overall well-being...",
  "insights": "You've been consistently happy this week.",
  "recommendations": ["Keep doing what makes you happy", "Consider journaling about positive experiences"]
}
```

---

### 7. Analyze Mood Trends
**Endpoint:** `GET /mood/entries/analysis/trends`

**Purpose:** Allows the AI bot to analyze patterns across multiple mood entries over time.

**Query Parameters:**
- `userId` (optional, string): Filter entries by user ID
- `startDate` (optional, ISO 8601 string): Start date for analysis period
- `endDate` (optional, ISO 8601 string): End date for analysis period

**Example Request:**
```
GET /mood/entries/analysis/trends?userId=user123&startDate=2024-01-01T00:00:00Z&endDate=2024-01-31T00:00:00Z
```

**Response:**
```json
{
  "trends": {
    "overallTrend": "improving",
    "averageMood": 3.8,
    "moodDistribution": {
      "Very Happy": 5,
      "Happy": 12,
      "Neutral": 8,
      "Sad": 3,
      "Very Sad": 1
    },
    "patterns": [
      "You tend to feel better on weekends",
      "Your mood improves after exercise",
      "Mondays are typically more challenging"
    ]
  },
  "summary": "Overall, your mood has been improving over the past month...",
  "recommendations": [
    "Continue activities that boost your mood on weekends",
    "Consider morning routines to improve Monday mood"
  ]
}
```

---

## Mood Tracker Implementation Notes

### Available Mood Values
- `"Very Happy"` (value: 5)
- `"Happy"` (value: 4)
- `"Neutral"` (value: 3)
- `"Sad"` (value: 2)
- `"Very Sad"` (value: 1)

### Current App Implementation

The Flutter app already has:
- ✅ `MoodApiService.getEntriesForAnalysis()` - Calls endpoint #5
- ✅ `MoodApiService.analyzeEntry()` - Calls endpoint #6
- ✅ `MoodApiService.analyzeMoodTrends()` - Calls endpoint #7
- ✅ `AiAnalysisService.analyzeMoodEntry()` - Uses endpoint #6
- ✅ `AiAnalysisService.analyzeMoodTrends()` - Uses endpoint #7

**The mood tracker is ready to use these endpoints once they're implemented on the backend!**

