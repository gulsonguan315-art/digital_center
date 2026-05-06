import 'package:flutter/material.dart';

import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../ui/base/input/ui_base_switch.dart';
import 'setting_page_room.dart';

class SettingPageView extends StatefulWidget {
  const SettingPageView({super.key});

  @override
  State<SettingPageView> createState() => _SettingPageViewState();
}

class _SettingPageViewState extends State<SettingPageView> {
  bool get _systemTheme =>
      ThemeProvider.instance.themeMode == ThemeMode.system;
  bool get _darkMode => ThemeProvider.instance.themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.card,
      child: Builder(
        builder: (context) {
          final material = context.useTheme();

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 360,
                  height: 180,
                  child: FocusIdentity(
                    id: SettingPageRoom.testId,
                    focusGeometry: RoundedRectFocusGeometry(
                      borderRadius: material.shape.radius as BorderRadius,
                    ),
                    onPressed: () {
                      print('Setting test card pressed');
                    },
                    builder: (context, hasFocus) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: material.colors.surface,
                          borderRadius: material.shape.radius,
                          boxShadow: material.visual.outerShadows,
                          border: Border.all(
                            color: hasFocus
                                ? material.colors.accent
                                : (material.visual.borderColor ??
                                      Colors.transparent),
                            width: hasFocus ? 2 : material.visual.borderWidth,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'SETTING TEST',
                            style: TextStyle(
                              color: hasFocus
                                  ? material.colors.accent
                                  : material.colors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SuperFocusSwitch(
                  id: SettingPageRoom.systemThemeSwitchId,
                  label: 'System theme',
                  value: _systemTheme,
                  onChanged: (value) {
                    ThemeProvider.instance.setThemeMode(
                      value
                          ? ThemeMode.system
                          : (_darkMode ? ThemeMode.dark : ThemeMode.light),
                    );
                  },
                ),
                const SizedBox(height: 16),
                SuperFocusSwitch(
                  id: SettingPageRoom.darkModeSwitchId,
                  label: 'Dark mode',
                  value: _darkMode,
                  onChanged: (value) {
                    ThemeProvider.instance.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
                const SizedBox(height: 24),
                _VisualStyleCard(
                  id: SettingPageRoom.visualStyleId,
                  currentStyle: ThemeProvider.instance.visualStyle,
                  onPressed: () {
                    ThemeProvider.instance.nextVisualStyle();
                  },
                ),
                const SizedBox(height: 16),
                _ShapeStyleCard(
                  id: SettingPageRoom.shapeStyleId,
                  currentStyle: ThemeProvider.instance.shapeStyle,
                  onPressed: () {
                    final values = ShapeStyle.values;
                    final currentIndex = values.indexOf(
                      ThemeProvider.instance.shapeStyle,
                    );
                    final next = values[(currentIndex + 1) % values.length];
                    ThemeProvider.instance.setShapeStyle(next);
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

class _ShapeStyleCard extends StatelessWidget {
  const _ShapeStyleCard({
    required this.id,
    required this.currentStyle,
    required this.onPressed,
  });

  final String id;
  final ShapeStyle currentStyle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = switch (currentStyle) {
      ShapeStyle.rightAngle => 'Right angle',
      ShapeStyle.soft => 'Soft',
      ShapeStyle.round => 'Round',
    };

    return ThemeIdentity(
      role: ThemeRole.card,
      child: Builder(
        builder: (context) {
          final material = context.useTheme();

          return SizedBox(
            width: 360,
            height: 96,
            child: FocusIdentity(
              id: id,
              focusGeometry: RoundedRectFocusGeometry(
                borderRadius: material.shape.radius as BorderRadius,
              ),
              onPressed: onPressed,
              builder: (context, hasFocus) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: material.colors.surface,
                    borderRadius: material.shape.radius,
                    boxShadow: material.visual.outerShadows,
                    border: Border.all(
                      color: hasFocus
                          ? material.colors.accent
                          : (material.visual.borderColor ??
                                Colors.transparent),
                      width: hasFocus ? 2 : material.visual.borderWidth,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.rounded_corner,
                        color: hasFocus
                            ? material.colors.accent
                            : material.colors.textPrimary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Shape style',
                          style: TextStyle(
                            color: material.colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          color: hasFocus
                              ? material.colors.accent
                              : material.colors.textPrimary.withValues(
                                  alpha: 0.65,
                                ),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _VisualStyleCard extends StatelessWidget {
  const _VisualStyleCard({
    required this.id,
    required this.currentStyle,
    required this.onPressed,
  });

  final String id;
  final VisualStyle currentStyle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = switch (currentStyle) {
      VisualStyle.flat => 'Flat',
      VisualStyle.glass => 'Glass',
      VisualStyle.neumorphic => 'Neumorphic',
    };

    return ThemeIdentity(
      role: ThemeRole.card,
      child: Builder(
        builder: (context) {
          final material = context.useTheme();

          return SizedBox(
            width: 360,
            height: 96,
            child: FocusIdentity(
              id: id,
              focusGeometry: RoundedRectFocusGeometry(
                borderRadius: material.shape.radius as BorderRadius,
              ),
              onPressed: onPressed,
              builder: (context, hasFocus) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: material.colors.surface,
                    borderRadius: material.shape.radius,
                    boxShadow: material.visual.outerShadows,
                    border: Border.all(
                      color: hasFocus
                          ? material.colors.accent
                          : (material.visual.borderColor ??
                                Colors.transparent),
                      width: hasFocus ? 2 : material.visual.borderWidth,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        color: hasFocus
                            ? material.colors.accent
                            : material.colors.textPrimary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Visual style',
                          style: TextStyle(
                            color: material.colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          color: hasFocus
                              ? material.colors.accent
                              : material.colors.textPrimary.withValues(
                                  alpha: 0.65,
                                ),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
