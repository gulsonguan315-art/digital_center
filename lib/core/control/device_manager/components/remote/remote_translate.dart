import 'package:flutter/services.dart';
import '../../device_manager.dart';

/// 遥控器按键翻译表
///
/// 职责：仅做遥控器物理键 -> [InputSignal] 的静态映射。
///
/// 遥控器按键在 Flutter 中通常以 [LogicalKeyboardKey] 的形式抵达，
/// 具体常量取决于遥控器型号及平台 HID 驱动实现（TV 平台、机顶盒等）。
///
/// 当前状态：映射表已搭好骨架，TODO 注释标记待验证项。
abstract final class RemoteTranslate {
  /// 将遥控器按键翻译为原子输入信号。
  /// 未映射的按键返回 null，表示不关心该按键。
  static InputSignal? translate(LogicalKeyboardKey key) {
    return switch (key) {
      // ── 方向键 ──────────────────────────────────────────────────────────
      // 大多数遥控器复用标准方向键
      LogicalKeyboardKey.arrowUp => InputSignal.up,
      LogicalKeyboardKey.arrowDown => InputSignal.down,
      LogicalKeyboardKey.arrowLeft => InputSignal.left,
      LogicalKeyboardKey.arrowRight => InputSignal.right,

      // ── 确认键（OK / 中键）──────────────────────────────────────────────
      LogicalKeyboardKey.select => InputSignal.confirm,
      LogicalKeyboardKey.enter => InputSignal.confirm,

      // ── 返回键 ──────────────────────────────────────────────────────────
      LogicalKeyboardKey.goBack => InputSignal.back,
      LogicalKeyboardKey.escape => InputSignal.back,
      LogicalKeyboardKey.browserBack => InputSignal.back,

      // ── 主页键 ──────────────────────────────────────────────────────────
      LogicalKeyboardKey.home => InputSignal.home,

      // ── 菜单键 ──────────────────────────────────────────────────────────
      LogicalKeyboardKey.contextMenu => InputSignal.menu,
      LogicalKeyboardKey.keyM => InputSignal.menu,

      // ── 平台特定/媒体键 ──────────────────────────────────────────────────
      LogicalKeyboardKey.mediaPlayPause => InputSignal.confirm,
      LogicalKeyboardKey.numpadAdd => InputSignal.volumeUp,
      LogicalKeyboardKey.numpadSubtract => InputSignal.volumeDown,

      // ── 未映射 ──────────────────────────────────────────────────────────
      _ => null,
    };
  }
}
