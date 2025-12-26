import 'package:hive/hive.dart';
import 'dart:convert';
import '../models/journal_entry.dart';

/// Service for local journal storage using Hive.
/// Provides offline-first storage for journal entries.
class JournalLocalService {
  static const String _boxName = 'journal_entries_box';
  Box? _box;
  
  /// Convert Map<dynamic, dynamic> to Map<String, dynamic> recursively
  static Map<String, dynamic> _convertMap(Map map) {
    return Map<String, dynamic>.from(
      map.map((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), _convertMap(value));
        } else if (value is List) {
          return MapEntry(key.toString(), _convertList(value));
        } else {
          return MapEntry(key.toString(), value);
        }
      }),
    );
  }
  
  /// Convert List<dynamic> to List<dynamic> with proper map conversion
  static List _convertList(List list) {
    return list.map((item) {
      if (item is Map) {
        return _convertMap(item);
      } else if (item is List) {
        return _convertList(item);
      }
      return item;
    }).toList();
  }

  /// Initialize the Hive box for journal entries
  Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
      print('JournalLocalService: Box opened successfully. Current entries: ${_box!.length}');
      // Verify box is accessible
      if (_box != null) {
        print('JournalLocalService: Box is ready. Keys: ${_box!.keys.toList()}');
        await verifyBoxIntegrity();
      }
    } catch (e) {
      print('JournalLocalService: Error opening box: $e');
      rethrow;
    }
  }

  Box get box {
    if (_box == null) {
      throw Exception('JournalLocalService not initialized. Call init() first.');
    }
    if (!_box!.isOpen) {
      throw Exception('Hive box is not open. Please reinitialize the service.');
    }
    return _box!;
  }
  
  /// Check if the service is initialized
  bool get isInitialized => _box != null && _box!.isOpen;

  /// Save a journal entry locally
  Future<void> saveEntry(JournalEntry entry) async {
    try {
      final jsonData = entry.toJson();
      print('JournalLocalService: Saving entry ${entry.id} with data: $jsonData');
      await box.put(entry.id, jsonData);
      await box.flush(); // Ensure data is persisted to disk
      print('JournalLocalService: Entry saved successfully. Box now has ${box.length} entries');
      
      // Verify it was saved by reading it back
      final saved = box.get(entry.id);
      if (saved != null) {
        print('JournalLocalService: Verified entry exists in box');
      } else {
        print('JournalLocalService: WARNING - Entry not found after save!');
      }
    } catch (e) {
      print('JournalLocalService: Error saving entry: $e');
      rethrow;
    }
  }

  /// Get all journal entries from local storage
  Future<List<JournalEntry>> getEntries() async {
    final entries = <JournalEntry>[];
    print('Loading journal entries from Hive box (${box.length} keys found)');
    for (var key in box.keys) {
      final data = box.get(key);
      if (data is Map) {
        try {
          // Convert Map<dynamic, dynamic> to Map<String, dynamic> recursively
          final convertedData = _convertMap(data);
          entries.add(JournalEntry.fromJson(convertedData));
        } catch (e) {
          print('Error parsing journal entry $key: $e');
          print('Entry data type: ${data.runtimeType}');
          continue;
        }
      } else {
        print('Warning: Entry $key is not a Map, type: ${data.runtimeType}');
      }
    }
    // Sort by timestamp, newest first (null-safe)
    entries.sort((a, b) {
      final bt = b.timestamp;
      final at = a.timestamp;
      return bt.compareTo(at);
    });
    print('Loaded ${entries.length} journal entries from local storage');
    return entries;
  }

  /// Get a journal entry by date
  Future<JournalEntry?> getEntryByDate(DateTime date) async {
    final entries = await getEntries();
    for (final entry in entries) {
      if (entry.date.year == date.year &&
          entry.date.month == date.month &&
          entry.date.day == date.day) {
        return entry;
      }
    }
    return null;
  }

  /// Delete a journal entry
  Future<void> deleteEntry(String id) async {
    await box.delete(id);
  }

  /// Get entries within a date range
  Future<List<JournalEntry>> getEntriesInRange(
      DateTime start, DateTime end) async {
    final entries = await getEntries();
    return entries
        .where((entry) =>
            entry.date.isAfter(start.subtract(const Duration(days: 1))) &&
            entry.date.isBefore(end.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  /// Verify box integrity and log current state
  Future<void> verifyBoxIntegrity() async {
    print('=== Journal Box Integrity Check ===');
    print('Box name: $_boxName');
    print('Box is open: ${_box?.isOpen ?? false}');
    print('Box length: ${_box?.length ?? 0}');
    print('Box keys: ${_box?.keys.toList() ?? []}');
    print('===============================');
  }
}

