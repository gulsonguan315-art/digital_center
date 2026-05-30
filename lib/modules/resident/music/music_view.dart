import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';

/// 🖥️ 音乐页面总排版视图 (纯插槽收纳盒)
///
/// 分三个 Zone：
///   - [music_folder]  顶部文件夹选择器
///   - 中部并排：[music_list] 歌曲列表 + [music_lyrics] 歌词面板
///   - [music_control] 底部播放控制栏
class MusicPageView extends StatelessWidget {
  final Map<String, Widget> slots;

  const MusicPageView({super.key, required this.slots});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ThemeIdentity(
        role: ThemeRole.card,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Zone 1：文件夹选择器
              slots['music_folder'] ?? const SizedBox.shrink(),
              const SizedBox(height: 16),

              // Zone 2 & 3：歌曲列表 + 歌词（并排，Expanded 撑满中间空间）
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: slots['music_list'] ?? const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: slots['music_lyrics'] ?? const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Zone 4：播放控制栏
              slots['music_control'] ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

class MusicLoadingView extends StatelessWidget {
  const MusicLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.card,
      child: Builder(
        builder: (ctx) {
          final colors = ctx.useTheme().colors;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                  strokeWidth: 3.5,
                ),
                const SizedBox(height: 24),
                Text(
                  '正在同步 Gonic 视听库...',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

typedef FocusSlotBuilder = Widget Function(Widget Function(BuildContext context, bool hasFocus) builder);

class MusicErrorView extends StatelessWidget {
  final String? errorMessage;
  final FocusSlotBuilder retrySlot;

  const MusicErrorView({
    super.key, 
    required this.errorMessage,
    required this.retrySlot,
  });

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.card,
      child: Builder(
        builder: (ctx) {
          final material = ctx.useTheme();
          final colors = material.colors;
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: material.shape.radius,
                border: Border.all(color: colors.border, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, color: colors.accent, size: 48),
                  const SizedBox(height: 24),
                  Text(
                    '视听中枢连接失败',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    errorMessage ??
                        '无法访问 Gonic 视听库，请验证服务器连通状态或检查 api_endpoints.json 中的配置。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  retrySlot((ctx, hasFocus) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: hasFocus ? colors.accent : colors.surface,
                      borderRadius: material.shape.radius,
                      border: Border.all(
                        color: hasFocus ? colors.accent : colors.border,
                        width: 1.5,
                      ),
                      boxShadow: hasFocus
                          ? material.visual.outerShadows
                          : null,
                    ),
                    child: Text(
                      '重新连接',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
