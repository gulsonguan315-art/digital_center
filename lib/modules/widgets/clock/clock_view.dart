import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../ui/base/text/surface_geometric_text.dart';
import '../../../ui/base/text/surface_text.dart';
import '../../../ui/base/surface/dashboard_card.dart';

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
    final hms = DateFormat('HH:mm:ss').format(_now);
    final dateStr = DateFormat('yyyy年MM月dd日 EEE', 'zh_CN').format(_now);
    
    final colors = context.useTheme().colors;

    // 直接返回 DashboardCard，自己发行“身份证”
    return DashboardCard(
      layer: ThemeLayer.base, // 你想变凹陷就改这里为 ThemeLayer.under
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 数字部分
          Expanded(
            flex: 7,
            child: ThemeIdentity(
              role: ThemeRole.card,
              layer: ThemeLayer.under,
              child: SurfaceGeometricText(
                hms,
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
                  color: colors.foreground.withValues(alpha: 0.4),
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
