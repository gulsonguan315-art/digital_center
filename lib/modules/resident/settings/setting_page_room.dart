import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/control/superfocus/focus_widgets.dart';
import '../../../ui/base/input/ui_base_switch.dart';
import 'setting_page_model.dart';
import 'setting_page_callback.dart';
import 'setting_page_view.dart';
import 'views_components/theme_setting_view.dart';
import 'views_components/custom_setting_view.dart';
import 'views_components/log_setting_view.dart';

/// 设置页主入口房间 (总承包商)
class SettingPageRoom extends StatelessWidget {
  final Widget? child;
  const SettingPageRoom({super.key, this.child});

  static const String roomId = SettingPageModel.settingPageId;

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(
      id: roomId,
      // 如果没有传入外部 child，则组装默认的 View
      child: child ?? const SettingPageView(
        slots: {
          'theme_setting': ThemeSettingRoom(),
          'custom_setting': CustomSettingRoom(),
          'log_setting': LogSettingRoom(),
        },
      ),
    );
  }
}

/// 主题设置装配房间 (二级包工头)
/// 负责将数据 (Model) 与动作 (Callback) 缝合成具体的 Widget，并注入给 View。
class ThemeSettingRoom extends StatelessWidget {
  const ThemeSettingRoom({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ 关键：让包工头监听状态变化，一旦状态变了，立即重新缝合插槽并下发
    return ListenableBuilder(
      listenable: ThemeProvider.instance,
      builder: (context, _) {
        return FocusIdentity(
          id: SettingPageModel.themeGroupId,
          builder: (context, hasFocus) {
            // 2. 召唤 View 并注入拼好的插槽
            return SuperFocusRoom(
              id: SettingPageModel.themeGroupId,
              child: ThemeSettingView(
                slots: {
                  // 颜色模式插槽
                  SettingPageModel.colorSelectId: _buildSelectNode(
                    id: SettingPageModel.colorSelectId,
                    title: SettingPageModel.colorSelectTitle,
                    options: SettingPageModel.colorOptions,
                    selectedValue: SettingPageCallback.getCurrentThemeKey(),
                    onToggle: SettingPageCallback.onThemeModeChanged,
                  ),

                  // 视觉风格插槽
                  SettingPageModel.visualSelectId: _buildSelectNode(
                    id: SettingPageModel.visualSelectId,
                    title: SettingPageModel.visualSelectTitle,
                    options: SettingPageModel.visualOptions,
                    selectedValue: SettingPageCallback.getCurrentVisualKey(),
                    onToggle: SettingPageCallback.onVisualModeChanged,
                  ),

                  // 形状风格插槽
                  SettingPageModel.shapeSelectId: _buildSelectNode(
                    id: SettingPageModel.shapeSelectId,
                    title: SettingPageModel.shapeSelectTitle,
                    options: SettingPageModel.shapeOptions,
                    selectedValue: SettingPageCallback.getCurrentShapeKey(),
                    onToggle: SettingPageCallback.onShapeModeChanged,
                  ),
                },
              ),
            );
          },
        );
      },
    );
  }
}

/// 自定义设置装配房间 (二级包工头)
class CustomSettingRoom extends StatelessWidget {
  const CustomSettingRoom({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingPageCallback.customModeNotifier,
      builder: (context, _) {
        return FocusIdentity(
          id: SettingPageModel.customGroupId,
          builder: (context, hasFocus) {
            return SuperFocusRoom(
              id: SettingPageModel.customGroupId,
              child: CustomSettingView(
                slots: {
                  SettingPageModel.customSelectId: _buildSelectNode(
                    id: '', // 卡片逻辑 ID 设为空，使其在拓扑中透明，实现“跳过卡片”直接选中选项
                    title: SettingPageModel.customSelectTitle,
                    options: SettingPageModel.customOptions,
                    selectedValue: SettingPageCallback.getCurrentCustomKey(),
                    onToggle: SettingPageCallback.onCustomModeChanged,
                  ),
                },
              ),
            );
          },
        );
      },
    );
  }
}

/// 日志设置装配房间
class LogSettingRoom extends StatelessWidget {
  const LogSettingRoom({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingPageCallback.logGroupsNotifier,
      builder: (context, _) {
        return FocusIdentity(
          id: SettingPageModel.logGroupId,
          builder: (context, hasFocus) {
            return SuperFocusRoom(
              id: SettingPageModel.logGroupId,
              child: LogSettingView(
                slots: {
                  SettingPageModel.logSelectId: _buildSelectNode(
                    id: '', // 让内部组件透明，直接暴露选项
                    title: SettingPageModel.logSelectTitle,
                    options: SettingPageModel.logOptions,
                    // 支持多选，将 Set 转换为 List 传入
                    selectedValues: SettingPageCallback.logGroupsNotifier.value.toList(),
                    onToggle: SettingPageCallback.onLogGroupToggled,
                  ),
                },
              ),
            );
          },
        );
      },
    );
  }
}

/// 核心装配逻辑：将一个普通的选择器包装成带 Room 的焦点节点
Widget _buildSelectNode({
  required String id,
  required String title,
  required List<SelectOption<String>> options,
  String? selectedValue,
  List<String>? selectedValues,
  required ValueChanged<String> onToggle,
}) {
  return SuperFocusSelect<String>(
    id: id,
    title: title,
    options: options,
    selectedValues: selectedValues ?? (selectedValue != null ? [selectedValue] : []),
    onToggle: onToggle,
    // 在这里统一处理 Sub-Room 逻辑
    roomBuilder: (child) => SuperFocusRoom(
      id: id,
      child: child,
    ),
  );
}
