package com.example.rfid

import android.content.Context
import android.util.Log
import com.rscja.deviceapi.RFIDWithUHFUART
import com.rscja.deviceapi.RFIDWithUHFUART
import com.rscja.deviceapi.entity.UHFTAGInfo
import com.rscja.deviceapi.exception.ConfigurationException
import com.rscja.deviceapi.interfaces.ISingleAntenna

object MyRFIDDeviceApi {
    private var reader: RFIDWithUHFUART? = null
    private var isScanning = false
    private var onTagScanned: ((UHFTAGInfo) -> Unit)? = null
    private var scanThread: Thread? = null


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

    fun startInventory(callback: (UHFTAGInfo) -> Unit) {
        if (reader == null || isScanning) return
    
        val started = reader?.startInventoryTag() ?: false
        if (!started) {
            Log.e("RFID", "❌ Gagal start inventory dari device.")
            return
        }
    
        isScanning = true
        scanThread = Thread {
            while (isScanning) {
                try {
                    val tag = reader?.readTagFromBuffer()  // ← Ini ganti sesuai SDK kamu
                    if (tag != null) {
                        callback(tag)
                    }
                    Thread.sleep(100)
                } catch (e: Exception) {
                    Log.e("DeviceApi", "Inventory error: ${e.message}")
                }
            }
        }
        scanThread?.start()
        Log.d("RFID", "▶️ Start inventory loop")
    }
    
    fun stopInventory() {
        isScanning = false
        scanThread?.interrupt()
        scanThread = null
        reader?.stopInventory() // <- ini sudah tepat
        Log.d("RFID", "⏹️ Stop inventory loop")
    } 
    
}
