// ============================================================
// SiberKalkan - Otomatik SMS Tarama Servisi
// Dosya Yolu: lib/services/sms_scanner_service.dart
// Native Kotlin MethodChannel üzerinden gelen SMS'leri otomatik tarar
// Sadece Android'de çalışır
// ============================================================

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:siber_kalkan/models/threat_log.dart';
import 'package:siber_kalkan/services/sms_analysis_service.dart';
import 'package:siber_kalkan/services/permission_service.dart';

/// Arka planda gelen SMS'leri otomatik tarayan servis
class SmsScannerService {
  static final SmsScannerService _instance = SmsScannerService._internal();
  factory SmsScannerService() => _instance;
  
  SmsScannerService._internal() {
    // Method channel dinleyicisini kur
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static const MethodChannel _channel = MethodChannel('siber_kalkan/sms_scanner');

  bool _isListening = false;
  Function(ThreatLog)? onThreatDetected;

  bool get isListening => _isListening;

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onSmsReceived') {
      final String sender = call.arguments['sender'] ?? 'Bilinmeyen';
      final String body = call.arguments['body'] ?? '';
      _processSms(sender, body);
    }
  }

  /// SMS dinlemeyi başlat
  Future<bool> startListening({
    required Function(ThreatLog) onThreat,
  }) async {
    // Web'de veya Android dışında çalışmaz
    if (kIsWeb || !PermissionService.isAndroid) {
      debugPrint('SMS tarama: Bu platform desteklenmiyor');
      return false;
    }

    // İzin kontrolü
    final hasPermission = await PermissionService.hasSmsPermission();
    if (!hasPermission) {
      final granted = await PermissionService.requestSmsPermission();
      if (!granted) {
        debugPrint('SMS tarama: İzin verilmedi');
        return false;
      }
    }

    onThreatDetected = onThreat;

    try {
      final success = await _channel.invokeMethod<bool>('startListening');
      _isListening = success ?? false;
      debugPrint('SMS tarama: Dinleme başlatıldı ($_isListening)');
      return _isListening;
    } catch (e) {
      debugPrint('SMS tarama başlatma hatası: $e');
      return false;
    }
  }

  /// SMS dinlemeyi durdur
  Future<void> stopListening() async {
    if (kIsWeb || !PermissionService.isAndroid) return;

    try {
      await _channel.invokeMethod('stopListening');
      _isListening = false;
      onThreatDetected = null;
      debugPrint('SMS tarama: Dinleme durduruldu');
    } catch (e) {
      debugPrint('SMS tarama durdurma hatası: $e');
    }
  }

  /// Gelen SMS'i işle
  void _processSms(String sender, String body) {
    if (body.isEmpty) return;

    debugPrint('SMS alındı - Gönderen: $sender');

    // Analiz et
    final result = SmsAnalysisService.analyzeSms(body);

    // Tehlikeli veya şüpheli ise kaydet
    if (result.isSuspicious) {
      final threatLog = SmsAnalysisService.createThreatLog(
        sender: sender,
        content: body,
        result: result,
      );

      debugPrint(
          'Tehdit tespit edildi! Skor: ${result.threatLevel} - Gönderen: $sender');

      // Callback ile bildir
      onThreatDetected?.call(threatLog);
    }
  }

  /// Mevcut SMS kutusunu tara (geçmiş SMS'ler)
  Future<List<ThreatLog>> scanExistingSms({int limit = 50}) async {
    if (kIsWeb || !PermissionService.isAndroid) return [];

    final hasPermission = await PermissionService.hasSmsPermission();
    if (!hasPermission) return [];

    final threats = <ThreatLog>[];

    try {
      final List<dynamic>? messages = await _channel.invokeMethod('getInboxSms', {'limit': limit});
      if (messages != null) {
        for (final msg in messages) {
          final Map<dynamic, dynamic> message = msg;
          final String body = message['body'] ?? '';
          final String sender = message['sender'] ?? 'Bilinmeyen';

          if (body.isEmpty) continue;

          final result = SmsAnalysisService.analyzeSms(body);
          if (result.isSuspicious) {
            final threatLog = SmsAnalysisService.createThreatLog(
              sender: sender,
              content: body,
              result: result,
            );
            threats.add(threatLog);
          }
        }
      }
    } catch (e) {
      debugPrint('Eski SMS tarama hatası: $e');
    }

    return threats;
  }
}
