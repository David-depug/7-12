import 'package:dio/dio.dart';
import '../models/mood_entry.dart';
import '../utils/api_exceptions.dart';
import '../config.dart';

/// Service for mood API operations.
/// Handles all backend communication for mood entries.
class MoodApiService {
  final Dio _dio;

  MoodApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: API_BASE_URL,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
              ),
            );

  /// Save a mood entry to the backend
  Future<void> saveEntry(MoodEntry entry) async {
    try {
      await _dio.post(
        '/mood/entries',
        data: entry.toJson(),
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Get all mood entries from backend
  Future<List<MoodEntry>> getEntries() async {
    try {
      final response = await _dio.get('/mood/entries');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => MoodEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      _handleDioError(e);
      return [];
    }
  }

  /// Get a mood entry by date
  Future<MoodEntry?> getEntryByDate(DateTime date) async {
    try {
      final response = await _dio.get(
        '/mood/entries',
        queryParameters: {
          'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
        },
      );
      if (response.data != null) {
        return MoodEntry.fromJson(response.data as Map<String, dynamic>);
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
  Future<List<MoodEntry>> getEntriesInRange(
      DateTime start, DateTime end) async {
    try {
      final response = await _dio.get(
        '/mood/entries',
        queryParameters: {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => MoodEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      _handleDioError(e);
      return [];
    }
  }

  /// Delete a mood entry
  Future<void> deleteEntry(String id) async {
    try {
      await _dio.delete('/mood/entries/$id');
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Get mood entries for AI analysis
  Future<List<MoodEntry>> getEntriesForAnalysis({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) queryParams['userId'] = userId;
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (limit != null) queryParams['limit'] = limit;

      final response = await _dio.get(
        '/mood/entries/analysis',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.data is List) {
        return (response.data as List)
            .map((e) => MoodEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      _handleDioError(e);
      return [];
    }
  }

  /// Analyze a single mood entry
  /// Sends the entry to the AI bot and returns insights
  Future<Map<String, dynamic>> analyzeEntry(String entryId) async {
    try {
      final response = await _dio.post(
        '/mood/entries/$entryId/analyze',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
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
      final queryParams = <String, dynamic>{};
      if (userId != null) queryParams['userId'] = userId;
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await _dio.get(
        '/mood/entries/analysis/trends',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
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

