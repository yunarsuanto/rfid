package com.example.rfid

import android.content.Context
import android.util.Log
import com.rscja.deviceapi.RFIDWithUHFUART
import com.rscja.deviceapi.entity.UHFTAGInfo
import com.rscja.deviceapi.exception.ConfigurationException
import com.rscja.deviceapi.interfaces.ISingleAntenna

object MyRFIDDeviceApi {
    private var reader: RFIDWithUHFUART? = null

    // Inisialisasi RFID
    fun initReader(context: Context): Boolean {
        return try {
            if (reader == null) {
                reader = RFIDWithUHFUART.getInstance()
            }
    
            if (!reader!!.isPowerOn) {
                val initResult = reader!!.init(context)
                Log.d("RFID", "✅ Reader init result: $initResult")
                initResult
            } else {
                Log.d("RFID", "⚠️ Reader already ON, skip init.")
                true
            }
        } catch (e: ConfigurationException) {
            Log.e("RFID", "❌ Init error: ${e.message}")
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
            if (reader != null) {
                if (reader!!.isPowerOn) {         // ✅ hanya panggil free() jika masih nyala
                    reader?.free()
                    reader = null
                    Log.i("DeviceApi", "Reader freed.")
                } else {
                    Log.i("DeviceApi", "Reader already off, skipping free().")
                }
            }
            true
        } catch (e: Exception) {
            Log.e("DeviceApi", "Free error: ${e.message}")
            false
        }
    }

    fun setPower(level: Int): Boolean {
        Log.d("RFID", "▶️ Mencoba setPower: $level")
    
        if (reader == null) {
            Log.e("RFID", "❌ reader null")
            return false
        }
    
        val isSingle = reader is ISingleAntenna
        Log.d("RFID", "🔍 ISingleAntenna instance? $isSingle")
    
        return try {
            val result = reader?.setPower(level) ?: false
            Log.d("RFID", "✅ Hasil setPower: $result")
            result
        } catch (e: Exception) {
            Log.e("RFID", "⚠️ Exception saat setPower: ${e.message}")
            false
        }
    }
    
    fun readTagInfo(): UHFTAGInfo? {
        return try {
            reader?.inventorySingleTag()
        } catch (e: Exception) {
            Log.e("DeviceApi", "Exception saat baca tag: ${e.message}")
            null
        }
    }    
    
}
