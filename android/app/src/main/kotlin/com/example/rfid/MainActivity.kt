package com.example.rfid

import android.content.Context
import com.rscja.deviceapi.RFIDWithUHFUART
import com.rscja.deviceapi.entity.UHFTAGInfo
import com.rscja.deviceapi.exception.ConfigurationException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.rfid.DeviceApi

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.rfid/deviceapi"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.yourapp.rfid/deviceapi")
        .setMethodCallHandler { call, result ->
            when (call.method) {
                "initReader" -> {
                    val ok = DeviceApi.initReader(this)
                    result.success(ok)
                }
                "readTag" -> {
                    val tag = DeviceApi.readTag()
                    result.success(tag)
                }
                "freeReader" -> {
                    val ok = DeviceApi.freeReader()
                    result.success(ok)
                }
                else -> result.notImplemented()
            }
        }
    }
}
