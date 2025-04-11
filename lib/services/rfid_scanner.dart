import 'package:flutter/services.dart';

class RFIDScanner {
  static const MethodChannel _channel = MethodChannel(
    'com.example.rfid/deviceapi',
  );

  static Future<void> initReader() async {
    await _channel.invokeMethod('initReader');
  }

  static Future<String?> readTag() async {
    final String? tag = await _channel.invokeMethod('readTag');
    return tag;
  }

  static Future<void> freeReader() async {
    await _channel.invokeMethod('freeReader');
  }
}
