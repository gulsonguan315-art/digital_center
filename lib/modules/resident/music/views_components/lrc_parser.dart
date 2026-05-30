import 'dart:convert';

/// LRC 逐字数据载体
class LrcWord {
  final String text;
  final Duration relativeStartTime;
  final Duration duration;
  const LrcWord(this.text, this.relativeStartTime, this.duration);
}

/// LRC 时间戳行数据载体
class LrcLine {
  final Duration time;
  final String text;
  final List<LrcWord>? words;
  const LrcLine(this.time, this.text, {this.words});
}

/// LRC 解析器：支持 [mm:ss]、[mm:ss.xx]、[mm:ss.xxx]
class LrcParser {
  static List<LrcLine> parse(String text) {
    final List<LrcLine> lines = [];
    final re = RegExp(r'\[(\d+):(\d+)(?:\.(\d+))?\](.*)');

    for (final line in text.split('\n')) {
      final m = re.firstMatch(line);
      if (m == null) continue;

      final min = int.parse(m.group(1)!);
      final sec = int.parse(m.group(2)!);
      final msStr = m.group(3) ?? '0';
      final ms = switch (msStr.length) {
        1 => int.parse(msStr) * 100,
        2 => int.parse(msStr) * 10,
        _ => int.parse(msStr.substring(0, 3)),
      };

      lines.add(LrcLine(
        Duration(minutes: min, seconds: sec, milliseconds: ms),
        m.group(4)!.trim(),
      ));
    }

    // 尝试解析并合入 awlrc 逐字歌词
    // 注意：某些后端（如 Gonic/taglib）可能会在解析多重标签时将多个 awlrc 拼接在一起，例如 `[awlrc:base64_1,awlrc:base64_2]`
    // 所以我们提取所有的 awlrc payload，并找到其中真正包含 `<时间,持续时间>` 逐字数据的那个进行解析
    final awlrcRe = RegExp(r'awlrc:(?:lrc:)?([A-Za-z0-9+/=]+)');
    final awlrcMatches = awlrcRe.allMatches(text);
    
    for (final match in awlrcMatches) {
      try {
        final b64Text = match.group(1)!;
        final decoded = utf8.decode(base64.decode(b64Text));
        
        // 简单校验是否包含逐字数据特征 `<时间,持续时间>`
        if (decoded.contains(RegExp(r'<\d+,\d+>'))) {
          _mergeWordByWordData(lines, decoded);
          break; // 找到并合入后就跳出
        }
      } catch (e) {
        // 解码或解析失败，忽略该片段
      }
    }

    // 纯文本降级：没有时间戳则按行展示
    if (lines.isEmpty) {
      int idx = 0;
      for (final line in text.split('\n')) {
        final t = line.trim();
        if (t.isNotEmpty) lines.add(LrcLine(Duration(milliseconds: idx++), t));
      }
    } else {
      lines.sort((a, b) => a.time.compareTo(b.time));
    }

    return lines;
  }

  /// 将解码后的 awlrc 逐字文本按时间戳合并入已有 lines 中
  static void _mergeWordByWordData(List<LrcLine> lines, String awlrcText) {
    final lineRe = RegExp(r'\[(\d+):(\d+)(?:\.(\d+))?\](.*)');
    // 匹配类似 <0,315>烟
    final wordRe = RegExp(r'<(\d+),(\d+)>([^<]+)');
    
    // 建立基于毫秒时间戳的快速映射，方便对应
    final Map<int, LrcLine> lineMap = {
      for (var line in lines) line.time.inMilliseconds: line
    };

    for (final lineStr in awlrcText.split('\n')) {
      final m = lineRe.firstMatch(lineStr);
      if (m == null) continue;

      final min = int.parse(m.group(1)!);
      final sec = int.parse(m.group(2)!);
      final msStr = m.group(3) ?? '0';
      final ms = switch (msStr.length) {
        1 => int.parse(msStr) * 100,
        2 => int.parse(msStr) * 10,
        _ => int.parse(msStr.substring(0, 3)),
      };
      
      final timestampMs = Duration(minutes: min, seconds: sec, milliseconds: ms).inMilliseconds;
      if (lineMap.containsKey(timestampMs)) {
        final wordsContent = m.group(4)!;
        final List<LrcWord> words = [];
        
        for (final wm in wordRe.allMatches(wordsContent)) {
          words.add(LrcWord(
            wm.group(3)!, // 文本
            Duration(milliseconds: int.parse(wm.group(1)!)), // 起始偏移
            Duration(milliseconds: int.parse(wm.group(2)!)), // 持续时长
          ));
        }
        
        if (words.isNotEmpty) {
          // 替换原来的 line 为包含 words 的新 line
          final idx = lines.indexWhere((l) => l.time.inMilliseconds == timestampMs);
          if (idx != -1) {
            lines[idx] = LrcLine(lines[idx].time, lines[idx].text, words: words);
          }
        }
      }
    }
  }
}
