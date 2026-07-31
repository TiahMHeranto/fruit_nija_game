package com.example.fruit_nija_game

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "fruit_ninja_tiahm/prefs"
    private val prefsName = "fruit_ninja_tiahm"
    private val highScoreKey = "high_score"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                val prefs = getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                when (call.method) {
                    "getHighScore" -> result.success(prefs.getInt(highScoreKey, 0))
                    "setHighScore" -> {
                        val value = call.arguments as? Int ?: 0
                        prefs.edit().putInt(highScoreKey, value).apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
