import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood_entry.dart';
import '../utils/api_exceptions.dart';

/// Service for mood Firestore operations.
/// Handles all backend communication for mood entries using Firebase Firestore.
class MoodApiService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MoodApiService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get the current user ID, throwing an error if not authenticated
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    print('MoodApiService._getCurrentUserId: Current user = ${user?.uid ?? "NULL"}');
    if (user == null) {
      print('MoodApiService._getCurrentUserId: ERROR - User is not authenticated');
      throw UnauthorizedException('User must be authenticated to save mood entries');
    }
    return user.uid;
  }

  /// Get the mood entries collection reference for the current user
  CollectionReference _getMoodCollection() {
    final userId = _getCurrentUserId();
    return _firestore.collection('users').doc(userId).collection('mood_entries');
  }

  /// Save a mood entry to Firestore
  Future<void> saveEntry(MoodEntry entry) async {
    try {
      final userId = _getCurrentUserId();
      print('MoodApiService.saveEntry: Attempting to save entry ${entry.id} for user $userId');
      final collection = _getMoodCollection();
      print('MoodApiService.saveEntry: Collection path = users/$userId/mood_entries');
      final entryData = entry.toJson();
      
      // Add userId and serverTimestamp for tracking
      entryData['userId'] = userId;
      entryData['createdAt'] = FieldValue.serverTimestamp();
      entryData['updatedAt'] = FieldValue.serverTimestamp();
      
      print('MoodApiService.saveEntry: Writing to Firestore document: ${entry.id}');
      await collection.doc(entry.id).set(entryData, SetOptions(merge: true));
      print('MoodApiService: Entry ${entry.id} saved to Firestore successfully');
    } catch (e) {
      print('MoodApiService: Error saving entry to Firestore: $e');
      if (e is FirebaseException) {
        print('MoodApiService: FirebaseException details - code: ${e.code}, message: ${e.message}');
        _handleFirestoreError(e);
      } else {
        print('MoodApiService: Non-Firebase exception: ${e.runtimeType}');
        throw ApiException('Failed to save mood entry: ${e.toString()}', 500);
      }
    }
  }

  /// Get all mood entries from Firestore for the current user
  Future<List<MoodEntry>> getEntries() async {
    try {
      final collection = _getMoodCollection();
      final snapshot = await collection
          .orderBy('timestamp', descending: true)
          .get();
      
      final entries = <MoodEntry>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Remove Firestore-specific fields before parsing
          data.remove('createdAt');
          data.remove('updatedAt');
          data.remove('userId');
          
          entries.add(MoodEntry.fromJson(data));
        } catch (e) {
          print('MoodApiService: Error parsing entry ${doc.id}: $e');
        }
      }
      
      print('MoodApiService: Retrieved ${entries.length} entries from Firestore');
      return entries;
    } catch (e) {
      print('MoodApiService: Error getting entries from Firestore: $e');
      if (e is FirebaseException) {
        _handleFirestoreError(e);
      }
      return [];
    }
  }

  /// Get a mood entry by date
  Future<MoodEntry?> getEntryByDate(DateTime date) async {
    try {
      final collection = _getMoodCollection();
      // Format date as YYYY-MM-DD for comparison
      final snapshot = await collection
          .where('date', isEqualTo: date.toIso8601String().split('T')[0])
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return null;
      }
      
      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      // Remove Firestore-specific fields
      data.remove('createdAt');
      data.remove('updatedAt');
      data.remove('userId');
      
      return MoodEntry.fromJson(data);
    } catch (e) {
      print('MoodApiService: Error getting entry by date from Firestore: $e');
      if (e is FirebaseException) {
        _handleFirestoreError(e);
      }
      return null;
    }
  }

  /// Get entries within a date range
  Future<List<MoodEntry>> getEntriesInRange(
      DateTime start, DateTime end) async {
    try {
      final collection = _getMoodCollection();
      // Use timestamp for range queries (more efficient than date string)
      final startTimestamp = start.toIso8601String();
      final endTimestamp = end.add(const Duration(days: 1)).toIso8601String(); // Include full end day
      
      final snapshot = await collection
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .where('timestamp', isLessThanOrEqualTo: endTimestamp)
          .orderBy('timestamp', descending: true)
          .get();
      
      final entries = <MoodEntry>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Remove Firestore-specific fields
          data.remove('createdAt');
          data.remove('updatedAt');
          data.remove('userId');
          
          entries.add(MoodEntry.fromJson(data));
        } catch (e) {
          print('MoodApiService: Error parsing entry ${doc.id}: $e');
        }
      }
      
      return entries;
    } catch (e) {
      print('MoodApiService: Error getting entries in range from Firestore: $e');
      if (e is FirebaseException) {
        _handleFirestoreError(e);
      }
      return [];
    }
  }

  /// Delete a mood entry from Firestore
  Future<void> deleteEntry(String id) async {
    try {
      final collection = _getMoodCollection();
      await collection.doc(id).delete();
      print('MoodApiService: Entry $id deleted from Firestore');
    } catch (e) {
      print('MoodApiService: Error deleting entry from Firestore: $e');
      if (e is FirebaseException) {
        _handleFirestoreError(e);
      } else {
        throw ApiException('Failed to delete mood entry: ${e.toString()}', 500);
      }
    }
  }

  /// Get mood entries for AI analysis
  /// This method is specifically designed for AI bots to fetch and analyze mood data
  /// Returns entries with all necessary data for analysis (mood, timestamps)
  Future<List<MoodEntry>> getEntriesForAnalysis({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      CollectionReference collection;
      
      // If userId is provided, use that user's collection (for AI bot access)
      // Otherwise, use current user's collection
      if (userId != null) {
        collection = _firestore
            .collection('users')
            .doc(userId)
            .collection('mood_entries');
      } else {
        collection = _getMoodCollection();
      }
      
      Query query = collection.orderBy('timestamp', descending: true);
      
      if (startDate != null && endDate != null) {
        // Firestore requires composite index for multiple range queries
        // Use timestamp for range queries
        query = query
            .where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String())
            .where('timestamp', isLessThanOrEqualTo: endDate.add(const Duration(days: 1)).toIso8601String());
      } else if (startDate != null) {
        query = query.where('timestamp', 
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      } else if (endDate != null) {
        query = query.where('timestamp', 
            isLessThanOrEqualTo: endDate.add(const Duration(days: 1)).toIso8601String());
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get();
      
      final entries = <MoodEntry>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Remove Firestore-specific fields
          data.remove('createdAt');
          data.remove('updatedAt');
          data.remove('userId');
          
          entries.add(MoodEntry.fromJson(data));
        } catch (e) {
          print('MoodApiService: Error parsing entry ${doc.id} for analysis: $e');
        }
      }
      
      print('MoodApiService: Retrieved ${entries.length} entries for AI analysis');
      return entries;
    } catch (e) {
      print('MoodApiService: Error getting entries for analysis: $e');
      if (e is FirebaseException) {
        _handleFirestoreError(e);
      }
      return [];
    }
  }

  /// Analyze a single mood entry
  /// Sends the entry to the AI bot and returns insights
  /// Note: This would typically call a Cloud Function or external API
  /// For now, this is a placeholder that returns the entry data
  Future<Map<String, dynamic>> analyzeEntry(String entryId) async {
    try {
      final collection = _getMoodCollection();
      final doc = await collection.doc(entryId).get();
      
      if (!doc.exists) {
        throw NotFoundException('Mood entry not found');
      }
      
      final data = doc.data() as Map<String, dynamic>;
      // Remove Firestore-specific fields
      data.remove('createdAt');
      data.remove('updatedAt');
      data.remove('userId');
      
      // Return entry data for analysis
      // In a real implementation, this would call an AI service/Cloud Function
      return {
        'entry': data,
        'status': 'ready_for_analysis',
        'message': 'Entry retrieved successfully. AI analysis can be performed on this data.',
      };
    } catch (e) {
      print('MoodApiService: Error analyzing entry: $e');
      if (e is FirebaseException) {
        _handleFirestoreError(e);
        throw ApiException('Failed to analyze mood entry: ${e.message ?? e.code}', 500);
      } else if (e is NotFoundException || e is ApiException) {
        rethrow;
      } else {
        throw ApiException('Failed to analyze mood entry: ${e.toString()}', 500);
      }
    }
  }

  /// Get AI analysis for mood trends
  /// Analyzes patterns across multiple mood entries over time
  Future<Map<String, dynamic>> analyzeMoodTrends({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final entries = await getEntriesForAnalysis(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Basic trend analysis
      // In a real implementation, this would call an AI service/Cloud Function
      if (entries.isEmpty) {
        return {
          'status': 'no_data',
          'message': 'No mood entries found for the specified period.',
        };
      }
      
      // Calculate average mood value
      final avgMood = entries.map((e) => e.moodValue).reduce((a, b) => a + b) / entries.length;
      
      return {
        'status': 'success',
        'totalEntries': entries.length,
        'averageMood': avgMood,
        'entries': entries.map((e) => e.toJson()).toList(),
        'message': 'Mood trends calculated successfully.',
      };
    } catch (e) {
      print('MoodApiService: Error analyzing mood trends: $e');
      if (e is FirebaseException) {
        _handleFirestoreError(e);
        throw ApiException('Failed to analyze mood trends: ${e.message ?? e.code}', 500);
      } else if (e is ApiException) {
        rethrow;
      } else {
        throw ApiException('Failed to analyze mood trends: ${e.toString()}', 500);
      }
    }
  }

  /// Handle Firestore errors and convert to custom exceptions
  void _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        throw UnauthorizedException('Permission denied. Please check your authentication.');
      case 'unauthenticated':
        throw UnauthorizedException('User must be authenticated to access mood entries');
      case 'not-found':
        throw NotFoundException('Mood entry not found');
      case 'unavailable':
        throw NetworkException();
      case 'deadline-exceeded':
        throw NetworkException();
      case 'resource-exhausted':
        throw ServerException('Service temporarily unavailable. Please try again later.');
      case 'internal':
        throw ServerException('Internal server error. Please try again later.');
      case 'unimplemented':
        throw ServerException('Feature not implemented.');
      default:
        throw ApiException('Firestore error: ${e.message ?? e.code}', 500);
    }
  }
}
