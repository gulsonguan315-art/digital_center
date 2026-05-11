import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';

/// 设置页总视图 (纯排版工具)
/// 它负责页面的滚动和整体背景，但不持有任何具体的业务逻辑或焦点房间。
class SettingPageView extends StatelessWidget {
  /// 主题设置区域的插槽
  final Widget themeSettingSlot;

  const SettingPageView({super.key, required this.themeSettingSlot});

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.card,
      child: ListenableBuilder(
        listenable: ThemeProvider.instance,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 注入来自外部的插槽内容
                themeSettingSlot,

                // 以后可以继续添加其他插槽
                // soundSettingSlot,
                // storageSettingSlot,
              ],
            ),
          );
        },
      ),
    );
  }
}
