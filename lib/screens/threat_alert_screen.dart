// ============================================================
// SiberKalkan - Kırmızı Tehdit Uyarı Ekranı
// Dosya Yolu: lib/screens/threat_alert_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siber_kalkan/models/threat_log.dart';
import 'package:siber_kalkan/utils/constants.dart';

class ThreatAlertScreen extends StatelessWidget {
  final ThreatLog threat;

  const ThreatAlertScreen({
    super.key,
    required this.threat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dangerRed,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Uyarı İkonu
              const Icon(
                Icons.warning_rounded,
                size: 120,
                color: AppColors.white,
              ),
              const SizedBox(height: 24),

              // DİKKAT başlığı
              Text(
                '⚠️ DİKKAT! ⚠️',
                style: GoogleFonts.nunito(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Ana uyarı mesajı
              Text(
                'Bu mesaj DOLANDIRICI\nolabilir!',
                style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Detay kutusu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gönderen: ${threat.sender}',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      threat.content,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: AppColors.white.withOpacity(0.9),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tehdit Skoru: ${threat.threatLevel}%',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (threat.matchedKeywords.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Şüpheli kelimeler: ${threat.matchedKeywords.join(", ")}',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Talimatlar
              Text(
                '🚫 Bu mesajdaki linklere\nTIKLAMAYIN!',
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Tamam butonu
              SizedBox(
                width: double.infinity,
                height: 72,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.dangerRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Anladım, Kapat',
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
