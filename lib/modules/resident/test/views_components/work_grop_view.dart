import 'package:flutter/material.dart';
import '../../../../ui/base/surface/group_frame.dart';
import '../test_page_model.dart';

/// 第三层：工作组视图
class WorkGropView extends StatelessWidget {
  final Map<String, Widget> slots;

  const WorkGropView({super.key, required this.slots});

  @override
  Widget build(BuildContext context) {
    return GroupFrame(
      title: TestPageModel.workGropTitle,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          slots[TestPageModel.workCId] ?? const SizedBox.shrink(),
          const SizedBox(width: 20),
          slots[TestPageModel.workDId] ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
