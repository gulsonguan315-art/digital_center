/// 健身房伪数据 - 模拟 API 返回的分类数据
class GymMockData {
  static const Map<String, List<Map<String, String>>> categorizedEquipment = {
    '有氧区': [
      {'id': '跑步机', 'label': '顶级跑步机'},
      {'id': '动感单车', 'label': '动感单车'},
    ],
    '力量区': [
      {'id': '哑铃', 'label': '20kg 哑铃'},
      {'id': '杠铃', 'label': '奥林匹克杠铃'},
    ],
  };

  /// 模拟 API 异步拉取，增加 2 秒延迟以验证“航道治理协议”
  static Future<Map<String, List<Map<String, String>>>> fetchEquipment() async {
    await Future.delayed(const Duration(seconds: 2));
    return categorizedEquipment;
  }
}
