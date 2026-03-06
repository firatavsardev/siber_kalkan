// ============================================================
// SiberKalkan - Eşleşme Ekranı
// Dosya Yolu: lib/screens/pairing_screen.dart
// Firebase ile gerçek eşleşme + Firebase yoksa mock mod
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siber_kalkan/providers/app_providers.dart';
import 'package:siber_kalkan/screens/elderly_home_screen.dart';
import 'package:siber_kalkan/screens/guardian_dashboard_screen.dart';
import 'package:siber_kalkan/utils/constants.dart';
import 'package:siber_kalkan/widgets/big_button.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? _generatedCode;
  bool _isPaired = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _generateCode() async {
    setState(() => _isLoading = true);

    final firebase = ref.read(firebaseServiceProvider);
    final user = ref.read(userProvider);

    if (user != null) {
      final code = await firebase.createPairingCode(user);
      if (code != null) {
        setState(() {
          _generatedCode = code;
          _isLoading = false;
        });
        ref.read(pairingCodeProvider.notifier).state = code;
        ref.read(userProvider.notifier).setPairingCode(code);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pair() async {
    final code = _codeController.text.trim();
    if (code.length != AppConstants.pairingCodeLength) {
      setState(() => _errorMessage = '6 haneli kod girin');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final firebase = ref.read(firebaseServiceProvider);
    final user = ref.read(userProvider);

    if (user != null) {
      final result = await firebase.joinWithCode(code, user);

      if (result != null && result['success'] == true) {
        final pairedWith = result['pairedWith'] as String;
        ref.read(userProvider.notifier).updatePairing(pairedWith);
        setState(() {
          _isPaired = true;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Eşleşme başarılı! ✓',
                style: GoogleFonts.nunito(fontSize: 18),
              ),
              backgroundColor: AppColors.primaryGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result?['error'] ?? 'Eşleşme başarısız';
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _goToHome() {
    final role = ref.read(selectedRoleProvider);
    Widget screen;

    if (role == AppConstants.roleElderly) {
      screen = const ElderlyHomeScreen();
    } else {
      screen = const GuardianDashboardScreen();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(selectedRoleProvider);
    final isGuardian = role == AppConstants.roleGuardian;
    final firebase = ref.watch(firebaseServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'Eşleşme',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // İkon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.link_rounded,
                  size: 60,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                isGuardian
                    ? 'Eşleşme Kodu Oluşturun'
                    : 'Eşleşme Kodunu Girin',
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                isGuardian
                    ? 'Bu kodu yaşlı yakınızla paylaşın'
                    : 'Aile üyenizden aldığınız 6 haneli kodu girin',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  color: AppColors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              // Firebase durumu göstergesi
              if (!firebase.isAvailable) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '⚠️ Çevrimdışı mod — lokal eşleşme',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.warningOrange,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),

              // Guardian: Kod oluştur
              if (isGuardian) ...[
                if (_isLoading)
                  const CircularProgressIndicator(
                      color: AppColors.primaryGreen)
                else if (_generatedCode != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _generatedCode!,
                      style: GoogleFonts.nunito(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                        letterSpacing: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bu kodu yaşlı yakınıza verin',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: AppColors.grey,
                    ),
                  ),
                ] else
                  BigButton(
                    text: 'Kod Oluştur',
                    icon: Icons.qr_code_rounded,
                    onPressed: _generateCode,
                  ),
              ],

              // Elderly: Kod gir
              if (!isGuardian) ...[
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: AppConstants.pairingCodeLength,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: GoogleFonts.nunito(
                      fontSize: 36,
                      color: AppColors.grey.withOpacity(0.3),
                      letterSpacing: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: AppColors.primaryGreen,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: AppColors.primaryGreen,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 24,
                    ),
                  ),
                ),

                // Hata mesajı
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: AppColors.dangerRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                if (_isLoading)
                  const CircularProgressIndicator(
                      color: AppColors.primaryGreen)
                else if (!_isPaired)
                  BigButton(
                    text: 'Eşleş',
                    icon: Icons.link_rounded,
                    onPressed: _pair,
                  ),
                if (_isPaired)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primaryGreen,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Eşleşme Başarılı!',
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],

              const Spacer(),

              // Devam butonu
              BigButton(
                text: _isPaired || isGuardian
                    ? 'Devam Et'
                    : 'Eşleşmeden Devam Et',
                icon: Icons.arrow_forward_rounded,
                color: _isPaired || (isGuardian && _generatedCode != null)
                    ? AppColors.primaryGreen
                    : AppColors.grey,
                onPressed: _goToHome,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
