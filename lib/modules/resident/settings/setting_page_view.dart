import 'package:flutter/material.dart';
import '../../../ui/base/input/ui_base_switch.dart';
import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/engine/theme/theme_api.dart';
import 'setting_page_room.dart';

class SettingPageView extends StatefulWidget {
  const SettingPageView({super.key});

  @override
  State<SettingPageView> createState() => _SettingPageViewState();
}

class _SettingPageViewState extends State<SettingPageView> {
  bool _notificationsEnabled = true;
  String _currentTheme = 'night';

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.card,
      child: Builder(
        builder: (context) {
          final material = context.useTheme();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. 图纸内成员：COLOR MODE (ID: color_mode)
                SizedBox(
                  width: 420,
                  child: SuperFocusSelect<String>(
                    id: 'color_mode',
                    title: 'COLOR MODE',
                    options: const [
                      SelectOption(
                        value: 'light',
                        label: 'LIGHT MODE',
                        id: 'light_mode',
                      ),
                      SelectOption(
                        value: 'night',
                        label: 'NIGHT MODE',
                        id: 'night_mode',
                      ),
                    ],
                    selectedValues: [_currentTheme],
                    onToggle: (val) => setState(() => _currentTheme = val),
                    roomBuilder: (child) => SuperFocusRoom(id: 'color_mode', child: child),
                  ),
                ),

                const SizedBox(height: 32),

                // 2. 装饰性内容 (图纸外)：PUSH NOTIFICATIONS
                // 移除了 FocusIdentity，它现在只是一个好看的 UI 元素，无法获得焦点
                SizedBox(
                  width: 420,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: material.colors.surface,
                      borderRadius: material.shape.radius,
                      boxShadow: material.visual.outerShadows,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PUSH NOTIFICATIONS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: material.colors.textPrimary.withValues(alpha: 0.4), // 调淡表示不可交互
                          ),
                        ),
                        // 这是一个普通的视觉 Switch，没有物理焦点
                        Switch(
                          value: _notificationsEnabled,
                          onChanged: (val) => setState(() => _notificationsEnabled = val),
                          activeColor: material.colors.accent,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 3. 装饰性卡片 (图纸外)：COMING SOON
                // 彻底移除了 FocusIdentity，回归纯净图纸
                SizedBox(
                  width: 420,
                  height: 120,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: material.colors.surface,
                      borderRadius: material.shape.radius,
                      boxShadow: material.visual.outerShadows,
                    ),
                    child: const Center(
                      child: Text(
                        'COMING SOON...',
                        style: TextStyle(
                          color: Colors.white10,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
