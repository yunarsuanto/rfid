import 'dart:async';
import 'package:flutter/material.dart';
import '../services/rfid_scanner.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String _tag = ''; // Menyimpan informasi tag yang terdeteksi
  Timer? _timer; // Timer untuk polling tag RFID secara berkala

  @override
  void initState() {
    super.initState();
    RFIDScanner.initReader(); // Inisialisasi pembaca RFID
    _startPolling(); // Mulai polling untuk membaca tag RFID
  }

  // Fungsi untuk melakukan polling setiap detik untuk membaca tag
  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      String? tag = await RFIDScanner.readTag();
      if (tag != null && tag.isNotEmpty && tag != _tag) {
        setState(() {
          _tag = tag; // Jika tag berbeda, perbarui tag yang terdeteksi
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Hentikan polling ketika halaman ini ditutup
    RFIDScanner.freeReader(); // Bebaskan pembaca RFID
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan RFID"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent, // Sesuaikan warna AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0), // Padding untuk konten layar
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Sesuaikan ukuran kolom
            children: [
              const Icon(
                Icons.nfc, // Ikon NFC sebagai tanda RFID
                size: 64,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 24), // Spasi antara ikon dan teks
              Text(
                _tag.isEmpty
                    ? "No tag detected"
                    : "Tag:\n$_tag", // Tampilkan tag yang terdeteksi
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: _tag.isEmpty ? Colors.grey : Colors.black,
                ),
              ),
              const SizedBox(height: 16), // Spasi sebelum teks instruksi
              const Text(
                "Arahkan tag RFID ke scanner untuk membaca", // Instruksi untuk pengguna
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
