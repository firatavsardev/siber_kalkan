import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siber_kalkan/providers/app_providers.dart';
import 'package:siber_kalkan/screens/onboarding_screen.dart';
import 'package:siber_kalkan/screens/elderly_home_screen.dart';
import 'package:siber_kalkan/screens/guardian_dashboard_screen.dart';
import 'package:siber_kalkan/screens/role_selection_screen.dart';
import 'package:siber_kalkan/screens/auth_screen.dart';
import 'package:siber_kalkan/services/local_storage_service.dart';
import 'package:siber_kalkan/services/firebase_service.dart';
import 'package:siber_kalkan/services/auth_service.dart';
import 'package:siber_kalkan/services/notification_service.dart';
import 'package:siber_kalkan/utils/constants.dart';

// Firebase Core — try/catch ile kullanılır
import 'package:firebase_core/firebase_core.dart';
import 'package:siber_kalkan/firebase_options.dart';

// ============================================================
// SiberKalkan - Ana Dosya
// Dosya Yolu: lib/main.dart
// ============================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. SharedPreferences başlat
  final prefs = await SharedPreferences.getInstance();
  final localStorage = LocalStorageService(prefs);

  // 2. Firebase başlat
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
    debugPrint('✅ Firebase başlatıldı');
  } catch (e) {
    debugPrint('⚠️ Firebase başlatılamadı: $e');
  }

  // 3. Firebase servisini başlat
  final firebaseService = FirebaseService();
  if (firebaseReady) {
    firebaseService.initialize();
  }

  // 4. Auth servisini başlat
  final authService = AuthService();
  if (firebaseReady) {
    authService.initialize();
  }

  // 5. Bildirim servisini başlat
  final notificationService = NotificationService();
  if (firebaseReady) {
    await notificationService.initialize();
  }

  // 6. Çevrimdışı senkronizasyon — bekleyen verileri gönder
  if (firebaseReady) {
    final user = localStorage.loadUser();
    if (user != null) {
      final pending = localStorage.getPendingThreats();
      if (pending.isNotEmpty) {
        await firebaseService.syncThreats(user.uid, pending);
        await localStorage.clearPendingThreats();
        debugPrint('🔄 ${pending.length} bekleyen tehdit senkronize edildi');
      }
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
        firebaseServiceProvider.overrideWithValue(firebaseService),
        authServiceProvider.overrideWithValue(authService),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const SiberKalkanApp(),
    ),
  );
}

class SiberKalkanApp extends StatelessWidget {
  const SiberKalkanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.nunitoTextTheme(),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ============================================================
// Açılış Ekranı (Splash) — 2 saniye sonra doğru ekrana yönlendirir
// ============================================================
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // 2 saniye sonra doğru ekrana yönlendir
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  void _navigateToNextScreen() {
    final storage = ref.read(localStorageProvider);
    final onboardingDone = storage?.onboardingComplete ?? false;
    final savedRole = storage?.selectedRole;
    final savedUser = ref.read(userProvider);

    Widget nextScreen;

    if (!onboardingDone) {
      // İlk kez açılıyor — onboarding göster
      nextScreen = const OnboardingScreen();
    } else if (savedUser == null) {
      // Onboarding tamam ama kullanıcı yok — auth ekranına git
      nextScreen = const AuthScreen();
    } else if (savedRole == null || savedRole.isEmpty) {
      // Kullanıcı var ama rol seçilmemiş
      nextScreen = const RoleSelectionScreen();
    } else if (savedRole == AppConstants.roleElderly) {
      nextScreen = const ElderlyHomeScreen();
    } else {
      nextScreen = const GuardianDashboardScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Kalkan İkonu
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.shieldSafe.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield,
                  size: 100,
                  color: AppColors.shieldSafe,
                ),
              ),
              const SizedBox(height: 32),

              // Uygulama Adı
              Text(
                AppConstants.appName,
                style: GoogleFonts.nunito(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 12),

              // Alt Başlık
              Text(
                'Siber Dolandırıcılığa Karşı Kalkanınız',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Yükleniyor göstergesi
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: AppColors.primaryGreen,
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Yükleniyor...',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
