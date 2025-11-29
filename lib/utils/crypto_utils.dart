// lib/utils/crypto_utils.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

String generateSalt([int length = 16]) {
  final rand = Random.secure();
  final bytes = List<int>.generate(length, (_) => rand.nextInt(256));
  return base64UrlEncode(bytes);
}

// PBKDF2 implementation using HMAC-SHA256 (pure Dart implementation)
Uint8List _u32ToBytes(int i) {
  final b = BytesBuilder();
  b.addByte((i >> 24) & 0xff);
  b.addByte((i >> 16) & 0xff);
  b.addByte((i >> 8) & 0xff);
  b.addByte(i & 0xff);
  return Uint8List.fromList(b.toBytes());
}

List<int> _hmacSha256(List<int> key, List<int> data) {
  final hmac = Hmac(sha256, key);
  final digest = hmac.convert(data);
  return digest.bytes;
}

String pbkdf2(String password, String saltBase64,
    {int iterations = 100000, int dkLen = 32, String pepper = ''}) {
  final salt = base64Url.decode(saltBase64);
  final passBytes = utf8.encode(password + pepper);

  final blocks = (dkLen / 32).ceil();
  final out = <int>[];

  for (var i = 1; i <= blocks; i++) {
    // U1 = HMAC(P, S || INT(i))
    final blockData = <int>[]..addAll(salt)..addAll(_u32ToBytes(i));
    var u = _hmacSha256(passBytes, blockData);
    final t = List<int>.from(u);

    for (var j = 1; j < iterations; j++) {
      u = _hmacSha256(passBytes, u);
      for (var k = 0; k < t.length; k++) t[k] ^= u[k];
    }
    out.addAll(t);
  }

  final derived = out.sublist(0, dkLen);
  return base64UrlEncode(derived);
}

bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff == 0;
}

bool verifyPassword(String password, String saltBase64, String storedHashBase64, {int iterations = 100000, int dkLen = 32, String pepper = ''}) {
  final computed = pbkdf2(password, saltBase64, iterations: iterations, dkLen: dkLen, pepper: pepper);
  final a = base64Url.decode(computed);
  final b = base64Url.decode(storedHashBase64);
  return constantTimeEquals(a, b);
}

// OTP generator (6 digits)
String generateOtp([int length = 6]) {
  final rand = Random.secure();
  String s = '';
  for (var i = 0; i < length; i++) s += rand.nextInt(10).toString();
  return s;
}




