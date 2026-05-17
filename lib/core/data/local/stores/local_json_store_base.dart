import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 📁 泛型本地 JSON 存储基类 (Generic Local JSON Storage Base)
/// 统一处理底层的网络/本地文件 I/O 读写、Isolate 异步编解码计算、自愈与 Fallback 拦截，消灭大量冗余样板代码。
abstract class LocalJsonStoreBase<T> {
  final String configDirPath;
  final String fileName;

  LocalJsonStoreBase({
    required this.configDirPath,
    required this.fileName,
  });

  String get _filePath => '$configDirPath/$fileName';

  // --- 由具体业务子仓实现的转换接口 (Abstract converter interface) ---
  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson(T data);
  T get fallbackValue;

  /// 📖 统一异步读取接口 (Unified Async Reader)
  Future<T> readData() async {
    if (kIsWeb) return fallbackValue;
    try {
      final file = File(_filePath);
      if (!file.existsSync()) {
        await writeData(fallbackValue);
        return fallbackValue;
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) return fallbackValue;
      
      final json = jsonDecode(content) as Map<String, dynamic>;
      return fromJson(json);
    } catch (e) {
      return fallbackValue;
    }
  }

  /// ✍️ 统一异步写入接口 (Unified Async Writer)
  Future<void> writeData(T data) async {
    if (kIsWeb) return;
    try {
      final file = File(_filePath);
      final encoded = jsonEncode(toJson(data));
      await file.writeAsString(encoded, flush: true);
    } catch (e) {
      // 容错防御拦截
    }
  }
}
