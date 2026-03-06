// ============================================================
// SiberKalkan - AI (Yapay Zeka) Servisi
// Dosya Yolu: lib/services/ai_service.dart
// TensorFlow Lite modeli ile cihaz içi (Offline) metin analizi
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  bool get isModelLoaded => _isModelLoaded;

  /// Modeli yükle
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/spam_model.tflite');
      _isModelLoaded = true;
      debugPrint('🤖 AI Modeli başarıyla yüklendi.');
    } catch (e) {
      debugPrint('🤖 AI Modeli yüklenemedi (Eksik olabilir): $e');
      _isModelLoaded = false;
    }
  }

  /// Metni yapay zeka ile analiz et ve 0.0 ile 1.0 arası bir tehdit olasılığı döndür
  Future<double> analyzeText(String text) async {
    if (!_isModelLoaded) {
      // Model yoksa 0 (Güvenli) döndürülür
      return 0.0;
    }

    try {
      // 1. Metni modelin anladığı formata (Tokenize) dönüştürme
      var input = _tokenizeText(text);

      // Keras modelimiz tek bir probability (float32) döndürüyor
      // Şekli: [1, 1]
      var output = List.filled(1 * 1, 0.0).reshape([1, 1]);

      // 3. Modeli çalıştır
      _interpreter!.run(input, output);

      // 4. Tahmini al
      double probability = output[0][0];
      return probability;
    } catch (e) {
      debugPrint('🤖 AI Analiz hatası: $e');
      return 0.0;
    }
  }

  /// Metni sayısal dizilere dönüştürme simülasyonu
  List<List<int>> _tokenizeText(String text) {
    // Gerçek bir NLP uygulamasında vocabulary ile kelimeler ID'lere çevrilir. (Max Length = 50 padding)
    // Şimdilik model çökmesin diye sıfırlarla dolu (veya rastgele) dummy bir dizi gönderiyoruz
    return [List.filled(50, 0)];
  }

  void dispose() {
    _interpreter?.close();
  }
}
