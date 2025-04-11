import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';

class AuthService {
  static Future<bool> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse(
      '${Api.baseUrl}/api/v1/general.general-auth-hendler/login',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['data']['access_token']; // adjust if key differs

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      return true;
    } else {
      return false;
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

  static Future<bool> register({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse(
      '${Api.baseUrl}/api/v1/general.general-auth-hendler/register',
    ); // pastikan endpoint ini ada
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      print("Register Success: ${response.body}");
      return true;
    } else {
      print("Register Failed: ${response.body}");
      return false;
    }
  }
}
