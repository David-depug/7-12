import 'package:dio/dio.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';
import '../utils/api_exceptions.dart';
import '../config.dart';

/// Service for AI-powered analysis.
/// Connects to backend AI bot endpoint to analyze journal entries and mood data.
class AiAnalysisService {
  final Dio _dio;

  AiAnalysisService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: API_BASE_URL,
                connectTimeout: const Duration(seconds: 60), // Longer timeout for AI processing
                receiveTimeout: const Duration(seconds: 60),
              ),
            );

  /// Analyze a single journal entry
  /// Sends the entry to the AI bot and returns insights
  Future<String> analyzeJournalEntry(JournalEntry entry) async {
    try {
      final response = await _dio.post(
        '/journal/entries/${entry.id}/analyze',
        data: entry.toJson(),
      );

      // Extract analysis result from response
      final analysisData = response.data as Map<String, dynamic>;
      return analysisData['analysis'] as String? ??
          analysisData['insights'] as String? ??
          'Analysis completed successfully.';
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// Analyze a single journal entry by combining all answers into text
  /// This is useful when you have the entry data but want to send it as text
  Future<String> analyzeJournalText(String journalText) async {
    try {
      final response = await _dio.post(
        '/journal/analyze',
        data: {'text': journalText},
      );

      final analysisData = response.data as Map<String, dynamic>;
      return analysisData['analysis'] as String? ??
          analysisData['insights'] as String? ??
          'Analysis completed successfully.';
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// Get AI analysis for multiple entries (trend analysis)
  /// Useful for analyzing patterns across multiple journal entries
  Future<Map<String, dynamic>> analyzeMultipleEntries({
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
        '/journal/entries/analysis/trends',
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
      final message = e.response!.data?['message'] ?? e.message ?? 'AI analysis error';

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

  // ========== MOOD ANALYSIS METHODS ==========

  /// Analyze a single mood entry
  /// Sends the mood entry to the AI bot and returns insights
  Future<String> analyzeMoodEntry(MoodEntry entry) async {
    try {
      final response = await _dio.post(
        '/mood/entries/${entry.id}/analyze',
        data: entry.toJson(),
      );

      final analysisData = response.data as Map<String, dynamic>;
      return analysisData['analysis'] as String? ??
          analysisData['insights'] as String? ??
          'Analysis completed successfully.';
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// Get AI analysis for mood trends
  /// Useful for analyzing patterns across multiple mood entries
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
}

