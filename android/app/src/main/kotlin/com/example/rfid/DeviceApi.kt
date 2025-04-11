package com.example.rfid

import android.content.Context
import android.util.Log
import com.rscja.deviceapi.RFIDWithUHFUART
import com.rscja.deviceapi.entity.UHFTAGInfo
import com.rscja.deviceapi.exception.ConfigurationException

object DeviceApi {
    private var reader: RFIDWithUHFUART? = null

    // Inisialisasi RFID
    fun initReader(context: Context): Boolean {
        return try {
            if (reader == null) {
                reader = RFIDWithUHFUART.getInstance()
                // reader?.init(context)
                reader?.init(context) ?: false
            } else {
                true
            }
        } catch (e: ConfigurationException) {
            Log.e("DeviceApi", "Init error: ${e.message}")
            false
        }
    }

    // Membaca Tag RFID
    fun readTag(): String? {
        return try {
            val tagInfo: UHFTAGInfo? = reader?.inventorySingleTag()
            tagInfo?.epc
        } catch (e: Exception) {
            Log.e("DeviceApi", "Read error: ${e.message}")
            null
        }
    }

    // Bebaskan reader
    fun freeReader(): Boolean {
        return try {
            reader?.free()
            true
        } catch (e: Exception) {
            Log.e("DeviceApi", "Free error: ${e.message}")
            false
        }
    }
}
