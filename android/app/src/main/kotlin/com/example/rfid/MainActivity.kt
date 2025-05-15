package com.example.rfid

import android.os.Bundle
import com.rscja.deviceapi.entity.UHFTAGInfo
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.rfid/deviceapi"
    private val EVENT_CHANNEL = "com.example.rfid/scan_stream"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
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
                        val args = call.arguments as? Map<*, *>
                        val level = (args?.get("level") as? Int) ?: 30
                        val success = MyRFIDDeviceApi.setPower(level)
                        result.success(success)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    MyRFIDDeviceApi.startInventory { tag ->
                        val data = mapOf(
                            "epc" to tag.epc,
                            "rssi" to tag.rssi
                        )
                        events?.success(data)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    MyRFIDDeviceApi.stopInventory()
                }
            })
    }
}
