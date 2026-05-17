import 'package:flutter/material.dart';
import 'test_page_model.dart';

/// 测试页总视图
class TestPageView extends StatelessWidget {
  final Map<String, Widget> slots;

  const TestPageView({super.key, required this.slots});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(60),
        child: Column(
          children: [
            const Text(
              TestPageModel.testPageTitle,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 60),

            // 根房间的插槽
            slots[TestPageModel.card1Id] ?? const SizedBox.shrink(),
            const SizedBox(height: 40),
            slots[TestPageModel.workSettingId] ?? const SizedBox.shrink(),
            const SizedBox(height: 40),
            slots[TestPageModel.explorerId] ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
