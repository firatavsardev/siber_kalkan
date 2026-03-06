package com.siberkalkan.siber_kalkan

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Kendi yazdığımız özel SMS Plugin'ini Flutter motoruna kaydediyoruz
        flutterEngine.plugins.add(SmsPlugin())
    }
}
