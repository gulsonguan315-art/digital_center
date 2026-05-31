import 'package:flutter/foundation.dart';

/// 日志业务分组定义
class LogGroup {
  static const String focus = 'Focus';
  static const String network = 'Network';
  static const String ui = 'UI';
  static const String system = 'System';
  static const String music = 'Music';
}

/// 全局日志系统
class Log {
  /// 当前开启的日志分组白名单
  /// 初始默认全部开启，可以在设置页动态调整
  static final ValueNotifier<Set<String>> enabledGroupsNotifier = 
      ValueNotifier({
        LogGroup.focus,
        LogGroup.network,
        LogGroup.ui,
        LogGroup.system,
        LogGroup.music,
      });

  /// 快捷访问当前的白名单
  static Set<String> get _enabledGroups => enabledGroupsNotifier.value;

  /// Debug 级别日志打印
  /// 仅在指定 [group] 处于白名单时才会输出
  /// [subGroup] 可选的二级分组标识，例如 'DeviceManager'
  static void d(String group, dynamic message, {String? subGroup}) {
    if (kDebugMode && _enabledGroups.contains(group)) {
      final prefix = subGroup != null ? '[$group][$subGroup]' : '[$group]';
      debugPrint('$prefix: $message');
    }
  }

  /// 开启某个分组的日志
  static void enable(String group) {
    if (!_enabledGroups.contains(group)) {
      final newSet = Set<String>.from(_enabledGroups)..add(group);
      enabledGroupsNotifier.value = newSet;
    }
  }

  /// 关闭某个分组的日志
  static void disable(String group) {
    if (_enabledGroups.contains(group)) {
      final newSet = Set<String>.from(_enabledGroups)..remove(group);
      enabledGroupsNotifier.value = newSet;
    }
  }

  /// 切换某个分组的日志状态
  static void toggle(String group) {
    if (_enabledGroups.contains(group)) {
      disable(group);
    } else {
      enable(group);
    }
  }

  /// 检查某个分组是否已开启
  static bool isEnabled(String group) {
    return _enabledGroups.contains(group);
  }
}
