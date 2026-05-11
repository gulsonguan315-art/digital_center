import 'package:flutter/material.dart';
import '../../../../ui/base/surface/group_frame.dart';
import '../setting_page_model.dart';

/// 主题设置视图 (纯排版工具)
/// 它不持有任何焦点逻辑或 ID，仅通过 [slots] 接收外部注入的组件并进行排版。
class ThemeSettingView extends StatelessWidget {
  final Map<String, Widget> slots;

  const ThemeSettingView({
    super.key,
    required this.slots,
  });

  @override
  Widget build(BuildContext context) {
    return GroupFrame(
      title: SettingPageModel.themeGroupTitle,
      child: Column(
        children: [
          // 按照预定的顺序从插槽中取组件排版
          _getSlot(SettingPageModel.colorSelectId),
          const SizedBox(height: 32),
          _getSlot(SettingPageModel.visualSelectId),
          const SizedBox(height: 32),
          _getSlot(SettingPageModel.shapeSelectId),
        ],
      ),
    );
  }

  Widget _getSlot(String id) {
    return slots[id] ?? const SizedBox.shrink();
  }
}
