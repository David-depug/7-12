import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// Service for handling step tracking permissions
/// Handles platform-specific permission requests
class StepPermissionService {
  /// Get the appropriate permission for the current platform
  Permission get _stepPermission {
    if (Platform.isAndroid) {
      // Android 10+ (API 29+) uses ACTIVITY_RECOGNITION
      // For older versions, we'll try activityRecognition first
      // and fall back if needed
      return Permission.activityRecognition;
    } else if (Platform.isIOS) {
      // iOS uses sensors permission (motion is not available in permission_handler)
      // We'll use activityRecognition as a fallback for iOS
      // Note: iOS step tracking may require HealthKit integration
      return Permission.activityRecognition;
    }
    // Fallback (shouldn't reach here)
    return Permission.activityRecognition;
  }

  /// Check if step tracking permission is granted
  Future<bool> hasPermission() async {
    try {
      return await _stepPermission.isGranted;
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }

  /// Request step tracking permission
  Future<bool> requestPermission() async {
    try {
      final status = await _stepPermission.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting permission: $e');
      return false;
    }
  }

  /// Check if permission can be requested (not permanently denied)
  Future<bool> canRequestPermission() async {
    try {
      final status = await _stepPermission.status;
      return !status.isPermanentlyDenied;
    } catch (e) {
      print('Error checking permission status: $e');
      return false;
    }
  }

  /// Open app settings if permission is permanently denied
  Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      print('Error opening settings: $e');
      return false;
    }
  }
}

