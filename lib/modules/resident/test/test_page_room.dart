import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/engine/theme/theme_api.dart';
import 'test_page_model.dart';
import 'test_page_callback.dart';
import 'test_page_view.dart';
import 'views_components/work_setting_view.dart';
import 'views_components/work_grop_view.dart';
import 'views_components/explorer_view.dart';

/// 测试页总承包商
class TestPageRoom extends StatelessWidget {
  const TestPageRoom({super.key});

  static const String roomId = TestPageModel.testPageId;

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(
      id: TestPageModel.testPageId,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: TestPageView(
          slots: {
            TestPageModel.card1Id: _buildLeaf(TestPageModel.card1Id, 'ROOT CARD'),
            
            // 入口门控：负责开启 explorer 房间
            TestPageModel.explorerId: FocusIdentity(
              id: TestPageModel.explorerId,
              onPressed: () => FocusAPI.dispatchAction(roomId, TestPageModel.explorerId),
              builder: (context, hasFocus) => DynamicExplorerRoom(
                roomId: TestPageModel.explorerId,
                hasFocus: hasFocus,
              ),
            ),

            TestPageModel.workSettingId: FocusIdentity(
              id: TestPageModel.workSettingId,
              builder: (context, hasFocus) => const WorkSettingRoom(),
            ),
          },
        ),
      ),
    );
  }
}

/// 动态房间容器：仅负责 SuperFocusRoom，不再内部加门，避免 ID 冲突
class DynamicExplorerRoom extends StatelessWidget {
  final String roomId;
  final bool hasFocus;
  const DynamicExplorerRoom({super.key, required this.roomId, this.hasFocus = false});

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(
      id: roomId,
      child: ExplorerView(roomId: roomId),
    );
  }
}

/// 第二层房间承包商 (静态)
class WorkSettingRoom extends StatelessWidget {
  const WorkSettingRoom({super.key});

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(
      id: TestPageModel.workSettingId,
      child: WorkSettingView(
        slots: {
          TestPageModel.workAId: _buildLeaf(TestPageModel.workAId, 'WORK A'),
          TestPageModel.workBId: _buildLeaf(TestPageModel.workBId, 'WORK B'),
          TestPageModel.workGropId: const WorkGropRoom(),
        },
      ),
    );
  }
}

/// 第三层房间承包商 (静态)
class WorkGropRoom extends StatelessWidget {
  const WorkGropRoom({super.key});

  @override
  Widget build(BuildContext context) {
    return FocusIdentity(
      id: TestPageModel.workGropId,
      builder: (context, hasFocus) {
        return SuperFocusRoom(
          id: TestPageModel.workGropId,
          child: WorkGropView(
            slots: {
              TestPageModel.workCId: _buildLeaf(TestPageModel.workCId, 'WORK C'),
              TestPageModel.workDId: _buildLeaf(TestPageModel.workDId, 'WORK D'),
            },
          ),
        );
      },
    );
  }
}

/// 统一叶子节点构建逻辑
Widget _buildLeaf(String id, String label) {
  return FocusIdentity(
    id: id,
    onPressed: () => TestPageCallback.onNodePressed(id),
    builder: (context, hasFocus) {
      final material = context.useTheme();
      final colors = material.colors;
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
        decoration: BoxDecoration(
          color: hasFocus ? colors.accent : colors.surface,
          borderRadius: material.shape.radius,
          boxShadow: hasFocus ? material.visual.outerShadows : null,
          border: Border.all(
            color: hasFocus ? colors.accent : colors.border,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: hasFocus ? Colors.white : colors.textPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      );
    },
  );
}
