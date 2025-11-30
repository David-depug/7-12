import 'package:flutter/services.dart';

class TamperCheck {
  static const _channel = MethodChannel('app_info_channel');
  final String expectedPackage = 'com.example.flutter_my_app_main';
  final String expectedVersion = '1.0.0';

  Future<bool> isTampered() async {
    try {
      final info = await _channel.invokeMethod<Map>('getPackageInfo');
      if (info == null) return true;
      final pkg = info['packageName'];
      final ver = info['versionName'];
      return pkg != expectedPackage || ver != expectedVersion;
    } catch (e) {
      return true;
    }
  }
}
