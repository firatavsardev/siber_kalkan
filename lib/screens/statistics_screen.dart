// ============================================================
// SiberKalkan - İstatistik Ekranı
// Dosya Yolu: lib/screens/statistics_screen.dart
// Detaylı tehdit istatistikleri ve grafikler
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siber_kalkan/providers/app_providers.dart';
import 'package:siber_kalkan/services/statistics_service.dart';
import 'package:siber_kalkan/utils/constants.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threats = ref.watch(threatLogsProvider);
    final stats = StatisticsService.calculateStats(threats: threats);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: Text(
          'İstatistikler',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Güvenlik Skoru
            _SecurityScoreCard(score: stats.securityScore),
            const SizedBox(height: 16),

            // Özet Kartları
            Row(
              children: [
                Expanded(
                  child: _MiniStatCard(
                    title: 'Toplam Tehdit',
                    value: '${stats.totalThreats}',
                    icon: Icons.warning_rounded,
                    color: AppColors.warningOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStatCard(
                    title: 'Tehlikeli',
                    value: '${stats.dangerousCount}',
                    icon: Icons.dangerous_rounded,
                    color: AppColors.dangerRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniStatCard(
                    title: 'SMS Phishing',
                    value: '${stats.smsPhishingCount}',
                    icon: Icons.sms_rounded,
                    color: AppColors.warningOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStatCard(
                    title: 'Scam Arama',
                    value: '${stats.scamCallCount}',
                    icon: Icons.phone_missed_rounded,
                    color: AppColors.dangerRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Koruma Süresi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield_rounded,
                        color: AppColors.primaryGreen, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Koruma Süresi',
                          style: GoogleFonts.nunito(
                            color: AppColors.grey,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          StatisticsService.formatDuration(
                              stats.protectionDuration),
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Son 7 Gün Grafiği
            Text(
              'Son 7 Gün',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _WeeklyChart(threatsByDay: stats.threatsByDay),
            const SizedBox(height: 24),

            // En Çok Eşleşen Kelimeler
            if (stats.topKeywords.isNotEmpty) ...[
              Text(
                'En Çok Eşleşen Kelimeler',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _KeywordsList(keywords: stats.topKeywords),
            ],

            // Tehdit Dağılımı
            if (stats.totalThreats > 0) ...[
              const SizedBox(height: 24),
              Text(
                'Tehdit Seviye Dağılımı',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _ThreatDistribution(stats: stats),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Güvenlik Skoru Kartı
// ============================================================
class _SecurityScoreCard extends StatelessWidget {
  final int score;
  const _SecurityScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    Color scoreColor;
    String emoji;
    String label;

    if (score >= 80) {
      scoreColor = AppColors.primaryGreen;
      emoji = '🛡️';
      label = 'Güvenli';
    } else if (score >= 50) {
      scoreColor = AppColors.warningOrange;
      emoji = '⚠️';
      label = 'Dikkatli Olun';
    } else {
      scoreColor = AppColors.dangerRed;
      emoji = '🚨';
      label = 'Risk Altında';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor, scoreColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            'Güvenlik Skoru',
            style: GoogleFonts.nunito(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          Text(
            '$score',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Mini İstatistik Kartı
// ============================================================
class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Haftalık Grafik (CustomPaint ile basit bar chart)
// ============================================================
class _WeeklyChart extends StatelessWidget {
  final Map<String, int> threatsByDay;
  const _WeeklyChart({required this.threatsByDay});

  @override
  Widget build(BuildContext context) {
    final maxVal = threatsByDay.values.fold(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: threatsByDay.entries.map((entry) {
                final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${entry.value}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: entry.value > 0
                                ? AppColors.dangerRed
                                : AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: (ratio * 80).clamp(4, 80),
                          decoration: BoxDecoration(
                            color: entry.value > 0
                                ? AppColors.dangerRed.withOpacity(0.7)
                                : AppColors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: threatsByDay.keys.map((day) {
              return Expanded(
                child: Text(
                  day,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Kelime Listesi
// ============================================================
class _KeywordsList extends StatelessWidget {
  final Map<String, int> keywords;
  const _KeywordsList({required this.keywords});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: keywords.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.dangerRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.key,
                    style: GoogleFonts.nunito(fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.dangerRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entry.value}',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      color: AppColors.dangerRed,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// Tehdit Dağılımı Barı
// ============================================================
class _ThreatDistribution extends StatelessWidget {
  final ThreatStatistics stats;
  const _ThreatDistribution({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.totalThreats;
    if (total == 0) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  if (stats.dangerousCount > 0)
                    Expanded(
                      flex: stats.dangerousCount,
                      child: Container(color: AppColors.dangerRed),
                    ),
                  if (stats.suspiciousCount > 0)
                    Expanded(
                      flex: stats.suspiciousCount,
                      child: Container(color: AppColors.warningOrange),
                    ),
                  if (stats.safeCount > 0)
                    Expanded(
                      flex: stats.safeCount,
                      child: Container(color: AppColors.primaryGreen),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legends
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _legend(AppColors.dangerRed, 'Tehlikeli', stats.dangerousCount),
              _legend(AppColors.warningOrange, 'Şüpheli', stats.suspiciousCount),
              _legend(AppColors.primaryGreen, 'Düşük Risk', stats.safeCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String text, int count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$text ($count)',
          style: GoogleFonts.nunito(fontSize: 12, color: AppColors.grey),
        ),
      ],
    );
  }
}
