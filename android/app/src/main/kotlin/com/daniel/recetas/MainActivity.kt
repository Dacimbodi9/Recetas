package com.daniel.recetas

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.daniel.recetas/file_reader"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getIntentData" -> {
                    val uri = intent?.data
                    if (uri != null) {
                        result.success(uri.toString())
                    } else {
                        result.success(null)
                    }
                }
                "readContentUri" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        try {
                            val uri = android.net.Uri.parse(uriString)
                            val inputStream = contentResolver.openInputStream(uri)
                            val content = inputStream?.bufferedReader()?.readText()
                            inputStream?.close()
                            result.success(content)
                        } catch (e: Exception) {
                            result.error("READ_ERROR", "Failed to read file: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_URI", "No URI provided", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
