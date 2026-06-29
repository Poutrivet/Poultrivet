import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =;

  // Fetch national summary - powers Statistics screen
  static Future<Map<String, dynamic>> getSummary() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/summary'))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load summary');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Fetch specific district - powers Maps screen
  static Future<Map<String, dynamic>> getDistrict(String districtName) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/district/$districtName'))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('District not found');
      } else {
        throw Exception('Failed to load district');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }
}
