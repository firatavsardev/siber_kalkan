package com.siberkalkan.siber_kalkan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log

class SmsBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_DELIVER_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            for (sms in messages) {
                if (sms != null) {
                    val sender = sms.originatingAddress ?: "Bilinmeyen"
                    val body = sms.displayMessageBody ?: ""
                    Log.d("SmsBroadcastReceiver", "Varsayılan SMS App olarak SMS alındı: $sender - $body")
                    // Arka plan motoru açıksa, SMS_DELIVER üzerinden işleyebiliriz.
                }
            }
        }
    }
}
