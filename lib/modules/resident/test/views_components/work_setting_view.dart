import 'package:flutter/material.dart';
import '../../../../ui/base/surface/group_frame.dart';
import '../test_page_model.dart';

/// 第二层：工作设置视图
class WorkSettingView extends StatelessWidget {
  final Map<String, Widget> slots;

  const WorkSettingView({super.key, required this.slots});

  @override
  Widget build(BuildContext context) {
    return GroupFrame(
      title: TestPageModel.workSettingTitle,
      child: Column(
        children: [
          slots[TestPageModel.workAId] ?? const SizedBox.shrink(),
          const SizedBox(height: 20),
          slots[TestPageModel.workBId] ?? const SizedBox.shrink(),
          const SizedBox(height: 40),
          
          // 嵌套第三层
          slots[TestPageModel.workGropId] ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
