import 'dart:convert';
import 'dart:io';

void main() async {
  final path = r'C:\Users\Administrator\AppData\Roaming\digital_center\user_settings.json';
  final file = File(path);
  if (!file.existsSync()) {
    print('User settings not found');
    return;
  }
  final content = file.readAsStringSync();
  final json = jsonDecode(content);
  final bookSec = json['book'];
  final baseUrl = bookSec?['abs_api_base'];
  final token = bookSec?['abs_api_keys'];

  if (baseUrl == null || token == null) return;

  // Let's get the first item from the first library
  final libUrl = '$baseUrl/api/libraries';
  final req = await HttpClient().getUrl(Uri.parse(libUrl));
  req.headers.add('Authorization', 'Bearer $token');
  final res = await req.close();
  final libStr = await res.transform(utf8.decoder).join();
  final libs = jsonDecode(libStr);
  final libId = libs['libraries'][0]['id'];

  final itemsUrl = '$baseUrl/api/libraries/$libId/items';
  final req2 = await HttpClient().getUrl(Uri.parse(itemsUrl));
  req2.headers.add('Authorization', 'Bearer $token');
  final res2 = await req2.close();
  final itemsStr = await res2.transform(utf8.decoder).join();
  final itemsData = jsonDecode(itemsStr);
  final results = itemsData['results'] as List;
  if (results.isEmpty) {
    print('No items found');
    return;
  }

  // Find a series if any, and get its libraryItemIds
  String? singleItemId;
  for (var item in results) {
    if (item.containsKey('collapsedSeries')) {
      final ids = item['collapsedSeries']['libraryItemIds'] as List;
      if (ids.isNotEmpty) {
        singleItemId = ids[0];
        break;
      }
    } else {
      singleItemId = item['id'];
    }
  }

  if (singleItemId == null) {
    singleItemId = results[0]['id'];
  }

  print('Fetching single item: $singleItemId');
  final itemUrl = '$baseUrl/api/items/$singleItemId';
  final req3 = await HttpClient().getUrl(Uri.parse(itemUrl));
  req3.headers.add('Authorization', 'Bearer $token');
  final res3 = await req3.close();
  final itemStr = await res3.transform(utf8.decoder).join();
  final itemJson = jsonDecode(itemStr);
  print('Item keys: ${itemJson.keys}');
  if (itemJson.containsKey('media')) {
    print('media keys: ${itemJson['media'].keys}');
    if (itemJson['media'].containsKey('metadata')) {
      print('metadata: ${itemJson['media']['metadata']}');
    }
  }
}
