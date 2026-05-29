import 'dart:async';

import '../../models/poetry_data.dart';
import 'local_json_store_base.dart';

/// 📂 每日网络诗词专属子仓 (Dedicated Poetry Sub-store)
/// 独立负责今日推荐诗词的本地持久化读取与写入，防止网络异常导致页面白屏。
class LocalPoetryStore extends LocalJsonStoreBase<PoetryData> {
  LocalPoetryStore({required super.configDirPath})
      : super(fileName: 'daily_poetry.json');

  final _poetryController = StreamController<PoetryData>.broadcast();

  /// 适配大管家历史调用 API (Backward Compatibility Proxies)
  Stream<PoetryData> watchPoetry() => _poetryController.stream;
  Future<PoetryData> readPoetry() => readData();
  Future<void> writePoetry(PoetryData poetry) => writeData(poetry);

  @override
  Future<void> writeData(PoetryData data) async {
    await super.writeData(data);
    _poetryController.add(data); // 广播触发前台 UI 响应式热更新
  }

  @override
  PoetryData fromJson(Map<String, dynamic> json) => PoetryData.fromJson(json);

  @override
  Map<String, dynamic> toJson(PoetryData data) => data.toJson();

  @override
  PoetryData get fallbackValue => PoetryData.defaultPoetry;

  bool _isDisposed = false;

  /// Safe dispose.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _poetryController.close();
  }
}
