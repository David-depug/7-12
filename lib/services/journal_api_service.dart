import 'package:dio/dio.dart';
import '../models/journal_entry.dart';
import '../utils/api_exceptions.dart';
import '../config.dart';

/// Service for journal API operations.
/// Handles all backend communication for journal entries.
class JournalApiService {
  final Dio _dio;

  JournalApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: API_BASE_URL,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
              ),
            );

  /// Save a journal entry to the backend
  Future<void> saveEntry(JournalEntry entry) async {
    try {
      await _dio.post(
        '/journal/entries',
        data: entry.toJson(),
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Get all journal entries from backend
  Future<List<JournalEntry>> getEntries() async {
    try {
      final response = await _dio.get('/journal/entries');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      _handleDioError(e);
      return [];
    }
  }

  /// Get a journal entry by date
  Future<JournalEntry?> getEntryByDate(DateTime date) async {
    try {
      final response = await _dio.get(
        '/journal/entries',
        queryParameters: {
          'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
        },
      );
      if (response.data != null) {
        return JournalEntry.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Not found is not an error
      }
      _handleDioError(e);
      return null;
    }
  }

  /// Get entries within a date range
  Future<List<JournalEntry>> getEntriesInRange(
      DateTime start, DateTime end) async {
    try {
      final response = await _dio.get(
        '/journal/entries',
        queryParameters: {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      _handleDioError(e);
      return [];
    }
  }

  /// Delete a journal entry
  Future<void> deleteEntry(String id) async {
    try {
      await _dio.delete('/journal/entries/$id');
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Handle Dio errors and convert to custom exceptions
  void _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw NetworkException();
    }

    if (e.response != null) {
      final statusCode = e.response!.statusCode ?? 0;
      final message = e.response!.data?['message'] ?? e.message ?? 'API error';

      switch (statusCode) {
        case 401:
          throw UnauthorizedException(message);
        case 404:
          throw NotFoundException(message);
        case 500:
        case 502:
        case 503:
          throw ServerException(message);
        default:
          throw ApiException(message, statusCode);
      }
    }

    throw NetworkException();
  }
}

