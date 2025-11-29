import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // 🔒 حفظ بيانات
  static Future<void> saveData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // 🔑 قراءة بيانات
  static Future<String?> readData(String key) async {
    return await _storage.read(key: key);
  }

  // 🧹 حذف بيانات
  static Future<void> deleteData(String key) async {
    await _storage.delete(key: key);
  }

  // 🧨 حذف كل شيء
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}




