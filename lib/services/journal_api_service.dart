import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';
import '../utils/api_exceptions.dart';

/// Service for journal Firestore operations.
/// Handles all backend communication for journal entries using Firebase Firestore.
class JournalApiService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  JournalApiService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get the current user ID, throwing an error if not authenticated
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    print('JournalApiService._getCurrentUserId: Current user = ${user?.uid ?? "NULL"}');
    if (user == null) {
      print('JournalApiService._getCurrentUserId: ERROR - User is not authenticated');
      throw UnauthorizedException('User must be authenticated to save journal entries');
    }
    return user.uid;
  }

  /// Get the journal entries collection reference for the current user
  CollectionReference _getJournalCollection() {
    final userId = _getCurrentUserId();
    return _firestore.collection('users').doc(userId).collection('journal_entries');
  }

  /// Save a journal entry to Firestore
  Future<void> saveEntry(JournalEntry entry) async {
    try {
      final userId = _getCurrentUserId();
      print('JournalApiService.saveEntry: Attempting to save entry ${entry.id} for user $userId');
      final collection = _getJournalCollection();
      print('JournalApiService.saveEntry: Collection path = users/$userId/journal_entries');
      final entryData = entry.toJson();
      
      // Add userId and serverTimestamp for tracking
      entryData['userId'] = userId;
      entryData['createdAt'] = FieldValue.serverTimestamp();
      entryData['updatedAt'] = FieldValue.serverTimestamp();
      
      print('JournalApiService.saveEntry: Writing to Firestore document: ${entry.id}');
      await collection.doc(entry.id).set(entryData, SetOptions(merge: true));
      print('JournalApiService: Entry ${entry.id} saved to Firestore successfully');
    } catch (e) {
      print('JournalApiService: Error saving entry to Firestore: $e');
      if (e is FirebaseException) {
        print('JournalApiService: FirebaseException details - code: ${e.code}, message: ${e.message}');
        _handleFirestoreError(e);
      } else {
        print('JournalApiService: Non-Firebase exception: ${e.runtimeType}');
        throw ApiException('Failed to save journal entry: ${e.toString()}', 500);
      }
    }
  }

  /// Get all journal entries from Firestore for the current user
  Future<List<JournalEntry>> getEntries() async {
    try {
      final collection = _getJournalCollection();
      final snapshot = await collection
          .orderBy('timestamp', descending: true)
          .get();
      
      final entries = <JournalEntry>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Remove Firestore-specific fields before parsing
          data.remove('createdAt');
          data.remove('updatedAt');
          data.remove('userId');
          
          entries.add(JournalEntry.fromJson(data));
        } catch (e) {
          print('JournalApiService: Error parsing entry ${doc.id}: $e');
        }
      }
      
      print('JournalApiService: Retrieved ${entries.length} entries from Firestore');
      return entries;
    } catch (e) {
      print('JournalApiService: Error getting entries from Firestore: $e');
      if (e is FirebaseException) {
        _handleFirestoreError(e);
      }
      return [];
    }
  }

  /// Get a journal entry by date
  Future<JournalEntry?> getEntryByDate(DateTime date) async {
    try {
      final collection = _getJournalCollection();
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
      
      return JournalEntry.fromJson(data);
    } catch (e) {
      print('JournalApiService: Error getting entry by date from Firestore: $e');
      if (e is FirebaseException) {
        _handleFirestoreError(e);
      }
      return null;
    }
  }

  /// Get entries within a date range
  Future<List<JournalEntry>> getEntriesInRange(
      DateTime start, DateTime end) async {
    try {
      final collection = _getJournalCollection();
      // Use timestamp for range queries (more efficient than date string)
      final startTimestamp = start.toIso8601String();
      final endTimestamp = end.add(const Duration(days: 1)).toIso8601String(); // Include full end day
      
      final snapshot = await collection
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .where('timestamp', isLessThanOrEqualTo: endTimestamp)
          .orderBy('timestamp', descending: true)
          .get();
      
      final entries = <JournalEntry>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Remove Firestore-specific fields
          data.remove('createdAt');
          data.remove('updatedAt');
          data.remove('userId');
          
          entries.add(JournalEntry.fromJson(data));
        } catch (e) {
          print('JournalApiService: Error parsing entry ${doc.id}: $e');
        }
      }
      
      return entries;
    } catch (e) {
      print('JournalApiService: Error getting entries in range from Firestore: $e');
      if (e is FirebaseException) {
        _handleFirestoreError(e);
      }
      return [];
    }
  }

  /// Delete a journal entry from Firestore
  Future<void> deleteEntry(String id) async {
    try {
      final collection = _getJournalCollection();
      await collection.doc(id).delete();
      print('JournalApiService: Entry $id deleted from Firestore');
    } catch (e) {
      print('JournalApiService: Error deleting entry from Firestore: $e');
      if (e is FirebaseException) {
        _handleFirestoreError(e);
      } else {
        throw ApiException('Failed to delete journal entry: ${e.toString()}', 500);
      }
    }
  }

  /// Get journal entries for AI analysis
  /// This method is specifically designed for AI bots to fetch and analyze journal data
  /// Returns entries with all necessary data for analysis (answers, mood, timestamps)
  Future<List<JournalEntry>> getEntriesForAnalysis({
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
            .collection('journal_entries');
      } else {
        collection = _getJournalCollection();
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
      
      final entries = <JournalEntry>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Remove Firestore-specific fields
          data.remove('createdAt');
          data.remove('updatedAt');
          data.remove('userId');
          
          entries.add(JournalEntry.fromJson(data));
        } catch (e) {
          print('JournalApiService: Error parsing entry ${doc.id} for analysis: $e');
        }
      }
      
      print('JournalApiService: Retrieved ${entries.length} entries for AI analysis');
      return entries;
    } catch (e) {
      print('JournalApiService: Error getting entries for analysis: $e');
      if (e is FirebaseException) {
        _handleFirestoreError(e);
      }
      return [];
    }
  }

  /// Send journal entry to AI bot for analysis and get insights
  /// This endpoint sends a single entry to the AI bot and returns analysis results
  /// Note: This would typically call a Cloud Function or external API
  /// For now, this is a placeholder that returns the entry data
  Future<Map<String, dynamic>> analyzeEntry(String entryId) async {
    try {
      final collection = _getJournalCollection();
      final doc = await collection.doc(entryId).get();
      
      if (!doc.exists) {
        throw NotFoundException('Journal entry not found');
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
      print('JournalApiService: Error analyzing entry: $e');
      if (e is FirebaseException) {
        _handleFirestoreError(e);
        throw ApiException('Failed to analyze journal entry: ${e.message ?? e.code}', 500);
      } else if (e is NotFoundException || e is ApiException) {
        rethrow;
      } else {
        throw ApiException('Failed to analyze journal entry: ${e.toString()}', 500);
      }
    }
  }

  /// Handle Firestore errors and convert to custom exceptions
  void _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        throw UnauthorizedException('Permission denied. Please check your authentication.');
      case 'unauthenticated':
        throw UnauthorizedException('User must be authenticated to access journal entries');
      case 'not-found':
        throw NotFoundException('Journal entry not found');
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
