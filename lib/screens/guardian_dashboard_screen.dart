// ============================================================
// SiberKalkan - Aile Üyesi Dashboard Ekranı
// Dosya Yolu: lib/screens/guardian_dashboard_screen.dart
// Firestore'dan gerçek zamanlı veri + lokal fallback
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siber_kalkan/providers/app_providers.dart';
import 'package:siber_kalkan/screens/sms_check_screen.dart';
import 'package:siber_kalkan/screens/threat_alert_screen.dart';
import 'package:siber_kalkan/screens/statistics_screen.dart';
import 'package:siber_kalkan/models/threat_log.dart';
import 'package:siber_kalkan/utils/constants.dart';
import 'package:siber_kalkan/widgets/threat_card.dart';

class GuardianDashboardScreen extends ConsumerWidget {
  const GuardianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threats = ref.watch(threatLogsProvider);
    final isSafe = ref.watch(shieldStatusProvider);
    final user = ref.watch(userProvider);
    final firebase = ref.watch(firebaseServiceProvider);
    final dangerCount = threats.where((t) => t.isDangerous).length;
    final totalCount = threats.length;

    // Eğer Firebase aktif ve eşleşme varsa, Firestore'dan canlı veri al
    final isPaired = user?.isPaired == true;
    final hasFirebase = firebase.isAvailable;

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: Text(
          'Aile Paneli',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatisticsScreen()),
              );
            },
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'İstatistikler',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SmsCheckScreen()),
              );
            },
            icon: const Icon(Icons.sms_rounded),
            tooltip: 'SMS Kontrol',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Durum Kartı
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSafe
                      ? [AppColors.primaryGreen, const Color(0xFF43A047)]
                      : [AppColors.dangerRed, const Color(0xFFE53935)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isSafe ? AppColors.primaryGreen : AppColors.dangerRed)
                            .withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isSafe ? Icons.shield_rounded : Icons.warning_rounded,
                        color: AppColors.white,
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isSafe
                              ? 'Yakını nız Güvende'
                              : 'Tehdit Tespit Edildi!',
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSafe
                        ? 'Son 24 saatte şüpheli bir aktivite algılanmadı.'
                        : 'Son 24 saatte $dangerCount tehdit tespit edildi!',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: AppColors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // İstatistik Kartları
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.shield_rounded,
                      label: 'Koruma\nSüresi',
                      value:
                          '${DateTime.now().difference(user?.createdAt ?? DateTime.now()).inHours}+ saat',
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.sms_failed_rounded,
                      label: 'Toplam\nTehdit',
                      value: '$dangerCount',
                      color: AppColors.dangerRed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.analytics_rounded,
                      label: 'Taranan\nSMS',
                      value: '$totalCount',
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Eşleşme ve Firebase Durumu
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPaired
                      ? AppColors.primaryGreen.withOpacity(0.3)
                      : AppColors.grey.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        isPaired
                            ? Icons.link_rounded
                            : Icons.link_off_rounded,
                        color: isPaired
                            ? AppColors.primaryGreen
                            : AppColors.grey,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isPaired
                            ? 'Yakınla eşleşildi ✓'
                            : 'Henüz eşleşilmedi',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isPaired
                              ? AppColors.primaryGreen
                              : AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        hasFirebase
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        color: hasFirebase
                            ? AppColors.primaryGreen
                            : AppColors.warningOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasFirebase
                            ? 'Bulut bağlantısı aktif'
                            : 'Çevrimdışı mod',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: hasFirebase
                              ? AppColors.primaryGreen
                              : AppColors.warningOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Son Tehditler Başlığı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Son Tehditler',
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Firestore canlı veri veya lokal veri
            if (isPaired && hasFirebase)
              _FirestoreThreatList(
                pairedUserUid: user!.pairedWith!,
                ref: ref,
              )
            else
              _LocalThreatList(threats: threats, ref: ref),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Firestore'dan canlı tehdit listesi (Guardian eşleşmişse)
class _FirestoreThreatList extends StatelessWidget {
  final String pairedUserUid;
  final WidgetRef ref;

  const _FirestoreThreatList({
    required this.pairedUserUid,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final firebase = ref.watch(firebaseServiceProvider);

    return StreamBuilder<List<ThreatLog>>(
      stream: firebase.watchPairedUserThreats(pairedUserUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGreen,
              ),
            ),
          );
        }

        final threats = snapshot.data ?? [];

        if (threats.isEmpty) {
          return _emptyState();
        }

        return Column(
          children: threats
              .map((threat) => ThreatCard(
                    threat: threat,
                    onTap: () {
                      if (threat.isDangerous) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ThreatAlertScreen(threat: threat),
                          ),
                        );
                      }
                    },
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 60,
              color: AppColors.primaryGreen,
            ),
            const SizedBox(height: 12),
            Text(
              'Henüz tehdit algılanmadı',
              style: GoogleFonts.nunito(
                fontSize: 18,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lokal tehdit listesi (Firebase yoksa veya eşleşme yoksa)
class _LocalThreatList extends StatelessWidget {
  final List<ThreatLog> threats;
  final WidgetRef ref;

  const _LocalThreatList({
    required this.threats,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    if (threats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 60,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 12),
              Text(
                'Henüz tehdit algılanmadı',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: threats
          .map((threat) => ThreatCard(
                threat: threat,
                onTap: () {
                  ref
                      .read(threatLogsProvider.notifier)
                      .markAsRead(threat.id);
                  if (threat.isDangerous) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ThreatAlertScreen(threat: threat),
                      ),
                    );
                  }
                },
              ))
          .toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
