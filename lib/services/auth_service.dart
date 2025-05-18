import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';

class AuthService {
  static Future<bool> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('${Api.baseUrl}/api/v1/GeneralAuthHandler/Login');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10)); // ⏱️ Set timeout

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['data']['access_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        return true;
      } else {
        // Misal salah password atau unauthorized
        throw Exception("Login gagal: ${response.statusCode}");
      }
    } on http.ClientException catch (_) {
      // Jika masalah di client (no internet, DNS)
      throw Exception("Tidak ada koneksi internet.");
    } on TimeoutException catch (_) {
      // Jika melebihi batas waktu
      throw Exception("Permintaan login terlalu lama (timeout).");
    } catch (e) {
      // Error lainnya
      throw Exception("Terjadi kesalahan: $e");
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // static Future<bool> register({
  //   required String username,
  //   required String password,
  // }) async {
  //   final url = Uri.parse(
  //     '${Api.baseUrl}/api/v1/general.general-auth-hendler/register',
  //   ); // pastikan endpoint ini ada
  //   final response = await http.post(
  //     url,
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({'username': username, 'password': password}),
  //   );

  //   if (response.statusCode == 200) {
  //     print("Register Success: ${response.body}");
  //     return true;
  //   } else {
  //     print("Register Failed: ${response.body}");
  //     return false;
  //   }
  //   // return true;
  // }
}
