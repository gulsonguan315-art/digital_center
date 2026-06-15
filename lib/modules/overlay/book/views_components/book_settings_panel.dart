import 'package:flutter/material.dart';
import '../../../../core/control/superfocus/focus_widgets.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../../../resident/book/book_service.dart';

class BookSettingsPanel extends StatelessWidget {
  const BookSettingsPanel({super.key});

  Widget _buildSettingRow({
    required String title,
    required Widget leftControl,
    required Widget valueWidget,
    required Widget rightControl,
    required RoleColors colors,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          FocusCluster(
            child: Row(
              children: [
                Expanded(child: leftControl),
                Container(
                  width: 120,
                  alignment: Alignment.center,
                  child: valueWidget,
                ),
                Expanded(child: rightControl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusButton({
    required String id,
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required RoleColors colors,
  }) {
    return SuperFocusItem(
      id: id,
      onPressed: onPressed,
      builder: (context, hasFocus) {
        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: hasFocus
                ? colors.accent.withValues(alpha: 0.2)
                : colors.textPrimary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: hasFocus ? colors.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: hasFocus ? colors.accent : colors.textPrimary,
              size: 20,
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeButton({
    required String id,
    required String text,
    required String mode,
    required String currentMode,
    required Color previewBg,
    required Color previewFg,
    required VoidCallback onPressed,
    required RoleColors colors,
  }) {
    final isSelected = currentMode == mode;
    return SuperFocusItem(
      id: id,
      onPressed: onPressed,
      builder: (context, hasFocus) {
        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: previewBg,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: hasFocus
                  ? colors.accent
                  : (isSelected ? colors.accent.withValues(alpha: 0.6) : colors.border.withValues(alpha: 0.2)),
              width: hasFocus ? 2.5 : (isSelected ? 2.0 : 1.0),
            ),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.3),
                      blurRadius: 8.0,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: previewFg,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_circle,
                  color: colors.accent,
                  size: 16,
                ),
              ],
            ],
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final colors = context.useTheme().colors;
    final controller = BookService.instance.readerController;

    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          left: BorderSide(
            color: colors.border,
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '阅读设置',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SuperFocusRoom(
              id: 'book_settings',
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  String weightName = switch (controller.fontWeightIndex) {
                    0 => '标准',
                    1 => '中等',
                    2 => '粗体',
                    _ => '标准',
                  };

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // 1. 字体大小
                      _buildSettingRow(
                        title: '字体大小 (pt)',
                        leftControl: _buildFocusButton(
                          id: 'font_size_minus',
                          text: '减小',
                          icon: Icons.remove,
                          onPressed: () => controller.adjustFontSize(-2.0),
                          colors: colors,
                        ),
                        valueWidget: Text(
                          '${controller.fontSize.toInt()}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        rightControl: _buildFocusButton(
                          id: 'font_size_plus',
                          text: '增大',
                          icon: Icons.add,
                          onPressed: () => controller.adjustFontSize(2.0),
                          colors: colors,
                        ),
                        colors: colors,
                      ),

                      // 2. 字体粗细
                      _buildSettingRow(
                        title: '字体粗细',
                        leftControl: _buildFocusButton(
                          id: 'font_weight_minus',
                          text: '减小',
                          icon: Icons.remove,
                          onPressed: () => controller.adjustFontWeight(-1),
                          colors: colors,
                        ),
                        valueWidget: Text(
                          weightName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        rightControl: _buildFocusButton(
                          id: 'font_weight_plus',
                          text: '增大',
                          icon: Icons.add,
                          onPressed: () => controller.adjustFontWeight(1),
                          colors: colors,
                        ),
                        colors: colors,
                      ),

                      // 3. 段落行距
                      _buildSettingRow(
                        title: '段落行距 (倍)',
                        leftControl: _buildFocusButton(
                          id: 'line_height_minus',
                          text: '减小',
                          icon: Icons.remove,
                          onPressed: () => controller.adjustLineHeight(-0.1),
                          colors: colors,
                        ),
                        valueWidget: Text(
                          controller.lineHeight.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        rightControl: _buildFocusButton(
                          id: 'line_height_plus',
                          text: '增大',
                          icon: Icons.add,
                          onPressed: () => controller.adjustLineHeight(0.1),
                          colors: colors,
                        ),
                        colors: colors,
                      ),
                      // 3.5. 按键滚动行数
                      _buildSettingRow(
                        title: '按键滚动行数',
                        leftControl: _buildFocusButton(
                          id: 'scroll_lines_minus',
                          text: '减小',
                          icon: Icons.remove,
                          onPressed: () => controller.adjustScrollLines(-1),
                          colors: colors,
                        ),
                        valueWidget: Text(
                          '${controller.scrollLines}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        rightControl: _buildFocusButton(
                          id: 'scroll_lines_plus',
                          text: '增大',
                          icon: Icons.add,
                          onPressed: () => controller.adjustScrollLines(1),
                          colors: colors,
                        ),
                        colors: colors,
                      ),

                      // 4. 背景主题
                      Text(
                        '背景主题',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FocusCluster(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildThemeButton(
                                id: 'theme_default',
                                text: '系统默认',
                                mode: 'default',
                                currentMode: controller.themeMode,
                                previewBg: colors.surface,
                                previewFg: colors.textPrimary,
                                onPressed: () => controller.setThemeMode('default'),
                                colors: colors,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildThemeButton(
                                id: 'theme_parchment',
                                text: '羊皮纸',
                                mode: 'parchment',
                                currentMode: controller.themeMode,
                                previewBg: const Color(0xFFF4ECD8),
                                previewFg: const Color(0xFF3E2723),
                                onPressed: () => controller.setThemeMode('parchment'),
                                colors: colors,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildThemeButton(
                                id: 'theme_eye_care',
                                text: '护眼豆沙',
                                mode: 'eye_care',
                                currentMode: controller.themeMode,
                                previewBg: const Color(0xFFCCE8CF),
                                previewFg: const Color(0xFF1B5E20),
                                onPressed: () => controller.setThemeMode('eye_care'),
                                colors: colors,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
