import 'dart:io';
import 'package:archive/archive_io.dart';

void main() {
  final bytes = File('scratch_book.bin').readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  for (var file in archive) {
    print('${file.name} - ${file.size}');
  }
}
