import 'package:flutter/material.dart';
import '../../../../ui/base/input/ui_base_switch.dart';
import '../../../../ui/base/surface/group_frame.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import '../setting_page_callback.dart';
import '../setting_page_model.dart';
import '../setting_page_room.dart';

class ThemeSettingView extends StatelessWidget {
  const ThemeSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. 焦点入口定义 (Focus Gate)
    return FocusIdentity(
      id: SettingPageModel.themeGroupId,
      builder: (context, hasFocus) {
        // 2. UI 装饰层 (Pure UI)
        return GroupFrame(
          title: SettingPageModel.themeGroupTitle,
          isHighlighted: hasFocus,
          // 3. 焦点房间定义 (Focus Room) - 使用房间文件里的 ThemeSettingRoom
          child: ThemeSettingRoom(
            child: Column(
              children: [
                // 1. COLOR MODE
                _buildSelect(
                  id: SettingPageModel.colorSelectId,
                  title: SettingPageModel.colorSelectTitle,
                  options: SettingPageModel.colorOptions,
                  selectedValue: SettingPageCallback.getCurrentThemeKey(),
                  onToggle: SettingPageCallback.onThemeModeChanged,
                  roomBuilder: (child) => ThemeColorRoom(child: child),
                ),

                const SizedBox(height: 32),

                // 2. VISUAL MODE
                _buildSelect(
                  id: SettingPageModel.visualSelectId,
                  title: SettingPageModel.visualSelectTitle,
                  options: SettingPageModel.visualOptions,
                  selectedValue: SettingPageCallback.getCurrentVisualKey(),
                  onToggle: SettingPageCallback.onVisualModeChanged,
                  roomBuilder: (child) => ThemeVisualRoom(child: child),
                ),

                const SizedBox(height: 32),

                // 3. SHAPE MODE
                _buildSelect(
                  id: SettingPageModel.shapeSelectId,
                  title: SettingPageModel.shapeSelectTitle,
                  options: SettingPageModel.shapeOptions,
                  selectedValue: SettingPageCallback.getCurrentShapeKey(),
                  onToggle: SettingPageCallback.onShapeModeChanged,
                  roomBuilder: (child) => ThemeShapeRoom(child: child),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建统一的选择项，它内部自持一个 SuperFocusRoom
  Widget _buildSelect({
    required String id,
    required String title,
    required List<SelectOption<String>> options,
    required String selectedValue,
    required ValueChanged<String> onToggle,
    required Widget Function(Widget) roomBuilder,
  }) {
    return SuperFocusSelect<String>(
      id: id,
      title: title,
      options: options,
      selectedValues: [selectedValue],
      onToggle: onToggle,
      // 直接转发来自房间文件的包装器
      roomBuilder: roomBuilder,
    );
  }
}
