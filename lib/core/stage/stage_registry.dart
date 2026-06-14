import 'stage_contract.dart';

/// 舞台注册中心 (档案柜)
class StageRegistry {
  static final Map<String, StageContract> _contracts = {};

  static void register(StageContract contract) {
    _contracts[contract.roomId] = contract;
  }

  static StageContract? getContract(String roomId) {
    if (_contracts.containsKey(roomId)) {
      return _contracts[roomId];
    }
    // 支持通配符前缀匹配，例如 movieDetail_* 匹配 movieDetail_123
    for (final key in _contracts.keys) {
      if (key.endsWith('*')) {
        final prefix = key.substring(0, key.length - 1);
        if (roomId.startsWith(prefix)) {
          return _contracts[key];
        }
      }
    }
    return null;
  }

  static Iterable<StageContract> get allContracts => _contracts.values;
}
