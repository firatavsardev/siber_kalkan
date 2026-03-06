import 'package:flutter_test/flutter_test.dart';
import 'package:siber_kalkan/models/threat_log.dart';

void main() {
  group('ThreatLog', () {
    test('JSON serialization/deserialization', () {
      final log = ThreatLog(
        id: 'test-123',
        type: 'sms_phishing',
        sender: '+905001234567',
        content: 'Tebrikler kazandınız! Tıklayın: bit.ly/xxx',
        threatLevel: 75,
        matchedKeywords: ['tebrikler', 'kazandınız', 'tıklayın'],
        matchedUrls: ['bit.ly/xxx'],
        isRead: false,
      );

      final json = log.toJson();
      final restored = ThreatLog.fromJson(json);

      expect(restored.id, 'test-123');
      expect(restored.type, 'sms_phishing');
      expect(restored.sender, '+905001234567');
      expect(restored.threatLevel, 75);
      expect(restored.matchedKeywords.length, 3);
      expect(restored.matchedUrls.length, 1);
      expect(restored.isRead, false);
    });

    test('maskedSender masks phone numbers and names correctly', () {
      final log1 = ThreatLog(
        id: '1', type: 'sms', sender: '+905001234567',
        content: 'x', threatLevel: 0, matchedKeywords: [],
      );
      expect(log1.maskedSender, '+90500****67');

      final log2 = ThreatLog(
        id: '2', type: 'sms', sender: 'BANKAM',
        content: 'x', threatLevel: 0, matchedKeywords: [],
      );
      expect(log2.maskedSender, 'BAN****AM');

      final log3 = ThreatLog(
        id: '3', type: 'sms', sender: 'AB',
        content: 'x', threatLevel: 0, matchedKeywords: [],
      );
      expect(log3.maskedSender, '****');
    });

    test('toFirebaseMap anonymizes content and masks sender', () {
      final log = ThreatLog(
        id: 'test-firebase',
        type: 'sms_phishing',
        sender: '+905551234567',
        content: 'Tebrikler şifreniz: 123456',
        threatLevel: 80,
        matchedKeywords: ['tebrikler', 'şifre'],
        matchedUrls: [],
        timestamp: DateTime(2023, 1, 1),
      );

      final firebaseMap = log.toFirebaseMap();

      expect(firebaseMap['id'], 'test-firebase');
      expect(firebaseMap['sender'], '+90555****67'); // Maskelenmiş gönderici
      expect(firebaseMap['content'], '[GİZLİLİK NEDENİYLE GİZLENDİ]'); // İçerik gizli
      expect(firebaseMap['threatLevel'], 80);
    });

    test('isDangerous returns true for threshold >= 60', () {
      final dangerous = ThreatLog(
        id: '1', type: 'sms_phishing', sender: 'x',
        content: 'x', threatLevel: 60, matchedKeywords: [],
      );
      expect(dangerous.isDangerous, true);
    });

    test('isDangerous returns false for threshold < 60', () {
      final safe = ThreatLog(
        id: '1', type: 'sms_phishing', sender: 'x',
        content: 'x', threatLevel: 59, matchedKeywords: [],
      );
      expect(safe.isDangerous, false);
    });

    test('isSuspicious returns true for threshold >= 40', () {
      final suspicious = ThreatLog(
        id: '1', type: 'sms_phishing', sender: 'x',
        content: 'x', threatLevel: 40, matchedKeywords: [],
      );
      expect(suspicious.isSuspicious, true);
    });

    test('threatLevelText returns correct labels', () {
      expect(
        ThreatLog(id: '1', type: 'x', sender: 'x', content: 'x',
            threatLevel: 85, matchedKeywords: []).threatLevelText,
        'Çok Tehlikeli',
      );
      expect(
        ThreatLog(id: '1', type: 'x', sender: 'x', content: 'x',
            threatLevel: 65, matchedKeywords: []).threatLevelText,
        'Tehlikeli',
      );
      expect(
        ThreatLog(id: '1', type: 'x', sender: 'x', content: 'x',
            threatLevel: 45, matchedKeywords: []).threatLevelText,
        'Şüpheli',
      );
      expect(
        ThreatLog(id: '1', type: 'x', sender: 'x', content: 'x',
            threatLevel: 10, matchedKeywords: []).threatLevelText,
        'Güvenli',
      );
    });

    test('copyWith preserves and overrides fields', () {
      final original = ThreatLog(
        id: '1', type: 'sms_phishing', sender: 'x',
        content: 'x', threatLevel: 70, matchedKeywords: [], isRead: false,
      );
      final updated = original.copyWith(isRead: true);
      expect(updated.isRead, true);
      expect(updated.id, '1');
      expect(updated.threatLevel, 70);
    });
  });
}
