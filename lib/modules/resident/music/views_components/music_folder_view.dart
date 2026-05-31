import 'package:flutter/material.dart';
import '../../../../core/data/models/music_data.dart';
import '../../../../core/control/superfocus/focus_api.dart';

typedef FocusSlotBuilder = Widget Function(
  Widget Function(BuildContext context, bool hasFocus, VoidCallback? onPressed) builder, {
  FocusGeometry? focusGeometry,
});

typedef FolderSlotBuilder = Widget Function(
  BuildContext context,
  int index,
  Widget Function(BuildContext context, bool hasFocus, VoidCallback? onPressed, {required MusicFolder folder, required bool isActive}) builder, {
  FocusGeometry? focusGeometry,
});


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
  final FocusSlotBuilder refreshSlot;
  final int folderCount;
  final FolderSlotBuilder folderSlot;
  final dynamic material;

  const MusicFolderList({
    super.key,
    required this.refreshSlot,
    required this.folderCount,
    required this.folderSlot,
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
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: refreshSlot(
                    focusGeometry: const RoundedRectFocusGeometry(
                      borderRadius: BorderRadius.all(Radius.circular(100)),
                    ),
                    (ctx, hasFocus, onPressed) => MusicFolderRefreshButton(
                      hasFocus: hasFocus,
                      onPressed: onPressed ?? () {},
                      material: material,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: folderCount,
                    itemBuilder: (ctx, index) => Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Center(
                        child: folderSlot(
                          ctx,
                          index,
                          focusGeometry: const RoundedRectFocusGeometry(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          (ctx, hasFocus, onPressed, {required folder, required isActive}) {
                            return MusicFolderCard(
                              folder: folder,
                              isActive: isActive,
                              hasFocus: hasFocus,
                              material: material,
                            );
                          },
                        ),
                      ),
                    ),
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

class MusicFolderRefreshButton extends StatelessWidget {
  final bool hasFocus;
  final VoidCallback onPressed;
  final dynamic material;
  
  const MusicFolderRefreshButton({
    super.key, required this.hasFocus, required this.onPressed, required this.material,
  });

  @override
  Widget build(BuildContext context) {
    final colors = material.colors;
    return Container(
      decoration: BoxDecoration(
        color: hasFocus ? colors.accent.withValues(alpha: 0.1) : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: hasFocus ? colors.accent : Colors.transparent, 
          width: 1.5,
        ),
      ),
      child: IconButton(
        icon: Icon(Icons.sync_rounded, color: colors.textSecondary),
        onPressed: onPressed,
      ),
    );
  }
}

class MusicFolderCard extends StatelessWidget {
  final MusicFolder folder;
  final bool isActive;
  final bool hasFocus;
  final dynamic material;

  const MusicFolderCard({
    super.key,
    required this.folder,
    required this.isActive,
    required this.hasFocus,
    required this.material,
  });

  @override
  Widget build(BuildContext context) {
    final colors = material.colors;
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
  }
}
