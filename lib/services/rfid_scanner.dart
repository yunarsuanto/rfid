import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RFIDScanner {
  static const MethodChannel _channel = MethodChannel(
    'com.example.rfid/deviceapi',
  );

  static Future<void> initReader() async {
    try {
      await _channel.invokeMethod('initReader');
    } catch (e) {
      debugPrint("RFIDScanner: initReader error: $e");
    }
  }

  static Future<Map<String, dynamic>?> readTag() async {
    final result = await _channel.invokeMethod('readTag');
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  static Future<void> freeReader() async {
    try {
      await _channel.invokeMethod('freeReader');
    } catch (e) {
      debugPrint("RFIDScanner: freeReader error: $e");
    }
  }

  static Future<bool> setPower(int power) async {
    final result = await _channel.invokeMethod('setPower', {'level': power});
    print("📡 Set power result: $result");
    return result == true;
  }
}
