package com.siberkalkan.siber_kalkan

import android.app.Service
import android.content.Intent
import android.os.IBinder

class HeadlessSmsSendService : Service() {
    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == "android.intent.action.RESPOND_VIA_MESSAGE") {
            // Hızlı yanıt mesajlarını gönderme mantığı, şimdilik boş.
        }
        return START_NOT_STICKY
    }
}
