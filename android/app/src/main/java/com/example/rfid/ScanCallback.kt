package com.example.rfid

interface ScanCallback {
    fun onScanTag(tag: String)
    fun onScanError(error: String)
}
