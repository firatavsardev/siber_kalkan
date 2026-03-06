// ============================================================
// SiberKalkan - Arama Engelleme Servisi
// Dosya Yolu: lib/services/call_blocker_service.dart
// Scam numaraları tespit + engelleme (Android)
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:siber_kalkan/models/threat_log.dart';
import 'package:siber_kalkan/services/permission_service.dart';
import 'package:siber_kalkan/utils/constants.dart';
import 'package:uuid/uuid.dart';

class CallBlockerService {
  static final CallBlockerService _instance = CallBlockerService._internal();
  factory CallBlockerService() => _instance;
  CallBlockerService._internal();

  static const _uuid = Uuid();
  bool _isEnabled = false;
  final List<String> _blockedNumbers = [];
  Function(ThreatLog)? onScamCallDetected;

  bool get isEnabled => _isEnabled;
  List<String> get blockedNumbers => List.unmodifiable(_blockedNumbers);

  // Bilinen scam numaraları pattern'leri
  static const List<String> _knownScamPatterns = [
    '0850', // Çağrı merkezi
    '0212444', // Sahte banka
    '0216444', // Sahte banka
    '0312444', // Sahte kurum
    '+44',  // İngiltere prefix (yaygın scam)
    '+91',  // Hindistan prefix (yaygın scam)
    '+234', // Nijerya prefix
    '+880', // Bangladeş prefix
  ];

  /// Servisi başlat
  Future<bool> enable({
    required Function(ThreatLog) onScamCall,
  }) async {
    if (kIsWeb || !PermissionService.isAndroid) {
      debugPrint('📞 Arama engelleme: Bu platform desteklenmiyor');
      return false;
    }

    // Telefon izni iste
    final hasPermission = await PermissionService.requestPhonePermission();
    if (!hasPermission) {
      debugPrint('📞 Arama engelleme: İzin verilmedi');
      return false;
    }

    onScamCallDetected = onScamCall;
    _isEnabled = true;
    debugPrint('📞 Arama engelleme: Aktif');
    return true;
  }

  /// Servisi durdur
  void disable() {
    _isEnabled = false;
    onScamCallDetected = null;
    debugPrint('📞 Arama engelleme: Devre dışı');
  }

  /// Numarayı kontrol et — scam mı?
  bool isScamNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Engellenen numara listesinde mi?
    if (_blockedNumbers.contains(cleaned)) return true;

    // Bilinen scam pattern'lerine uyuyor mu?
    for (final pattern in _knownScamPatterns) {
      if (cleaned.startsWith(pattern)) return true;
    }

    return false;
  }

  /// Numarayı engelleme listesine ekle
  void blockNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!_blockedNumbers.contains(cleaned)) {
      _blockedNumbers.add(cleaned);
      debugPrint('📞 Numara engellendi: $cleaned');
    }
  }

  /// Engelleme listesinden kaldır
  void unblockNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    _blockedNumbers.remove(cleaned);
    debugPrint('📞 Numara engeli kaldırıldı: $cleaned');
  }

  /// Gelen aramayı analiz et ve ThreatLog oluştur
  ThreatLog? analyzeCall(String phoneNumber) {
    if (!isScamNumber(phoneNumber)) return null;

    final threat = ThreatLog(
      id: _uuid.v4(),
      type: AppConstants.threatScamCall,
      sender: phoneNumber,
      content: 'Şüpheli arama tespit edildi',
      threatLevel: 70,
      matchedKeywords: ['scam_call'],
    );

    onScamCallDetected?.call(threat);
    return threat;
  }

  /// Engellenen numara sayısı
  int get blockedCount => _blockedNumbers.length;
}
