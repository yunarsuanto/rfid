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
    // private var reader: RFIDWithUHFUART? = null
    

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.rfid/deviceapi")
        .setMethodCallHandler { call, result ->
            when (call.method) {
                "initReader" -> {
                    val ok = MyRFIDDeviceApi.initReader(this)
                    result.success(ok)
                }
                "readTag" -> {
                    val tagInfo = MyRFIDDeviceApi.readTagInfo()
                    if (tagInfo != null) {
                        val data = mapOf(
                            "epc" to tagInfo.epc,
                            "rssi" to tagInfo.rssi
                        )
                        result.success(data)
                    } else {
                        result.success(null)
                    }
                }
                "freeReader" -> {
                    val ok = MyRFIDDeviceApi.freeReader()
                    result.success(ok)
                }
                "setPower" -> {
                    val level = call.arguments as? Int ?: 30 // default max
                    val success = MyRFIDDeviceApi?.setPower(level) ?: false
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }
    }
}
