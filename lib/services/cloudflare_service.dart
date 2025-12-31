// lib/services/cloudflare_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudflareService {
  // Cloudflare Turnstile configuration
  static const String siteKey =
      '1x00000000000000000000AA'; // Replace with your actual site key
  static const String secretKey =
      '1x0000000000000000000000000000000AA'; // Replace with your actual secret key

  static Future<bool> verifyToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('https://challenges.cloudflare.com/turnstile/v0/siteverify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'secret': secretKey,
          'response': token,
          'remoteip': null, // Optional: IP address of the user
        }),
      );

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Cloudflare verification error: $e');
      return false;
    }
  }

  static String getSiteKey() {
    return siteKey;
  }
}
