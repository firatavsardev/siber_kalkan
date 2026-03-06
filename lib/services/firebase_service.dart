// ============================================================
// SiberKalkan - Firebase Servisi
// Dosya Yolu: lib/services/firebase_service.dart
// Firestore ile eşleşme, tehdit senkronizasyonu + çevrimdışı
// ============================================================

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siber_kalkan/models/threat_log.dart';
import 'package:siber_kalkan/models/user_model.dart';
import 'package:siber_kalkan/services/mock_data_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isAvailable = false;
  FirebaseFirestore? _firestore;

  bool get isAvailable => _isAvailable;

  /// Firebase'i başlat (main.dart'tan çağrılır)
  void initialize() {
    try {
      _firestore = FirebaseFirestore.instance;

      // Offline persistence'ı etkinleştir
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      _isAvailable = true;
      debugPrint('Firebase: Firestore bağlantısı başarılı');
    } catch (e) {
      _isAvailable = false;
      debugPrint('Firebase: Kullanılamıyor — $e');
    }
  }

  // ============================================================
  // EŞLEŞME SİSTEMİ
  // ============================================================

  /// Guardian: Eşleşme kodu oluştur ve Firestore'a kaydet
  Future<String?> createPairingCode(UserModel user) async {
    if (!_isAvailable || _firestore == null) {
      debugPrint('Firebase yok — mock kod üretiliyor');
      return MockDataService.generatePairingCode();
    }

    try {
      final code = MockDataService.generatePairingCode();

      await _firestore!.collection('pairing_codes').doc(code).set({
        'creatorUid': user.uid,
        'creatorRole': user.role,
        'creatorName': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'isUsed': false,
      });

      // Kullanıcı belgesini de güncelle
      await _firestore!.collection('users').doc(user.uid).set(
            user.copyWith(pairingCode: code).toJson(),
            SetOptions(merge: true),
          );

      debugPrint('Eşleşme kodu oluşturuldu: $code');
      return code;
    } catch (e) {
      debugPrint('Eşleşme kodu oluşturma hatası: $e');
      return MockDataService.generatePairingCode();
    }
  }

  /// Elderly: Kodla eşleş
  Future<Map<String, dynamic>?> joinWithCode(
      String code, UserModel user) async {
    if (!_isAvailable || _firestore == null) {
      debugPrint('Firebase yok — mock eşleşme');
      return {'success': true, 'pairedWith': 'mock_user', 'mock': true};
    }

    try {
      final codeDoc =
          await _firestore!.collection('pairing_codes').doc(code).get();

      if (!codeDoc.exists) {
        return {'success': false, 'error': 'Kod bulunamadı'};
      }

      final codeData = codeDoc.data()!;
      if (codeData['isUsed'] == true) {
        return {'success': false, 'error': 'Bu kod zaten kullanılmış'};
      }

      final creatorUid = codeData['creatorUid'] as String;

      // Kodu kullanıldı olarak işaretle
      await _firestore!.collection('pairing_codes').doc(code).update({
        'isUsed': true,
        'usedBy': user.uid,
        'usedAt': FieldValue.serverTimestamp(),
      });

      // İki kullanıcıyı eşleştir
      await _firestore!.collection('users').doc(user.uid).set(
            user.copyWith(pairedWith: creatorUid).toJson(),
            SetOptions(merge: true),
          );

      await _firestore!.collection('users').doc(creatorUid).update({
        'pairedWith': user.uid,
      });

      debugPrint('Eşleşme başarılı: ${user.uid} ↔ $creatorUid');
      return {
        'success': true,
        'pairedWith': creatorUid,
        'creatorName': codeData['creatorName'] ?? 'Aile Üyesi',
      };
    } catch (e) {
      debugPrint('Eşleşme hatası: $e');
      return {'success': false, 'error': 'Bağlantı hatası: $e'};
    }
  }

  // ============================================================
  // TEHDİT SENKRONİZASYONU
  // ============================================================

  /// Tehdit logunu Firestore'a kaydet
  Future<void> saveThreatToFirestore(String userUid, ThreatLog threat) async {
    if (!_isAvailable || _firestore == null) return;

    try {
      await _firestore!
          .collection('users')
          .doc(userUid)
          .collection('threats')
          .doc(threat.id)
          .set(threat.toFirebaseMap());
    } catch (e) {
      debugPrint('Firestore tehdit kaydetme hatası: $e');
    }
  }

  /// Birden fazla tehdidi senkronize et
  Future<void> syncThreats(String userUid, List<ThreatLog> threats) async {
    if (!_isAvailable || _firestore == null) return;

    try {
      final batch = _firestore!.batch();
      final threatsRef =
          _firestore!.collection('users').doc(userUid).collection('threats');

      for (final threat in threats) {
        batch.set(threatsRef.doc(threat.id), threat.toFirebaseMap());
      }

      await batch.commit();
      debugPrint('${threats.length} tehdit Firestore\'a senkronize edildi');
    } catch (e) {
      debugPrint('Firestore senkronizasyon hatası: $e');
    }
  }

  /// Eşleşmiş kullanıcının tehditlerini dinle (Guardian için)
  Stream<List<ThreatLog>> watchPairedUserThreats(String pairedUserUid) {
    if (!_isAvailable || _firestore == null) {
      return Stream.value([]);
    }

    return _firestore!
        .collection('users')
        .doc(pairedUserUid)
        .collection('threats')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ThreatLog.fromJson(doc.data());
      }).toList();
    });
  }

  /// Kullanıcı bilgisini Firestore'a kaydet
  Future<void> saveUserToFirestore(UserModel user) async {
    if (!_isAvailable || _firestore == null) return;

    try {
      await _firestore!
          .collection('users')
          .doc(user.uid)
          .set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore kullanıcı kaydetme hatası: $e');
    }
  }

  // ============================================================
  // BAĞLANTI DURUMU İZLEME
  // ============================================================

  /// Bağlantı durumunu kontrol et
  Future<bool> checkConnection() async {
    if (!_isAvailable || _firestore == null) return false;

    try {
      await _firestore!
          .collection('_health')
          .doc('check')
          .get(const GetOptions(source: Source.server));
      return true;
    } catch (e) {
      return false;
    }
  }
}
