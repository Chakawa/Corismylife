package com.example.mycorislife

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.coris.mycorislife/screen_lock"
    private var screenLockReceiver: BroadcastReceiver? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Créer le channel pour communiquer avec Flutter
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        // Enregistrer le BroadcastReceiver pour détecter le verrouillage/déverrouillage
        registerScreenLockReceiver()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterScreenLockReceiver()
    }

    private fun registerScreenLockReceiver() {
        screenLockReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    Intent.ACTION_SCREEN_OFF -> {
                        // Écran éteint/verrouillé
                        android.util.Log.d("ScreenLock", "🔒 Écran verrouillé (ACTION_SCREEN_OFF)")
                        methodChannel?.invokeMethod("onScreenLocked", null)
                    }
                    Intent.ACTION_USER_PRESENT -> {
                        // Écran déverrouillé (utilisateur présent)
                        android.util.Log.d("ScreenLock", "🔓 Écran déverrouillé (ACTION_USER_PRESENT)")
                        methodChannel?.invokeMethod("onScreenUnlocked", null)
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        
        registerReceiver(screenLockReceiver, filter)
        android.util.Log.d("ScreenLock", "✅ BroadcastReceiver enregistré pour détecter verrouillage d'écran")
    }

    private fun unregisterScreenLockReceiver() {
        screenLockReceiver?.let {
            try {
                unregisterReceiver(it)
                android.util.Log.d("ScreenLock", "✅ BroadcastReceiver désenregistré")
            } catch (e: Exception) {
                android.util.Log.e("ScreenLock", "Erreur désenregistrement: ${e.message}")
            }
        }
    }
}
