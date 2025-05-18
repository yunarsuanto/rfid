import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rfid/config/api.dart';
import 'package:rfid/models/shelf.dart';
import 'package:rfid/services/unauthorize.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StockopnameService {
  // URL dasar tanpa query parameter
  final Uri baseUrl = Uri.parse(
    '${Api.baseUrl}/api/v1/general/GeneralBiblioHandler/GetAllBiblioItem',
  );

  // Fungsi untuk mengambil data buku dari API
  Future<List<Shelf>> fetchStockopnames() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final Uri url = baseUrl.replace(queryParameters: {});

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      // print('Decoded body: ${json.encode(data)}');

      List<Shelf> shelfs =
          (data['data'] as List)
              .map((shelfData) => Shelf.fromJson(shelfData))
              .toList();
      return shelfs;
    } else if (response.statusCode == 401) {
      throw UnauthorizedException(); // lempar exception khusus
    } else {
      throw Exception('Failed to load shelfs');
    }
  }
}
