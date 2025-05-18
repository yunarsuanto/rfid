package com.example.rfid

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import com.rscja.deviceapi.RFIDWithUHFUART
import com.rscja.deviceapi.entity.UHFTAGInfo
import com.rscja.deviceapi.exception.ConfigurationException
import io.flutter.embedding.android.FlutterActivity
import androidx.core.app.ActivityCompat
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {
    private val DEVICE_CHANNEL = "com.example.rfid/deviceapi"
    private val PERMISSION_CHANNEL = "com.example/permissions"
    private val STORAGE_PERMISSION_CODE = 1001
    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Channel untuk device RFID
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL)
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
                        val level = call.arguments as? Int ?: 30
                        val success = MyRFIDDeviceApi?.setPower(level) ?: false
                        result.success(success)
                    }
                    else -> result.notImplemented()
                }
            }

        // Channel untuk permission
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "checkStorage") {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        if (!Environment.isExternalStorageManager()) {
                            // Arahkan user ke settings khusus untuk beri izin
                            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                            intent.data = Uri.parse("package:$packageName")
                            startActivity(intent)
                            result.success(false)
                            return@setMethodCallHandler
                        } else {
                            result.success(true)
                        }
                    } else {
                        val granted = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.WRITE_EXTERNAL_STORAGE
                        ) == PackageManager.PERMISSION_GRANTED
                
                        if (granted) {
                            result.success(true)
                        } else {
                            permissionResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                                STORAGE_PERMISSION_CODE
                            )
                        }
                    }
                }
                
            }
    }
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == STORAGE_PERMISSION_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            permissionResult?.success(granted)
            permissionResult = null
        }
    }

}
