import 'package:flutter/material.dart';
import 'stage_models.dart';

typedef StageDynamicBuilder = Widget Function(BuildContext context, String fullRoomId);
typedef StageCustomTransition = Widget Function(BuildContext context, Widget child, bool isVisible, Rect? heroRect);

class StageContract {
  final String roomId;
  final StageZone zone;
  final bool keepAlive;
  final WidgetBuilder? builder;
  final StageDynamicBuilder? dynamicBuilder;
  final StageCustomTransition? customTransition;
  final Duration exitDelay;

  const StageContract({
    required this.roomId,
    required this.zone,
    this.keepAlive = false,
    this.builder,
    this.dynamicBuilder,
    this.customTransition,
    this.exitDelay = const Duration(milliseconds: 350),
  }) : assert(builder != null || dynamicBuilder != null, '必须提供 builder 或 dynamicBuilder');
}
