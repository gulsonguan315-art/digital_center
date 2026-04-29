import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_widgets.dart';
import '../../../ui/base/input/super_focus_switch.dart';

/// 设置页面 - 已将原有的测试按钮替换为 SuperFocusSwitch
class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  static const String roomId = 'settingPage';
  static const String switchId = 'settingAction';

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  // 维护开关的内部状态
  bool _isFeatureEnabled = false;

  @override
  Widget build(BuildContext context) {
    // 使用 SuperFocusRoom 包装，确保该页面拥有独立的焦点作用域
    return SuperFocusRoom(
      id: SettingPage.roomId,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 使用新创建的基础开关组件
            SuperFocusSwitch(
              id: SettingPage.switchId,
              label: '示例功能开关',
              value: _isFeatureEnabled,
              autofocus: true, // 进入设置页时自动聚焦此开关
              onChanged: (newValue) {
                setState(() {
                  _isFeatureEnabled = newValue;
                });
                // 交互式打印状态
                print('【设置中心】开关状态已变更: ${newValue ? "开启 ON" : "关闭 OFF"}');
              },
            ),

            const SizedBox(height: 20),

            // 状态提示文本
            Text(
              '当前状态: ${_isFeatureEnabled ? "已激活" : "未激活"}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
