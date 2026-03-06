// ============================================================
// SiberKalkan - Riverpod Providerları
// Dosya Yolu: lib/providers/app_providers.dart
// Lokal depolama, Firebase, Auth ve Bildirim entegrasyonlu
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:siber_kalkan/models/threat_log.dart';
import 'package:siber_kalkan/models/user_model.dart';
import 'package:siber_kalkan/services/local_storage_service.dart';
import 'package:siber_kalkan/services/firebase_service.dart';
import 'package:siber_kalkan/services/auth_service.dart';
import 'package:siber_kalkan/services/notification_service.dart';
import 'package:siber_kalkan/services/call_blocker_service.dart';

// --- Lokal Depolama Provider ---
// main.dart'ta override edilir
final localStorageProvider = Provider<LocalStorageService?>((ref) => null);

// --- Firebase Provider ---
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// --- Auth Provider ---
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// --- Bildirim Provider ---
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// --- Arama Engelleme Provider ---
final callBlockerProvider = Provider<CallBlockerService>((ref) {
  return CallBlockerService();
});

// --- Kullanıcı Provider ---
final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  final storage = ref.watch(localStorageProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  return UserNotifier(storage: storage, firebase: firebase);
});

class UserNotifier extends StateNotifier<UserModel?> {
  final LocalStorageService? storage;
  final FirebaseService firebase;

  UserNotifier({this.storage, required this.firebase}) : super(null) {
    // Başlangıçta diskten yükle
    _loadFromDisk();
  }

  void _loadFromDisk() {
    final saved = storage?.loadUser();
    if (saved != null) {
      state = saved;
    }
  }

  void setUser(UserModel user) {
    state = user;
    _saveToDisk();
    firebase.saveUserToFirestore(user);
  }

  void clearUser() {
    state = null;
    storage?.clearUser();
  }

  void updatePairing(String pairedWith) {
    if (state != null) {
      state = state!.copyWith(pairedWith: pairedWith);
      _saveToDisk();
      firebase.saveUserToFirestore(state!);
    }
  }

  void setPairingCode(String code) {
    if (state != null) {
      state = state!.copyWith(pairingCode: code);
      _saveToDisk();
    }
  }

  void updateRole(String role) {
    if (state != null) {
      state = state!.copyWith(role: role);
      _saveToDisk();
      firebase.saveUserToFirestore(state!);
    }
  }

  void updateFcmToken(String token) {
    if (state != null) {
      state = state!.copyWith(fcmToken: token);
      _saveToDisk();
      firebase.saveUserToFirestore(state!);
    }
  }

  void _saveToDisk() {
    if (state != null) {
      storage?.saveUser(state!);
    }
  }
}

// --- Tehdit Logları Provider ---
final threatLogsProvider =
    StateNotifierProvider<ThreatLogsNotifier, List<ThreatLog>>((ref) {
  final storage = ref.watch(localStorageProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  final user = ref.watch(userProvider);
  return ThreatLogsNotifier(storage: storage, firebase: firebase, user: user);
});

class ThreatLogsNotifier extends StateNotifier<List<ThreatLog>> {
  final LocalStorageService? storage;
  final FirebaseService firebase;
  final UserModel? user;

  ThreatLogsNotifier({
    this.storage,
    required this.firebase,
    this.user,
  }) : super([]) {
    _loadFromDisk();
  }

  void _loadFromDisk() {
    final saved = storage?.loadThreatLogs();
    if (saved != null && saved.isNotEmpty) {
      state = saved;
    }
  }

  void addThreat(ThreatLog log) {
    state = [log, ...state];
    _saveToDisk();
    // Firebase'e de kaydet
    if (user != null) {
      firebase.saveThreatToFirestore(user!.uid, log);
    }
  }

  void markAsRead(String id) {
    state = [
      for (final log in state)
        if (log.id == id) log.copyWith(isRead: true) else log,
    ];
    _saveToDisk();
  }

  void clearAll() {
    state = [];
    _saveToDisk();
  }

  void addMultipleThreats(List<ThreatLog> logs) {
    // Mevcut ID'leri kontrol et (tekrar ekleme)
    final existingIds = state.map((t) => t.id).toSet();
    final newLogs = logs.where((l) => !existingIds.contains(l.id)).toList();
    if (newLogs.isNotEmpty) {
      state = [...newLogs, ...state];
      _saveToDisk();
    }
  }

  void _saveToDisk() {
    storage?.saveThreatLogs(state);
  }

  int get unreadCount => state.where((log) => !log.isRead).length;
  int get dangerousCount => state.where((log) => log.isDangerous).length;
}

// --- Kalkan Durumu Provider ---
// true = güvenli (yeşil), false = tehdit var (kırmızı)
final shieldStatusProvider = Provider<bool>((ref) {
  final threats = ref.watch(threatLogsProvider);
  final recentDangerous = threats.where((t) {
    final isRecent = DateTime.now().difference(t.timestamp).inHours < 24;
    return t.isDangerous && !t.isRead && isRecent;
  });
  return recentDangerous.isEmpty;
});

// --- Seçilen Rol Provider ---
final selectedRoleProvider = StateProvider<String?>((ref) {
  final storage = ref.watch(localStorageProvider);
  return storage?.selectedRole;
});

// --- Eşleşme Kodu Provider ---
final pairingCodeProvider = StateProvider<String?>((ref) => null);

// --- Onboarding Tamamlandı mı? ---
final onboardingCompleteProvider = StateProvider<bool>((ref) {
  final storage = ref.watch(localStorageProvider);
  return storage?.onboardingComplete ?? false;
});

// --- Otomatik SMS Tarama Provider ---
final autoScanEnabledProvider = StateProvider<bool>((ref) {
  final storage = ref.watch(localStorageProvider);
  return storage?.autoScanEnabled ?? false;
});

// --- Arama Engelleme Provider ---
final callBlockEnabledProvider = StateProvider<bool>((ref) => false);
