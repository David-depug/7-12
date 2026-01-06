import '../models/journal_entry.dart';
import '../utils/api_exceptions.dart';
import 'journal_api_service.dart';
import 'journal_local_service.dart';

/// Offline-first journal service combining local Hive storage with optional API sync.
class JournalService {
  final JournalLocalService localService;
  final JournalApiService apiService;

  JournalService({
    required this.localService,
    required this.apiService,
  });

  Future<void> saveEntry(JournalEntry entry) async {
    // Save locally first for offline support.
    await localService.saveEntry(entry);
    // Best-effort sync to backend.
    try {
      await apiService.saveEntry(entry);
      print('JournalService.saveEntry: Successfully synced entry ${entry.id} to Firestore');
    } catch (e) {
      // Log and keep local; sync can retry later.
      print('JournalService.saveEntry backend error: $e');
      print('JournalService.saveEntry: Entry ${entry.id} saved locally but NOT synced to Firestore');
      // Enhanced error logging for debugging
      if (e is ApiException) {
        print('JournalService.saveEntry: ApiException - ${e.message} (status: ${e.statusCode})');
      }
    }
  }

  Future<List<JournalEntry>> getEntries() async {
    // Offline-first: always load local entries first
    final localEntries = await localService.getEntries();
    print('JournalService.getEntries: Found ${localEntries.length} local entries');
    
    // Try to sync from remote in background, but don't block on it
    try {
      final remoteEntries = await apiService.getEntries();
      if (remoteEntries.isNotEmpty) {
        print('JournalService.getEntries: Found ${remoteEntries.length} remote entries, merging...');
        // Merge: prefer local, but add any new remote entries
        final localIds = localEntries.map((e) => e.id).toSet();
        final newRemoteEntries = remoteEntries.where((e) => !localIds.contains(e.id)).toList();
        if (newRemoteEntries.isNotEmpty) {
          // Save new remote entries locally
          for (final entry in newRemoteEntries) {
            await localService.saveEntry(entry);
          }
          return [...localEntries, ...newRemoteEntries];
        }
      }
    } catch (e) {
      print('JournalService.getEntries backend error (using local only): $e');
    }
    return localEntries;
  }

  Future<JournalEntry?> getEntryByDate(DateTime date) async {
    final local = await localService.getEntryByDate(date);
    if (local != null) return local;
    try {
      return await apiService.getEntryByDate(date);
    } catch (e) {
      print('JournalService.getEntryByDate backend error: $e');
      return local;
    }
  }

  Future<void> deleteEntry(String id) async {
    await localService.deleteEntry(id);
    try {
      await apiService.deleteEntry(id);
    } catch (e) {
      print('JournalService.deleteEntry backend error: $e');
    }
  }

  Future<List<JournalEntry>> getEntriesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final local = await localService.getEntriesInRange(start, end);
    try {
      final remote = await apiService.getEntriesInRange(start, end);
      if (remote.isNotEmpty) return remote;
    } catch (e) {
      print('JournalService.getEntriesInRange backend error: $e');
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
      print('JournalService.syncPendingEntries api error: $e');
      rethrow;
    } catch (e) {
      print('JournalService.syncPendingEntries error: $e');
      rethrow;
    }
  }

  /// Placeholder for pending sync tracking.
  int getPendingSyncCount() {
    // In a full implementation, track unsynced entries separately.
    return 0;
  }
}

