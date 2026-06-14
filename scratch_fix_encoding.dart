import 'dart:io';
import 'dart:convert';

void main() {
  final dir = Directory('lib/modules/overlay/book');
  for (final file in dir.listSync()) {
    if (file is File && file.path.endsWith('.dart')) {
      try {
        final content = file.readAsStringSync(encoding: utf8);
        print('${file.path} is already UTF-8');
      } catch (e) {
        final bytes = file.readAsBytesSync();
        final content = utf16le(bytes);
        file.writeAsStringSync(content, encoding: utf8);
        print('${file.path} converted to UTF-8');
      }
    }
  }
}

String utf16le(List<int> bytes) {
  var str = '';
  // Skip BOM if present (0xFF 0xFE)
  int start = 0;
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
    start = 2;
  }
  for (var i = start; i < bytes.length; i += 2) {
    if (i + 1 < bytes.length) {
      str += String.fromCharCode(bytes[i] | (bytes[i + 1] << 8));
    }
  }
  return str;
}
