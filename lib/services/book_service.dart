import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:elibrary/config/api.dart';
import 'package:elibrary/models/book.dart';
import 'package:elibrary/services/unauthorize.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookService {
  // URL dasar tanpa query parameter
  final Uri baseUrl = Uri.parse(
    '${Api.baseUrl}/api/v1/general/GeneralBiblioHandler/GetList',
  );

  // Fungsi untuk mengambil data buku dari API
  Future<List<Book>> fetchBooks({
    String search = '',
    int limit = 20,
    int page = 1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final Uri url = baseUrl.replace(
      queryParameters: {'limit': '$limit', 'page': '$page', 'search': search},
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      List<Book> books =
          (data['data'] as List)
              .map((bookData) => Book.fromJson(bookData))
              .toList();
      return books;
    } else if (response.statusCode == 401) {
      throw UnauthorizedException(); // lempar exception khusus
    } else {
      throw Exception('Failed to load books');
    }
  }
}
