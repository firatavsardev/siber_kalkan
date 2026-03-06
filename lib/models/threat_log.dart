// ============================================================
// SiberKalkan - Tehdit Logu Modeli
// Dosya Yolu: lib/models/threat_log.dart
// ============================================================

class ThreatLog {
  final String id;
  final String type; // 'sms_phishing' veya 'scam_call'
  final String sender; // Gönderici numara/isim
  final String content; // SMS içeriği
  final int threatLevel; // 0-100 arası tehdit skoru
  final List<String> matchedKeywords; // Eşleşen zararlı kelimeler
  final List<String> matchedUrls; // Tespit edilen şüpheli URL'ler
  final DateTime timestamp;
  final bool isRead;

  ThreatLog({
    required this.id,
    required this.type,
    required this.sender,
    required this.content,
    required this.threatLevel,
    required this.matchedKeywords,
    this.matchedUrls = const [],
    DateTime? timestamp,
    this.isRead = false,
  }) : timestamp = timestamp ?? DateTime.now();

  /// JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'sender': sender,
      'content': content,
      'threatLevel': threatLevel,
      'matchedKeywords': matchedKeywords,
      'matchedUrls': matchedUrls,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  /// Gönderici numarasını maskele (örn: +90555****12)
  String get maskedSender {
    if (sender.length < 5) return '****';
    
    // Telefon numarası formatı
    if (sender.startsWith('+') && sender.length > 8) {
      return '${sender.substring(0, 6)}****${sender.substring(sender.length - 2)}';
    }
    // Normal numara veya kısa isim formatı
    return '${sender.substring(0, 3)}****${sender.substring(sender.length - 2)}';
  }

  /// Firebase'e yazılacak KVKK uyumlu anonimleştirilmiş veri
  Map<String, dynamic> toFirebaseMap() {
    return {
      'id': id,
      'type': type,
      'sender': maskedSender,
      'content': '[GİZLİLİK NEDENİYLE GİZLENDİ]',
      'threatLevel': threatLevel,
      'matchedKeywords': matchedKeywords,
      'matchedUrls': matchedUrls,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  /// JSON'dan oluştur
  factory ThreatLog.fromJson(Map<String, dynamic> json) {
    return ThreatLog(
      id: json['id'] as String,
      type: json['type'] as String,
      sender: json['sender'] as String,
      content: json['content'] as String,
      threatLevel: json['threatLevel'] as int,
      matchedKeywords: List<String>.from(json['matchedKeywords'] as List),
      matchedUrls: json['matchedUrls'] != null
          ? List<String>.from(json['matchedUrls'] as List)
          : [],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  ThreatLog copyWith({bool? isRead}) {
    return ThreatLog(
      id: id,
      type: type,
      sender: sender,
      content: content,
      threatLevel: threatLevel,
      matchedKeywords: matchedKeywords,
      matchedUrls: matchedUrls,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Tehdit seviyesi açıklaması
  String get threatLevelText {
    if (threatLevel >= 80) return 'Çok Tehlikeli';
    if (threatLevel >= 60) return 'Tehlikeli';
    if (threatLevel >= 40) return 'Şüpheli';
    if (threatLevel >= 20) return 'Düşük Risk';
    return 'Güvenli';
  }

  bool get isDangerous => threatLevel >= 60;
  bool get isSuspicious => threatLevel >= 40;
}
