import 'package:flutter/material.dart';
import 'package:rfid/screens/book_list_screen.dart';
import 'package:rfid/screens/scan_single_book.dart';
import 'package:rfid/screens/stockopname.dart';
import '../services/auth_service.dart';

final List<Map<String, dynamic>> menus = [
  {'title': 'Daftar Buku', 'icon': Icons.book},
  {'title': 'Stockopname', 'icon': Icons.qr_code_scanner},
  {'title': 'Scan Buku', 'icon': Icons.zoom_in},
  // {'title': 'Pengaturan', 'icon': Icons.settings},
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoggingOut = false;

  void handleLogout() async {
    setState(() {
      isLoggingOut = true;
    });

    await AuthService.logout();
    if (!mounted) return;
    setState(() {
      isLoggingOut = false;
    });
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130), // Menambah tinggi AppBar
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.2 * 255).toInt()),
                spreadRadius: 2,
                blurRadius: 10,
                offset: Offset(0, 4), // Shading
              ),
            ],
            // borderRadius: BorderRadius.only(
            //   bottomLeft: Radius.circular(30),
            //   bottomRight: Radius.circular(30),
            // ),
          ),
          child: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text("Beranda", style: TextStyle(color: Colors.white)),
            centerTitle: true,
            backgroundColor:
                Colors
                    .transparent, // Transparent untuk menggunakan background gradient
            elevation: 0,
            actions: [
              isLoggingOut
                  ? const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                  : IconButton(
                    icon: const Icon(Icons.logout),
                    color: Colors.white,
                    onPressed: handleLogout,
                  ),
            ],
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg.png', fit: BoxFit.cover),
          Container(color: Colors.black.withAlpha((0.7 * 255).toInt())),
          Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.builder(
              itemCount: menus.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final item = menus[index];
                return GestureDetector(
                  onTap: () {
                    switch (item['title']) {
                      case 'Daftar Buku':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BookListScreen(),
                          ),
                        );
                        break;
                      case 'Stockopname':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Stockopname(),
                          ),
                        );
                        break;
                      case 'Scan Buku':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScanSingleBook(),
                          ),
                        );
                        break;
                      case 'Pengaturan':
                        break;
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        CircleAvatar(
                          backgroundColor: Colors.orange.withAlpha(
                            (1 * 255).toInt(),
                          ),
                          radius: 50,
                          child: Icon(
                            item['icon'],
                            color: Colors.black.withAlpha((1 * 255).toInt()),
                            size: 60,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          item['title'],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
