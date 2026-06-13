import 'dart:convert';
import 'dart:io';

void main() async {
  final path = r'C:\Users\Administrator\AppData\Roaming\digital_center\user_settings.json';
  final file = File(path);
  if (!file.existsSync()) {
    print('User settings not found at $path');
    return;
  }
  final content = file.readAsStringSync();
  final json = jsonDecode(content);
  final bookSec = json['book'];
  final baseUrl = bookSec?['abs_api_base'];
  final token = bookSec?['abs_api_keys'];

  print('baseUrl: $baseUrl');
  print('token: $token');

  if (baseUrl == null || token == null || token.isEmpty) {
    print('No valid absBaseUrl or absApiKey in user settings');
    return;
  }

  print('Base URL: $baseUrl');
  
  // 1. Fetch libraries
  final libUrl = '$baseUrl/api/libraries';
  final req1 = await HttpClient().getUrl(Uri.parse(libUrl));
  req1.headers.add('Authorization', 'Bearer $token');
  final res1 = await req1.close();
  final libStr = await res1.transform(utf8.decoder).join();
  print('Libraries status: ${res1.statusCode}');
  
  if (res1.statusCode == 200) {
    final libs = jsonDecode(libStr);
    final libraries = libs['libraries'] as List;
    print('Libraries count: ${libraries.length}');
    for (var lib in libraries) {
      print('Lib: ${lib['id']} - ${lib['name']}');
      
      final itemsUrl = '$baseUrl/api/libraries/${lib['id']}/items?collapseseries=1';
      final req2 = await HttpClient().getUrl(Uri.parse(itemsUrl));
      req2.headers.add('Authorization', 'Bearer $token');
      final res2 = await req2.close();
      final itemsStr = await res2.transform(utf8.decoder).join();
      print('Items for ${lib['name']} status: ${res2.statusCode}');
      
      if (res2.statusCode == 200) {
        final itemsData = jsonDecode(itemsStr);
        final results = itemsData['results'] as List?;
        print('Items count: ${results?.length}');
        if (results != null && results.isNotEmpty) {
          print('First item keys: ${results[0].keys}');
          if (results[0].containsKey('media')) {
             print('media keys: ${results[0]['media'].keys}');
          }
          if (results[0].containsKey('collapsedSeries')) {
             print('collapsedSeries keys: ${results[0]['collapsedSeries'].keys}');
          }
        }
      } else {
        print(itemsStr);
      }
    }
  } else {
    print(libStr);
  }
}
