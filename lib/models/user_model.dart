// ============================================================
// SiberKalkan - Kullanıcı Modeli
// Dosya Yolu: lib/models/user_model.dart
// ============================================================

class UserModel {
  final String uid;
  final String role; // 'elderly' veya 'guardian'
  final String displayName;
  final String? pairedWith; // Eşleşilen kullanıcının uid'si
  final String? pairingCode; // 6 haneli eşleşme kodu
  final String? fcmToken;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.role,
    required this.displayName,
    this.pairedWith,
    this.pairingCode,
    this.fcmToken,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// JSON'a dönüştür (Firestore için hazır)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'role': role,
      'displayName': displayName,
      'pairedWith': pairedWith,
      'pairingCode': pairingCode,
      'fcmToken': fcmToken,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// JSON'dan oluştur
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      role: json['role'] as String,
      displayName: json['displayName'] as String,
      pairedWith: json['pairedWith'] as String?,
      pairingCode: json['pairingCode'] as String?,
      fcmToken: json['fcmToken'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Kopyala ve güncelle
  UserModel copyWith({
    String? uid,
    String? role,
    String? displayName,
    String? pairedWith,
    String? pairingCode,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      pairedWith: pairedWith ?? this.pairedWith,
      pairingCode: pairingCode ?? this.pairingCode,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }

  bool get isElderly => role == 'elderly';
  bool get isGuardian => role == 'guardian';
  bool get isPaired => pairedWith != null && pairedWith!.isNotEmpty;
}
