import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../resident/music/views_components/lrc_parser.dart';
import '../../../resident/music/views_components/lyrics_animator.dart';
import '../../../resident/music/engine/lyrics_chunker.dart';

class ImmersiveMoodStyle extends StatefulWidget {
  final List<LrcLine> lyrics;
  final int activeIndex;

  const ImmersiveMoodStyle({
    super.key,
    required this.lyrics,
    required this.activeIndex,
  });

  @override
  State<ImmersiveMoodStyle> createState() => _ImmersiveMoodStyleState();
}

class MoodLineItem {
  final List<List<MoodChunk>> chunkLines;
  final int sequenceIndex;
  final Alignment alignment;
  final WrapAlignment textAlignment;
  
  // 用于通知当前行其"年龄"的变化，彻底隔离外层刷新
  final ValueNotifier<int> activeIndexNotifier = ValueNotifier(-1);
  
  late final Widget cachedWidget; // 缓存底层的纯文字 Column
  late final Widget cachedLineWidget; // 缓存整棵包含 FloatingWidget 的树！

  MoodLineItem(
    this.chunkLines,
    this.sequenceIndex,
    this.alignment,
    this.textAlignment,
  );
}

class _ImmersiveMoodStyleState extends State<ImmersiveMoodStyle> {
  final List<MoodLineItem> _history = [];
  int _lastHandledIndex = -1;

  @override
  void initState() {
    super.initState();
    _syncActiveIndex();
  }

  @override
  void didUpdateWidget(ImmersiveMoodStyle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != _lastHandledIndex ||
        oldWidget.lyrics != widget.lyrics) {
      if (oldWidget.lyrics != widget.lyrics) {
        _history.clear(); // 切换歌曲时清空历史
      }
      _syncActiveIndex();
    }
  }

  void _syncActiveIndex() {
    if (widget.activeIndex < 0 || widget.activeIndex >= widget.lyrics.length) {
      _lastHandledIndex = widget.activeIndex;
      return;
    }

    setState(() {
      final chunks = LyricsChunker.chunkLine(widget.lyrics[widget.activeIndex]);
      final random = math.Random();

      // 1. 随机切割成 1 到 3 行
      final List<List<MoodChunk>> chunkLines = [];
      if (chunks.isEmpty) {
        chunkLines.add([]);
      } else {
        int K = 1 + random.nextInt(3);
        K = K.clamp(1, chunks.length);
        if (K == 1) {
          chunkLines.add(chunks);
        } else {
          // 在 chunks 中随机挑选 K-1 个切割点，保证能精确切出 K 行
          final Set<int> splitIndices = {};
          while (splitIndices.length < K - 1) {
            splitIndices.add(1 + random.nextInt(chunks.length - 1));
          }
          final sortedSplits = splitIndices.toList()..sort();

          int start = 0;
          for (int split in sortedSplits) {
            chunkLines.add(chunks.sublist(start, split));
            start = split;
          }
          chunkLines.add(chunks.sublist(start));
        }
      }

      // 2. 随机对齐模式：左对齐，右对齐（去掉居中，使排版更具错落的美感）
      final aligns = [
        WrapAlignment.start,
        WrapAlignment.end,
      ];
      final textAlignment = aligns[random.nextInt(aligns.length)];

      // 3. 生成随机坐标
      final rx = (random.nextDouble() * 1.5) - 0.75;
      final ry = (random.nextDouble() * 1.5) - 0.75;
      final alignment = Alignment(rx, ry);

      final newItem = MoodLineItem(
        chunkLines,
        widget.activeIndex,
        alignment,
        textAlignment,
      );

      // 极致性能优化：提前构建并缓存整棵 Widget 树实例！
      // 因为外层 music_immersive_overlay 可能会以 60FPS 的频率触发 setState（监听音乐进度），
      // 如果我们不在这一层拦截，Flutter 引擎每帧都会创建几百个全新的 Wrap 和 Text 对象进行 Diff 甚至重绘，
      // 这会导致 RepaintBoundary 的缓存频繁失效，从而引发由于矢量文字重绘带来的“微颤抖（Jitter/Stutter）”。
      // 通过保存 widget 实例引用，Flutter 在 Element Tree 刷新时会进行 identical 检查，直接阻断遍历！
      newItem.cachedWidget = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: textAlignment == WrapAlignment.start
            ? CrossAxisAlignment.start
            : textAlignment == WrapAlignment.end
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.center,
        children: chunkLines.asMap().entries.map((lineEntry) {
          final lineIndex = lineEntry.key;
          final lineChunks = lineEntry.value;
          return Wrap(
            alignment: textAlignment,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8.0,
            runSpacing: 12.0,
            children: lineChunks.asMap().entries.map((entry) {
              final i = entry.key;
              final chunk = entry.value;
              return LyricsAnimator(
                type: LyricAnimationType.elasticDrop,
                duration: const Duration(milliseconds: 1000),
                delay: chunk.delay,
                child: Text(
                  chunk.text,
                  key: ValueKey('chunk_${newItem.sequenceIndex}_${lineIndex}_$i'),
                  style: TextStyle(
                    color: chunk.color,
                    fontSize: 72.0 * chunk.scale,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: 2.0,
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      );

      newItem.cachedLineWidget = MoodLineWidget(
        key: ValueKey(newItem.sequenceIndex), // 必须加 Key！否则历史列表移除头部元素时，所有后续节点会错位重建，导致退场歌词重新触发入场动画！
        item: newItem,
      );

      _history.add(newItem);

      // 保留最近的 3 句歌词（age = 0, 1, 2, 3），保证两段式退场有足够时间播完
      _history.removeWhere(
        (item) => widget.activeIndex - item.sequenceIndex > 3,
      );
      _lastHandledIndex = widget.activeIndex;
    });

    // 通知所有存在的历史节点更新它们的 activeIndex
    for (var item in _history) {
      item.activeIndexNotifier.value = widget.activeIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_history.isEmpty) {
      return const Center(child: SizedBox(key: ValueKey('empty')));
    }

    // 直接返回 Stack，让外部的约束撑满全屏
    // 这里因为 item.cachedLineWidget 是提前构建好的同一个引用，
    // Flutter 引擎 Diff 时会瞬间终止向下的遍历！完全不受外层 1Hz/60Hz 的影响。
    return Stack(
      clipBehavior: Clip.none,
      children: _history.map((item) => item.cachedLineWidget).toList(),
    );
  }
}

/// 负责单个歌词段落生命周期的全功能独立组件。
/// 通过将其自身缓存到内存中，彻底隔绝了父组件 `music_immersive_overlay` 因为监听进度带来的持续刷新（Beat Frequency Jitter 节拍微颤）。
class MoodLineWidget extends StatelessWidget {
  final MoodLineItem item;

  const MoodLineWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder 只有在换词时（activeIndex 改变）才会触发局部刷新
    return ValueListenableBuilder<int>(
      valueListenable: item.activeIndexNotifier,
      builder: (context, activeIndex, child) {
        final int age = activeIndex - item.sequenceIndex;

        return Positioned.fill(
          key: ValueKey(item.sequenceIndex),
          child: Align(
            alignment: item.alignment,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: age.toDouble(), end: age.toDouble()),
              duration: const Duration(milliseconds: 1000), // 退场时间
              curve: Curves.easeOutQuart,
              builder: (context, currentAge, innerChild) {
                final double currentOpacity = (1.0 - currentAge * 0.5).clamp(0.0, 1.0);
                final double currentScale = (1.0 - currentAge * 0.35).clamp(0.1, 1.0);
                final double currentDy = -(currentAge * 60.0);
                
                // 恢复退场时的高斯模糊，随着 age 增加而变模糊
                final double blurAmount = (currentAge * 6.0).clamp(0.0, 20.0);
                
                // 允许 sigma 绝对为 0！之前强制 0.001 是罪魁祸首！
                // 在 Impeller 引擎中，任何哪怕是 0.001 的 blur 都会强制触发一次离屏渲染（Offscreen Pass）。
                // 离屏渲染的纹理因为精度误差和浮点数混合计算，会在边界留下极为微弱的 Alpha 残留（也就是您截图里的“撕裂/鬼影线条”）！
                Widget blurredChild = ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: blurAmount, 
                    sigmaY: blurAmount,
                    tileMode: TileMode.clamp,
                  ),
                  child: innerChild!,
                );

                // 终极绝杀遮罩：
                Widget animatedChild = ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (Rect bounds) {
                    final double vStop = (32.0 / bounds.height).clamp(0.0, 0.5);
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                      stops: [0.0, vStop, 1.0 - vStop, 1.0], 
                    ).createShader(bounds);
                  },
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (Rect bounds) {
                      final double hStop = (32.0 / bounds.width).clamp(0.0, 0.5);
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: const [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                        stops: [0.0, hStop, 1.0 - hStop, 1.0], 
                      ).createShader(bounds);
                    },
                    child: blurredChild,
                  ),
                );

                return Transform.rotate(
                  angle: 0.0001, // 杀手锏：打破底层引擎纯平移带来的物理像素吸附（Pixel Snapping）
                  child: Transform.translate(
                    offset: Offset(0, currentDy),
                    child: Transform.scale(
                      scale: currentScale,
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: currentOpacity,
                        child: animatedChild,
                      ),
                    ),
                  ),
                );
              },
              // 将包含复杂正弦波漂浮计算的 FloatingWidget 作为 static child 传入！
              // 保证它整个生命周期只被创建一次，它的内部 AnimationController 永远不会和外部刷新节拍冲突！
              child: child,
            ),
          ),
        );
      },
      child: FloatingWidget(
        seed: item.sequenceIndex,
        child: Padding(
          // ⚠️ 极其关键的 Padding！专门解决您提到的 "Edge Bleeding" (边缘溢血/纹理截断) Bug。
          // 当 ImageFiltered(blur) 在退场时渲染高斯模糊，如果容器紧贴着文字，模糊算法就会在边缘“断崖式”撞墙，导致边缘出现难看的线条。
          // 给它 32 像素的“缓冲区”，就能让模糊效果平滑过渡到 0 alpha，线条就会彻底消失！
          padding: const EdgeInsets.all(32.0),
          child: item.cachedWidget,
        ),
      ),
    );
  }
}

class FloatingWidget extends StatefulWidget {
  final Widget child;
  final int seed;

  const FloatingWidget({super.key, required this.child, required this.seed});

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final double _xAmplitude;
  late final double _yAmplitude;
  
  late final double _phaseX;
  late final double _phaseY;

  @override
  void initState() {
    super.initState();
    final random = math.Random(widget.seed);
    // 随机振幅减半：X轴漂移 2~6px，Y轴漂移 4~10px（微弱呼吸感）
    _xAmplitude = 2.0 + random.nextDouble() * 3.0; // 2~5
    _yAmplitude = 3.0 + random.nextDouble() * 4.0; // 3~7
    
    _phaseX = random.nextDouble() * 2 * math.pi;
    _phaseY = random.nextDouble() * 2 * math.pi;
    // 随机周期，3到7秒不等，制造无规律的有机呼吸感
    final durationMs = 3000 + random.nextInt(4000);

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 使用正弦波模拟自然的空气浮力
        final t = _controller.value * 2 * math.pi;
        final dx = math.sin(t + _phaseX) * _xAmplitude;
        final dy = math.sin(t + _phaseY) * _yAmplitude;

        return Transform(
          // 1. 升级魔法矩阵：彻底破坏引擎底层的整数优化策略
          transform: Matrix4.identity()
            // ignore: deprecated_member_use
            ..translate(dx, dy)
            // ignore: deprecated_member_use
            ..scale(1.002, 1.002) // 极其微弱的缩放，强迫引擎开启双线性插值 (Bilinear Filtering)
            ..rotateZ(0.005),     // 约 0.28 度，足以绕过引擎把 0.0001 当作 0 的误差阈值
          alignment: Alignment.center,
          
          // 2. ⚠️ 终极杀招：直接丢弃 RepaintBoundary！
          // 让 GPU 实时计算矢量文字的亚像素边缘，而不是去平移一张会吸附像素的位图。
          // 因为外层已经阻断了 Layout 重算，GPU 纯画几行矢量字的开销几乎为零！
          child: widget.child,
        );
      },
    );
  }
}
