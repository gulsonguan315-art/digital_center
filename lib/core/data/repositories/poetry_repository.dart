import 'dart:async';
import '../local/local_config_store.dart';
import '../models/poetry_data.dart';
import '../remote/remote_api_client.dart';

/// 📂 每日诗词业务专属仓库 (Poetry Domain Repository)
/// 负责每日推荐古诗词、高亮划线、以及内容自定义的 SWR 读写逻辑与后台网络同步。
class PoetryRepository {
  final LocalConfigStore _localStore;
  final RemoteApiClient _remoteClient;

  PoetryRepository(this._localStore, this._remoteClient);

  /// 全局唯一单例，在 DataManager 初始化时注入绑定
  static late final PoetryRepository instance;

  Stream<PoetryData>? _poetryStream;
  PoetryData? _lastPoetry; // 内存高保真缓存，支持 Web 重用与零延时同步
  Timer? _midnightTimer;

  PoetryData get latestPoetry => _lastPoetry ?? PoetryData.defaultPoetry;

  /// 用于引导启动加载内存缓存
  Future<void> init() async {
    try {
      _lastPoetry = await _localStore.poetry.readPoetry();
    } catch (_) {}
    _scheduleMidnightRefresh();
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    // 计算下一个午夜的时间 (跨天加 1 秒，确保足够跨入第二天)
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationToMidnight = tomorrow.difference(now) + const Duration(seconds: 1);

    _midnightTimer = Timer(durationToMidnight, () {
      // 午夜时分，主动在后台同步最新的古诗
      _syncPoetryInBackground();
      // 同步完成后，安排下一个午夜的定时器
      _scheduleMidnightRefresh();
    });
  }

  void dispose() {
    _midnightTimer?.cancel();
  }

  /// 业务层向总管家申请：响应式收听每日推荐网络诗词。
  /// 使用“自销毁共享广播流”，确保高频/并发订阅时 0 重复网络开销、0 内存泄露！
  Stream<PoetryData> watchTodayPoetry() {
    _poetryStream ??= _createPoetryStream().asBroadcastStream(
      onCancel: (subscription) {
        // 🛡️ 自销毁：订阅者全部离开时清空缓存，断开管道防泄漏
        _poetryStream = null;
        subscription.cancel();
      },
    );
    return _poetryStream!;
  }

  /// 创建底层的网络古诗监控管道流
  Stream<PoetryData> _createPoetryStream() {
    final controller = StreamController<PoetryData>();

    // 1. Offline-First: 立即向本地磁盘诗词子仓读取缓存，实现 0 延时闪瞬秒开
    _localStore.poetry.readPoetry().then((cached) {
      _lastPoetry = cached;
      if (!controller.isClosed) {
        controller.add(cached);
      }
      // 2. Background Sync (SWR): 发起后台异步网络请求，对用户无感
      _syncPoetryInBackground();
    });

    // 3. Reactive Piping: 订阅本地磁盘缓存子仓的更改广播
    final subscription = _localStore.poetry.watchPoetry().listen(
      (data) {
        _lastPoetry = data;
        if (!controller.isClosed) {
          controller.add(data);
        }
      },
      onError: (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      },
      onDone: () {
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    controller.onCancel = () {
      subscription.cancel();
    };

    // 🌟 配合重载的 PoetryData.== 操作符进行去重，杜绝网络获取相同数据时的重复刷新！
    return controller.stream.distinct();
  }

  /// 后台异步诗词数据拉取同步逻辑
  Future<void> _syncPoetryInBackground() async {
    try {
      final fresh = await _remoteClient.fetchTodayPoetry();
      // 拉取成功后直接刷写本地磁盘缓存，自动广播触发前台 UI 刷新
      await _localStore.poetry.writePoetry(fresh);
    } catch (e) {
      // 容错：网络离线或接口异常时，静默捕获异常，前台完美展示上一次缓存的古诗
    }
  }

  /// 业务层向总管家申请：保存并回写诗词标记数据（离线秒写 + 异步网络回传 SWR）
  Future<void> savePoetryMarks(PoetryData updatedPoetry) async {
    _lastPoetry = updatedPoetry;
    // 1. 立刻写入本地缓存子仓，以触发前台 UI 看板同步响应式更新
    await _localStore.poetry.writePoetry(updatedPoetry);

    // 2. 后台异步发送网络回传保存，完全对前台无阻碍，支持断网离线操作
    _uploadPoetryMarksInBackground(updatedPoetry.id, updatedPoetry.markedLines);
  }

  Future<void> _uploadPoetryMarksInBackground(
    String poemId,
    List<int> markedLines,
  ) async {
    try {
      await _remoteClient.uploadPoemMark(poemId, markedLines);
    } catch (e) {
      // 容错：静默吸收网络异常，保障极端的离线手账体验
    }
  }

  /// 业务层向总管家申请：保存并回写自定义修改的诗词内容（离线秒写 + 异步网络回传 SWR）
  Future<void> saveCustomPoetry(PoetryData updatedPoetry) async {
    _lastPoetry = updatedPoetry;
    // 1. 立刻写入本地缓存子仓，以触发前台 UI 看板同步响应式更新
    await _localStore.poetry.writePoetry(updatedPoetry);

    // 2. 后台异步发送网络回传保存
    _uploadCustomPoetryInBackground(
      updatedPoetry.id,
      updatedPoetry.paragraphs,
      updatedPoetry.title,
      updatedPoetry.author,
    );
  }

  Future<void> _uploadCustomPoetryInBackground(
    String poemId,
    List<String> paragraphs,
    String title,
    String author,
  ) async {
    try {
      await _remoteClient.uploadPoemCustom(
        poemId,
        paragraphs,
        title: title,
        author: author,
      );
    } catch (e) {
      // 容错：静默吸收网络异常，保障极端的离线手账体验
    }
  }
}
