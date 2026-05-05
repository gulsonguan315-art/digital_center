import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../ui/base/text/surface_geometric_text.dart';
import '../../../ui/base/text/surface_text.dart';

class ClockView extends StatefulWidget {
  const ClockView({super.key});

  @override
  State<ClockView> createState() => _ClockViewState();
}

class _ClockViewState extends State<ClockView> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.card,
      layer: ThemeLayer.base,
      child: Builder(
        builder: (context) {
          final material = context.useTheme();
          final chrome = material.visual;

          final hms = DateFormat('HH:mm:ss').format(_now);
          final dateStr = DateFormat('yyyy年MM月dd日 EEE', 'zh_CN').format(_now);

          return Container(
            width: double.infinity,
            height: double.infinity,
            // 外部 Container 不再需要 Padding，因为 SurfaceGeometricText 内部自带 Padding 控制
            decoration: BoxDecoration(
              color: material.colors.surface,
              borderRadius: material.shape.radius,
              boxShadow: chrome.outerShadows,
              border: Border.all(
                color: chrome.borderColor ?? Colors.transparent,
                width: chrome.borderWidth,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 数字部分占满剩余空间的 70%
                Expanded(
                  flex: 7,
                  child: ThemeIdentity(
                    role: ThemeRole.card,
                    layer: ThemeLayer.under,
                    child: SurfaceGeometricText(
                      hms,
                      // 不再传 size，开启全自动填充
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ),
                // 日期部分
                Expanded(
                  flex: 2,
                  child: Center(
                    child: SurfaceText(
                      dateStr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: material.colors.textPrimary.withOpacity(0.4),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
