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
