import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../ui/base/text/surface_text.dart';
import '../../../ui/base/surface/dashboard_card.dart';
import 'system_monitor_service.dart';

/// 🖥️ 系统硬件性能监控卡片挂件 (System Monitor Card Widget)
/// 展示 CPU、内存、网速、显存 4 大核心性能指标，并拥有精美的动效与实时网速波形图 (Sparkline)。
class SystemMonitorView extends StatefulWidget {
  const SystemMonitorView({super.key});

  @override
  State<SystemMonitorView> createState() => _SystemMonitorViewState();
}

class _SystemMonitorViewState extends State<SystemMonitorView> {
  @override
  void initState() {
    super.initState();
    // 启动系统指标监听 (默认 3 秒刷新一次)
    SystemMonitorService.instance.startMonitoring(interval: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    // 停止系统指标监听，节省 CPU 资源
    SystemMonitorService.instance.stopMonitoring();
    super.dispose();
  }

  /// 格式化网速为人类可读文本
  String _formatSpeed(double bytesPerSec) {
    if (bytesPerSec >= 1024 * 1024) {
      return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    } else if (bytesPerSec >= 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';
    } else {
      return '${bytesPerSec.toStringAsFixed(0)} B/s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.useTheme();
    final colors = theme.colors;

    return StreamBuilder<SystemMetrics>(
      stream: SystemMonitorService.instance.metricsStream,
      initialData: SystemMonitorService.instance.currentMetrics,
      builder: (context, snapshot) {
        final metrics = snapshot.data ?? SystemMonitorService.instance.currentMetrics;

        return DashboardCard(
          layer: ThemeLayer.base,
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. 背景芯片电路纹理 (Futuristic chip backdrop decoration)
              Positioned(
                bottom: -35,
                left: -20,
                child: Icon(
                  Icons.developer_board_rounded,
                  size: 110,
                  color: colors.accent.withValues(alpha: 0.04),
                ),
              ),

              // 2. 四列主布局 (Row layout containing the 4 monitor metrics)
              Row(
                children: [
                  // 1. CPU 环形仪表盘 (Sector 1: CPU Circular Gauge)
                  Expanded(
                    flex: 10,
                    child: _buildPanelItem(
                      context,
                      title: 'CPU 处理器',
                      icon: Icons.speed_rounded,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0, end: metrics.cpuUsage),
                        builder: (context, value, _) {
                          return CustomPaint(
                            size: const Size(60, 60),
                            painter: _GaugePainter(
                              percent: value,
                              accentColor: colors.accent,
                              trackColor: colors.border.withValues(alpha: 0.15),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SurfaceText(
                                    '${value.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  SurfaceText(
                                    metrics.cpuUsage > 50
                                        ? 'LOADED'
                                        : (metrics.cpuUsage > 25 ? 'NORMAL' : 'IDLE'),
                                    style: TextStyle(
                                      fontSize: 6,
                                      fontWeight: FontWeight.w900,
                                      color: colors.textSecondary.withValues(alpha: 0.5),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  _buildDivider(colors.border.withValues(alpha: 0.1)),

                  // 2. 内存条形环 (Sector 2: Memory Usage Capsule Progress)
                  Expanded(
                    flex: 11,
                    child: _buildPanelItem(
                      context,
                      title: 'RAM 运行内存',
                      icon: Icons.memory_rounded,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                tween: Tween<double>(begin: 0, end: metrics.usedMemory),
                                builder: (context, value, _) {
                                  return SurfaceText(
                                    '${value.toStringAsFixed(1)} GB',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  );
                                },
                              ),
                              SurfaceText(
                                '/ ${metrics.totalMemory.toStringAsFixed(0)} GB',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textSecondary.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            tween: Tween<double>(begin: 0, end: metrics.memoryUsagePercent),
                            builder: (context, value, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProgressBar(
                                    percent: value,
                                    color: colors.accent,
                                    backgroundColor: colors.border.withValues(alpha: 0.15),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: value > 80
                                              ? Colors.redAccent
                                              : (value > 60 ? Colors.orangeAccent : colors.accent),
                                        ),
                                      ),
                                      SurfaceText(
                                        '使用率 ${value.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: colors.textSecondary.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  _buildDivider(colors.border.withValues(alpha: 0.1)),

                  // 3. 显存环形盘 (Sector 3: GPU VRAM Gauge)
                  Expanded(
                    flex: 10,
                    child: _buildPanelItem(
                      context,
                      title: 'GPU VRAM 显存',
                      icon: Icons.developer_board_rounded,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0, end: metrics.vramUsagePercent),
                        builder: (context, value, _) {
                          return CustomPaint(
                            size: const Size(60, 60),
                            painter: _GaugePainter(
                              percent: value,
                              accentColor: colors.accent,
                              trackColor: colors.border.withValues(alpha: 0.15),
                              isDoubleRing: true,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SurfaceText(
                                    '${metrics.usedVram.toStringAsFixed(1)}G',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  SurfaceText(
                                    '共${metrics.totalVram.toStringAsFixed(0)}G',
                                    style: TextStyle(
                                      fontSize: 6,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textSecondary.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  _buildDivider(colors.border.withValues(alpha: 0.1)),

                  // 4. 网速波形仪表 (Sector 4: Network speed and high-tech real-time Bezier curve sparkline)
                  Expanded(
                    flex: 12,
                    child: _buildPanelItem(
                      context,
                      title: 'NETWORK 网速',
                      icon: Icons.sensors_rounded,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                size: 12,
                                color: colors.accent,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: SurfaceText(
                                  _formatSpeed(metrics.downloadSpeed),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: colors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_upward_rounded,
                                size: 12,
                                color: colors.accent.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: SurfaceText(
                                  _formatSpeed(metrics.uploadSpeed),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 实时网速波形图 (Futuristic Bezier Sparkline Graph)
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: colors.border.withValues(alpha: 0.05),
                                ),
                                child: CustomPaint(
                                  painter: _SparklinePainter(
                                    data: SystemMonitorService.instance.downloadHistory,
                                    lineColor: colors.accent,
                                    fillColor: colors.accent.withValues(alpha: 0.1),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 绘制每个指标的小卡片模组框架
  Widget _buildPanelItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colors = context.useTheme().colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部标识 (Header title & icon)
          Row(
            children: [
              Icon(
                icon,
                size: 13,
                color: colors.accent,
              ),
              const SizedBox(width: 5),
              SurfaceText(
                title,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: colors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 内容区域
          Expanded(
            child: Center(
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  /// 绘制分隔虚线或细实线
  Widget _buildDivider(Color color) {
    return Container(
      width: 1,
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: color,
    );
  }

  /// 绘制极具科技感的圆角胶囊进度条
  Widget _buildProgressBar({
    required double percent,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      height: 6,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (percent / 100.0).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              colors: [
                color,
                color.withValues(alpha: 0.6),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(1, 0),
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// 🎨 环形极简仪表盘绘制器 (Premium Ring Gauge Painter)
class _GaugePainter extends CustomPainter {
  final double percent;
  final Color accentColor;
  final Color trackColor;
  final bool isDoubleRing;

  _GaugePainter({
    required this.percent,
    required this.accentColor,
    required this.trackColor,
    this.isDoubleRing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;

    // 1. 绘制背景圆轨 (Background track)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDoubleRing ? 2.5 : 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. 绘制极富细节的“科技刻度线 (Tech Ticks)”
    final tickPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    final int tickCount = 12;
    for (int i = 0; i < tickCount; i++) {
      final angle = (i * 2 * math.pi) / tickCount;
      final start = Offset(
        center.dx + (radius + 2) * math.cos(angle),
        center.dy + (radius + 2) * math.sin(angle),
      );
      final end = Offset(
        center.dx + (radius + 4) * math.cos(angle),
        center.dy + (radius + 4) * math.sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }

    // 3. 绘制进度电脉冲圆环 (Active Progress Arc)
    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          accentColor.withValues(alpha: 0.1),
          accentColor,
          accentColor,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDoubleRing ? 2.5 : 4.0
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = (percent / 100.0) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );

    // 4. 双层环装饰：如果是显存，绘制一层内圈虚点线
    if (isDoubleRing) {
      final innerRadius = radius - 6;
      final innerPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, innerRadius, innerPaint);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.trackColor != trackColor;
  }
}

/// 🎨 实时数据平滑贝塞尔波形绘制器 (Bezier Wave Sparkline Painter)
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;

  _SparklinePainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final width = size.width;
    final height = size.height;
    final maxVal = data.reduce(math.max);
    final minVal = data.reduce(math.min);
    final range = maxVal - minVal > 0 ? maxVal - minVal : 1.0;

    final stepX = width / (data.length - 1);

    final path = Path();
    final fillPath = Path();

    // 映射 Y 坐标函数，留出顶部和底部各 4 像素边距防裁切
    double getY(double val) {
      final double normalized = (val - minVal) / range;
      return height - 4 - normalized * (height - 8);
    }

    final double firstY = getY(data.first);
    path.moveTo(0, firstY);
    fillPath.moveTo(0, height);
    fillPath.lineTo(0, firstY);

    // 绘制平滑的贝塞尔曲线 (Cubic Bezier Spline)
    for (int i = 0; i < data.length - 1; i++) {
      final x1 = i * stepX;
      final y1 = getY(data[i]);
      final x2 = (i + 1) * stepX;
      final y2 = getY(data[i + 1]);

      // 控制点计算，实现平滑流动感
      final cx1 = x1 + stepX / 2;
      final cy1 = y1;
      final cx2 = x2 - stepX / 2;
      final cy2 = y2;

      path.cubicTo(cx1, cy1, cx2, cy2, x2, y2);
      fillPath.cubicTo(cx1, cy1, cx2, cy2, x2, y2);
    }

    fillPath.lineTo(width, height);
    fillPath.close();

    // 1. 填充发光区域 (Gradient Fill Area)
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          fillColor,
          fillColor.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 2. 绘制主体平滑实线 (Stroke Line)
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // 3. 绘制最右端实时数据呼吸灯小圆点 (Rightmost Real-Time Interactive Pulse Dot)
    final lastX = width;
    final lastY = getY(data.last);
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final dotGlowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(lastX - 2, lastY), 5, dotGlowPaint);
    canvas.drawCircle(Offset(lastX - 2, lastY), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    // 列表元素变化，重绘
    return oldDelegate.data != data ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}
