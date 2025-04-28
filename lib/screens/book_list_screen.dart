import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:rfid/models/book.dart';
import 'package:rfid/services/book_service.dart';
import 'package:rfid/services/rfid_scanner.dart';
import 'package:rfid/services/unauthorize.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _signalStrength = 0.0;

  String? selectedBook;
  String? detectedTag;
  DateTime? lastTagTime;
  bool _isBeeping = false;
  Timer? _scanTimer;

  List<Book> books = [];
  List<Book> filteredBooks = [];

  TextEditingController searchController = TextEditingController();

  double _currentRssi = -100;
  bool _isReading = false;
  bool _lockedToTag = false;

  Future<void> _startScanning({List<Item> tags = const []}) async {
    final validTags =
        tags
            .where((tag) => tag.availability == 'Tersedia')
            .map((tag) => tag.rfidCode)
            .toList();

    if (validTags.isEmpty) {
      setState(() {
        selectedBook = null;
      });

      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Info'),
              content: const Text('Buku yang tersedia tidak ada.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return; // ⬅️ STOP di sini, tidak lanjut ke bawah
    }

    _signalStrength = 0.0;
    _scanTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      if (_isReading) return;
      _isReading = true;

      final tagData = await RFIDScanner.readTag();

      if (tagData != null) {
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

      if (_isBeeping && lastTagTime != null) {
        final diff = DateTime.now().difference(lastTagTime!);
        if (diff.inMilliseconds > 2000) {
          _isBeeping = false;
          _currentRssi = -100;
          detectedTag = null;
          _lockedToTag = false;
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
  void initState() {
    super.initState();
    _loadBooks();
    searchController.addListener(() {
      _loadBooks(search: searchController.text);
    });
    RFIDScanner.initReader();
  }

  final apiService = BookService();
  Future<void> _loadBooks({String search = ''}) async {
    try {
      List<Book> loadedBooks = await apiService.fetchBooks(search: search);
      setState(() {
        books = loadedBooks;
        filteredBooks = loadedBooks;
      });
    } on UnauthorizedException {
      // Kosongkan list
      setState(() {
        books = [];
        filteredBooks = [];
      });

      // Hapus token dari local storage (opsional)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');

      // Redirect ke login screen
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Error saat load buku: $e');
    }
  }

  void dispose() {
    searchController.dispose();
    _audioPlayer.dispose();
    _stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Daftar Buku', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.orange,
        elevation: 0,
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
        const SizedBox(height: kToolbarHeight + 24),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Cari judul atau penulis...',
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withAlpha((0.1 * 255).toInt()),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child:
              filteredBooks.isEmpty
                  ? const Center(
                    child: Text(
                      'Tidak ada buku ditemukan',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                  : ListView.builder(
                    itemCount: filteredBooks.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      return Card(
                        color: Colors.white.withAlpha((0.2 * 255).toInt()),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          onTap: () async {
                            if (book.items.isNotEmpty) {
                              await RFIDScanner.initReader();
                              await RFIDScanner.setPower(30);
                              setState(() {
                                selectedBook = book.title;
                                detectedTag = null;
                              });
                              _startScanning(tags: book.items);
                            } else {
                              showDialog(
                                context: context,
                                builder:
                                    (_) => AlertDialog(
                                      title: const Text('RFID Belum Tersedia'),
                                      content: const Text(
                                        'Buku ini belum memiliki data RFID yang terdaftar.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                              );
                            }
                          },
                          contentPadding: const EdgeInsets.all(12),
                          leading:
                              book.imageUrl.isNotEmpty
                                  ? Image.network(
                                    book.imageUrl,
                                    height: 120,
                                    width: 80,
                                    fit: BoxFit.cover,
                                  )
                                  : const Icon(Icons.book, color: Colors.white),
                          title: Text(
                            book.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            book.publisher,
                            style: TextStyle(
                              color: Colors.white.withAlpha(
                                (0.8 * 255).toInt(),
                              ),
                            ),
                          ),
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
          color: Colors.white.withAlpha((0.2 * 255).toInt()),
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
                  "Mencari tag Buku $selectedBook",
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
