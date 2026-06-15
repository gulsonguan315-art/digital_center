import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/data/data_manager.dart';
import '../../../core/data/models/poetry_data.dart';
import 'package:superfocus/core/control/superfocus/core/interaction_manager.dart'; // 🌟 引入焦点管理器以触发 backCommand
import '../../../core/control/superfocus/focus_api.dart';
import 'package:superfocus/core/control/superfocus/widgets/focus_widgets.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/stage/stage_contract.dart';
import '../../../core/stage/stage_models.dart';
import '../../../core/stage/stage_registry.dart';
import '../../../ui/base/text/surface_text.dart';
import '../../../ui/base/surface/dashboard_card.dart';

/// 📂 诗词沉浸式交互高亮房间 (Immersive fullscreen highlight editor)
class PoetryOverlayRoom extends StatelessWidget {
  static const String roomId = 'poetry_overlay';
  const PoetryOverlayRoom({super.key});

  static void register() {
    StageRegistry.register(
      StageContract(
        roomId: roomId,
        zone: StageZone.thirdFloorOverlay,
        keepAlive: false,
        builder: (context) => const PoetryOverlayRoom(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: Colors.transparent,
      child: SuperFocusRoom(id: roomId, child: PoetryOverlayContent()),
    );
  }
}

class PoetryOverlayContent extends StatefulWidget {
  const PoetryOverlayContent({super.key});

  @override
  State<PoetryOverlayContent> createState() => _PoetryOverlayContentState();
}

class _PoetryOverlayContentState extends State<PoetryOverlayContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _blurAnimation;

  Set<int>? _tempMarks; // 当前点选的临时高亮行号集合
  Set<int>? _initialMarks; // 进入时的初始高亮行号快照，用于退出时的脏检查
  PoetryData? _currentPoetry; // 缓存当前的诗词对象以供退场回写

  bool? _wasActive; // 追踪 isActive 状态以驱动退场绝对扣锁

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 15.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isActive = RoomScope.of(context)?.isActive ?? false;

    // 1. 响应式驱动进退场过渡动画
    if (_wasActive != isActive) {
      if (isActive) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }

    // 2. 🛡️ 物理退场扣锁：一旦感知到 isActive 从 true 变为 false，强制同步回写数据库
    if (_wasActive == true && !isActive) {
      _triggerWriteback();
    }

    _wasActive = isActive;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// 触发脏检查与持久化写入（Offline-First 后台回写 SWR）
  void _triggerWriteback() {
    if (_tempMarks == null || _initialMarks == null || _currentPoetry == null) {
      return;
    }

    // 🔍 脏检查：只有当临时标记与初始标记不一致时才写库
    final hasChanges = !setEquals(_initialMarks, _tempMarks);
    if (hasChanges) {
      // 🌟 修复：将 Set 转为 List 后，强制按行号从小到大排序，杜绝顺序不一致导致的 UI 重绘和脏检查误判
      final sortedMarks = _tempMarks!.toList()..sort();

      final updated = PoetryData(
        id: _currentPoetry!.id,
        title: _currentPoetry!.title,
        author: _currentPoetry!.author,
        paragraphs: _currentPoetry!.paragraphs,
        date: _currentPoetry!.date,
        markedLines: sortedMarks,
      );

      // 大管家立刻刷写本地缓存并异步网络回传
      DataManager.instance.savePoetryMarks(updated);
    }
  }

  void _showEditDialog(BuildContext context, PoetryData data) {
    final theme = context.useTheme();
    final colors = theme.colors;

    final titleController = TextEditingController(text: data.title);
    final authorController = TextEditingController(text: data.author);
    final paragraphsController = TextEditingController(text: data.paragraphs.join('\n'));

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) {
        return Center(
          child: SizedBox(
            width: 600,
            child: DashboardCard(
              layer: ThemeLayer.base,
              padding: const EdgeInsets.all(32.0),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SurfaceText(
                        '修改诗词内容',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: titleController,
                            decoration: InputDecoration(
                              labelText: '标题',
                              labelStyle: TextStyle(color: colors.textSecondary),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: colors.border),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: colors.accent),
                              ),
                            ),
                            style: TextStyle(color: colors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: authorController,
                            decoration: InputDecoration(
                              labelText: '作者',
                              labelStyle: TextStyle(color: colors.textSecondary),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: colors.border),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: colors.accent),
                              ),
                            ),
                            style: TextStyle(color: colors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: paragraphsController,
                      maxLines: 10,
                      minLines: 5,
                      decoration: InputDecoration(
                        labelText: '诗词段落（每行一句）',
                        labelStyle: TextStyle(color: colors.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colors.border),
                          borderRadius: theme.shape.radius as BorderRadius,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colors.accent),
                          borderRadius: theme.shape.radius as BorderRadius,
                        ),
                        alignLabelWithHint: true,
                      ),
                      style: TextStyle(
                        color: colors.textPrimary,
                        height: 1.6,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: SurfaceText(
                            '取消',
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            final newTitle = titleController.text.trim();
                            final newAuthor = authorController.text.trim();
                            final newParagraphs = paragraphsController.text
                                .split('\n')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();

                            if (newTitle.isNotEmpty && newParagraphs.isNotEmpty) {
                              final updated = PoetryData(
                                id: data.id,
                                title: newTitle,
                                author: newAuthor.isEmpty ? '未知' : newAuthor,
                                paragraphs: newParagraphs,
                                date: data.date,
                                markedLines: const [],
                              );
                              DataManager.instance.saveCustomPoetry(updated);
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: theme.shape.radius,
                            ),
                          ),
                          child: const Text('保存修改'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 安全保存并退出房间
  void _saveAndExit() {
    _triggerWriteback(); // 主动执行脏检查
    SuperFocusManager.instance.onBackCommand(); // 触发焦点导航退回 Dashboard Room
  }

  /// 点选/去除行标记
  void _toggleLine(int index) {
    if (_tempMarks == null) return;
    setState(() {
      if (_tempMarks!.contains(index)) {
        _tempMarks!.remove(index);
      } else {
        _tempMarks!.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.useTheme();
    final colors = theme.colors;

    return StreamBuilder<PoetryData>(
      stream: DataManager.instance.watchTodayPoetry(),
      initialData: DataManager.instance.latestPoetry,
      builder: (context, snapshot) {
        final data = snapshot.data ?? DataManager.instance.latestPoetry;

        // 🌟 修复：不仅判空，还要在网络流推送全新诗词（如 ID 变更）时，强制重置并初始化高亮快照，杜绝状态穿透
        if (_tempMarks == null || _currentPoetry?.id != data.id) {
          _tempMarks = Set<int>.from(data.markedLines);
          _initialMarks = Set<int>.from(data.markedLines);
        }

        _currentPoetry = data; // 赋值必须放在判决之后

        return AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Stack(
              children: [
                // 1. 全屏高斯模糊与暗色背景平滑过渡
                Positioned.fill(
                  child: MouseDismissRegion(
                    onDismiss: _saveAndExit,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: _blurAnimation.value,
                        sigmaY: _blurAnimation.value,
                      ),
                      child: Container(
                        color: colors.surface.withValues(
                          // 🌟 纠正 RoleColors 属性使用 surface
                          alpha: 0.92 * _fadeAnimation.value,
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. 沉浸式诗词卡片主体 (GPU Scale & Fade 动画联动)
                Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: SizedBox(
                        width: 800,
                        height: MediaQuery.of(context).size.height * 0.85,
                        child: DashboardCard(
                          layer: ThemeLayer.base,
                          padding: const EdgeInsets.all(40.0),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // 装饰背景巨型引号
                              Positioned(
                                top: -20,
                                left: -10,
                                child: Text(
                                  '“',
                                  style: TextStyle(
                                    fontSize: 120,
                                    fontFamily: 'Georgia',
                                    fontWeight: FontWeight.bold,
                                    color: colors.accent.withValues(
                                      alpha: 0.08,
                                    ),
                                    height: 1,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -80,
                                right: -10,
                                child: Text(
                                  '”',
                                  style: TextStyle(
                                    fontSize: 120,
                                    fontFamily: 'Georgia',
                                    fontWeight: FontWeight.bold,
                                    color: colors.accent.withValues(
                                      alpha: 0.08,
                                    ),
                                    height: 1,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),

                              // 诗词内容交互区
                              Positioned.fill(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // 顶部标题与落款
                                    Center(
                                      child: SurfaceText(
                                        data.title,
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: colors.textPrimary,
                                          letterSpacing: 3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Center(
                                      child: SurfaceText(
                                        '[ ${data.author} ]',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                          color: colors.textSecondary.withValues(
                                            alpha: 0.6,
                                          ),
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 40),

                                    // 中间列表：每一行古诗作为一个带焦点的交互行
                                    Expanded(
                                      child: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: Column(
                                          children: List.generate(
                                            data.paragraphs.length,
                                            (i) => _buildLineNode(
                                              index: i,
                                              text: data.paragraphs[i],
                                              colors: colors,
                                              theme: theme,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 24),
                                    // 底部保存返回操作指南
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        FocusIdentity(
                                          id: 'btn_poetry_edit',
                                          onPressed: () => _showEditDialog(context, data),
                                          builder: (context, hasFocus) {
                                            return AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 32,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: hasFocus
                                                    ? colors.accent
                                                    : colors.surface,
                                                borderRadius: theme.shape.radius,
                                                boxShadow: hasFocus
                                                    ? theme.visual.outerShadows
                                                    : null,
                                                border: Border.all(
                                                  color: hasFocus
                                                      ? colors.accent
                                                      : colors.border,
                                                  width: 2,
                                                ),
                                              ),
                                              child: SurfaceText(
                                                '修改文字',
                                                style: TextStyle(
                                                  color: hasFocus
                                                      ? Colors.white
                                                      : colors.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.5,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 16),
                                        FocusIdentity(
                                          id: 'btn_poetry_exit',
                                          onPressed: _saveAndExit,
                                          builder: (context, hasFocus) {
                                            return AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 32,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: hasFocus
                                                    ? colors.accent
                                                    : colors.surface,
                                                borderRadius: theme.shape.radius,
                                                boxShadow: hasFocus
                                                    ? theme.visual.outerShadows
                                                    : null,
                                                border: Border.all(
                                                  color: hasFocus
                                                      ? colors.accent
                                                      : colors.border,
                                                  width: 2,
                                                ),
                                              ),
                                              child: SurfaceText(
                                                '保存并返回 (Esc)',
                                                style: TextStyle(
                                                  color: hasFocus
                                                      ? Colors.white
                                                      : colors.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.5,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 构建诗词交互行焦点微件 (Spatial Discrete Line Node)
  Widget _buildLineNode({
    required int index,
    required String text,
    required RoleColors colors, // 🌟 纠正强类型定义
    required ResolvedThemeMaterial theme, // 🌟 纠正强类型定义
  }) {
    final bool isMarked = _tempMarks?.contains(index) ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FocusIdentity(
        id: 'poetry_line_$index',
        onPressed: () => _toggleLine(index),
        focusGeometry: RoundedRectFocusGeometry(
          borderRadius: theme.shape.radius as BorderRadius,
        ),
        builder: (context, hasFocus) {
          // 👑 东方轻奢美学金箔勾勒高亮效果
          final Color inkGold = Colors.amber.shade700;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: isMarked
                  ? inkGold.withValues(alpha: 0.08)
                  : (hasFocus
                        ? colors.surface.withValues(alpha: 0.5)
                        : Colors.transparent),
              borderRadius: theme.shape.radius,
              border: Border.all(
                color: hasFocus
                    ? (isMarked ? inkGold : colors.accent)
                    : (isMarked
                          ? inkGold.withValues(alpha: 0.3)
                          : Colors.transparent),
                width: 1.5,
              ),
            ),
            child: Center(
              child: SurfaceText(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isMarked ? FontWeight.w800 : FontWeight.normal,
                  color: isMarked
                      ? inkGold
                      : (hasFocus
                            ? colors.textPrimary
                            : colors.textPrimary.withValues(alpha: 0.8)),
                  letterSpacing: 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
