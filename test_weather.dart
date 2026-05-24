import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'https://api.caiyunapp.com/v2.6/k2y8CKo80CZXFjGr/101.6656,39.2072'.trim();
  
  try {
    print('Testing realtime...');
    final rtRes = await http.get(Uri.parse('$baseUrl/realtime'), headers: {
      // 'User-Agent': 'Mozilla/5.0',
    }).timeout(const Duration(seconds: 5));
    print('Realtime status: ${rtRes.statusCode}');
    if (rtRes.statusCode != 200) {
      print('Realtime body: ${rtRes.body}');
    }

    print('Testing daily...');
    final dailyRes = await http.get(Uri.parse('$baseUrl/daily?dailysteps=3')).timeout(const Duration(seconds: 5));
    print('Daily status: ${dailyRes.statusCode}');
    if (dailyRes.statusCode != 200) {
      print('Daily body: ${dailyRes.body}');
    }

    print('Testing hourly...');
    final hourlyRes = await http.get(Uri.parse('$baseUrl/hourly?hourlysteps=24')).timeout(const Duration(seconds: 5));
    print('Hourly status: ${hourlyRes.statusCode}');
    if (hourlyRes.statusCode != 200) {
      print('Hourly body: ${hourlyRes.body}');
    }

  } catch (e) {
    print('Exception: $e');
  }
}
