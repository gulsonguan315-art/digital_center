import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';

/// 设置页总视图 (纯排版工具)
/// 统一采用 [slots] 插槽收纳盒模式，实现与组件层级的高度对称。
class SettingPageView extends StatelessWidget {
  /// 插槽收纳盒
  final Map<String, Widget> slots;

  const SettingPageView({super.key, required this.slots});

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.card,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 从收纳盒中按需取件
            slots['theme_setting'] ?? const SizedBox.shrink(),

            // 以后在这里可以继续通过 slots 扩展
            // const SizedBox(height: 32),
            // slots['network_setting'] ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
