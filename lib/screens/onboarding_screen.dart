// ============================================================
// SiberKalkan - Onboarding Ekranı
// Dosya Yolu: lib/screens/onboarding_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siber_kalkan/providers/app_providers.dart';
import 'package:siber_kalkan/screens/auth_screen.dart';
import 'package:siber_kalkan/utils/constants.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.shield_rounded,
      iconColor: AppColors.shieldSafe,
      title: 'Siber Koruma',
      description:
          'SiberKalkan, sizi sahte SMS\'lerden\nve dolandırıcı aramalardan korur.',
    ),
    _OnboardingPage(
      icon: Icons.sms_rounded,
      iconColor: AppColors.warningOrange,
      title: 'SMS Tarama',
      description:
          'Gelen SMS\'leri otomatik tarar,\nşüpheli mesajları anında tespit eder.',
    ),
    _OnboardingPage(
      icon: Icons.family_restroom_rounded,
      iconColor: AppColors.primaryGreen,
      title: 'Aile Bağlantısı',
      description:
          'Aileniz tehditleri takip edebilir\nve sizi uzaktan koruyabilir.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Onboarding tamamlandı — kaydet
      ref.read(localStorageProvider)?.setOnboardingComplete(true);
      ref.read(onboardingCompleteProvider.notifier).state = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Sayfa içerikleri
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // İkon
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: page.iconColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 90,
                            color: page.iconColor,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Başlık
                        Text(
                          page.title,
                          style: GoogleFonts.nunito(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Açıklama
                        Text(
                          page.description,
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            color: AppColors.grey,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Sayfa göstergeleri
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: _currentPage == index ? 30 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primaryGreen
                        : AppColors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Buton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Başla'
                        : 'Devam Et',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Atla butonu
            if (_currentPage < _pages.length - 1)
              TextButton(
                onPressed: () {
                  ref.read(localStorageProvider)?.setOnboardingComplete(true);
                  ref.read(onboardingCompleteProvider.notifier).state = true;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => const AuthScreen()),
                  );
                },
                child: Text(
                  'Atla',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    color: AppColors.grey,
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });
}
