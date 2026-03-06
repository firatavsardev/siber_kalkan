// ============================================================
// SiberKalkan - Gelişmiş SMS Analiz Servisi
// Dosya Yolu: lib/services/sms_analysis_service.dart
// Çok katmanlı heuristik motor ile AI-benzeri analiz
// ============================================================

import 'package:siber_kalkan/models/threat_log.dart';
import 'package:siber_kalkan/services/ai_service.dart';
import 'package:siber_kalkan/utils/constants.dart';
import 'package:uuid/uuid.dart';

/// SMS analiz sonucu
class ThreatAnalysisResult {
  final int threatLevel; // 0-100
  final List<String> matchedKeywords;
  final List<String> detectedUrls;
  final bool hasSuspiciousDomain;
  final Map<String, double> categoryScores;
  final List<String> reasons;
  final bool isTrustedSender;
  final bool hasPersonalInfoRequest;
  final bool hasFakeBankReference;

  ThreatAnalysisResult({
    required this.threatLevel,
    required this.matchedKeywords,
    required this.detectedUrls,
    required this.hasSuspiciousDomain,
    this.categoryScores = const {},
    this.reasons = const [],
    this.isTrustedSender = false,
    this.hasPersonalInfoRequest = false,
    this.hasFakeBankReference = false,
  });

  bool get isDangerous => threatLevel >= 60;
  bool get isSuspicious => threatLevel >= 40;
  bool get isSafe => threatLevel < 40;

  String get riskLabel {
    if (threatLevel >= 80) return 'Çok Tehlikeli';
    if (threatLevel >= 60) return 'Tehlikeli';
    if (threatLevel >= 40) return 'Şüpheli';
    if (threatLevel >= 20) return 'Düşük Risk';
    return 'Güvenli';
  }
}

/// Çok katmanlı SMS analiz servisi — AI-benzeri heuristik motor
class SmsAnalysisService {
  static const _uuid = Uuid();

  // URL tespit eden RegExp
  static final RegExp _urlRegex = RegExp(
    r'https?://[^\s<>"]+|www\.[^\s<>"]+',
    caseSensitive: false,
  );

  /// Ana analiz fonksiyonu — çok katmanlı skor hesaplama
  static ThreatAnalysisResult analyzeSms(String message, {String? sender}) {
    final lowerMessage = message.toLowerCase();
    final matchedKeywords = <String>[];
    final detectedUrls = <String>[];
    final categoryScores = <String, double>{};
    final reasons = <String>[];
    var hasSuspiciousDomain = false;
    var hasPersonalInfoRequest = false;
    var hasFakeBankReference = false;

    // 0. Güvenilir gönderici kontrolü
    final isTrustedSender = _checkTrustedSender(sender);

    // ===== KATMAN 1: Kategorize Kelime Analizi (Ağırlıklı) =====
    double weightedScore = 0;

    for (final category in ThreatKeywords.allCategories) {
      int categoryHits = 0;
      for (final keyword in category.keywords) {
        if (lowerMessage.contains(keyword.toLowerCase())) {
          matchedKeywords.add(keyword);
          categoryHits++;
        }
      }
      if (categoryHits > 0) {
        final catScore = categoryHits * category.weight * 8;
        categoryScores[category.name] = catScore;
        weightedScore += catScore;
        reasons.add('${category.name}: $categoryHits kelime eşleşti');
      }
    }

    // ===== KATMAN 2: URL Analizi =====
    final urlMatches = _urlRegex.allMatches(message);
    for (final match in urlMatches) {
      final url = match.group(0)!;
      detectedUrls.add(url);

      for (final domain in ThreatKeywords.suspiciousDomains) {
        if (url.toLowerCase().contains(domain)) {
          hasSuspiciousDomain = true;
          break;
        }
      }
    }

    if (detectedUrls.isNotEmpty) {
      weightedScore += detectedUrls.length * 12;
      reasons.add('${detectedUrls.length} URL tespit edildi');
    }
    if (hasSuspiciousDomain) {
      weightedScore += 20;
      reasons.add('Kısa link / şüpheli domain tespit edildi');
    }

    // ===== KATMAN 3: Regex Pattern Tespiti =====
    // TC Kimlik numarası isteme
    if (ThreatKeywords.tcKimlikRegex.hasMatch(message) ||
        lowerMessage.contains('tc kimlik') ||
        lowerMessage.contains('kimlik no')) {
      weightedScore += 15;
      hasPersonalInfoRequest = true;
      reasons.add('TC Kimlik numarası tespiti');
    }

    // IBAN isteme
    if (ThreatKeywords.ibanRegex.hasMatch(message) ||
        lowerMessage.contains('iban')) {
      weightedScore += 15;
      hasPersonalInfoRequest = true;
      reasons.add('IBAN / banka hesabı tespiti');
    }

    // ===== KATMAN 4: Sahte Kurum Taklidi =====
    for (final pattern in ThreatKeywords.fakeBankPatterns) {
      if (lowerMessage.contains(pattern)) {
        // Banka adı + hesap tehdidi = çok şüpheli
        if (categoryScores.containsKey('Hesap Tehdidi') ||
            categoryScores.containsKey('Kişisel Bilgi')) {
          weightedScore += 15;
          hasFakeBankReference = true;
          reasons.add('Sahte banka/kurum taklidi şüphesi');
        }
        break;
      }
    }

    // ===== KATMAN 5: Kombine Tehdit Çarpanı =====
    // Birden fazla kategori bir arada → çarpan uygula
    final activeCategories = categoryScores.keys.length;
    if (activeCategories >= 3) {
      weightedScore *= 1.4; // 3+ kategori → %40 bonus
      reasons.add('Çoklu kategori eşleşmesi ($activeCategories kategori)');
    } else if (activeCategories >= 2) {
      weightedScore *= 1.2; // 2 kategori → %20 bonus
    }

    // URL + kişisel bilgi isteme = çok tehlikeli
    if (detectedUrls.isNotEmpty && hasPersonalInfoRequest) {
      weightedScore *= 1.3;
      reasons.add('URL + kişisel bilgi isteme kombinasyonu');
    }

    // ===== KATMAN 6: Güvenilir Gönderici İndirimi =====
    if (isTrustedSender && weightedScore < 60) {
      weightedScore *= 0.5; // Güvenilir gönderici → skor yarıya düşer
      reasons.add('Güvenilir gönderici (skor düşürüldü)');
    }

    // Skor 0-100 arasında kalsın
    final finalScore = weightedScore.round().clamp(0, 100);

    // TODO: Gerçek AI modeli entegre edilip asenkron bir analiz süreci başlatıldığında,
    // AI skoru ağırlıklı bir şekilde `threatLevel` ile birleştirilecek (Örn: Model %80 spam diyorsa skor +20 artacak).
    // final aiScore = await AiService().analyzeText(message);
    // if (aiScore > 0.7) threatLevel += 20;

    return ThreatAnalysisResult(
      threatLevel: finalScore,
      matchedKeywords: matchedKeywords,
      detectedUrls: detectedUrls,
      hasSuspiciousDomain: hasSuspiciousDomain,
      categoryScores: categoryScores,
      reasons: reasons,
      isTrustedSender: isTrustedSender,
      hasPersonalInfoRequest: hasPersonalInfoRequest,
      hasFakeBankReference: hasFakeBankReference,
    );
  }

  /// Güvenilir gönderici kontrolü
  static bool _checkTrustedSender(String? sender) {
    if (sender == null || sender.isEmpty) return false;
    final upperSender = sender.toUpperCase().replaceAll(RegExp(r'\s+'), '');
    return ThreatKeywords.trustedSenders.any(
      (trusted) => upperSender.contains(trusted),
    );
  }

  /// Analiz sonucundan ThreatLog oluştur
  static ThreatLog createThreatLog({
    required String sender,
    required String content,
    required ThreatAnalysisResult result,
  }) {
    return ThreatLog(
      id: _uuid.v4(),
      type: AppConstants.threatSmsPhishing,
      sender: sender,
      content: content,
      threatLevel: result.threatLevel,
      matchedKeywords: result.matchedKeywords,
      matchedUrls: result.detectedUrls,
    );
  }
}
