import 'package:flutter/material.dart';
import '../../../ui/base/input/ui_base_switch.dart';
import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/engine/theme/theme_api.dart';
import 'setting_page_callback.dart';

class SettingPageView extends StatefulWidget {
  const SettingPageView({super.key});

  @override
  State<SettingPageView> createState() => _SettingPageViewState();
}

class _SettingPageViewState extends State<SettingPageView> {
  late String _currentTheme;
  late String _currentVisual;
  late String _currentShape;

  @override
  void initState() {
    super.initState();
    _syncState();
    SettingPageCallback.addThemeListener(_onThemeChanged);
  }

  @override
  void dispose() {
    SettingPageCallback.removeThemeListener(_onThemeChanged);
    super.dispose();
  }

  void _syncState() {
    _currentTheme = SettingPageCallback.getCurrentThemeKey();
    _currentVisual = SettingPageCallback.getCurrentVisualKey();
    _currentShape = SettingPageCallback.getCurrentShapeKey();
  }

  void _onThemeChanged() {
    if (!mounted) return;
    setState(() {
      _syncState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.card,
      child: Builder(
        builder: (context) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 【THEME SETTING】 入口节点 (属于 settingPage 房间)
                FocusIdentity(
                  id: 'theme_setting', // 对应图纸中的 /theme_setting 入口
                  builder: (context, hasFocus) {
                    final material = context.useTheme();
                    final colors = material.colors;

                    // 内部才是 theme_setting 房间
                    return SuperFocusRoom(
                      id: 'theme_setting',
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 1. 底层大线框
                          Container(
                            width: 500,
                            padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
                            decoration: BoxDecoration(
                              borderRadius: material.shape.radius,
                              border: Border.all(
                                color: colors.textPrimary.withValues(
                                  alpha: hasFocus ? 0.2 : 0.05,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                // 1. COLOR MODE
                                SuperFocusSelect<String>(
                                  id: 'color_mode',
                                  title: 'COLOR MODE',
                                  options: const [
                                    SelectOption(
                                      value: 'light',
                                      label: 'LIGHT',
                                      id: 'light_mode',
                                    ),
                                    SelectOption(
                                      value: 'night',
                                      label: 'NIGHT',
                                      id: 'night_mode',
                                    ),
                                  ],
                                  selectedValues: [_currentTheme],
                                  onToggle: (val) =>
                                      SettingPageCallback.onThemeModeChanged(
                                        val,
                                      ),
                                  roomBuilder: (child) => SuperFocusRoom(
                                    id: 'color_mode',
                                    child: child,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // 2. VISUAL MODE
                                SuperFocusSelect<String>(
                                  id: 'visual_mode',
                                  title: 'VISUAL MODE',
                                  options: const [
                                    SelectOption(
                                      value: 'flat',
                                      label: 'FLAT',
                                      id: 'flat',
                                    ),
                                    SelectOption(
                                      value: 'glassy',
                                      label: 'GLASSY',
                                      id: 'glassy',
                                    ),
                                    SelectOption(
                                      value: 'neumorphic',
                                      label: 'NEUMORPHIC',
                                      id: 'neumorphic',
                                    ),
                                  ],
                                  selectedValues: [_currentVisual],
                                  onToggle: (val) =>
                                      SettingPageCallback.onVisualModeChanged(
                                        val,
                                      ),
                                  roomBuilder: (child) => SuperFocusRoom(
                                    id: 'visual_mode',
                                    child: child,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // 3. SHAPE MODE
                                SuperFocusSelect<String>(
                                  id: 'shape_mode',
                                  title: 'SHAPE MODE',
                                  options: const [
                                    SelectOption(
                                      value: 'rightangle',
                                      label: 'RIGHT',
                                      id: 'rightangle',
                                    ),
                                    SelectOption(
                                      value: 'round',
                                      label: 'ROUND',
                                      id: 'round',
                                    ),
                                    SelectOption(
                                      value: 'soft',
                                      label: 'SOFT',
                                      id: 'soft',
                                    ),
                                  ],
                                  selectedValues: [_currentShape],
                                  onToggle: (val) =>
                                      SettingPageCallback.onShapeModeChanged(
                                        val,
                                      ),
                                  roomBuilder: (child) => SuperFocusRoom(
                                    id: 'shape_mode',
                                    child: child,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 2. 嵌入在顶部的标题文字 (卡口效果)
                          Positioned(
                            top: -10,
                            left: 32,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              color: colors.surface,
                              child: Text(
                                'THEME SETTING',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                  color: colors.textPrimary.withValues(
                                    alpha: hasFocus ? 0.8 : 0.3,
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
              ],
            ),
          );
        },
      ),
    );
  }
}
