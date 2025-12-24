import 'dart:convert';

import 'package:http/http.dart' as http;

/// Base URL for the UpHeal backend.
///
/// Platform-specific URLs:
/// - Android emulator: http://10.0.2.2:8000
/// - iOS simulator: http://localhost:8000
/// - Physical device: http://YOUR_COMPUTER_IP:8000
///
/// Current: Physical device using computer's local network IP
const String uphealBaseUrl = 'http://10.36.76.153:8000';

class UphealApi {
  final String baseUrl;

  const UphealApi({required this.baseUrl});

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// Simple health check against `{baseUrl}/health`.
  Future<Map<String, dynamic>> health() async {
    final response = await http.get(_uri('/health'));
    if (response.statusCode != 200) {
      throw Exception(
        'Health check failed (${response.statusCode}): ${response.body}',
      );
    }
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) {
      return body;
    }
    throw Exception('Unexpected health response shape: $body');
  }

  /// Call the assessment endpoint `{baseUrl}/api/assess`.
  ///
  /// Body:
  /// ```json
  /// {
  ///   "answers": { "gad7_q1": 0, ... },
  ///   "user_id": "user_123",
  ///   "session_id": "optional"
  /// }
  /// ```
  Future<Map<String, dynamic>> assess({
    required Map<String, int> answers,
    required String userId,
    String? sessionId,
  }) async {
    final uri = _uri('/api/assess');
    final payload = <String, dynamic>{
      'answers': answers,
      'user_id': userId,
    };
    if (sessionId != null) {
      payload['session_id'] = sessionId;
    }

    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Assess failed (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) {
      return body;
    }
    throw Exception('Unexpected assess response shape: $body');
  }
}


