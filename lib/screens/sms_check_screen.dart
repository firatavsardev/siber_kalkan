// ============================================================
// SiberKalkan - SMS Kontrol Ekranı
// Dosya Yolu: lib/screens/sms_check_screen.dart
// Kullanıcı SMS metni yapıştırarak manuel kontrol yapabilir
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siber_kalkan/providers/app_providers.dart';
import 'package:siber_kalkan/screens/threat_alert_screen.dart';
import 'package:siber_kalkan/services/sms_analysis_service.dart';
import 'package:siber_kalkan/utils/constants.dart';
import 'package:siber_kalkan/widgets/big_button.dart';

class SmsCheckScreen extends ConsumerStatefulWidget {
  const SmsCheckScreen({super.key});

  @override
  ConsumerState<SmsCheckScreen> createState() => _SmsCheckScreenState();
}

class _SmsCheckScreenState extends ConsumerState<SmsCheckScreen> {
  final TextEditingController _smsController = TextEditingController();
  ThreatAnalysisResult? _result;
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _smsController.dispose();
    super.dispose();
  }

  Future<void> _analyzeSms() async {
    if (_smsController.text.trim().isEmpty) return;

    setState(() => _isAnalyzing = true);

    // Gerçekçi bir gecikme simüle et
    await Future.delayed(const Duration(milliseconds: 800));

    final result = SmsAnalysisService.analyzeSms(_smsController.text);
    setState(() {
      _result = result;
      _isAnalyzing = false;
    });

    // Tehlikeli ise ThreatLog oluştur ve kaydet
    if (result.isDangerous) {
      final log = SmsAnalysisService.createThreatLog(
        sender: 'Manuel Kontrol',
        content: _smsController.text,
        result: result,
      );
      ref.read(threatLogsProvider.notifier).addThreat(log);

      // Tam ekran uyarı göster
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ThreatAlertScreen(threat: log),
          ),
        );
      }
    }
  }

  Color get _resultColor {
    if (_result == null) return AppColors.grey;
    if (_result!.isDangerous) return AppColors.dangerRed;
    if (_result!.isSuspicious) return AppColors.warningOrange;
    return AppColors.primaryGreen;
  }

  String get _resultText {
    if (_result == null) return '';
    if (_result!.isDangerous) return '🚨 TEHLİKELİ';
    if (_result!.isSuspicious) return '⚠️ ŞÜPHELİ';
    return '✅ GÜVENLİ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'SMS Kontrol',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Açıklama
            Text(
              'Şüpheli bir SMS aldınız mı?',
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SMS metnini aşağıya yapıştırın, biz kontrol edelim.',
              style: GoogleFonts.nunito(
                fontSize: 18,
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // SMS giriş alanı
            TextField(
              controller: _smsController,
              maxLines: 6,
              style: GoogleFonts.nunito(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'SMS metnini buraya yapıştırın...',
                hintStyle: GoogleFonts.nunito(
                  fontSize: 18,
                  color: AppColors.grey.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primaryGreen,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 20),

            // Kontrol Et butonu
            _isAnalyzing
                ? const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                        ),
                        SizedBox(height: 12),
                        Text('Analiz ediliyor...'),
                      ],
                    ),
                  )
                : BigButton(
                    text: 'Kontrol Et',
                    icon: Icons.search_rounded,
                    onPressed: _analyzeSms,
                  ),
            const SizedBox(height: 24),

            // Sonuç
            if (_result != null) ...[
              // Sonuç başlığı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _resultColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _resultColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _resultText,
                      style: GoogleFonts.nunito(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _resultColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tehdit Skoru: ${_result!.threatLevel}%',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        color: _resultColor,
                      ),
                    ),

                    // İlerleme çubuğu
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _result!.threatLevel / 100,
                        backgroundColor: AppColors.grey.withOpacity(0.2),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_resultColor),
                        minHeight: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Eşleşen kelimeler
              if (_result!.matchedKeywords.isNotEmpty) ...[
                Text(
                  'Tespit Edilen Şüpheli Kelimeler:',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _result!.matchedKeywords.map((keyword) {
                    return Chip(
                      label: Text(
                        keyword,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: AppColors.dangerRed,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Tespit edilen URL'ler
              if (_result!.detectedUrls.isNotEmpty) ...[
                Text(
                  'Tespit Edilen Linkler:',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...(_result!.detectedUrls.map((url) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.link_off_rounded,
                          color: AppColors.warningOrange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            url,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: AppColors.warningOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                })),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
