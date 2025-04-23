import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/rfid_scanner.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();
  double _signalStrength = 0.0;

  String? selectedBook;
  String? detectedTag;
  DateTime? lastTagTime;
  bool _isBeeping = false;
  Timer? _scanTimer;

  final Map<String, List<String>> bookTags = {
    'BUKU A': [
      'E28069950000401919F0F0C2',
      'E28069950000401919F0FCC2',
      'E28069950000401919F104C2',
    ],
    'BUKU B': [
      'E28069950000401919F108C2',
      'E28069950000401919F110C2',
      'E28069950000501919F0F4C2',
    ],
    'BUKU C': [
      'E28069950000501919F0F8C2',
      'E28069950000501919F100C2',
      'E28069950000501919F10CC2',
    ],
    'BUKU D': ['E28069950000501919F114C2'],
  };

  List<String> get filteredBooks {
    final query = _searchController.text.toLowerCase();
    return bookTags.keys
        .where((title) => title.toLowerCase().contains(query))
        .toList();
  }

  double _currentRssi = -100;

  @override
  void initState() {
    super.initState();
    RFIDScanner.initReader();
  }

  bool _isReading = false;
  bool _lockedToTag = false;

  void _startScanning() {
    _signalStrength = 0.0;
    _scanTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      if (_isReading) return;
      _isReading = true;

      final tagData = await RFIDScanner.readTag();
      final validTags = bookTags[selectedBook];

      if (tagData != null && validTags != null) {
        final epc = tagData['epc']?.toString().trim().toUpperCase();
        final rssi = double.tryParse(tagData['rssi'].toString()) ?? -100;

        final normalizedValidTags =
            validTags.map((e) => e.toUpperCase()).toList();

        if (epc != null &&
            (epc == detectedTag ||
                (!_lockedToTag && normalizedValidTags.contains(epc)))) {
          if (detectedTag == null || rssi > _currentRssi) {
            setState(() {
              detectedTag = epc;
              _currentRssi = rssi;

              // ✅ Update sinyal berdasarkan rssi
              _signalStrength = _normalizeRssi(rssi);
            });
          }

          lastTagTime = DateTime.now();

          if (!_isBeeping) {
            _isBeeping = true;
            _startBeepingLoop();
          }

          _adjustBeepVolume(rssi);
        }
      }

      // Stop bip jika tag hilang > 2 detik
      if (_isBeeping && lastTagTime != null) {
        final diff = DateTime.now().difference(lastTagTime!);
        if (diff.inMilliseconds > 2000) {
          _isBeeping = false;
          _currentRssi = -100;
          detectedTag = null;
          _lockedToTag = false; // 🔓 Siap cari lagi
        }
      }

      _isReading = false;
    });
  }

  void _adjustBeepVolume(double rssi) {
    if (rssi > -40) {
      _audioPlayer.setVolume(1.0);
    } else if (rssi > -55) {
      _audioPlayer.setVolume(0.7);
    } else if (rssi > -70) {
      _audioPlayer.setVolume(0.5);
    } else {
      _audioPlayer.setVolume(0.2);
    }
  }

  void _startBeepingLoop() async {
    if (!_isBeeping) return;

    try {
      await _audioPlayer.stop(); // Pastikan berhenti dulu
      await _audioPlayer.play(AssetSource('sounds/bip.wav'));

      // 🔁 Delay antar bip berdasarkan jarak (RSSI)
      int delay;
      if (_currentRssi > -45) {
        delay = 200; // 🟢 Sangat dekat → Sangat cepat
      } else if (_currentRssi > -60) {
        delay = 500; // 🟠 Cukup dekat
      } else if (_currentRssi > -70) {
        delay = 1000; // 🔴 Jarak menengah
      } else {
        delay = 1500; // ⚫️ Jauh
      }

      await Future.delayed(Duration(milliseconds: delay));

      if (_isBeeping) {
        _startBeepingLoop(); // 🔄 Panggil ulang
      }
    } catch (e) {
      debugPrint("❌ Error bip: $e");
    }
  }

  double _normalizeRssi(double rssi) {
    // RSSI diharapkan antara -80 (lemah) sampai -40 (kuat)
    const minRssi = -80.0;
    const maxRssi = -40.0;

    double normalized = (rssi - minRssi) / (maxRssi - minRssi);
    return normalized.clamp(0.0, 1.0);
  }

  void _stopScanning() {
    _scanTimer?.cancel();
    _isBeeping = false;
    detectedTag = null;
    RFIDScanner.freeReader();
  }

  void _stopTimerOnly() {
    _scanTimer?.cancel();
    _isBeeping = false;
    detectedTag = null;
    _currentRssi = -100;
    _lockedToTag = false;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _searchController.dispose();
    _stopScanning(); // 🧹 ini tetap freeReader saat app benar-benar ditutup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedBook == null ? 'Pilih Buku' : 'Mencari ${selectedBook!}',
        ),
        backgroundColor: Colors.orange,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/images/bg.png", fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.7)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: selectedBook == null ? _buildBookList() : _buildScanView(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookList() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Cari buku...",
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: filteredBooks.length,
            itemBuilder: (_, index) {
              final title = filteredBooks[index];
              return Card(
                color: Colors.white.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                  onTap: () async {
                    await RFIDScanner.initReader(); // ✅ Inisialisasi ulang reader
                    await RFIDScanner.setPower(30); // ✅ Set ulang power
                    print("Init reader: done");

                    final powerOk = await RFIDScanner.setPower(30);
                    print("Set power: $powerOk");
                    setState(() {
                      selectedBook = title;
                      detectedTag = null;
                    });

                    _startScanning();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScanView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.nfc, size: 72, color: Colors.white),
        const SizedBox(height: 24),
        Card(
          color: Colors.white.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  detectedTag == null
                      ? "Mencari tag..."
                      : "Tag ditemukan:\n$detectedTag",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  "Mencari tag milik $selectedBook",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                LinearProgressIndicator(
                  value: _signalStrength,
                  backgroundColor: Colors.white24,
                  color:
                      _signalStrength > 0.7
                          ? Colors.greenAccent
                          : _signalStrength > 0.4
                          ? Colors.orangeAccent
                          : Colors.redAccent,

                  minHeight: 10,
                ),
                const SizedBox(height: 12),
                Text(
                  "Proximity: ${(_signalStrength * 100).toInt()}%",
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () {
            _stopTimerOnly();
            setState(() {
              selectedBook = null;
            });
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text("Kembali ke daftar buku"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
