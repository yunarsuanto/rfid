import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:rfid/models/book_detail.dart';
import 'package:flutter/material.dart';
import 'package:rfid/models/shel_item.dart';
import 'package:rfid/models/shelf.dart';
import 'package:rfid/services/detail_stockopname_service.dart';
import 'package:rfid/services/rfid_scanner.dart';
import 'package:rfid/services/unauthorize.dart';
// import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

class ScanSingleBook extends StatefulWidget {
  const ScanSingleBook({super.key});

  @override
  State<ScanSingleBook> createState() => _ScanSingleBookState();
}

class _ScanSingleBookState extends State<ScanSingleBook> {
  List<ShelfItem> filteredShelfItems = [];
  List<ShelfItem> detectedShelfItems = [];
  List<ShelfItem> undetectedItems = [];
  List<String> unknownTags = [];

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? selectedShelf;
  String? detectedTag;
  DateTime? lastTagTime;
  Timer? _scanTimer;

  List<Shelf> books = [];
  BookDetail? bookDetail;
  List<Shelf> filteredShelfs = [];
  TextEditingController searchController = TextEditingController();

  bool _isReading = false;
  bool _isScanning = false;

  // Method untuk memulai pemindaian
  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
    });

    await RFIDScanner.initReader();
    await RFIDScanner.setPower(1);

    final tagData = await RFIDScanner.readTag();

    if (tagData != null) {
      final epc = tagData['epc']?.toString().trim().toUpperCase();
      final rssi = double.tryParse(tagData['rssi'].toString()) ?? -100;

      if (epc != null) {
        setState(() {
          detectedTag = epc;
        });
        await _loadBookDetail(rfid_tag: epc);
      }
    }

    _isReading = false;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Detail Buku'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child:
                      bookDetail?.imageUrl != null &&
                              bookDetail!.imageUrl.isNotEmpty
                          ? Image.network(
                            bookDetail!.imageUrl,
                            height: 150,
                            width: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.book,
                                size: 100,
                                color: Colors.grey,
                              );
                            },
                          )
                          : const Icon(
                            Icons.book,
                            size: 100,
                            color: Colors.grey,
                          ),
                ),
                const SizedBox(height: 12),
                Text('Judul: ${bookDetail?.title ?? '-'}'),
                Text('Kode: ${bookDetail?.itemCode ?? '-'}'),
                Text('Call Number: ${bookDetail?.callNumber ?? '-'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup'),
              ),
            ],
          ),
    );
    _stopScanning();
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
    final undetected =
        filteredShelfItems
            .where(
              (tag) =>
                  !detectedShelfItems.any(
                    (detected) => detected.rfidCode == tag.rfidCode,
                  ),
            )
            .toList();

    if (_scanTimer != null) {
      _scanTimer?.cancel();
      _scanTimer = null;
      RFIDScanner.freeReader();

      setState(() {
        _isReading = false;
        undetectedItems = undetected; // 👈 ini penting!
      });
    }
  }

  void _filterLocalShelf() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredShelfs =
          books.where((shelf) {
            return shelf.shelfName.toLowerCase().contains(query);
          }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterLocalShelf);
    RFIDScanner.initReader();
  }

  final apidetailService = DetailStockopnameService();
  Future<void> _loadBookDetail({String rfid_tag = ''}) async {
    try {
      BookDetail respBookDetail = await apidetailService
          .fetchDetailStockopnames(rfid_tag: rfid_tag);
      setState(() {
        bookDetail = respBookDetail;
      });
    } on UnauthorizedException {
      // handle seperti biasa...
    } catch (e) {
      print('Error saat load buku: $e');
    }
  }

  Future<Directory?> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    }
    return await getApplicationDocumentsDirectory(); // fallback untuk iOS dll
  }

  @override
  void dispose() {
    searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'ScanSingleBook',
          style: TextStyle(color: Colors.white),
        ),
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
            child:
                selectedShelf == null
                    ? _buildBookSearch()
                    : const Text("data kosong"),
          ),
        ],
      ),
    );
  }

  Widget _buildBookSearch() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          textStyle: const TextStyle(fontSize: 18),
          backgroundColor: Colors.orange,
        ),
        onPressed: () {
          _startScanning(); // Panggil scanning saat tombol ditekan
        },
        child: const Text(
          'Mulai Scan Buku',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
