// ============================================================
// SiberKalkan - Yaşlı Ana Ekranı
// Dosya Yolu: lib/screens/elderly_home_screen.dart
// Minimal, büyük fontlu, yaşlı dostu arayüz
// Otomatik SMS tarama toggle eklenmiş
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siber_kalkan/providers/app_providers.dart';
import 'package:siber_kalkan/screens/sms_check_screen.dart';
import 'package:siber_kalkan/screens/threat_alert_screen.dart';
import 'package:siber_kalkan/screens/statistics_screen.dart';
import 'package:siber_kalkan/services/permission_service.dart';
import 'package:siber_kalkan/services/sms_scanner_service.dart';
import 'package:siber_kalkan/utils/constants.dart';
import 'package:siber_kalkan/widgets/big_button.dart';
import 'package:siber_kalkan/widgets/shield_widget.dart';

class ElderlyHomeScreen extends ConsumerStatefulWidget {
  const ElderlyHomeScreen({super.key});

  @override
  ConsumerState<ElderlyHomeScreen> createState() => _ElderlyHomeScreenState();
}

class _ElderlyHomeScreenState extends ConsumerState<ElderlyHomeScreen> {
  final SmsScannerService _smsScanner = SmsScannerService();

  @override
  void initState() {
    super.initState();
    // Otomatik tarama daha önce açıksa başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final autoScan = ref.read(autoScanEnabledProvider);
      if (autoScan && PermissionService.isAndroid) {
        _startScanning();
      }
    });
  }

  Future<void> _toggleAutoScan(bool enable) async {
    if (enable) {
      // İzin iste
      final granted = await PermissionService.requestSmsPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'SMS izni verilmedi',
                style: GoogleFonts.nunito(fontSize: 18),
              ),
              backgroundColor: AppColors.dangerRed,
            ),
          );
        }
        return;
      }

      await _startScanning();
    } else {
      _smsScanner.stopListening();
    }

    ref.read(autoScanEnabledProvider.notifier).state = enable;
    ref.read(localStorageProvider)?.setAutoScanEnabled(enable);
  }

  Future<void> _startScanning() async {
    await _smsScanner.startListening(
      onThreat: (threatLog) {
        // Tehdit bulundu — kaydet
        ref.read(threatLogsProvider.notifier).addThreat(threatLog);

        // Tam ekran uyarı göster (uygulama ön plandaysa)
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ThreatAlertScreen(threat: threatLog),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSafe = ref.watch(shieldStatusProvider);
    final threats = ref.watch(threatLogsProvider);
    final unreadCount =
        threats.where((t) => !t.isRead && t.isDangerous).length;
    final autoScanEnabled = ref.watch(autoScanEnabledProvider);
    final isAndroid = PermissionService.isAndroid;

    return Scaffold(
      backgroundColor: isSafe ? AppColors.white : const Color(0xFFFFF3F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Üst başlık
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SiberKalkan',
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  // Bildirim ikonu
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          _showRecentThreats(context, ref);
                        },
                        icon: const Icon(
                          Icons.notifications_rounded,
                          size: 32,
                          color: AppColors.grey,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.dangerRed,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Otomatik SMS Tarama Toggle (sadece Android)
              if (isAndroid)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: autoScanEnabled
                        ? AppColors.primaryGreen.withOpacity(0.1)
                        : AppColors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: autoScanEnabled
                          ? AppColors.primaryGreen.withOpacity(0.3)
                          : AppColors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        autoScanEnabled
                            ? Icons.radar_rounded
                            : Icons.radar_outlined,
                        color: autoScanEnabled
                            ? AppColors.primaryGreen
                            : AppColors.grey,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          autoScanEnabled
                              ? 'Otomatik tarama AÇK'
                              : 'Otomatik tarama kapalı',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: autoScanEnabled
                                ? AppColors.primaryGreen
                                : AppColors.grey,
                          ),
                        ),
                      ),
                      Switch(
                        value: autoScanEnabled,
                        onChanged: _toggleAutoScan,
                        activeColor: AppColors.primaryGreen,
                      ),
                    ],
                  ),
                ),

              // Dev Kalkan
              const Spacer(),
              ShieldWidget(
                isSafe: isSafe,
                size: 200,
              ),
              const Spacer(),

              // SMS Kontrol Butonu
              BigButton(
                text: 'SMS Kontrol Et',
                icon: Icons.sms_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SmsCheckScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Son uyarılar
              BigButton(
                text: 'Son Uyarılar',
                icon: Icons.history_rounded,
                color: unreadCount > 0
                    ? AppColors.warningOrange
                    : AppColors.grey,
                onPressed: () {
                  _showRecentThreats(context, ref);
                },
              ),
              const SizedBox(height: 16),

              // İstatistikler
              BigButton(
                text: 'İstatistikler',
                icon: Icons.bar_chart_rounded,
                color: AppColors.blue,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StatisticsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Durum metni
              Text(
                isSafe
                    ? 'Cihazınız güvende 🛡️'
                    : 'Şüpheli mesaj tespit edildi!',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isSafe ? AppColors.primaryGreen : AppColors.dangerRed,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecentThreats(BuildContext context, WidgetRef ref) {
    final threats = ref.read(threatLogsProvider);
    final dangerousThreats = threats.where((t) => t.isSuspicious).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Çizgi göstergesi
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Son Uyarılar',
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: dangerousThreats.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 80,
                                  color: AppColors.primaryGreen,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Hiç uyarı yok! 🎉',
                                  style: GoogleFonts.nunito(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: dangerousThreats.length,
                            itemBuilder: (context, index) {
                              final threat = dangerousThreats[index];
                              return ListTile(
                                leading: Icon(
                                  threat.isDangerous
                                      ? Icons.dangerous_rounded
                                      : Icons.warning_amber_rounded,
                                  color: threat.isDangerous
                                      ? AppColors.dangerRed
                                      : AppColors.warningOrange,
                                  size: 36,
                                ),
                                title: Text(
                                  threat.sender,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(
                                  threat.content,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  '${threat.threatLevel}%',
                                  style: TextStyle(
                                    color: threat.isDangerous
                                        ? AppColors.dangerRed
                                        : AppColors.warningOrange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                onTap: () {
                                  ref
                                      .read(threatLogsProvider.notifier)
                                      .markAsRead(threat.id);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ThreatAlertScreen(threat: threat),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
