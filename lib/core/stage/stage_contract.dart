import 'package:flutter/material.dart';
import 'stage_models.dart';

/// 业务模块入驻舞台的“合同”
class StageContract {
  final String roomId;
  final StageZone zone;
  final bool keepAlive;
  final WidgetBuilder builder;

  const StageContract({
    required this.roomId,
    required this.zone,
    this.keepAlive = false,
    required this.builder,
  });
}
