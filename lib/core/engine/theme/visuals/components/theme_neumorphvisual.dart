import 'package:flutter/material.dart';
import '../theme_visuals.dart';

// =============================================================================
// 第一部分：【完整菜单库】 (在这里定义所有物理参数)
// =============================================================================

// --- A. Base层 (凸起) 菜单 ---
const _baseDefaultMenu = NeumorphPhysics(
  shadowOffsetX: 8.0,
  shadowOffsetY: -8.0, // 👈 现在正数代表向上！
  shadowAlpha: 1.0,
  shadowBlur: 0.0,
);

// --- B. Under层 (凹陷) 菜单 ---
const _underDefaultMenu = NeumorphPhysics(
  shadowOffsetX: 1.0,
  shadowOffsetY: 1.0, // 向上
  shadowAlpha: 0.5,
  shadowBlur: 3.0,
);

const _underSidebarMenu = NeumorphPhysics(
  shadowOffsetX: 2.0,
  shadowOffsetY: 2.0, // 向上
  shadowAlpha: 0.6,
  shadowBlur: 4.0,
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
          // 👈 核心修改：dy 取负值，从而让正数输入代表向上
          offset: Offset(p.shadowOffsetX, -p.shadowOffsetY),
          blurRadius: p.shadowBlur,
        ),
      ],
      surfaceOpacity: 1.0,
    );
  }

  // 厨师 B：负责凹陷效果
  SurfaceChrome _renderSunken(NeumorphPhysics p) {
    return SurfaceChrome(
      innerShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: p.shadowAlpha),
          // 👈 核心修改：dy 取负值，从而让正数输入代表向上
          offset: Offset(p.shadowOffsetX, -p.shadowOffsetY),
          blurRadius: p.shadowBlur,
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
  });

  final double shadowOffsetX;
  final double shadowOffsetY;
  final double shadowBlur;
  final double shadowAlpha;
}

const neumorphicVisualLayer = ThemeVisualLayer(
  sidebar: NeumorphSurfaceEffect(),
  card: NeumorphSurfaceEffect(),
  appBackground: NeumorphSurfaceEffect(),
  button: NeumorphSurfaceEffect(),
  focusGlowRadius: 2.0,
  focusGlowOpacity: 0.2,
);
