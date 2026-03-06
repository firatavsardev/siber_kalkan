package com.siberkalkan.siber_kalkan

import android.app.Activity
import android.os.Bundle

class ComposeSmsActivity : Activity() {
    override fun onCreate(saved: savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // SiberKalkan bir mesajlaşma aracı değil koruma aracıdır, bu yüzden açılırsa hemen kapanır.
        finish()
    }
}
