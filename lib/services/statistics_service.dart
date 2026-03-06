// ============================================================
// SiberKalkan - İstatistik Servisi
// Dosya Yolu: lib/services/statistics_service.dart
// Tehdit loglarından istatistik hesaplama
// ============================================================

import 'package:siber_kalkan/models/threat_log.dart';
import 'package:siber_kalkan/utils/constants.dart';

/// İstatistik özeti
class ThreatStatistics {
  final int totalThreats;
  final int dangerousCount;
  final int suspiciousCount;
  final int safeCount;
  final int smsPhishingCount;
  final int scamCallCount;
  final int totalScannedSms;
  final double averageThreatLevel;
  final Map<String, int> topKeywords;
  final Map<String, int> threatsByDay;
  final int securityScore; // 0-100 (yüksek = güvenli)
  final Duration protectionDuration;
  final int unreadCount;

  ThreatStatistics({
    required this.totalThreats,
    required this.dangerousCount,
    required this.suspiciousCount,
    required this.safeCount,
    required this.smsPhishingCount,
    required this.scamCallCount,
    required this.totalScannedSms,
    required this.averageThreatLevel,
    required this.topKeywords,
    required this.threatsByDay,
    required this.securityScore,
    required this.protectionDuration,
    required this.unreadCount,
  });
}

class StatisticsService {
  /// Tehdit loglarından istatistik hesapla
  static ThreatStatistics calculateStats({
    required List<ThreatLog> threats,
    DateTime? installDate,
  }) {
    final now = DateTime.now();
    final install = installDate ?? now.subtract(const Duration(days: 1));

    // Genel sayılar
    final dangerous = threats.where((t) => t.isDangerous).length;
    final suspicious = threats.where((t) => t.isSuspicious && !t.isDangerous).length;
    final safe = threats.where((t) => !t.isSuspicious).length;
    final smsPhishing = threats.where((t) => t.type == AppConstants.threatSmsPhishing).length;
    final scamCall = threats.where((t) => t.type == AppConstants.threatScamCall).length;
    final unread = threats.where((t) => !t.isRead).length;

    // Ortalama tehdit seviyesi
    double avgLevel = 0;
    if (threats.isNotEmpty) {
      avgLevel = threats.map((t) => t.threatLevel).reduce((a, b) => a + b) / threats.length;
    }

    // En çok eşleşen kelimeler
    final keywordCounts = <String, int>{};
    for (final threat in threats) {
      for (final keyword in threat.matchedKeywords) {
        keywordCounts[keyword] = (keywordCounts[keyword] ?? 0) + 1;
      }
    }
    // En çok kullanılan 10 kelimeyi al
    final sortedKeywords = keywordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topKeywords = Map.fromEntries(sortedKeywords.take(10));

    // Güne göre tehdit dağılımı (son 7 gün)
    final threatsByDay = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStr = '${day.day}.${day.month}';
      threatsByDay[dayStr] = 0;
    }
    for (final threat in threats) {
      final dayStr = '${threat.timestamp.day}.${threat.timestamp.month}';
      if (threatsByDay.containsKey(dayStr)) {
        threatsByDay[dayStr] = threatsByDay[dayStr]! + 1;
      }
    }

    // Güvenlik skoru hesaplama
    // 100 = mükemmel, 0 = çok tehlikeli
    int securityScore = 100;
    // Son 24 saatteki okunmamış tehlikeli tehditlere göre düşür
    final recentDangerous = threats.where((t) {
      return t.isDangerous && !t.isRead &&
          now.difference(t.timestamp).inHours < 24;
    }).length;
    securityScore -= recentDangerous * 20;
    // Toplam tehditlere göre hafif düşür
    securityScore -= (dangerous * 2).clamp(0, 30);
    securityScore = securityScore.clamp(0, 100);

    // Koruma süresi
    final protectionDuration = now.difference(install);

    return ThreatStatistics(
      totalThreats: threats.length,
      dangerousCount: dangerous,
      suspiciousCount: suspicious,
      safeCount: safe,
      smsPhishingCount: smsPhishing,
      scamCallCount: scamCall,
      totalScannedSms: threats.length,
      averageThreatLevel: avgLevel,
      topKeywords: topKeywords,
      threatsByDay: threatsByDay,
      securityScore: securityScore,
      protectionDuration: protectionDuration,
      unreadCount: unread,
    );
  }

  /// Son N gündeki tehditleri filtrele
  static List<ThreatLog> filterByDays(List<ThreatLog> threats, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return threats.where((t) => t.timestamp.isAfter(cutoff)).toList();
  }

  /// Koruma süresi formatla
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} gün ${duration.inHours.remainder(24)} saat';
    }
    return '${duration.inHours} saat';
  }
}
