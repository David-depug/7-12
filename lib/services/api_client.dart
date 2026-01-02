import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// API Client service for making HTTP requests to backend.
/// Automatically adds Firebase authentication tokens to requests.
class ApiClient {
  static Dio? _dio;
  static String? _baseUrl;

  /// Initialize the API client with base URL
  static void initialize({required String baseUrl}) {
    _baseUrl = baseUrl;
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Setup interceptors for authentication
    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add Firebase token to all requests
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          print('Error getting Firebase token: $e');
          // Continue without token - backend will handle auth errors
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle common errors
        if (error.response != null) {
          print('API Error: ${error.response?.statusCode} - ${error.response?.data}');
        } else {
          print('Network Error: ${error.message}');
        }
        return handler.next(error);
      },
    ));
  }

  /// Get the Dio instance (throws if not initialized)
  static Dio get instance {
    if (_dio == null) {
      throw Exception('ApiClient not initialized. Call ApiClient.initialize() first.');
    }
    return _dio!;
  }

  /// Get base URL
  static String? get baseUrl => _baseUrl;

  /// Check if client is initialized
  static bool get isInitialized => _dio != null;
}

