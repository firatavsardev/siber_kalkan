// ============================================================
// SiberKalkan - Bildirim Servisi
// Dosya Yolu: lib/services/notification_service.dart
// FCM + Flutter Local Notifications
// ============================================================

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show Color;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:siber_kalkan/models/threat_log.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  String? _fcmToken;

  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;

  /// Bildirim servisini başlat
  Future<void> initialize() async {
    try {
      // Lokal bildirimleri başlat
      await _initLocalNotifications();

      // FCM başlat
      await _initFCM();

      _isInitialized = true;
      debugPrint('🔔 Bildirim servisi başlatıldı');
    } catch (e) {
      debugPrint('🔔 Bildirim servisi hatası: $e');
    }
  }

  /// Lokal bildirim kanalını başlat
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Bildirim tıklandı: ${details.payload}');
      },
    );
  }

  /// Firebase Cloud Messaging başlat
  Future<void> _initFCM() async {
    try {
      _messaging = FirebaseMessaging.instance;

      // İzin iste
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // FCM token al
        _fcmToken = await _messaging!.getToken();
        debugPrint('FCM Token: $_fcmToken');

        // Ön plandayken gelen mesajları dinle
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Token değişikliklerini dinle
        _messaging!.onTokenRefresh.listen((token) {
          _fcmToken = token;
          debugPrint('FCM Token güncellendi: $token');
        });
      }
    } catch (e) {
      debugPrint('FCM başlatma hatası: $e');
    }
  }

  /// Ön planda gelen FCM mesajlarını işle
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM mesaj alındı: ${message.notification?.title}');

    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? 'SiberKalkan',
        body: message.notification!.body ?? '',
      );
    }
  }

  /// Lokal bildirim göster
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'siber_kalkan_threats',
      'Tehdit Bildirimleri',
      channelDescription: 'Tespit edilen tehditler için bildirimler',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFD32F2F),
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Tehdit tespit edilince bildirim gönder
  Future<void> notifyThreat(ThreatLog threat) async {
    String title;
    String body;

    if (threat.threatLevel >= 80) {
      title = '🚨 ÇOK TEHLİKELİ SMS!';
      body = 'Gönderen: ${threat.sender} — Bu mesaj çok tehlikeli!';
    } else if (threat.threatLevel >= 60) {
      title = '⚠️ Tehlikeli SMS Tespit Edildi';
      body = 'Gönderen: ${threat.sender} — Dikkatli olun!';
    } else {
      title = '📋 Şüpheli SMS';
      body = 'Gönderen: ${threat.sender} — Kontrol edin.';
    }

    await showLocalNotification(title: title, body: body, payload: threat.id);
  }

  /// Eşleşmiş kullanıcıya (guardian) bildirim metni oluştur
  String createGuardianAlert(ThreatLog threat) {
    return 'Yakınınıza şüpheli SMS geldi! '
        'Gönderen: ${threat.sender}, '
        'Tehdit Seviyesi: ${threat.threatLevelText}';
  }
}
