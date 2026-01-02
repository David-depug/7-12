import 'package:flutter/foundation.dart';
import 'mood_entry.dart';
import '../services/mood_service.dart';
import '../utils/api_exceptions.dart';

/// Mood model using ChangeNotifier pattern (matching MindQuest project style).
/// Manages mood entries state and operations.
class MoodModel extends ChangeNotifier {
  final MoodService _service;

  List<MoodEntry> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSaving = false;
  MoodEntry? _todayEntry;

  MoodModel(this._service);

  // Getters
  List<MoodEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;
  bool get hasError => _errorMessage != null;
  MoodEntry? get todayEntry => _todayEntry;
  bool get hasTrackedToday => _todayEntry != null;

  /// Load all mood entries
  Future<void> loadEntries() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _entries = await _service.getEntries();
      _todayEntry = await _service.getTodayEntry();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      print('Error loading entries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save a new mood entry
  Future<bool> saveEntry(MoodEntry entry) async {
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

  /// Check if user can track mood today (once per 24 hours)
  Future<bool> canTrackToday() async {
    try {
      final hasTracked = await _service.hasTrackedToday();
      return !hasTracked;
    } catch (e) {
      print('Error checking if can track today: $e');
      return true; // Allow tracking on error
    }
  }

  /// Get entry for a specific date
  Future<MoodEntry?> getEntryByDate(DateTime date) async {
    try {
      return await _service.getEntryByDate(date);
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  /// Delete a mood entry
  Future<bool> deleteEntry(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteEntry(id);
      // Remove from local list immediately
      _entries.removeWhere((e) => e.id == id);
      if (_todayEntry?.id == id) {
        _todayEntry = null;
      }
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
  Future<List<MoodEntry>> getEntriesInRange(
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

