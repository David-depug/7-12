import '../models/mood_entry.dart';
import '../utils/api_exceptions.dart';
import 'mood_api_service.dart';
import 'mood_local_service.dart';

/// Offline-first mood service combining local Hive storage with optional API sync.
class MoodService {
  final MoodLocalService localService;
  final MoodApiService apiService;

  MoodService({
    required this.localService,
    required this.apiService,
  });

  Future<void> saveEntry(MoodEntry entry) async {
    // Save locally first for offline support.
    await localService.saveEntry(entry);
    // Best-effort sync to backend.
    try {
      await apiService.saveEntry(entry);
    } catch (e) {
      // Log and keep local; sync can retry later.
      print('MoodService.saveEntry backend error: $e');
    }
  }

  Future<List<MoodEntry>> getEntries() async {
    // Offline-first: always load local entries first
    final localEntries = await localService.getEntries();
    print('MoodService.getEntries: Found ${localEntries.length} local entries');

    // Try to sync from remote in background, but don't block on it
    try {
      final remoteEntries = await apiService.getEntries();
      if (remoteEntries.isNotEmpty) {
        print('MoodService.getEntries: Found ${remoteEntries.length} remote entries, merging...');
        // Merge: prefer local, but add any new remote entries
        final localIds = localEntries.map((e) => e.id).toSet();
        final newRemoteEntries =
            remoteEntries.where((e) => !localIds.contains(e.id)).toList();
        if (newRemoteEntries.isNotEmpty) {
          // Save new remote entries locally
          for (final entry in newRemoteEntries) {
            await localService.saveEntry(entry);
          }
          return [...localEntries, ...newRemoteEntries];
        }
      }
    } catch (e) {
      print('MoodService.getEntries backend error (using local only): $e');
    }
    return localEntries;
  }

  Future<MoodEntry?> getEntryByDate(DateTime date) async {
    final local = await localService.getEntryByDate(date);
    if (local != null) return local;
    try {
      return await apiService.getEntryByDate(date);
    } catch (e) {
      print('MoodService.getEntryByDate backend error: $e');
      return local;
    }
  }

  /// Check if user has already tracked mood today
  Future<bool> hasTrackedToday() async {
    return await localService.hasTrackedToday();
  }

  /// Get today's mood entry
  Future<MoodEntry?> getTodayEntry() async {
    final today = DateTime.now();
    return await getEntryByDate(today);
  }

  Future<void> deleteEntry(String id) async {
    await localService.deleteEntry(id);
    try {
      await apiService.deleteEntry(id);
    } catch (e) {
      print('MoodService.deleteEntry backend error: $e');
    }
  }

  Future<List<MoodEntry>> getEntriesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final local = await localService.getEntriesInRange(start, end);
    try {
      final remote = await apiService.getEntriesInRange(start, end);
      if (remote.isNotEmpty) return remote;
    } catch (e) {
      print('MoodService.getEntriesInRange backend error: $e');
    }
    return local;
  }

  /// Attempt to sync any locally stored entries to the backend.
  Future<void> syncPendingEntries() async {
    try {
      final entries = await localService.getEntries();
      for (final entry in entries) {
        await apiService.saveEntry(entry);
      }
    } on ApiException catch (e) {
      print('MoodService.syncPendingEntries api error: $e');
      rethrow;
    } catch (e) {
      print('MoodService.syncPendingEntries error: $e');
      rethrow;
    }
  }
}

