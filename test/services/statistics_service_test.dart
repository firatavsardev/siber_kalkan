import 'package:flutter_test/flutter_test.dart';
import 'package:siber_kalkan/models/threat_log.dart';
import 'package:siber_kalkan/services/statistics_service.dart';

void main() {
  group('StatisticsService', () {
    final now = DateTime.now();

    List<ThreatLog> createThreats() {
      return [
        ThreatLog(
          id: '1', type: 'sms_phishing', sender: 'x',
          content: 'Tehlikeli mesaj', threatLevel: 80,
          matchedKeywords: ['tebrikler', 'kazandınız'],
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
        ThreatLog(
          id: '2', type: 'sms_phishing', sender: 'y',
          content: 'Şüpheli mesaj', threatLevel: 50,
          matchedKeywords: ['kampanya'],
          timestamp: now.subtract(const Duration(hours: 5)),
        ),
        ThreatLog(
          id: '3', type: 'scam_call', sender: '0850xxx',
          content: 'Scam arama', threatLevel: 70,
          matchedKeywords: ['scam_call'],
          timestamp: now.subtract(const Duration(days: 1)),
        ),
        ThreatLog(
          id: '4', type: 'sms_phishing', sender: 'z',
          content: 'Düşük riskli', threatLevel: 25,
          matchedKeywords: ['hediye'],
          timestamp: now.subtract(const Duration(days: 3)),
        ),
      ];
    }

    test('calculates correct threat counts', () {
      final stats = StatisticsService.calculateStats(
        threats: createThreats(),
        installDate: now.subtract(const Duration(days: 7)),
      );

      expect(stats.totalThreats, 4);
      expect(stats.dangerousCount, 2); // 80 and 70
      expect(stats.smsPhishingCount, 3);
      expect(stats.scamCallCount, 1);
    });

    test('calculates security score', () {
      final stats = StatisticsService.calculateStats(
        threats: createThreats(),
        installDate: now.subtract(const Duration(days: 7)),
      );

      // Score should be reduced due to unread dangerous threats
      expect(stats.securityScore, lessThan(100));
      expect(stats.securityScore, greaterThanOrEqualTo(0));
    });

    test('empty threats gives perfect score', () {
      final stats = StatisticsService.calculateStats(
        threats: [],
        installDate: now.subtract(const Duration(days: 7)),
      );

      expect(stats.totalThreats, 0);
      expect(stats.securityScore, 100);
      expect(stats.averageThreatLevel, 0);
    });

    test('top keywords calculated correctly', () {
      final threats = [
        ThreatLog(
          id: '1', type: 'sms_phishing', sender: 'x',
          content: 'x', threatLevel: 80,
          matchedKeywords: ['tebrikler', 'kazandınız'],
        ),
        ThreatLog(
          id: '2', type: 'sms_phishing', sender: 'y',
          content: 'y', threatLevel: 60,
          matchedKeywords: ['tebrikler', 'hemen'],
        ),
      ];

      final stats = StatisticsService.calculateStats(threats: threats);
      expect(stats.topKeywords['tebrikler'], 2);
      expect(stats.topKeywords['kazandınız'], 1);
    });

    test('filterByDays filters correctly', () {
      final threats = createThreats();
      final last24h = StatisticsService.filterByDays(threats, 1);
      // Only threats from last 24h
      expect(last24h.length, lessThan(threats.length));
    });

    test('formatDuration formats correctly', () {
      expect(
        StatisticsService.formatDuration(const Duration(days: 5, hours: 3)),
        '5 gün 3 saat',
      );
      expect(
        StatisticsService.formatDuration(const Duration(hours: 8)),
        '8 saat',
      );
    });
  });
}
