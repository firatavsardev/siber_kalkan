import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:siber_kalkan/main.dart';

void main() {
  testWidgets('SiberKalkan uygulaması açılma testi', (WidgetTester tester) async {
    // Uygulamayı başlat
    await tester.pumpWidget(
      const ProviderScope(
        child: SiberKalkanApp(),
      ),
    );

    // SiberKalkan başlığının göründüğünü doğrula
    expect(find.text('SiberKalkan'), findsOneWidget);

    // Alt başlığın göründüğünü doğrula
    expect(find.text('Siber Dolandırıcılığa Karşı Kalkanınız'), findsOneWidget);

    // Kalkan ikonunun göründüğünü doğrula
    expect(find.byIcon(Icons.shield), findsOneWidget);

    // Yükleniyor metninin göründüğünü doğrula
    expect(find.text('Yükleniyor...'), findsOneWidget);

    // Timer'ı tüket (SplashScreen'in 2 saniyelik gecikmesi)
    await tester.pump(const Duration(seconds: 3));
    // Animasyonları de tamamla
    await tester.pump(const Duration(seconds: 1));
  });
}
