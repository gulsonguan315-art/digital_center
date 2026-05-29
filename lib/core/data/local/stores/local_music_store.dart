import 'dart:async';

import '../../models/music_config.dart';
import 'local_json_store_base.dart';

/// 📂 音乐模块专属子仓 (Dedicated Music Config Sub-store)
/// 独立负责音乐文件夹记忆和播放模式的持久化读写。
class LocalMusicStore extends LocalJsonStoreBase<MusicConfig> {
  LocalMusicStore({required super.configDirPath})
      : super(fileName: 'music_config.json');

  final _musicController = StreamController<MusicConfig>.broadcast();

  Stream<MusicConfig> watchConfig() => _musicController.stream;
  
  Future<MusicConfig> readConfig() => readData();
  
  Future<void> writeConfig(MusicConfig config) async {
    await super.writeData(config);
    _musicController.add(config); // 广播触发前台 UI 响应式热更新
  }

  @override
  MusicConfig fromJson(Map<String, dynamic> json) => MusicConfig.fromJson(json);

  @override
  Map<String, dynamic> toJson(MusicConfig data) => data.toJson();

  @override
  MusicConfig get fallbackValue => MusicConfig.defaultConfig;

  bool _isDisposed = false;

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _musicController.close();
  }
}
