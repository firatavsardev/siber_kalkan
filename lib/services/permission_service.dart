// ============================================================
// SiberKalkan - İzin Yönetim Servisi
// Dosya Yolu: lib/services/permission_service.dart
// SMS ve telefon izinlerini yönetir
// ============================================================

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Platform Android mi kontrol et
  static bool get isAndroid {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  /// SMS okuma izni ver
  static Future<bool> requestSmsPermission() async {
    if (!isAndroid) return false;

    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// SMS izni var mı kontrol et
  static Future<bool> hasSmsPermission() async {
    if (!isAndroid) return false;

    final status = await Permission.sms.status;
    return status.isGranted;
  }

  /// Telefon izni ver
  static Future<bool> requestPhonePermission() async {
    if (!isAndroid) return false;

    final status = await Permission.phone.request();
    return status.isGranted;
  }

  /// Bildirim izni ver (Android 13+)
  static Future<bool> requestNotificationPermission() async {
    if (!isAndroid) return false;

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Tüm gerekli izinleri iste
  static Future<Map<String, bool>> requestAllPermissions() async {
    if (!isAndroid) {
      return {
        'sms': false,
        'phone': false,
        'notification': false,
      };
    }

    final results = await [
      Permission.sms,
      Permission.phone,
      Permission.notification,
    ].request();

    return {
      'sms': results[Permission.sms]?.isGranted ?? false,
      'phone': results[Permission.phone]?.isGranted ?? false,
      'notification': results[Permission.notification]?.isGranted ?? false,
    };
  }
}
