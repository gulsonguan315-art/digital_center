import 'package:flutter/material.dart';
import 'package:superfocus/core/control/superfocus/widgets/focus_widgets.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/engine/theme/theme_api.dart';

class BookControlPanel extends StatelessWidget {
  const BookControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.useTheme().colors;

    return Center(
      child: Container(
        width: 500,
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10.0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SuperFocusRoom(
          id: 'book_control',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: SuperFocusItem(
                  id: 'book_menu',
                  onPressed: () {},
                  builder: (context, hasFocus) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.format_list_bulleted,
                              color: hasFocus ? colors.accent : colors.textPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '章节目录',
                              style: TextStyle(
                                color: hasFocus ? colors.accent : colors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: SuperFocusItem(
                  id: 'book_settings',
                  onPressed: () {},
                  builder: (context, hasFocus) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.settings,
                              color: hasFocus ? colors.accent : colors.textPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '阅读设置',
                              style: TextStyle(
                                color: hasFocus ? colors.accent : colors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
