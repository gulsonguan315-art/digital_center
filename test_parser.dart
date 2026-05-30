import 'dart:io';
import 'lib/modules/resident/music/views_components/lrc_parser.dart';

void main() async {
  final text = await File('test.lrc').readAsString();
  final lines = LrcParser.parse(text);
  print('Total lines: ${lines.length}');
  
  int wordsCount = 0;
  for (var line in lines) {
    if (line.words != null && line.words!.isNotEmpty) {
      wordsCount++;
      print('Line: ${line.time} -> ${line.text} (words: ${line.words!.length})');
      for (var word in line.words!) {
        print('  - ${word.text} at ${word.relativeStartTime}');
      }
    }
  }
  
  if (wordsCount == 0) {
    print('Failed to find any words!');
    // Let's debug the regex
    final awlrcRe = RegExp(r'\[awlrc:(?:lrc:)?([A-Za-z0-9+/=]+)\]');
    final awlrcMatch = awlrcRe.firstMatch(text);
    if (awlrcMatch != null) {
      print('Found awlrc match!');
    } else {
      print('No awlrc match found.');
      // print end of text
      print('End of text: ${text.substring(text.length - 200)}');
    }
  }
}
