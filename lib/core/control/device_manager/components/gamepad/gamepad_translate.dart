import 'package:flutter/services.dart';
import '../../device_manager.dart';

/// 手柄按键翻译表
///
/// 职责：仅做手柄物理键 -> [InputSignal] 的静态映射。
/// Flutter 将手柄 D-Pad/按键统一用 [LogicalKeyboardKey] 表达，
/// 实际常量名需在目标平台（Android/Windows/Linux）接入手柄后确认。
///
/// 当前状态：映射表已搭好骨架，TODO 注释标记待验证项。
abstract final class GamepadTranslate {
  /// 将手柄按键翻译为原子输入信号。
  /// 未映射的按键返回 null，表示不关心该按键。
  static InputSignal? translate(LogicalKeyboardKey key) {
    return switch (key) {
      // ── D-Pad 方向键 ─────────────────────────────────────────────────────
      // TODO: 在目标平台接入手柄后，确认以下 LogicalKeyboardKey 常量是否正确。
      // 参考 Flutter issue #75472 & HID gamepad spec。
      // LogicalKeyboardKey.gameButtonDpadUp    => InputSignal.up,
      // LogicalKeyboardKey.gameButtonDpadDown  => InputSignal.down,
      // LogicalKeyboardKey.gameButtonDpadLeft  => InputSignal.left,
      // LogicalKeyboardKey.gameButtonDpadRight => InputSignal.right,

      // ── 确认键（通常为 A / Cross 键）────────────────────────────────────
      // LogicalKeyboardKey.gameButtonA => InputSignal.confirm,

      // ── 返回键（通常为 B / Circle 键）───────────────────────────────────
      // LogicalKeyboardKey.gameButtonB => InputSignal.back,

      // ── 未映射 ──────────────────────────────────────────────────────────
      _ => null,
    };
  }
}
