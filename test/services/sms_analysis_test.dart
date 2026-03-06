import 'package:flutter_test/flutter_test.dart';
import 'package:siber_kalkan/services/sms_analysis_service.dart';

void main() {
  group('SmsAnalysisService', () {
    test('safe message returns low threat level', () {
      final result = SmsAnalysisService.analyzeSms(
        'Merhaba, nasılsınız? İyi günler dilerim.',
      );
      expect(result.threatLevel, lessThan(40));
      expect(result.isSafe, true);
      expect(result.isDangerous, false);
    });

    test('phishing message returns high threat level', () {
      final result = SmsAnalysisService.analyzeSms(
        'TEBRİKLER! Büyük ödül kazandınız! Hemen tıklayın: http://bit.ly/sahte-link '
        'TC kimlik numaranızı girin ve ödülünüzü alın!',
      );
      expect(result.threatLevel, greaterThanOrEqualTo(60));
      expect(result.isDangerous, true);
      expect(result.matchedKeywords, isNotEmpty);
      expect(result.detectedUrls, isNotEmpty);
    });

    test('URL detection works correctly', () {
      final result = SmsAnalysisService.analyzeSms(
        'Hesabınız askıya alındı. Giriş yapın: https://sahte-banka.com/giris',
      );
      expect(result.detectedUrls, isNotEmpty);
      expect(result.detectedUrls.first, contains('sahte-banka.com'));
    });

    test('suspicious domain detection works', () {
      final result = SmsAnalysisService.analyzeSms(
        'Hediye kazandınız! Tıklayın: http://bit.ly/hediye',
      );
      expect(result.hasSuspiciousDomain, true);
    });

    test('personal info request detected', () {
      final result = SmsAnalysisService.analyzeSms(
        'Bankanız: Şifrenizi güncelleyin, TC kimlik numaranızı doğrulayın.',
      );
      expect(result.hasPersonalInfoRequest, true);
      expect(result.threatLevel, greaterThanOrEqualTo(40));
    });

    test('trusted sender reduces score', () {
      const message = 'Hediye kampanyası başladı!';
      final normalResult = SmsAnalysisService.analyzeSms(message);
      final trustedResult = SmsAnalysisService.analyzeSms(
        message,
        sender: 'TURKCELL',
      );
      expect(trustedResult.isTrustedSender, true);
      // Güvenilir gönderici ile skor düşmeli (eğer skor < 60 ise)
      if (normalResult.threatLevel < 60) {
        expect(trustedResult.threatLevel, lessThanOrEqualTo(normalResult.threatLevel));
      }
    });

    test('bank fraud pattern detected', () {
      final result = SmsAnalysisService.analyzeSms(
        'Ziraat Bankası: Hesabınız bloke edildi! Hemen şifrenizi güncelleyin.',
      );
      expect(result.threatLevel, greaterThanOrEqualTo(40));
    });

    test('multiple categories increase score', () {
      // Tek kategori
      final singleResult = SmsAnalysisService.analyzeSms('Hediye kazandınız!');
      // Çoklu kategori
      final multiResult = SmsAnalysisService.analyzeSms(
        'ACIL! Hesabınız bloke edildi! Hediye kazandınız! '
        'Şifrenizi güncelleyin hemen!',
      );
      expect(multiResult.threatLevel, greaterThan(singleResult.threatLevel));
    });

    test('empty message returns safe result', () {
      final result = SmsAnalysisService.analyzeSms('');
      expect(result.threatLevel, 0);
      expect(result.isSafe, true);
    });

    test('createThreatLog generates valid ThreatLog', () {
      final analysisResult = SmsAnalysisService.analyzeSms(
        'Tebrikler kazandınız!',
      );
      final log = SmsAnalysisService.createThreatLog(
        sender: '+905001234567',
        content: 'Tebrikler kazandınız!',
        result: analysisResult,
      );
      expect(log.id, isNotEmpty);
      expect(log.sender, '+905001234567');
      expect(log.type, 'sms_phishing');
    });
  });
}
