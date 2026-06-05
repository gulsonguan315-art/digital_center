import 'package:flutter/material.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/engine/theme/theme_api.dart';

class MediaDetailRoom extends StatelessWidget {
  final String roomId;
  final String itemId;

  const MediaDetailRoom({super.key, required this.roomId, required this.itemId});

  @override
  Widget build(BuildContext context) {
    // 注册动态子房间
    return SuperFocusRoom(
      id: roomId,
      child: ThemeIdentity(
        role: ThemeRole.appBackground,
        child: Builder(
          builder: (context) {
            final material = context.useTheme();

            return Container(
              color: material.colors.surface, // 背景色盖住下方海报墙
              child: Stack(
                children: [
                  // TODO: Backdrop image placeholder
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            material.colors.surface.withValues(alpha: 0.3),
                            material.colors.surface,
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // 内容层
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Media Detail: $itemId',
                          style: TextStyle(
                            fontSize: 32,
                            color: material.colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // 播放按钮 (焦点捕获)
                        FocusIdentity(
                          id: 'btn_play',
                          autofocus: true,
                          onPressed: () {
                            // TODO: Play video
                          },
                          builder: (context, hasFocus) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                              decoration: BoxDecoration(
                                color: hasFocus ? material.colors.accent : material.colors.backgroundActive,
                                borderRadius: material.shape.radius,
                                border: Border.all(
                                  color: hasFocus ? material.colors.accent : material.colors.border,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                'Play',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: hasFocus ? material.colors.surface : material.colors.textPrimary,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // 返回按钮占位
                  Positioned(
                    top: 32,
                    left: 32,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: material.colors.textPrimary, size: 32),
                      onPressed: () {
                        FocusAPI.dispatchBack(context);
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }
}
