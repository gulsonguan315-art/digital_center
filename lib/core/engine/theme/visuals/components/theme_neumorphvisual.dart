import 'package:flutter/material.dart';
import 'package:superfocus/core/engine/theme/theme_role.dart';
import '../theme_visuals.dart';

// =============================================================================
// 第一部分：【完整菜单库】 (在这里定义所有物理参数)
// =============================================================================

// --- A. Base层 (凸起) 菜单 ---
const _baseDefaultMenu = NeumorphPhysics(
  shadowOffsetX: 10.0,
  shadowOffsetY: -10.0,
  shadowAlpha: 0.6,
  shadowBlur: 10.0,
  highlightOffsetX: 5.0,
  highlightOffsetY: -5.0,
  highlightAlpha: 1.0,
  highlightBlur: 5.0,
  // 描边参数 (只给 Base 层开启)
  borderWidth: 0.0,
  borderAlpha: 0.0,
  borderBlur: 0.0,
);

// --- B. Under层 (凹陷) 菜单 ---
const _underDefaultMenu = NeumorphPhysics(
  shadowOffsetX: 3.0,
  shadowOffsetY: -3.0,
  shadowAlpha: 0.6,
  shadowBlur: 1.0,
  highlightOffsetX: 1.0,
  highlightOffsetY: -1.0,
  highlightAlpha: 0.2,
  highlightBlur: 0.5,
  borderWidth: 0,
  borderAlpha: 0,
  borderBlur: 0,
);

const _underSidebarMenu = NeumorphPhysics(
  shadowOffsetX: 8.0,
  shadowOffsetY: -8.0,
  shadowAlpha: 0.6,
  shadowBlur: 5.0,
  highlightOffsetX: 2.0, // 右下方高光
  highlightOffsetY: -2.0,
  highlightAlpha: 0.5,
  highlightBlur: 2.0,
  borderWidth: 0,
  borderAlpha: 0,
  borderBlur: 0,
);

// --- C. Above层 (悬浮凸起) 菜单 ---
const _aboveDefaultMenu = NeumorphPhysics(
  shadowOffsetX: 8.0,
  shadowOffsetY: -8.0,
  shadowAlpha: 0.6,
  shadowBlur: 2.0,
  highlightOffsetX: 8.0,
  highlightOffsetY: -8.0,
  highlightAlpha: 0.0,
  highlightBlur: 1.0,
  borderWidth: 0,
  borderAlpha: 0,
  borderBlur: 0,
);

// =============================================================================
// 第二部分：【身份识别与取参】 (柜台：负责验票、查单、传话)
// =============================================================================

class NeumorphSurfaceEffect extends SurfaceEffect {
  const NeumorphSurfaceEffect();

  @override
  SurfaceChrome resolve({
    required Color accent,
    required Color border,
    required Color surface,
    required ThemeLayer layer,
    ThemeRole? role,
  }) {
    // 1. 验票：查身份证第二维 (在哪一层)
    if (layer == ThemeLayer.under) {
      // 2. 查单：查身份证第一维 (你是谁)，提取匹配的菜单
      final physics = (role == ThemeRole.sidebar)
          ? _underSidebarMenu
          : _underDefaultMenu;

      // 3. 传话：把点好的菜发给后厨
      return _renderSunken(physics);
    } else if (layer == ThemeLayer.above) {
      // 2. 查单：Above层目前统一取默认菜单
      final physics = _aboveDefaultMenu;

      // 3. 传话：同样是凸起效果，但用 Above 的参数
      return _renderConvex(physics);
    } else {
      // 2. 查单：Base层目前统一取默认菜单
      final physics = _baseDefaultMenu;

      // 3. 传话：把点好的菜发给后厨
      return _renderConvex(physics);
    }
  }

  @override
  SurfaceEffect lerp(SurfaceEffect other, double t) => other;

  // =============================================================================
  // 第三部分：【后厨渲染中心】 (只管按单做菜，不认识客人)
  // =============================================================================

  // 厨师 A：负责凸起效果
  SurfaceChrome _renderConvex(NeumorphPhysics p) {
    return SurfaceChrome(
      outerShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: p.shadowAlpha),
          offset: Offset(p.shadowOffsetX, -p.shadowOffsetY),
          blurRadius: p.shadowBlur,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: p.highlightAlpha),
          offset: Offset(-p.highlightOffsetX, p.highlightOffsetY),
          blurRadius: p.highlightBlur,
        ),
      ],
      // 描边应用
      borderColor: p.borderWidth > 0
          ? Colors.white.withValues(alpha: p.borderAlpha)
          : null,
      borderWidth: p.borderWidth,
      borderBlur: p.borderBlur,
      surfaceOpacity: 1.0,
    );
  }

  // 厨师 B：负责凹陷效果
  SurfaceChrome _renderSunken(NeumorphPhysics p) {
    return SurfaceChrome(
      innerShadows: [
        // 左上黑色阴影
        BoxShadow(
          color: Colors.black.withValues(alpha: p.shadowAlpha),
          offset: Offset(p.shadowOffsetX, -p.shadowOffsetY),
          blurRadius: p.shadowBlur,
        ),
        // 右下白色高光 (注意偏移取反)
        BoxShadow(
          color: Colors.white.withValues(alpha: p.highlightAlpha),
          offset: Offset(-p.highlightOffsetX, p.highlightOffsetY),
          blurRadius: p.highlightBlur,
        ),
      ],
      surfaceOpacity: 1.0,
    );
  }
}

// =============================================================================
// 附录：数据模型与底层支持
// =============================================================================

class NeumorphPhysics {
  const NeumorphPhysics({
    required this.shadowOffsetX,
    required this.shadowOffsetY,
    required this.shadowBlur,
    required this.shadowAlpha,
    required this.highlightOffsetX,
    required this.highlightOffsetY,
    required this.highlightBlur,
    required this.highlightAlpha,
    required this.borderWidth,
    required this.borderAlpha,
    required this.borderBlur,
  });

  final double shadowOffsetX;
  final double shadowOffsetY;
  final double shadowBlur;
  final double shadowAlpha;

  final double highlightOffsetX;
  final double highlightOffsetY;
  final double highlightBlur;
  final double highlightAlpha;

  final double borderWidth;
  final double borderAlpha;
  final double borderBlur;
}

const neumorphicVisualLayer = ThemeVisualLayer(
  sidebar: NeumorphSurfaceEffect(),
  card: NeumorphSurfaceEffect(),
  appBackground: NeumorphSurfaceEffect(),
  button: NeumorphSurfaceEffect(),
  focusGlowRadius: 2.0,
  focusGlowOpacity: 0.2,
);
