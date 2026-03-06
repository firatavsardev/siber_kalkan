package com.siberkalkan.siber_kalkan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.provider.Telephony
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SmsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var receiver: BroadcastReceiver? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "siber_kalkan/sms_scanner")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stopListening()
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startListening" -> {
                startListening()
                result.success(true)
            }
            "stopListening" -> {
                stopListening()
                result.success(true)
            }
            "getInboxSms" -> {
                val limit = call.argument<Int>("limit") ?: 50
                val messages = getInboxSms(limit)
                result.success(messages)
            }
            "requestDefaultSmsApp" -> {
                requestDefaultSmsApp()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun startListening() {
        if (receiver != null) return
        receiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context, intent: Intent) {
                if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
                    val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
                    for (sms in messages) {
                        if (sms != null) {
                            val map = mapOf(
                                "sender" to (sms.originatingAddress ?: "Bilinmeyen"),
                                "body" to (sms.displayMessageBody ?: "")
                            )
                            channel.invokeMethod("onSmsReceived", map)
                        }
                    }
                }
            }
        }
        val filter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
        
        // Android 14 (API 34+) compatibility for dynamically registered receivers.
        // System broadcasts like SMS_RECEIVED require RECEIVER_EXPORTED.
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            context?.registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            context?.registerReceiver(receiver, filter)
        }
    }

    private fun stopListening() {
        receiver?.let {
            context?.unregisterReceiver(it)
            receiver = null
        }
    }

    private fun getInboxSms(limit: Int): List<Map<String, String>> {
        val resultList = mutableListOf<Map<String, String>>()
        val uri = Uri.parse("content://sms/inbox")
        val cursor = context?.contentResolver?.query(uri, arrayOf("address", "body", "date"), null, null, "date DESC")
        
        cursor?.use {
            var count = 0
            val addressIndex = it.getColumnIndex("address")
            val bodyIndex = it.getColumnIndex("body")
            
            while (it.moveToNext() && count < limit) {
                val address = if (addressIndex >= 0) it.getString(addressIndex) else "Bilinmeyen"
                val body = if (bodyIndex >= 0) it.getString(bodyIndex) else ""
                
                resultList.add(mapOf(
                    "sender" to address,
                    "body" to body
                ))
                count++
            }
        }
        return resultList
    }

    private fun requestDefaultSmsApp() {
        val intent = Intent(Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT)
        intent.putExtra(Telephony.Sms.Intents.EXTRA_PACKAGE_NAME, context?.packageName)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context?.startActivity(intent)
    }
}
