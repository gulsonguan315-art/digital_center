/// 设置页面的交互回调逻辑
class SettingPageCallback {
  static void onSwitchChanged(bool newValue) {
    // 交互式打印状态
    print('【设置中心】开关状态已变更: ${newValue ? "开启 ON" : "关闭 OFF"}');
  }
}
