import 'package:flutter/foundation.dart';
import 'journal_entry.dart';
import '../services/journal_service.dart';
import '../utils/api_exceptions.dart';

/// Journal model using ChangeNotifier pattern (matching MindQuest project style).
/// Manages journal entries state and operations.
class JournalModel extends ChangeNotifier {
  final JournalService _service;

  List<JournalEntry> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSaving = false;

  JournalModel(this._service);

  // Getters
  List<JournalEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;
  bool get hasError => _errorMessage != null;

  /// Load all journal entries
  Future<void> loadEntries() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _entries = await _service.getEntries();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      print('Error loading entries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save a new journal entry
  Future<bool> saveEntry(JournalEntry entry) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.saveEntry(entry);
      // Reload entries to get updated list
      await loadEntries();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      print('Error saving entry: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Get entry for a specific date
  Future<JournalEntry?> getEntryByDate(DateTime date) async {
    try {
      return await _service.getEntryByDate(date);
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  /// Delete a journal entry
  Future<bool> deleteEntry(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteEntry(id);
      // Remove from local list immediately
      _entries.removeWhere((e) => e.id == id);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      print('Error deleting entry: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get entries within a date range
  Future<List<JournalEntry>> getEntriesInRange(
      DateTime start, DateTime end) async {
    try {
      return await _service.getEntriesInRange(start, end);
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return [];
    }
  }

  /// Refresh entries from backend
  Future<void> refresh() async {
    await loadEntries();
  }

  /// Sync pending entries to backend
  Future<void> syncPendingEntries() async {
    try {
      await _service.syncPendingEntries();
      // Reload entries after sync
      await loadEntries();
    } catch (e) {
      print('Error syncing pending entries: $e');
    }
  }

  /// Get count of pending sync operations
  int getPendingSyncCount() {
    return _service.getPendingSyncCount();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Convert exception to user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    } else if (error is NetworkException) {
      return 'Network error. Please check your internet connection.';
    } else if (error is UnauthorizedException) {
      return 'Authentication failed. Please log in again.';
    } else {
      return error.toString();
    }
  }
}

