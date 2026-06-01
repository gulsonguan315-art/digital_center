import 'dart:ui';
import 'package:flutter/material.dart';

/// 🔮 过程化径向运动模糊频谱圆圈组件 (Procedural Radial Motion Blur Spectrum Circle)
/// 基于 GLSL Fragment Shader + SDF (Signed Distance Fields) 实现满血 120FPS GPU 级渲染。
class ShaderVisualizerCircle extends StatefulWidget {
  final double energy;             // 音频频段瞬时能量 (0.0 ~ 1.0)
  final Color color;               // 圆环颜色
  final double baseSize;           // 基础直径 (默认 100.0)
  final double scaleMultiplier;    // 能量缩放系数 (默认 500.0)
  final double strokeWidth;        // 描边粗细 (默认 2.0)

  const ShaderVisualizerCircle({
    super.key,
    required this.energy,
    required this.color,
    this.baseSize = 100.0,
    this.scaleMultiplier = 500.0,
    this.strokeWidth = 2.0,
  });

  @override
  State<ShaderVisualizerCircle> createState() => _ShaderVisualizerCircleState();
}

class _ShaderVisualizerCircleState extends State<ShaderVisualizerCircle> {
  // 全局静态 Shader 程序缓存，避免多实例重复编译导致微顿卡
  static FragmentProgram? _cachedProgram;
  
  late bool _loading;
  double _lastRadius = 50.0;
  double _velocity = 0.0;

  @override
  void initState() {
    super.initState();
    _loading = _cachedProgram == null;
    _lastRadius = (widget.baseSize + widget.energy * widget.scaleMultiplier) / 2.0;
    _loadShader();
  }

  Future<void> _loadShader() async {
    if (_cachedProgram != null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final program = await FragmentProgram.fromAsset(
        'shaders/motion_blur_circle.frag',
      );
      _cachedProgram = program;
    } catch (e) {
      debugPrint('Error loading motion blur shader: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void didUpdateWidget(covariant ShaderVisualizerCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 每一帧计算瞬时径向膨胀速度
    final double currentRadius = (widget.baseSize + widget.energy * widget.scaleMultiplier) / 2.0;
    final double rawVelocity = currentRadius - _lastRadius;
    
    // 经典一阶低通滤波 (Low-pass Filter)，阻尼掉音频微弱的高频噪声抖动，使拖尾顺滑自然
    _velocity = rawVelocity * 0.75 + _velocity * 0.25;
    _lastRadius = currentRadius;
  }

  @override
  Widget build(BuildContext context) {
    final double currentRadius = (widget.baseSize + widget.energy * widget.scaleMultiplier) / 2.0;
    // 固定的最大渲染尺寸，彻底消除 Layout 振荡！
    // 使得每一帧大小缩放时只重绘（Paint），完全免除昂贵的布局（Layout）重算
    final double maxDrawSize = widget.baseSize + widget.scaleMultiplier + 120.0;

    if (_loading || _cachedProgram == null) {
      // 在 Shader 编译加载未就绪时，回退到原先无模糊的 Container 描边以防闪烁
      return OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: Container(
          width: currentRadius * 2.0,
          height: currentRadius * 2.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(
              color: widget.color.withValues(alpha: 0.4 + (widget.energy * 0.6)),
              width: widget.strokeWidth + (widget.energy * 4.0),
            ),
          ),
        ),
      );
    }

    // 编译就绪，启用满血 GPU SDF 着色器绘制
    return OverflowBox(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: SizedBox(
        width: maxDrawSize,
        height: maxDrawSize,
        child: CustomPaint(
          painter: ShaderCirclePainter(
            shader: _cachedProgram!.fragmentShader(),
            center: Offset(maxDrawSize / 2.0, maxDrawSize / 2.0),
            radius: currentRadius,
            strokeWidth: widget.strokeWidth + (widget.energy * 4.0), // 描边随能量变粗
            color: widget.color.withValues(alpha: 0.4 + (widget.energy * 0.6)),
            velocity: _velocity,
          ),
        ),
      ),
    );
  }
}

/// 🎨 ShaderCirclePainter
/// 将 Dart 端计算好的参数序列化，通过 Uniforms 传入 GPU 片元管线
class ShaderCirclePainter extends CustomPainter {
  final FragmentShader shader;
  final Offset center;
  final double radius;
  final double strokeWidth;
  final Color color;
  final double velocity;

  ShaderCirclePainter({
    required this.shader,
    required this.center,
    required this.radius,
    required this.strokeWidth,
    required this.color,
    required this.velocity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 按着色器中定义顺序注入 Uniform 变量：
    // 0: uResolution (vec2)
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    
    // 2: uCenter (vec2)
    shader.setFloat(2, center.dx);
    shader.setFloat(3, center.dy);
    
    // 4: uRadius (float)
    shader.setFloat(4, radius);
    
    // 5: uStrokeWidth (float)
    shader.setFloat(5, strokeWidth);
    
    // 6: uColor (vec4)
    shader.setFloat(6, color.r);
    shader.setFloat(7, color.g);
    shader.setFloat(8, color.b);
    shader.setFloat(9, color.a);
    
    // 10: uVelocity (float)
    shader.setFloat(10, velocity * 2.5);

    final Paint paint = Paint()..shader = shader;
    
    // 填充整个视口，让 SDF 算法实时绘制圆形及其外部拖尾、阴影
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant ShaderCirclePainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.velocity != velocity ||
        oldDelegate.center != center ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color;
  }
}
