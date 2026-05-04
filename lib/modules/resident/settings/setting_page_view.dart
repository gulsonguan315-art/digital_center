import 'package:flutter/material.dart';
import '../../../ui/base/input/ui_base_switch.dart';
import '../../../ui/base/input/ui_base_button.dart';
import '../../../core/engine/theme/theme_provider.dart';
import '../../../core/engine/theme/theme_shape.dart';
import '../../../core/engine/theme/theme_visuals.dart';
import 'setting_page_room.dart';

/// 设置页面的核心 UI 视图 - 模仿健身房 (GymView) 结构
class SettingPageView extends StatelessWidget {
  const SettingPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider.instance,
      builder: (context, _) {
        final provider = ThemeProvider.instance;

        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. 颜色模式选择区域
                SizedBox(
                  width: 420, // 👈 在视图层限制宽度
                  child: SuperFocusSelect<ThemeMode>(
                    id: ThemeColorRoom.roomId,
                    title: '颜色模式',
                    options: const {
                      ThemeMode.light: '明亮模式',
                      ThemeMode.dark: '深邃暗夜',
                    },
                    selectedValues: [provider.themeMode],
                    onToggle: (mode) => provider.setThemeMode(mode),
                    roomBuilder: (child) => ThemeColorRoom(child: child),
                  ),
                ),

                const SizedBox(height: 24),

                // 2. 视觉风格选择区域
                SizedBox(
                  width: 420, // 👈 在视图层限制宽度
                  child: SuperFocusSelect<VisualStyle>(
                    id: ThemeVisualRoom.roomId,
                    title: '视觉风格',
                    options: const {
                      VisualStyle.flat: '极简扁平',
                      VisualStyle.glass: '磨砂玻璃',
                      VisualStyle.neumorphic: '拟态 3D',
                    },
                    selectedValues: [provider.visualStyle],
                    onToggle: (style) => provider.setVisualStyle(style),
                    roomBuilder: (child) => ThemeVisualRoom(child: child),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: 420,
                  child: SuperFocusSelect<ShapeStyle>(
                    id: ThemeShapeRoom.roomId,
                    title: '形状风格',
                    options: const {
                      ShapeStyle.rightAngle: '直角',
                      ShapeStyle.soft: '柔和圆角',
                      ShapeStyle.round: '圆润',
                    },
                    selectedValues: [provider.shapeStyle],
                    onToggle: (style) => provider.setShapeStyle(style),
                    roomBuilder: (child) => ThemeShapeRoom(child: child),
                  ),
                ),

                const SizedBox(height: 40),

                // 3. 测试按钮
                SuperFocusButton(
                  id: SettingPageRoom.testId,
                  label: '点击测试业务',
                  onPressed: () {
                    print('【业务测试】SettingPage 测试按钮被点击！');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
