import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  // Read settings
  final settingsFile = File('C:/Users/Administrator/AppData/Roaming/digital_center/user_settings.json');
  if (!settingsFile.existsSync()) {
    print('Settings not found');
    return;
  }
  final settingsData = jsonDecode(settingsFile.readAsStringSync());
  final token = settingsData['book']['abs_api_keys'];
  final baseUrl = settingsData['book']['abs_api_base'];

  final itemId = '5072e0b4-54f0-46e5-91c3-cf053d6a5353';
  final url = '$baseUrl/api/items/$itemId/download';

  final response = await http.get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
  print(response.statusCode);
  File('scratch_book.bin').writeAsBytesSync(response.bodyBytes);
  print('Saved to scratch_book.bin, size: ${response.bodyBytes.length}');
}
