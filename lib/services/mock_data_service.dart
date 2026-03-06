// ============================================================
// SiberKalkan - Mock Veri Servisi
// Dosya Yolu: lib/services/mock_data_service.dart
// Firebase entegrasyonu yapılana kadar yerel veri yönetimi
// ============================================================

import 'package:siber_kalkan/models/threat_log.dart';
import 'package:siber_kalkan/models/user_model.dart';
import 'package:uuid/uuid.dart';

class MockDataService {
  static const _uuid = Uuid();

  /// Demo tehdit logları
  static List<ThreatLog> getDemoThreatLogs() {
    return [
      ThreatLog(
        id: _uuid.v4(),
        type: 'sms_phishing',
        sender: '+90 555 000 00 00',
        content:
            'Tebrikler! 10.000 TL ödül kazandınız. Hemen tıklayın: bit.ly/odulunuz',
        threatLevel: 92,
        matchedKeywords: ['tebrikler', 'kazandınız', 'hemen', 'tıklayın'],
        matchedUrls: ['bit.ly/odulunuz'],
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ThreatLog(
        id: _uuid.v4(),
        type: 'sms_phishing',
        sender: 'BANKA',
        content:
            'Hesabınız bloke edilmiştir. Şifrenizi güncellemek için: tinyurl.com/banka-giris',
        threatLevel: 88,
        matchedKeywords: [
          'hesabınız',
          'bloke',
          'şifre',
          'güncelle',
        ],
        matchedUrls: ['tinyurl.com/banka-giris'],
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      ThreatLog(
        id: _uuid.v4(),
        type: 'sms_phishing',
        sender: '+90 532 111 22 33',
        content:
            'Son gün! Ücretsiz kredi kampanyasından yararlanmak için hemen arayın.',
        threatLevel: 65,
        matchedKeywords: ['son gün', 'ücretsiz', 'kredi', 'kampanya', 'hemen'],
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ThreatLog(
        id: _uuid.v4(),
        type: 'sms_phishing',
        sender: '+90 544 333 44 55',
        content: 'Kargonuz teslim edilecektir. Takip numarası: 123456789',
        threatLevel: 0,
        matchedKeywords: [],
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  /// Yeni kullanıcı oluştur
  static UserModel createUser({
    required String role,
    required String displayName,
  }) {
    return UserModel(
      uid: _uuid.v4(),
      role: role,
      displayName: displayName,
    );
  }

  /// 6 haneli eşleşme kodu üret
  static String generatePairingCode() {
    final code = (100000 +
            (DateTime.now().millisecondsSinceEpoch % 900000))
        .toString();
    return code;
  }
}
