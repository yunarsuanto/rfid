import 'package:flutter/material.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  List<Map<String, String>> books = [
    {'title': 'Flutter Dasar', 'author': 'John Doe'},
    {'title': 'Pemrograman Golang', 'author': 'Jane Smith'},
    {'title': 'Belajar UI/UX', 'author': 'Alex Tan'},
  ];

  List<Map<String, String>> filteredBooks = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredBooks = books;
    searchController.addListener(_filterBooks);
  }

  void _filterBooks() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredBooks =
          books.where((book) {
            return book['title']!.toLowerCase().contains(query) ||
                book['author']!.toLowerCase().contains(query);
          }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          Image.asset("lib/assets/images/bg.png", fit: BoxFit.cover),
          Container(color: Colors.black.withAlpha((0.7 * 255).toInt())),
          Column(
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
                child: ListView.builder(
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
                        leading: const Icon(Icons.book, color: Colors.white),
                        title: Text(
                          book['title']!,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          book['author']!,
                          style: TextStyle(
                            color: Colors.white.withAlpha((0.8 * 255).toInt()),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
