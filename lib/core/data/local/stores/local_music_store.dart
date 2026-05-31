import 'dart:async';

import '../../models/music_config.dart';
import 'local_json_store_base.dart';

/// 📂 音乐模块专属子仓 (Dedicated Music Config Sub-store)
/// 独立负责音乐文件夹记忆和播放模式的持久化读写。
class LocalMusicStore extends LocalJsonStoreBase<MusicConfig> {
  LocalMusicStore({required super.configDirPath})
      : super(fileName: 'music_config.json');

  final _musicController = StreamController<MusicConfig>.broadcast();
  Timer? _saveTimer;
  MusicConfig? _pendingConfig;

  Stream<MusicConfig> watchConfig() => _musicController.stream;
  
  Future<MusicConfig> readConfig() async {
    if (_pendingConfig != null) {
      return _pendingConfig!;
    }
    return readData();
  }
  
  Future<void> writeConfig(MusicConfig config) async {
    _pendingConfig = config;
    _musicController.add(config); // 广播触发前台 UI 响应式热更新
    
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 5000), () async {
      if (_pendingConfig != null) {
        await super.writeData(_pendingConfig!);
        _pendingConfig = null;
      }
    });
  }

  @override
  MusicConfig fromJson(Map<String, dynamic> json) => MusicConfig.fromJson(json);

  @override
  Map<String, dynamic> toJson(MusicConfig data) => data.toJson();

  @override
  MusicConfig get fallbackValue => MusicConfig.defaultConfig;

  bool _isDisposed = false;

  void flush() {
    _saveTimer?.cancel();
    if (_pendingConfig != null) {
      super.writeData(_pendingConfig!);
      _pendingConfig = null;
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    flush();
    _musicController.close();
  }
}
