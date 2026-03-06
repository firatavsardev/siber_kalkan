import 'package:flutter/material.dart';

// ============================================================
// SiberKalkan - Sabitler Dosyası
// Dosya Yolu: lib/utils/constants.dart
// ============================================================

// --- RENKLER ---
class AppColors {
  // Ana Renkler
  static const Color primaryGreen = Color(0xFF2E7D32);   // Güvenli
  static const Color dangerRed = Color(0xFFD32F2F);      // Tehlike
  static const Color warningOrange = Color(0xFFF57C00);   // Uyarı
  static const Color background = Color(0xFFF5F5F5);     // Arka plan
  static const Color darkBackground = Color(0xFF1A1A2E); // Koyu arka plan
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFF757575);
  static const Color blue = Color(0xFF1976D2);

  // Kalkan Renkleri
  static const Color shieldSafe = Color(0xFF4CAF50);     // Yeşil kalkan
  static const Color shieldDanger = Color(0xFFE53935);   // Kırmızı kalkan

  // Arka Plan
  static const Color backgroundGrey = Color(0xFFF5F5F5);
}

// --- YAZI STİLLERİ ---
class AppTextStyles {
  // Yaşlılar için büyük fontlar (min 24sp)
  static const TextStyle elderlyTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static const TextStyle elderlyBody = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static const TextStyle elderlyWarning = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  // Normal fontlar
  static const TextStyle heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.black,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: AppColors.grey,
  );
}

// --- SABİT DEĞERLER ---
class AppConstants {
  static const String appName = 'SiberKalkan';
  static const String appVersion = '1.0.0';

  // Kullanıcı rolleri
  static const String roleElderly = 'elderly';
  static const String roleGuardian = 'guardian';

  // Tehdit türleri
  static const String threatSmsPhishing = 'sms_phishing';
  static const String threatScamCall = 'scam_call';

  // Eşleşme kodu uzunluğu
  static const int pairingCodeLength = 6;
}

// ============================================================
// GELİŞMİŞ TEHDİT ANALİZ SÖZLÜĞÜ
// Kategorize edilmiş kelime listeleri + ağırlıklar
// ============================================================

/// Tehdit kelime kategorisi
class ThreatCategory {
  final String name;
  final double weight; // 1.0 - 3.0 arası ağırlık
  final List<String> keywords;

  const ThreatCategory({
    required this.name,
    required this.weight,
    required this.keywords,
  });
}

class ThreatKeywords {
  // --- KATEGORİZE EDİLMİŞ ZARARLI KELİMELER ---

  /// Aciliyet ve korku tetikleyicileri (yüksek ağırlık)
  static const ThreatCategory urgencyCategory = ThreatCategory(
    name: 'Aciliyet',
    weight: 2.5,
    keywords: [
      'acil', 'hemen', 'derhal', 'son gün', 'son şans',
      'son tarih', 'süre doluyor', 'zaman daralıyor',
      'beklemeden', 'geç kalmayın', 'kaçırmayın',
      'bugün içinde', 'saat içinde', 'dakika içinde',
    ],
  );

  /// Ödül ve hediye tuzakları (yüksek ağırlık)
  static const ThreatCategory rewardCategory = ThreatCategory(
    name: 'Ödül/Hediye',
    weight: 2.0,
    keywords: [
      'hediye', 'ödül', 'kazandınız', 'tebrikler',
      'şanslı', 'çekiliş', 'kampanya', 'promosyon',
      'bonus', 'ücretsiz', 'bedava', 'indirim',
      'hediye kazandınız', 'büyük ödül',
    ],
  );

  /// Kişisel bilgi isteme (çok yüksek ağırlık)
  static const ThreatCategory personalInfoCategory = ThreatCategory(
    name: 'Kişisel Bilgi',
    weight: 3.0,
    keywords: [
      'şifre', 'parola', 'tc kimlik', 'kimlik no',
      'tc no', 'kart numarası', 'kart no', 'cvv',
      'son kullanma', 'güvenlik kodu', 'banka hesabı',
      'iban', 'hesap numarası', 'doğrulama kodu',
      'sms kodu', 'onay kodu', 'pin', 'pin kodu',
    ],
  );

  /// Hesap tehditleri (yüksek ağırlık)
  static const ThreatCategory accountThreatCategory = ThreatCategory(
    name: 'Hesap Tehdidi',
    weight: 2.5,
    keywords: [
      'hesabınız', 'hesabiniz', 'bloke', 'kapatılacak',
      'askıya alındı', 'donduruldu', 'kısıtlandı',
      'yetkisiz giriş', 'şüpheli işlem', 'güncelle',
      'doğrula', 'onayla', 'giriş yapın', 'güncelleme gerekli',
    ],
  );

  /// Finansal tuzaklar (yüksek ağırlık)
  static const ThreatCategory financialCategory = ThreatCategory(
    name: 'Finansal',
    weight: 2.0,
    keywords: [
      'kredi', 'kredi kartı', 'banka', 'para',
      'borç', 'ödeme', 'ceza', 'vergi', 'icra',
      'haciz', 'faiz', 'taksit', 'iade', 'transfer',
      'havale', 'eft', 'bakiye',
    ],
  );

  /// Tıklama yönlendirme (orta ağırlık)
  static const ThreatCategory clickCategory = ThreatCategory(
    name: 'Tıklama',
    weight: 1.5,
    keywords: [
      'tikla', 'tıkla', 'tiklayiniz', 'tıklayınız',
      'linke tıklayın', 'buraya tıklayın', 'aşağıdaki link',
      'detay için', 'bilgi için', 'giriş yapın',
      'formu doldurun',
    ],
  );

  /// Tüm kategoriler listesi
  static const List<ThreatCategory> allCategories = [
    urgencyCategory,
    rewardCategory,
    personalInfoCategory,
    accountThreatCategory,
    financialCategory,
    clickCategory,
  ];

  // --- Düz liste (geriye uyumluluk) ---
  static List<String> get dangerousWords {
    final words = <String>[];
    for (final cat in allCategories) {
      words.addAll(cat.keywords);
    }
    return words;
  }

  // --- ŞÜPHELİ DOMAİNLER (genişletilmiş) ---
  static const List<String> suspiciousDomains = [
    'bit.ly', 'tinyurl.com', 'shorturl.at', 'is.gd',
    't.co', 'goo.gl', 'ow.ly', 'cutt.ly', 'rb.gy',
    'tinyurl.at', 'short.io', 'rebrand.ly', 'tiny.cc',
    's.id', 'clck.ru', 'bc.vc', 'bit.do',
  ];

  // --- GÜVENİLİR GÖNDERİCİLER (beyaz liste) ---
  static const List<String> trustedSenders = [
    'TURKTELEKOM', 'TURKCELL', 'VODAFONE',
    'PTT', 'E-DEVLET', 'SAGLIKBAKANLIGI',
    'ZIRAATBNK', 'ISBANK', 'GARANTI', 'YAPIKREDI',
    'AKBANK', 'HALKBANK', 'VAKIFBANK', 'DENIZBANK',
    'QNB', 'ENPARA', 'TEB', 'ING',
    'SGK', 'GIB', 'TCMB',
  ];

  // --- SAHTE KURUM KALIPLARI ---
  static const List<String> fakeBankPatterns = [
    'ziraat', 'garanti', 'yapı kredi', 'yapikredi',
    'akbank', 'halkbank', 'vakıfbank', 'vakifbank',
    'denizbank', 'iş bankası', 'is bankasi', 'isbank',
    'qnb', 'enpara', 'teb', 'ing bank',
  ];

  // --- REGEX PATTERNLERİ ---
  /// TC Kimlik numarası pattern'i (11 haneli)
  static final RegExp tcKimlikRegex = RegExp(r'\b[1-9]\d{10}\b');

  /// IBAN pattern'i
  static final RegExp ibanRegex = RegExp(
    r'\bTR\s?\d{2}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{2}\b',
    caseSensitive: false,
  );

  /// Telefon numarası pattern'i
  static final RegExp phoneRegex = RegExp(
    r'\b0?5\d{2}[\s\-]?\d{3}[\s\-]?\d{2}[\s\-]?\d{2}\b',
  );
}
