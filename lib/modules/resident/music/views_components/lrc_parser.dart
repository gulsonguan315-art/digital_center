/// LRC 时间戳行数据载体
class LrcLine {
  final Duration time;
  final String text;
  const LrcLine(this.time, this.text);
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
}
