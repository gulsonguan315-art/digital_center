import 'stage_contract.dart';

/// 舞台注册中心 (档案柜)
class StageRegistry {
  static final Map<String, StageContract> _contracts = {};

  static void register(StageContract contract) {
    _contracts[contract.roomId] = contract;
  }

  static StageContract? getContract(String roomId) => _contracts[roomId];

  static Iterable<StageContract> get allContracts => _contracts.values;
}
