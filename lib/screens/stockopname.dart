import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:csv/csv.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/services.dart';
import 'package:rfid/models/book_detail.dart';
import 'package:rfid/services/detail_stockopname_service.dart';
import 'package:flutter/material.dart';
import 'package:rfid/models/shel_item.dart';
import 'package:rfid/models/shelf.dart';
import 'package:rfid/services/rfid_scanner.dart';
import 'package:rfid/services/stockopname_service.dart';
import 'package:rfid/services/unauthorize.dart';
// import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

class Stockopname extends StatefulWidget {
  const Stockopname({super.key});

  @override
  State<Stockopname> createState() => _StockopnameState();
}

class _StockopnameState extends State<Stockopname> {
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
  TextEditingController folderName = TextEditingController();

  bool _isReading = false;
  bool _isScanning = false;

  // Method untuk memulai pemindaian
  Future<void> _startScanning({List<ShelfItem> tags = const []}) async {
    setState(() {
      _isScanning = true;
    });

    await RFIDScanner.initReader();
    await RFIDScanner.setPower(10);

    final validTags =
        tags.where((tag) => tag.availability == 'Tersedia').toList();

    if (validTags.isEmpty) {
      setState(() {
        selectedShelf = null;
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
      return;
    }

    final detectedEpcs =
        <String>{}; // Set untuk melacak EPC yang sudah terdeteksi

    _scanTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (_isReading) return;
      _isReading = true;

      final tagData = await RFIDScanner.readTag();

      if (tagData != null) {
        final epc = tagData['epc']?.toString().trim().toUpperCase();
        print("EPC Bytes: ${epc?.codeUnits}");

        if (epc != null) {
          // Cek jika EPC sudah ada dalam detectedShelfItems
          if (detectedEpcs.contains(epc) ||
              detectedShelfItems.any((item) => item.rfidCode == epc)) {
            _isReading = false;
            return; // Tidak perlu menambahkannya lagi
          }

          // Cari item yang sesuai dengan EPC
          final detectedItem = validTags.firstWhere(
            (tag) => tag.rfidCode == epc,
            orElse:
                () => ShelfItem(
                  id: 0,
                  itemCode: '',
                  callNumber: '',
                  availability: '',
                  rfidCode: '',
                ),
          );

          if (detectedItem.rfidCode.isNotEmpty) {
            // Item yang valid ditemukan
            setState(() {
              detectedShelfItems.add(detectedItem);
              detectedEpcs.add(epc);

              // Perbarui undetectedItems agar tidak ada duplikat
              undetectedItems =
                  validTags
                      .where(
                        (item) =>
                            !detectedShelfItems.any(
                              (d) => d.rfidCode == item.rfidCode,
                            ),
                      )
                      .toList();
            });

            // Putar suara setiap kali RFID baru ditambahkan
            _audioPlayer.setVolume(1.0);
            await _audioPlayer.play(AssetSource('sounds/bip.wav'));
          } else {
            // Jika RFID tidak ditemukan dalam daftar valid, tambahkan ke unknownTags
            setState(() {
              if (!unknownTags.contains(epc)) {
                unknownTags.add(epc); // Tambahkan EPC ke unknownTags
              }
            });
          }
        }
      }

      _isReading = false;

      // Stop jika semua valid tags telah terdeteksi
      if (detectedEpcs.length == validTags.length) {
        _scanTimer?.cancel();
        RFIDScanner.freeReader();
      }
    });
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
    _loadShelfs();
    searchController.addListener(_filterLocalShelf);
    RFIDScanner.initReader();
  }

  final apiService = StockopnameService();
  Future<void> _loadShelfs() async {
    try {
      List<Shelf> loadedShelfs = await apiService.fetchStockopnames();
      setState(() {
        books = loadedShelfs;
        filteredShelfs = loadedShelfs; // Awal sama dengan semua
      });
    } on UnauthorizedException {
      // handle seperti biasa...
    } catch (e) {
      print('Error saat load buku: $e');
    }
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

  Future<void> _saveCsv() async {
    final foldername = folderName.text.toLowerCase();
    try {
      const permissionChannel = MethodChannel('com.example/permissions');

      if (Platform.isAndroid) {
        bool granted = await permissionChannel.invokeMethod('checkStorage');
        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Akses storage dibutuhkan. Silakan izinkan lewat Settings.',
              ),
            ),
          );

          // Tunggu sebentar, lalu cek lagi
          await Future.delayed(const Duration(seconds: 2));
          granted = await permissionChannel.invokeMethod('checkStorage');
        }

        if (granted) {
          print('Permission granted');
        } else {
          print('Permission masih ditolak');
        }
      }

      List<String> rowDetecteds = [];
      List<String> rowUndetecteds = [];
      List<String> rowUnknows = [];
      for (var item in detectedShelfItems) {
        rowDetecteds.add(item.itemCode);
      }

      for (var item in undetectedItems) {
        rowUndetecteds.add(item.itemCode);
      }

      for (var item in unknownTags) {
        rowUnknows.add(item.toString());
      }

      // String csv = const ListToCsvConverter().convert(rowDetecteds);

      final downloadsPath =
          await ExternalPath.getExternalStoragePublicDirectory(
            ExternalPath.DIRECTORY_DOWNLOAD,
          );
      final directory = Directory(downloadsPath);

      final contentDetected = rowDetecteds.join('\n');
      final file = File(
        '${directory.path}/${foldername}_terdeteksi_${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      await file.writeAsString(contentDetected);

      final contentUndetecteds = rowUndetecteds.join('\n');
      final fileUndetected = File(
        '${directory.path}/${foldername}_tidak_terdeteksi_${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      await fileUndetected.writeAsString(contentUndetecteds);

      final contentUnknows = rowUnknows.join('\n');
      final fileUnknow = File(
        '${directory.path}/${foldername}_tidak_diketahui_${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      await fileUnknow.writeAsString(contentUnknows);

      // await saveToTextFile(unknownTags, type: 'adadsadd');
      // final path =
      //     '${directory.path}/rfid_scan_${DateTime.now().millisecondsSinceEpoch}.txt';
      // final file = File(path);

      // await file.writeAsString(csv);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV berhasil disimpan')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan CSV: $e')));
    }
  }

  Future<void> saveToTextFile(
    List<List<String>> rows, {
    String type = '',
  }) async {
    try {
      final directory = await getExternalStorageDirectory();
      final path = directory?.path ?? '/storage/emulated/0/Download';
      final file = File(
        '$path/scan_result${type}_${DateTime.now().millisecondsSinceEpoch}.txt',
      );

      // Format data menjadi string per baris
      final content = rows.map((row) => row.join('\t')).join('\n');

      await file.writeAsString(content);

      print('File saved to: ${file.path}');
    } catch (e) {
      print('Error saving file: $e');
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
        title: const Text('Stockopname', style: TextStyle(color: Colors.white)),
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
            child: selectedShelf == null ? _buildShelfList() : _buildScanView(),
          ),
        ],
      ),
    );
  }

  Widget _buildShelfList() {
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
              filteredShelfs.isEmpty
                  ? const Center(
                    child: Text(
                      'Tidak ada buku ditemukan',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                  : ListView.builder(
                    itemCount: filteredShelfs.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final shelf = filteredShelfs[index];
                      return Card(
                        color: Colors.white.withAlpha((0.2 * 255).toInt()),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          onTap: () async {
                            if (shelf.items.isNotEmpty) {
                              setState(() {
                                selectedShelf = shelf.shelfName;
                                filteredShelfItems = shelf.items;
                                detectedTag = null;
                              });
                              // _startScanning(tags: shelf.items);
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
                          leading: const Icon(Icons.book, color: Colors.white),
                          title: Text(
                            shelf.shelfName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            // shelf.hashCode.toString(),
                            "Rak: ${shelf.shelfCode} \nJumlah Buku Terdaftar ${shelf.totalItems}",
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

  // filteredShelfItems
  // detectedShelfItems
  // undetectedItems
  // unknownTags
  Widget _buildScanView() {
    return Column(
      children: [
        const SizedBox(height: kToolbarHeight + 24),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), // Lekuk atas kiri
                topRight: Radius.circular(20), // Lekuk atas kanan
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selectedShelf} Jumlah: ${filteredShelfItems.length}, Terdeteksi: ${detectedShelfItems.length}, Tidak Terdeteksi: ${undetectedItems.length}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      ...detectedShelfItems.map(
                        (item) => Card(
                          color: Colors.white.withOpacity(0.8),
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            title: Text(
                              item.itemCode,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              '${item.callNumber} - ${item.availability}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (undetectedItems.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Divider(),
                        Text(
                          'RFID Tidak Terdeteksi:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        ...undetectedItems.map(
                          (item) => Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              leading: Icon(Icons.cancel, color: Colors.red),
                              title: Text(
                                item.itemCode,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              subtitle: Text(
                                '${item.callNumber} - ${item.availability}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.only(
                // topLeft: Radius.circular(20), // Lekuk atas kiri
                // topRight: Radius.circular(20), // Lekuk atas kanan
                bottomLeft: Radius.circular(20), // Lekuk atas kanan
                bottomRight: Radius.circular(20), // Lekuk atas kanan
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RFID Tidak Dikenal Jumlah : ${unknownTags.length}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: unknownTags.length, // dummy count
                    itemBuilder: (context, index) {
                      return Card(
                        color: Colors.white,
                        child: ListTile(
                          title: Text('RFID Tidak Dikenal #$index'),
                          subtitle: Text('RFID: ${unknownTags[index]}'),
                          onTap: () async {
                            final rfid = unknownTags[index];
                            await _loadBookDetail(rfid_tag: rfid.toString());
                            ShelfItem? matchedItem;

                            for (final shelf in books) {
                              try {
                                matchedItem = shelf.items.firstWhere(
                                  (item) => item.rfidCode == rfid,
                                );
                                break; // keluar dari loop jika sudah ketemu
                              } catch (_) {
                                break;
                              }
                            }

                            // Tampilkan dialog
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text('Detail Buku'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child:
                                              bookDetail?.imageUrl != null &&
                                                      bookDetail!
                                                          .imageUrl
                                                          .isNotEmpty
                                                  ? Image.network(
                                                    bookDetail!.imageUrl,
                                                    height: 150,
                                                    width: 100,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
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
                                        Text(
                                          'Judul: ${bookDetail?.title ?? '-'}',
                                        ),
                                        Text(
                                          'Kode: ${bookDetail?.itemCode ?? '-'}',
                                        ),
                                        Text(
                                          'Call Number: ${bookDetail?.callNumber ?? '-'}',
                                        ),
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
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isScanning)
              ElevatedButton(
                onPressed: () {
                  _startScanning(tags: filteredShelfItems);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: BorderSide(color: Colors.black),
                ),
                child: Text("Start Scanning"),
              ),
            SizedBox(width: 20),
            if (_isScanning)
              ElevatedButton(
                onPressed: _stopScanning,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text("Stop Scanning"),
              ),
            SizedBox(width: 20),
            ElevatedButton(
              onPressed:
                  () => showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Simpan'),
                          content: SizedBox(
                            width: 100,
                            height: 50,
                            child: Column(
                              children: [
                                TextField(
                                  controller: folderName,
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed:
                                  () => {Navigator.pop(context), _saveCsv()},
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                  ), // fungsi simpan CSV
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text("Save CSV"),
            ),
          ],
        ),
      ],
    );
  }
}
