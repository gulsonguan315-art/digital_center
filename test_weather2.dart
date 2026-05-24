import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'https://api.caiyunapp.com/v2.6/k2y8CKo80CZXFjGr/101.6656,39.2072'.trim();
  
  try {
    print('Testing unified weather endpoint...');
    final res = await http.get(Uri.parse('$baseUrl/weather?dailysteps=3&hourlysteps=24')).timeout(const Duration(seconds: 10));
    print('Status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      print('Has realtime: ${data['result']?['realtime'] != null}');
      print('Has daily: ${data['result']?['daily'] != null}');
      print('Has hourly: ${data['result']?['hourly'] != null}');
    } else {
      print('Body: ${res.body}');
    }

  } catch (e) {
    print('Exception: $e');
  }
}
