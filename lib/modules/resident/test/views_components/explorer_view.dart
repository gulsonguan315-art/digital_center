import 'package:flutter/material.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../ui/base/surface/group_frame.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../test_page_model.dart';
import '../test_page_callback.dart';
import '../test_page_room.dart';

/// 动态资源管理器视图
class ExplorerView extends StatelessWidget {
  final String roomId;

  const ExplorerView({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    // 关键：根据当前房间 ID 获取模拟数据
    final List<MockFileItem> items = TestPageCallback.getItemsFor(roomId);
    
    return GroupFrame(
      title: 'ROOM: $roomId (${items.length} items)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('EMPTY FOLDER', style: TextStyle(color: Colors.grey)),
            ),
          
          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: items.map((item) => _buildItem(context, item)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, MockFileItem item) {
    // 检查此项是否已作为房间进入
    final bool isActive = context.useIsActive(item.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 门控节点
        FocusIdentity(
          id: item.id,
          onPressed: () {
            // 触发进入动作
            // 如果是文件（非文件夹），将其标记为死胡同房间，阻断继承
            FocusAPI.dispatchAction(roomId, item.id, asTerminalRoom: !item.isFolder);
          },
          builder: (context, hasFocus) {
            return _ItemBox(
              label: '${item.isFolder ? "📁" : "📄"} ${item.label}',
              hasFocus: hasFocus,
              isActive: isActive,
              isFolder: item.isFolder,
            );
          },
        ),
        
        // 递归渲染子房间
        if (item.isFolder && isActive) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: DynamicExplorerRoom(roomId: item.id),
          ),
        ],
      ],
    );
  }
}

class _ItemBox extends StatelessWidget {
  final String label;
  final bool hasFocus;
  final bool isActive;
  final bool isFolder;

  const _ItemBox({
    required this.label,
    required this.hasFocus,
    required this.isActive,
    required this.isFolder,
  });

  @override
  Widget build(BuildContext context) {
    final material = context.useTheme();
    final colors = material.colors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // 如果被激活（正在其子文件夹中），显示特殊背景
        color: hasFocus 
            ? colors.accent 
            : (isActive ? colors.accent.withValues(alpha: 0.2) : colors.surface),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasFocus ? Colors.white : (isActive ? colors.accent : colors.border),
          width: 2,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: hasFocus ? Colors.white : colors.textPrimary,
          fontWeight: isActive || hasFocus ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
