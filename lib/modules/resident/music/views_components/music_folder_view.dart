import 'package:flutter/material.dart';
import '../../../../core/data/models/music_data.dart';
import '../../../../core/control/superfocus/focus_widgets.dart';

/// 📂 Zone：music_folder
/// 物理文件夹横向选择器 (纯排版 View，无状态)
class MusicFolderView extends StatelessWidget {
  final Map<String, Widget> slots;

  const MusicFolderView({super.key, required this.slots});

  @override
  Widget build(BuildContext context) {
    return slots['folder_list'] ?? const SizedBox.shrink();
  }
}

/// 文件夹选择器 Widget（由 Room 构建并注入插槽）
class MusicFolderList extends StatelessWidget {
  final List<MusicFolder> folders;
  final Set<String> activeFolderIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onRefresh;
  final dynamic material;

  const MusicFolderList({
    super.key,
    required this.folders,
    required this.activeFolderIds,
    required this.onToggle,
    required this.onRefresh,
    required this.material,
  });

  @override
  Widget build(BuildContext context) {
    final colors = material.colors;

    return Container(
      height: 100,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: material.shape.radius,
        border: Border.all(color: colors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                FocusIdentity(
                  id: 'folder_refresh_btn',
                  onPressed: onRefresh,
                  builder: (context, hasFocus) {
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: hasFocus ? colors.accent.withValues(alpha: 0.1) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: hasFocus ? Border.all(color: colors.accent, width: 1.5) : null,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.sync_rounded, color: colors.textSecondary),
                        onPressed: onRefresh,
                        tooltip: '同步/刷新 Gonic 目录',
                      ),
                    );
                  },
                ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
                      final isActive = activeFolderIds.contains(folder.id);
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Center(
                          child: FocusIdentity(
                            id: 'folder_card_${folder.id}',
                            onPressed: () => onToggle(folder.id),
                            builder: (context, hasFocus) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isActive ? colors.accent.withValues(alpha: 0.2) : colors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isActive ? colors.accent : colors.border,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isActive ? Icons.folder_special_rounded : Icons.folder_open_rounded,
                                      color: isActive ? colors.accent : colors.textPrimary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      folder.name,
                                      style: TextStyle(
                                        color: isActive ? colors.accent : colors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
