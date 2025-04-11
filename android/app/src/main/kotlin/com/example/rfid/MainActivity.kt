package com.example.rfid

import android.content.Context
import com.rscja.deviceapi.RFIDWithUHFUART
import com.rscja.deviceapi.entity.UHFTAGInfo
import com.rscja.deviceapi.exception.ConfigurationException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.rfid.MyRFIDDeviceApi

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.rfid/deviceapi"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.eample.rfid/deviceapi")
        .setMethodCallHandler { call, result ->
            when (call.method) {
                "initReader" -> {
                    val ok = MyRFIDDeviceApi.initReader(this)
                    result.success(ok)
                }
                "readTag" -> {
                    val tag = MyRFIDDeviceApi.readTag()
                    result.success(tag)
                }
                "freeReader" -> {
                    val ok = MyRFIDDeviceApi.freeReader()
                    result.success(ok)
                }
                else -> result.notImplemented()
            }
        }
    }
}
