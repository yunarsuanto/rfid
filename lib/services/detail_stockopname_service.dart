import 'dart:convert';
import 'package:elibrary/models/book_detail.dart';
import 'package:http/http.dart' as http;
import 'package:elibrary/config/api.dart';
import 'package:elibrary/models/shelf.dart';
import 'package:elibrary/services/unauthorize.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailStockopnameService {
  // URL dasar tanpa query parameter
  final Uri baseUrl = Uri.parse(
    '${Api.baseUrl}/api/v1/general/GeneralBiblioHandler/GetDetail',
  );

  // Fungsi untuk mengambil data buku dari API
  Future<BookDetail> fetchDetailStockopnames({String rfid_tag = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final Uri url = baseUrl.replace(queryParameters: {'rfid_tag': rfid_tag});

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('---- REQUEST');
    print('URL: $url');
    print('Headers: ${response.request?.headers}');
    print('---- RESPONSE');
    print('Status Code: ${response.statusCode}');
    print('Body: ${response.body.length}');
    print('---- END RESPONSE');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final Map<String, dynamic> bookData = data['data'];
      if (bookData.isNotEmpty) {
        return BookDetail.fromJson(bookData);
      } else {
        throw Exception('Data kosong');
      }
    } else if (response.statusCode == 401) {
      throw UnauthorizedException();
    } else {
      throw Exception('Failed to load book detail');
    }
  }
}
