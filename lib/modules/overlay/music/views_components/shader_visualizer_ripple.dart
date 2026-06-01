import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 🌊 concentric 波纹发射频谱圆圈组件 (Wave-Emission Ripple Spectrum Circle)
/// 精确微分检测鼓点瞬间，发射出独立物理扩散和衰减的三次缓出涟漪，具备极佳的密集鼓点视觉响应度。
class ShaderVisualizerRipple extends StatefulWidget {
  final double energy;             // 音频频段瞬时能量 (0.0 ~ 1.0)
  final Color color;               // 圆环颜色
  final double baseSize;           // 基础直径 (默认 100.0)
  final double scaleMultiplier;    // 能量扩散系数 (默认 500.0)
  final double strokeWidth;        // 描边粗细 (默认 2.0)

  const ShaderVisualizerRipple({
    super.key,
    required this.energy,
    required this.color,
    this.baseSize = 100.0,
    this.scaleMultiplier = 500.0,
    this.strokeWidth = 2.0,
  });

  @override
  State<ShaderVisualizerRipple> createState() => _ShaderVisualizerRippleState();
}

class EmittedRipple {
  final double initialEnergy;     // 触发该波纹的瞬时鼓点能量
  final double duration;          // 波纹生命时长 (秒)
  double age = 0.0;               // 已存活时间 (秒)

  EmittedRipple({
    required this.initialEnergy,
    this.duration = 0.8,
  });
}

class _ShaderVisualizerRippleState extends State<ShaderVisualizerRipple>
    with SingleTickerProviderStateMixin {
  
  static FragmentProgram? _cachedProgram;
  
  late bool _loading;
  final List<EmittedRipple> _ripples = [];
  
  // 💥 实例化精准局部滑动均值鼓点检测器
  final BeatDetector _kickDetector = BeatDetector(
    historySize: 40,
    variance: 1.35,      // 能量必须大于局部平均值的 1.35 倍
    cooldownFrames: 10,  // 冷却 10 帧 (约 160ms)，完美过滤重复触发和长底鼓波动
    noiseFloor: 0.08,    // 过滤底噪 (低于该能量的声音直接忽略)
  );
  
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loading = _cachedProgram == null;
    _loadShader();
    
    // 初始化 Ticker，建立 high-frequency 重绘回路
    _ticker = createTicker(_onTick)..start();
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
      debugPrint('Error loading motion blur shader in ripple: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (_ripples.isEmpty) {
      _lastElapsed = elapsed;
      return;
    }

    // 计算两帧之间的增量时间 dt (秒)
    final double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    bool changed = false;
    for (int i = _ripples.length - 1; i >= 0; i--) {
      final ripple = _ripples[i];
      ripple.age += dt;
      
      // 超出寿命的粒子自动回收
      if (ripple.age >= ripple.duration) {
        _ripples.removeAt(i);
        changed = true;
      } else {
        changed = true;
      }
    }

    // 仅在有活动粒子更新时触发 Paint 重绘，最大化节约 CPU 资源
    if (changed && mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant ShaderVisualizerRipple oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 使用 BeatDetector 的滑动窗口局部平均及物理不应期算法检测这一帧是否构成真正的鼓点爆发
    if (_kickDetector.detect(widget.energy)) {
      _spawnRipple(widget.energy);
    }
  }

  void _spawnRipple(double energy) {
    // 限制最大同时共存波纹数，防止密集鼓点或长啸叫导致 GPU 负担超载
    if (_ripples.length >= 6) {
      _ripples.removeAt(0); // 移除最老的一个
    }
    
    _ripples.add(EmittedRipple(
      initialEnergy: energy,
      duration: 0.8, // 0.8秒平滑衰减
    ));
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 固定的最大渲染尺寸，彻底消除 Layout 振荡！
    final double maxDrawSize = widget.baseSize + widget.scaleMultiplier + 120.0;
    final double currentRadius = (widget.baseSize + widget.energy * widget.scaleMultiplier) / 2.0;

    if (_loading || _cachedProgram == null) {
      // 备用兜底逻辑：加载期间，绘制一个渐变的底图
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

    return OverflowBox(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: SizedBox(
        width: maxDrawSize,
        height: maxDrawSize,
        child: CustomPaint(
          painter: ShaderRipplePainter(
            shader: _cachedProgram!.fragmentShader(),
            center: Offset(maxDrawSize / 2.0, maxDrawSize / 2.0),
            ripples: _ripples,
            baseRadius: widget.baseSize / 2.0,
            maxSpreadRadius: widget.scaleMultiplier / 2.0,
            baseStrokeWidth: widget.strokeWidth,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

/// 🎨 ShaderRipplePainter
/// 批量将当前存活的全部波纹提交给着色器管线合并渲染
class ShaderRipplePainter extends CustomPainter {
  final FragmentShader shader;
  final Offset center;
  final List<EmittedRipple> ripples;
  final double baseRadius;
  final double maxSpreadRadius;
  final double baseStrokeWidth;
  final Color color;

  ShaderRipplePainter({
    required this.shader,
    required this.center,
    required this.ripples,
    required this.baseRadius,
    required this.maxSpreadRadius,
    required this.baseStrokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (ripples.isEmpty) return;

    for (final ripple in ripples) {
      final double progress = (ripple.age / ripple.duration).clamp(0.0, 1.0);
      final double t = progress;
      
      // 三次 ease-out 扩张曲线，让波纹爆发时膨胀极快，随后缓慢衰减
      final double radiusCurve = 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t);
      
      // 扩散限制：鼓声越大，扩散极限半径越大
      final double spreadLimit = maxSpreadRadius * (0.4 + ripple.initialEnergy * 0.6);
      final double currentRadius = baseRadius + spreadLimit * radiusCurve;
      
      // 随着扩张而淡出：从 1.0 (完全不透明) 完美线性衰减至 0.0 (完全透明)
      final double currentOpacity = 1.0 - progress;
      
      // 线宽收窄：扩散越远越薄
      final double currentStrokeWidth = baseStrokeWidth * (1.0 - progress * 0.45) * (1.0 + ripple.initialEnergy * 2.5);
      
      // 物理精确的径向瞬时速度公式（半径半径对 progress 求导）
      // dr/dt = spreadLimit * 3 * (1-t)^2
      // 转化为每帧跨度像素并进行放大
      final double rawVelocity = (spreadLimit * 3.0 * (1.0 - t) * (1.0 - t)) / (ripple.duration * 60.0);
      final double velocity = rawVelocity * 2.5;
      
      // 绑定着色器 Uniforms 并向 GPU 发起一次 Draw 调用
      shader.setFloat(0, size.width);
      shader.setFloat(1, size.height);
      shader.setFloat(2, center.dx);
      shader.setFloat(3, center.dy);
      shader.setFloat(4, currentRadius);
      shader.setFloat(5, currentStrokeWidth);
      
      // 传入当前不透明度 alpha
      final double alpha = currentOpacity;
      shader.setFloat(6, color.r);
      shader.setFloat(7, color.g);
      shader.setFloat(8, color.b);
      shader.setFloat(9, alpha);
      
      shader.setFloat(10, velocity);

      final Paint paint = Paint()..shader = shader;
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ShaderRipplePainter oldDelegate) {
    // 只要有活动粒子，就必须在 Ticker 帧心跳中持续重绘
    return ripples.isNotEmpty;
  }
}

/// 🎯 极其精准的音乐瞬态（鼓点）检测器 (Dynamic Onset Beat Detector)
/// 引入滑动窗口局部均值（Local Average）与帧级物理冷却不应期（Cooldown），彻底解决假阳性/假阴性/鬼畜重叠三大痛点！
class BeatDetector {
  final int historySize;       // 记录过去多少帧的数据（决定了“局部平均”的时间跨度）
  final double variance;       // 触发乘数（核心玄学参数，越大越迟钝，越小越敏感）
  final int cooldownFrames;    // 冷却帧数（防止一个鼓点触发多次发射）
  final double noiseFloor;     // 噪音底噪（低于这个绝对值的能量直接无视）

  final List<double> _history = [];
  int _currentCooldown = 0;

  BeatDetector({
    this.historySize = 40,     // 60FPS下，约 0.6秒 的记忆
    this.variance = 1.35,      // 当前能量必须大于平均值的 1.35 倍才会触发！
    this.cooldownFrames = 10,  // 冷却 10 帧 (约 160ms，完美过滤双击)
    this.noiseFloor = 0.05,    // 太小的声音不理会
  });

  /// 每一帧把底鼓(Kick)的能量传进来，它会告诉你这一帧要不要发射
  bool detect(double currentEnergy) {
    // 1. 如果还在冷却期，强制不触发，但要记录历史
    if (_currentCooldown > 0) {
      _currentCooldown--;
      _pushHistory(currentEnergy);
      return false;
    }

    // 2. 历史数据不够时，先攒数据
    if (_history.length < historySize ~/ 2) {
      _pushHistory(currentEnergy);
      return false;
    }

    // 3. 计算“过去一段时间的平均能量”
    double sum = 0;
    for (var e in _history) {
      sum += e;
    }
    double localAverage = sum / _history.length;

    // 4. 🎯 核心判断逻辑：
    // 条件A：能量必须大于底噪（不能在极度安静时乱发）
    // 条件B：当前能量 必须大于 局部平均值 乘以 乘数
    if (currentEnergy > noiseFloor && currentEnergy > localAverage * variance) {
      _currentCooldown = cooldownFrames; // 💥 触发！进入冷却
      // 触发时，为了防止影响后续判断，可以把当前能量稍微打个折塞进历史
      _pushHistory(currentEnergy * 0.5); 
      return true; // 告诉外部：发射涟漪！
    }

    _pushHistory(currentEnergy);
    return false;
  }

  void _pushHistory(double energy) {
    _history.add(energy);
    if (_history.length > historySize) {
      _history.removeAt(0); // 维持队列长度
    }
  }
}
