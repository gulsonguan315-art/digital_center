import 'package:flutter/material.dart';

/// 🎭 舞台状态管理器
/// 维护二楼大舞台的全局激活状态，供侧边栏等组件进行响应式联动
class StageManager {
  static final StageManager instance = StageManager._internal();
  StageManager._internal();

  /// 标识二楼大舞台是否正处于激活状态 (使用 ValueNotifier 方便侧边栏响应式监听)
  final ValueNotifier<bool> isSecondFloorActive = ValueNotifier<bool>(false);
  final List<String> _activeSecondFloors = [];

  /// 标识主舞台是否正在进行翻页/转场动画
  final ValueNotifier<bool> isTransitioning = ValueNotifier<bool>(false);

  /// 注册一个二楼大舞台实例
  void registerSecondFloor(String key) {
    if (!_activeSecondFloors.contains(key)) {
      _activeSecondFloors.add(key);
      // 🛡️ 避免在 build/initState 阶段同步更新引起 setState() during build 报错
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isSecondFloorActive.value = true;
      });
    }
  }

  /// 注销一个二楼大舞台实例
  void unregisterSecondFloor(String key) {
    _activeSecondFloors.remove(key);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isSecondFloorActive.value = _activeSecondFloors.isNotEmpty;
    });
  }
}

/// 🏛️ 一楼标准主舞台包装器
/// 语义插槽，代表在避让侧边栏、带标准边距和圆角的普通舞台区域进行渲染。
class StageFirstFloor extends StatelessWidget {
  final Widget child;

  const StageFirstFloor({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// 🏛️ 二楼大舞台包装器
/// 用于将 UI 元素放置在逃逸了边距和侧边栏约束的沉浸式全屏舞台区域。
/// 它在挂载和销毁时，会自动向 [StageManager] 报备激活状态。
class StageSecondFloor extends StatefulWidget {
  final String id;
  final Widget child;
  final bool isCustomPositioned;

  const StageSecondFloor({
    super.key,
    required this.id,
    required this.child,
    this.isCustomPositioned = false,
  });

  @override
  State<StageSecondFloor> createState() => _StageSecondFloorState();
}

class _StageSecondFloorState extends State<StageSecondFloor> {
  @override
  void initState() {
    super.initState();
    StageManager.instance.registerSecondFloor(widget.id);
  }

  @override
  void dispose() {
    StageManager.instance.unregisterSecondFloor(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 已经由 StagePhysicalFrame 的独立层级保证了全屏渲染，无需再使用负边距逃逸
    return widget.child;
  }
}
