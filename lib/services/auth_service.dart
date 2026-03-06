// ============================================================
// SiberKalkan - Kimlik Doğrulama Servisi
// Dosya Yolu: lib/services/auth_service.dart
// Firebase Auth ile email/şifre + anonim giriş
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:siber_kalkan/models/user_model.dart';
import 'package:uuid/uuid.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth? _auth;
  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;
  User? get currentUser => _auth?.currentUser;
  bool get isLoggedIn => currentUser != null;

  /// Auth servisini başlat
  void initialize() {
    try {
      _auth = FirebaseAuth.instance;
      _isAvailable = true;
      debugPrint('🔐 Auth servisi başlatıldı');
    } catch (e) {
      _isAvailable = false;
      debugPrint('🔐 Auth servisi hatası: $e');
    }
  }

  /// Email ve şifre ile kayıt ol
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!_isAvailable || _auth == null) {
      return AuthResult.offline(displayName);
    }

    try {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(displayName);

      debugPrint('✅ Kayıt başarılı: ${credential.user?.uid}');
      return AuthResult(
        success: true,
        uid: credential.user!.uid,
        displayName: displayName,
        email: email,
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Bu e-posta adresi zaten kullanımda';
          break;
        case 'weak-password':
          message = 'Şifre çok zayıf (en az 6 karakter)';
          break;
        case 'invalid-email':
          message = 'Geçersiz e-posta adresi';
          break;
        default:
          message = 'Kayıt hatası: ${e.message}';
      }
      return AuthResult(success: false, error: message);
    } catch (e) {
      return AuthResult(success: false, error: 'Bağlantı hatası: $e');
    }
  }

  /// Email ve şifre ile giriş yap
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    if (!_isAvailable || _auth == null) {
      return AuthResult(
        success: false,
        error: 'Firebase bağlantısı yok',
      );
    }

    try {
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ Giriş başarılı: ${credential.user?.uid}');
      return AuthResult(
        success: true,
        uid: credential.user!.uid,
        displayName: credential.user?.displayName ?? 'Kullanıcı',
        email: email,
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Bu e-posta ile kayıtlı kullanıcı bulunamadı';
          break;
        case 'wrong-password':
          message = 'Yanlış şifre';
          break;
        case 'invalid-email':
          message = 'Geçersiz e-posta adresi';
          break;
        case 'user-disabled':
          message = 'Bu hesap devre dışı bırakılmış';
          break;
        default:
          message = 'Giriş hatası: ${e.message}';
      }
      return AuthResult(success: false, error: message);
    } catch (e) {
      return AuthResult(success: false, error: 'Bağlantı hatası: $e');
    }
  }

  /// Anonim giriş (yaşlılar için basit mod)
  Future<AuthResult> loginAnonymously({String displayName = 'Kullanıcı'}) async {
    if (!_isAvailable || _auth == null) {
      return AuthResult.offline(displayName);
    }

    try {
      final credential = await _auth!.signInAnonymously();
      debugPrint('✅ Anonim giriş: ${credential.user?.uid}');
      return AuthResult(
        success: true,
        uid: credential.user!.uid,
        displayName: displayName,
        isAnonymous: true,
      );
    } catch (e) {
      return AuthResult.offline(displayName);
    }
  }

  /// Google ile giriş yap
  Future<AuthResult> loginWithGoogle() async {
    if (!_isAvailable || _auth == null) {
      return AuthResult.offline('Kullanıcı');
    }

    try {
      UserCredential result;

      if (kIsWeb) {
        // Web (Chrome) için Firebase'in kendi popup çözümünü kullanıyoruz
        // Bu, index.html'e meta tag ekleme zorunluluğunu ortadan kaldırır.
        final googleProvider = GoogleAuthProvider();
        result = await _auth!.signInWithPopup(googleProvider);
      } else {
        // Mobil (Android/iOS) için GoogleSignIn paketini kullanıyoruz
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          return AuthResult(success: false, error: 'Giriş iptal edildi');
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        result = await _auth!.signInWithCredential(credential);
      }

      debugPrint('✅ Google ile giriş: ${result.user?.uid}');
      return AuthResult(
        success: true,
        uid: result.user!.uid,
        displayName: result.user?.displayName ?? 'Kullanıcı',
        email: result.user?.email,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Google Giriş Hatası: ${e.code} - ${e.message}');
      if (e.code == 'popup-closed-by-user') {
        return AuthResult(success: false, error: 'Giriş penceresi kapatıldı');
      }
      return AuthResult(
        success: false, 
        error: 'Hata (${e.code}): ${e.message}',
      );
    } catch (e) {
      debugPrint('Google Sign-In genel hata: $e');
      return AuthResult(success: false, error: 'Bir hata oluştu: $e');
    }
  }

  /// Şifre sıfırlama emaili gönder
  Future<String?> resetPassword(String email) async {
    if (!_isAvailable || _auth == null) {
      return 'Firebase bağlantısı yok';
    }

    try {
      await _auth!.sendPasswordResetEmail(email: email);
      return null; // Hata yok
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı';
        case 'invalid-email':
          return 'Geçersiz e-posta adresi';
        default:
          return 'Hata: ${e.message}';
      }
    } catch (e) {
      return 'Bağlantı hatası: $e';
    }
  }

  /// Çıkış yap
  Future<void> logout() async {
    try {
      await _auth?.signOut();
      debugPrint('🔐 Çıkış yapıldı');
    } catch (e) {
      debugPrint('Çıkış hatası: $e');
    }
  }

  /// Mevcut kullanıcıdan UserModel oluştur
  UserModel? createUserModelFromAuth(String role) {
    final user = currentUser;
    if (user == null) return null;

    return UserModel(
      uid: user.uid,
      role: role,
      displayName: user.displayName ?? 'Kullanıcı',
    );
  }
}

/// Kimlik doğrulama sonucu
class AuthResult {
  final bool success;
  final String? uid;
  final String? displayName;
  final String? email;
  final String? error;
  final bool isAnonymous;
  final bool isOffline;

  AuthResult({
    required this.success,
    this.uid,
    this.displayName,
    this.email,
    this.error,
    this.isAnonymous = false,
    this.isOffline = false,
  });

  /// Çevrimdışı mod — Firebase yoksa rastgele UID ile devam
  factory AuthResult.offline(String displayName) {
    return AuthResult(
      success: true,
      uid: const Uuid().v4(),
      displayName: displayName,
      isAnonymous: true,
      isOffline: true,
    );
  }
}
