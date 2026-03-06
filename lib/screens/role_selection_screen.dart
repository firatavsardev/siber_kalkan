// ============================================================
// SiberKalkan - Rol Seçim Ekranı
// Dosya Yolu: lib/screens/role_selection_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siber_kalkan/providers/app_providers.dart';
import 'package:siber_kalkan/screens/pairing_screen.dart';
import 'package:siber_kalkan/screens/permissions_screen.dart';
import 'package:siber_kalkan/services/mock_data_service.dart';
import 'package:siber_kalkan/utils/constants.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Başlık
              Text(
                'Kimsiniz?',
                style: GoogleFonts.nunito(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Lütfen rolünüzü seçin',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 48),

              // Yaşlı Kullanıcı Kartı
              Expanded(
                child: _RoleCard(
                  icon: Icons.person_rounded,
                  emoji: '👴',
                  title: 'Yaşlı Kullanıcı',
                  description: 'Dolandırıcılara karşı\nkorunmak istiyorum',
                  color: AppColors.primaryGreen,
                  onTap: () {
                    final user = MockDataService.createUser(
                      role: AppConstants.roleElderly,
                      displayName: 'Kullanıcı',
                    );
                    ref.read(userProvider.notifier).setUser(user);
                    ref.read(selectedRoleProvider.notifier).state =
                        AppConstants.roleElderly;
                    ref.read(localStorageProvider)?.setSelectedRole(AppConstants.roleElderly);

                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const PermissionsScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Aile Üyesi Kartı
              Expanded(
                child: _RoleCard(
                  icon: Icons.family_restroom_rounded,
                  emoji: '👨‍👩‍👧',
                  title: 'Aile Üyesi',
                  description: 'Yakınımı uzaktan\nkorumak istiyorum',
                  color: const Color(0xFF1565C0),
                  onTap: () {
                    final user = MockDataService.createUser(
                      role: AppConstants.roleGuardian,
                      displayName: 'Aile Üyesi',
                    );
                    ref.read(userProvider.notifier).setUser(user);
                    ref.read(selectedRoleProvider.notifier).state =
                        AppConstants.roleGuardian;
                    ref.read(localStorageProvider)?.setSelectedRole(AppConstants.roleGuardian);

                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const PairingScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String emoji;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
            color: color.withOpacity(0.05),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji ve İkon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Başlık
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),

              // Açıklama
              Text(
                description,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  color: AppColors.grey,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
