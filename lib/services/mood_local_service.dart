import 'package:hive/hive.dart';
import '../models/mood_entry.dart';

/// Service for local mood storage using Hive.
/// Provides offline-first storage for mood entries.
class MoodLocalService {
  static const String _boxName = 'mood_entries_box';
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

  /// Initialize the Hive box for mood entries
  Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
      print('MoodLocalService: Box opened successfully. Current entries: ${_box!.length}');
      if (_box != null) {
        print('MoodLocalService: Box is ready. Keys: ${_box!.keys.toList()}');
      }
    } catch (e) {
      print('MoodLocalService: Error opening box: $e');
      rethrow;
    }
  }

  Box get box {
    if (_box == null) {
      throw Exception('MoodLocalService not initialized. Call init() first.');
    }
    if (!_box!.isOpen) {
      throw Exception('Hive box is not open. Please reinitialize the service.');
    }
    return _box!;
  }

  /// Check if the service is initialized
  bool get isInitialized => _box != null && _box!.isOpen;

  /// Save a mood entry locally
  Future<void> saveEntry(MoodEntry entry) async {
    try {
      final jsonData = entry.toJson();
      print('MoodLocalService: Saving entry ${entry.id} with data: $jsonData');
      await box.put(entry.id, jsonData);
      await box.flush(); // Ensure data is persisted to disk
      print('MoodLocalService: Entry saved successfully. Box now has ${box.length} entries');
    } catch (e) {
      print('MoodLocalService: Error saving entry: $e');
      rethrow;
    }
  }

  /// Get all mood entries from local storage
  Future<List<MoodEntry>> getEntries() async {
    final entries = <MoodEntry>[];
    print('Loading mood entries from Hive box (${box.length} keys found)');
    for (var key in box.keys) {
      final data = box.get(key);
      if (data is Map) {
        try {
          final convertedData = _convertMap(data);
          entries.add(MoodEntry.fromJson(convertedData));
        } catch (e) {
          print('Error parsing mood entry $key: $e');
          continue;
        }
      }
    }
    // Sort by timestamp, newest first
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    print('Loaded ${entries.length} mood entries from local storage');
    return entries;
  }

  /// Get mood entry for a specific date
  Future<MoodEntry?> getEntryByDate(DateTime date) async {
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

  /// Check if user has already tracked mood today
  Future<bool> hasTrackedToday() async {
    final today = DateTime.now();
    final entry = await getEntryByDate(today);
    return entry != null;
  }

  /// Get the last mood entry
  Future<MoodEntry?> getLastEntry() async {
    final entries = await getEntries();
    return entries.isNotEmpty ? entries.first : null;
  }

  /// Delete a mood entry
  Future<void> deleteEntry(String id) async {
    await box.delete(id);
  }

  /// Get entries within a date range
  Future<List<MoodEntry>> getEntriesInRange(
      DateTime start, DateTime end) async {
    final entries = await getEntries();
    return entries
        .where((entry) =>
            entry.date.isAfter(start.subtract(const Duration(days: 1))) &&
            entry.date.isBefore(end.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}

