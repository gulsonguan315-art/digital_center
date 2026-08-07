import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/data/data_manager.dart';
import '../../../core/data/repositories/aria2_repository.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../ui/base/text/surface_text.dart';
import '../../../ui/base/surface/dashboard_card.dart';

/// 📥 Aria2 下载管理器卡片挂件 (Aria2 Monitor Card Widget)
class Aria2View extends StatefulWidget {
  const Aria2View({super.key});

  @override
  State<Aria2View> createState() => _Aria2ViewState();
}

class _Aria2ViewState extends State<Aria2View> {
  Timer? _timer;
  String? _baseUrl;
  String? _secret;
  Aria2Status? _status;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndStartPoll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettingsAndStartPoll() async {
    try {
      final userSettings = await DataManager.instance.getUserSettings();
      _baseUrl = userSettings.api.aria2BaseUrl;
      _secret = userSettings.api.aria2Secret;

      if (_baseUrl == null || _baseUrl!.trim().isEmpty) {
        setState(() {
          _error = '请在 user_settings.json 中配置 Aria2';
          _loading = false;
        });
        return;
      }

      // 立即刷新一次
      await _fetchStatus();

      // 开始定时轮询 (每 3 秒刷新一次)
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _fetchStatus();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '配置加载失败: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchStatus() async {
    if (_baseUrl == null) return;
    try {
      final status = await Aria2Repository.instance.fetchStatus(_baseUrl!, _secret ?? '');
      if (mounted) {
        setState(() {
          _status = status;
          _error = null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // 只保留简短关键错误描述，避免内容溢出
          _error = '连接服务失败\n${e.toString().split(':').last.trim()}';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.useTheme();
    final colors = theme.colors;

    return DashboardCard(
      layer: ThemeLayer.base,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. 右下角微缩科技图标底纹 (Backdrop tech icon decoration)
          Positioned(
            bottom: -25,
            right: -15,
            child: Icon(
              Icons.download_for_offline_rounded,
              size: 110,
              color: colors.accent.withValues(alpha: 0.05),
            ),
          ),

          // 2. 主体内容布局
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2.1 卡片头部 (Header: Title & Circular Icon Frame)
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.accent.withValues(alpha: 0.12),
                      border: Border.all(
                        color: colors.accent.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.download_for_offline_rounded,
                      size: 14,
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SurfaceText(
                    'ARIA2 下载中心',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  if (!_loading && _error == null)
                    _StatusDot(color: colors.accent),
                ],
              ),
              const SizedBox(height: 12),

              // 2.2 内容状态切换 (Loading / Error / Content)
              Expanded(
                child: _buildContent(colors),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(RoleColors colors) {
    if (_loading && _status == null) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_error != null && _status == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 28,
              color: colors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 6),
            SurfaceText(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final status = _status!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2.1.1 上部：3个框展示任务数量
        Row(
          children: [
            _buildCountBox(
              colors: colors,
              title: '下载中',
              count: status.activeCount.toString(),
              isHighlight: status.activeCount > 0,
            ),
            _buildCountBox(
              colors: colors,
              title: '队列中',
              count: status.waitingCount.toString(),
              isHighlight: status.waitingCount > 0,
            ),
            _buildCountBox(
              colors: colors,
              title: '已结束',
              count: status.stoppedCount.toString(),
              isHighlight: status.stoppedCount > 0,
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 2.1.2 中部：总下载/上传速度
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.accent.withValues(alpha: 0.25),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  Icon(Icons.arrow_downward_rounded, size: 12, color: colors.accent),
                  const SizedBox(width: 4),
                  SurfaceText(
                    '下载: ${Aria2Repository.formatSpeed(status.totalDownloadSpeed)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.arrow_upward_rounded, size: 12, color: colors.textSecondary),
                  const SizedBox(width: 4),
                  SurfaceText(
                    '上传: ${Aria2Repository.formatSpeed(status.totalUploadSpeed)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2.1.3 下部：最多5个正在下载的任务列表
        const SurfaceText(
          '正在下载',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: status.activeTasks.isEmpty
              ? Center(
                  child: SurfaceText(
                    '暂无进行中的下载任务',
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: status.activeTasks.length,
                  itemBuilder: (context, index) {
                    final task = status.activeTasks[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_circle_filled_rounded,
                            size: 10,
                            color: colors.accent,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: SurfaceText(
                              task.name,
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SurfaceText(
                            Aria2Repository.formatSpeed(task.downloadSpeed),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: colors.accent,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCountBox({
    required RoleColors colors,
    required String title,
    required String count,
    required bool isHighlight,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.accent.withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
        child: Column(
          children: [
            SurfaceText(
              title,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 3),
            SurfaceText(
              count,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isHighlight ? colors.accent : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 呼吸状态指示灯
class _StatusDot extends StatefulWidget {
  final Color color;

  const _StatusDot({required this.color});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _animation.value),
          ),
        );
      },
    );
  }
}
