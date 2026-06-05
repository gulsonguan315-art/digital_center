import 'package:flutter/services.dart';
import '../../device_manager.dart';

/// 键盘按键翻译表
///
/// 职责：仅做 [LogicalKeyboardKey] -> [InputSignal] 的静态映射。
/// 不含任何设备监听逻辑，可以单独维护和测试。
abstract final class KeyboardTranslate {
  /// 将键盘按键翻译为原子输入信号。
  /// 未映射的按键返回 null，表示不关心该按键。
  static InputSignal? translate(LogicalKeyboardKey key) {
    return switch (key) {
      // ── 方向键 ──────────────────────────────────────────────────────────
      LogicalKeyboardKey.arrowUp => InputSignal.up,
      LogicalKeyboardKey.arrowDown => InputSignal.down,
      LogicalKeyboardKey.arrowLeft => InputSignal.left,
      LogicalKeyboardKey.arrowRight => InputSignal.right,

      // ── WASD（游戏风格方向键）────────────────────────────────────────────
      LogicalKeyboardKey.keyW => InputSignal.up,
      LogicalKeyboardKey.keyS => InputSignal.down,
      LogicalKeyboardKey.keyA => InputSignal.left,
      LogicalKeyboardKey.keyD => InputSignal.right,

      // ── 确认键 ──────────────────────────────────────────────────────────
      LogicalKeyboardKey.enter => InputSignal.confirm,
      LogicalKeyboardKey.select => InputSignal.confirm,
      LogicalKeyboardKey.space => InputSignal.confirm,

      // ── 返回键 ──────────────────────────────────────────────────────────
      LogicalKeyboardKey.escape => InputSignal.back,
      LogicalKeyboardKey.backspace => InputSignal.back,

      // ── 菜单键 ──────────────────────────────────────────────────────────
      LogicalKeyboardKey.keyM => InputSignal.menu,

      // ── 全局音量控制 ───────────────────────────────────────────────────
      LogicalKeyboardKey.numpadAdd => InputSignal.volumeUp,
      LogicalKeyboardKey.equal => InputSignal.volumeUp, // 主键盘加号/+
      LogicalKeyboardKey.numpadSubtract => InputSignal.volumeDown,
      LogicalKeyboardKey.minus => InputSignal.volumeDown, // 主键盘减号/-

      // ── 未映射 ──────────────────────────────────────────────────────────
      _ => null,
    };
  }
}
