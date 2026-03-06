// ============================================================
// SiberKalkan - Sistem İzinleri Servisi
// Dosya Yolu: lib/services/system_permission_service.dart
// Android Native sistem izin dialoglarını (Varsayılan SMS vb.) tetikler
// ============================================================

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:siber_kalkan/services/permission_service.dart';

class SystemPermissionService {
  static const MethodChannel _channel = MethodChannel('siber_kalkan/sms_scanner');

  /// Android sistemine "Beni Varsayılan SMS Uygulaması yap" isteği gönderir
  static Future<void> requestDefaultSmsApp() async {
    if (kIsWeb || !PermissionService.isAndroid) return;

    try {
      await _channel.invokeMethod('requestDefaultSmsApp');
      debugPrint('Varsayılan SMS isteği tetiklendi.');
    } catch (e) {
      debugPrint('Varsayılan SMS isteği başarısız: $e');
    }
  }
}
