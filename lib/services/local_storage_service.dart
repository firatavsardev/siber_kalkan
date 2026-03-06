// ============================================================
// SiberKalkan - Lokal Depolama Servisi
// Dosya Yolu: lib/services/local_storage_service.dart
// SharedPreferences ile veri kalıcılığı + çevrimdışı sync
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siber_kalkan/models/threat_log.dart';
import 'package:siber_kalkan/models/user_model.dart';

class LocalStorageService {
  static const String _threatLogsKey = 'siber_kalkan_threat_logs';
  static const String _userKey = 'siber_kalkan_user';
  static const String _settingsKey = 'siber_kalkan_settings';
  static const String _onboardingCompleteKey = 'siber_kalkan_onboarding';
  static const String _selectedRoleKey = 'siber_kalkan_role';
  static const String _pendingThreatsKey = 'siber_kalkan_pending_threats';
  static const String _installDateKey = 'siber_kalkan_install_date';
  static const String _blockedNumbersKey = 'siber_kalkan_blocked_numbers';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs) {
    // İlk kurulum tarihini kaydet
    if (_prefs.getString(_installDateKey) == null) {
      _prefs.setString(_installDateKey, DateTime.now().toIso8601String());
    }
  }

  // --- Tehdit Logları ---

  /// Tehdit loglarını diske kaydet
  Future<void> saveThreatLogs(List<ThreatLog> logs) async {
    final jsonList = logs.map((log) => jsonEncode(log.toJson())).toList();
    await _prefs.setStringList(_threatLogsKey, jsonList);
  }

  /// Tehdit loglarını diskten yükle
  List<ThreatLog> loadThreatLogs() {
    final jsonList = _prefs.getStringList(_threatLogsKey);
    if (jsonList == null || jsonList.isEmpty) return [];

    return jsonList.map((jsonStr) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ThreatLog.fromJson(map);
    }).toList();
  }

  // --- Kullanıcı Bilgisi ---

  /// Kullanıcı verisini diske kaydet
  Future<void> saveUser(UserModel user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Kullanıcı verisini diskten yükle
  UserModel? loadUser() {
    final jsonStr = _prefs.getString(_userKey);
    if (jsonStr == null) return null;

    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return UserModel.fromJson(map);
  }

  /// Kullanıcı verisini sil
  Future<void> clearUser() async {
    await _prefs.remove(_userKey);
  }

  // --- Ayarlar ---

  /// Otomatik SMS tarama açık mı?
  bool get autoScanEnabled => _prefs.getBool('auto_scan_enabled') ?? false;

  Future<void> setAutoScanEnabled(bool value) async {
    await _prefs.setBool('auto_scan_enabled', value);
  }

  /// Onboarding tamamlandı mı?
  bool get onboardingComplete =>
      _prefs.getBool(_onboardingCompleteKey) ?? false;

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(_onboardingCompleteKey, value);
  }

  /// Seçilen rol
  String? get selectedRole => _prefs.getString(_selectedRoleKey);

  Future<void> setSelectedRole(String role) async {
    await _prefs.setString(_selectedRoleKey, role);
  }

  /// Kurulum tarihi
  DateTime get installDate {
    final str = _prefs.getString(_installDateKey);
    return str != null ? DateTime.parse(str) : DateTime.now();
  }

  // --- Çevrimdışı Senkronizasyon Kuyruğu ---

  /// Bekleyen tehditleri kaydet (Firebase geri gelince gönderilecek)
  Future<void> addPendingThreat(ThreatLog threat) async {
    final pending = getPendingThreats();
    pending.add(threat);
    final jsonList = pending.map((t) => jsonEncode(t.toJson())).toList();
    await _prefs.setStringList(_pendingThreatsKey, jsonList);
  }

  /// Bekleyen tehditleri yükle
  List<ThreatLog> getPendingThreats() {
    final jsonList = _prefs.getStringList(_pendingThreatsKey);
    if (jsonList == null || jsonList.isEmpty) return [];

    return jsonList.map((jsonStr) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ThreatLog.fromJson(map);
    }).toList();
  }

  /// Bekleyen tehditleri temizle (sync sonrası)
  Future<void> clearPendingThreats() async {
    await _prefs.remove(_pendingThreatsKey);
  }

  /// Bekleyen tehdit var mı?
  bool get hasPendingSync {
    final list = _prefs.getStringList(_pendingThreatsKey);
    return list != null && list.isNotEmpty;
  }

  // --- Engellenen Numaralar ---

  /// Engellenen numaraları yükle
  List<String> get blockedNumbers =>
      _prefs.getStringList(_blockedNumbersKey) ?? [];

  /// Engellenen numara ekle
  Future<void> addBlockedNumber(String number) async {
    final list = blockedNumbers;
    if (!list.contains(number)) {
      list.add(number);
      await _prefs.setStringList(_blockedNumbersKey, list);
    }
  }

  /// Engellenen numara kaldır
  Future<void> removeBlockedNumber(String number) async {
    final list = blockedNumbers;
    list.remove(number);
    await _prefs.setStringList(_blockedNumbersKey, list);
  }

  // --- Genel ---

  /// Tüm verileri sil (fabrika ayarlarına dön)
  Future<void> clearAll() async {
    await _prefs.remove(_threatLogsKey);
    await _prefs.remove(_userKey);
    await _prefs.remove(_settingsKey);
    await _prefs.remove(_onboardingCompleteKey);
    await _prefs.remove(_selectedRoleKey);
    await _prefs.remove('auto_scan_enabled');
    await _prefs.remove(_pendingThreatsKey);
    await _prefs.remove(_blockedNumbersKey);
  }
}
