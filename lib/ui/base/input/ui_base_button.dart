import 'package:flutter/material.dart';

import '../../../core/control/superfocus/focus_geometry.dart';
import '../../../core/control/superfocus/focus_manager.dart';
import '../../../core/control/superfocus/focus_widgets.dart';
import '../../../core/engine/theme/theme_colors.dart';
import '../../../core/engine/theme/theme_identity.dart';
import '../../../core/engine/theme/theme_role.dart';
import '../../visual/surface/themed_surface.dart';

class SuperFocusButton extends StatelessWidget {
  const SuperFocusButton({
    super.key,
    required this.id,
    required this.label,
    this.onPressed,
    this.autofocus = false,
  });

  final String id;
  final String label;
  final VoidCallback? onPressed;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.button,
      child: Builder(
        builder: (context) {
          final material = context.useTheme();

          return SuperFocusItem(
            id: id,
            autofocus: autofocus,
            onPressed: onPressed,
            focusGeometry: RoundedRectFocusGeometry(
              borderRadius: material.shape.radius as BorderRadius,
            ),
            builder: (context, hasFocus) {
              return ValueListenableBuilder<String?>(
                valueListenable: SuperFocusManager.instance.intentionRoomId,
                builder: (context, intentionId, _) {
                  final isWaiting = intentionId == id;
                  final themeColors = Theme.of(
                    context,
                  ).extension<ThemeColors>()!;

                  return ThemedSurface(
                    isFocused: hasFocus,
                    isWaiting: isWaiting,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: isWaiting ? 0.0 : 1.0,
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 16,
                                color: hasFocus
                                    ? themeColors.adormColor
                                    : themeColors.textPrimary,
                                fontWeight: hasFocus
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isWaiting)
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  themeColors.adormColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
