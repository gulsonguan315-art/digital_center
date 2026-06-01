import 'package:flutter/material.dart';
import '../../../core/data/data_manager.dart';
import '../../../core/data/models/weather_data.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../ui/base/text/surface_text.dart';
import '../../../ui/base/surface/dashboard_card.dart';

/// 🌤️ 天气卡片挂件 (Weather Card Widget)
class WeatherView extends StatelessWidget {
  const WeatherView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.useTheme();
    final colors = theme.colors;

    return StreamBuilder<WeatherData?>(
      initialData: DataManager.instance.latestWeather,
      stream: DataManager.instance.watchWeather(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return DashboardCard(
            layer: ThemeLayer.base,
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(colors.accent),
              ),
            ),
          );
        }

        final data = snapshot.data;
        if (data == null || data.realtime == null) {
          return DashboardCard(
            layer: ThemeLayer.base,
            padding: const EdgeInsets.all(24.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = (constraints.maxWidth / 360.0).clamp(0.45, 1.5);
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: (48 * scale).clamp(24.0, 64.0),
                        color: colors.textSecondary.withValues(alpha: 0.5),
                      ),
                      SizedBox(height: (16 * scale).clamp(8.0, 24.0)),
                      SurfaceText(
                        '暂无天气数据\n请检查网络或 api_endpoints.json',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: (13 * scale).clamp(9.0, 16.0),
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
          );
        }

        final rt = data.realtime!;
        final today = data.today;

        // 2x1 紧凑型均衡卡片 UI (带自适应缩放与布局切换)
        return DashboardCard(
          layer: ThemeLayer.base,
          padding: EdgeInsets.zero,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double scaleWidth = constraints.maxWidth / 360.0;
              final double scaleHeight = constraints.maxHeight / 170.0;
              final double scale = (scaleWidth < scaleHeight ? scaleWidth : scaleHeight).clamp(0.45, 1.5);

              final dynamicPadding = EdgeInsets.symmetric(
                horizontal: (28 * scale).clamp(8.0, 36.0),
                vertical: (20 * scale).clamp(6.0, 24.0),
              );

              final double tempSize = (64 * scale).clamp(24.0, 80.0);
              final double skyconSize = (18 * scale).clamp(11.0, 24.0);
              final double rangeSize = (14 * scale).clamp(10.0, 18.0);
              final double mainIconSize = (72 * scale).clamp(28.0, 96.0);
              final double subIconSize = (14 * scale).clamp(8.0, 18.0);
              final double subTextSize = (13 * scale).clamp(9.0, 16.0);

              final double gapBig = (12 * scale).clamp(4.0, 18.0);
              final double gapSmall = (6 * scale).clamp(2.0, 10.0);

              // 宽度小于 240 时切换为更紧凑的垂直排列，防止横向挤压溢出
              final bool useVerticalLayout = constraints.maxWidth < 240.0;

              if (useVerticalLayout) {
                return Padding(
                  padding: dynamicPadding,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _getSkyconIcon(rt.skycon, size: mainIconSize * 0.8, color: colors.accent),
                            SizedBox(width: gapSmall),
                            SurfaceText(
                              '${rt.temperature.round()}°',
                              style: TextStyle(
                                fontSize: tempSize * 0.8,
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: gapSmall),
                        SurfaceText(
                          getSkyconName(rt.skycon),
                          style: TextStyle(
                            fontSize: skyconSize,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (today != null) ...[
                          const SizedBox(height: 2),
                          SurfaceText(
                            '${today.minTemp.round()}° ~ ${today.maxTemp.round()}°',
                            style: TextStyle(
                              fontSize: rangeSize,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              // 宽屏模式：左右经典分栏
              return Padding(
                padding: dynamicPadding,
                child: SizedBox.expand(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 左侧：气温 + 描述 + 极值
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SurfaceText(
                            '${rt.temperature.round()}°',
                            style: TextStyle(
                              fontSize: tempSize,
                              fontWeight: FontWeight.w900,
                              color: colors.textPrimary,
                              height: 1.0,
                            ),
                          ),
                          SizedBox(height: gapBig),
                          SurfaceText(
                            getSkyconName(rt.skycon),
                            style: TextStyle(
                              fontSize: skyconSize,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: gapSmall),
                          if (today != null)
                            SurfaceText(
                              '${today.minTemp.round()}° ~ ${today.maxTemp.round()}°',
                              style: TextStyle(
                                fontSize: rangeSize,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                        ],
                      ),

                      // 右侧：大图标 + 湿度 & AQI
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _getSkyconIcon(rt.skycon, size: mainIconSize, color: colors.accent),
                          SizedBox(height: gapBig),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.water_drop_rounded,
                                size: subIconSize,
                                color: colors.textSecondary,
                              ),
                              SizedBox(width: 4),
                              SurfaceText(
                                '湿度 ${(rt.humidity * 100).round()}%',
                                style: TextStyle(
                                  fontSize: subTextSize,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: gapSmall),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.eco_rounded,
                                size: subIconSize,
                                color: _getAqiColor(rt.aqi),
                              ),
                              SizedBox(width: 4),
                              SurfaceText(
                                '${rt.aqiDesc} ${rt.aqi}',
                                style: TextStyle(
                                  fontSize: subTextSize,
                                  fontWeight: FontWeight.bold,
                                  color: _getAqiColor(rt.aqi),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow.shade700;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown;
  }

  Widget _getSkyconIcon(
    String skycon, {
    required double size,
    required Color color,
  }) {
    IconData icon;
    switch (skycon) {
      case 'CLEAR_DAY':
        icon = Icons.wb_sunny_rounded;
        break;
      case 'CLEAR_NIGHT':
        icon = Icons.bedtime_rounded;
        break; // 纯月亮，无云
      case 'PARTLY_CLOUDY_DAY':
        icon = Icons.cloud_queue_rounded;
        break;
      case 'PARTLY_CLOUDY_NIGHT':
        icon = Icons.nights_stay_rounded;
        break; // 月亮+云
      case 'CLOUDY':
        icon = Icons.cloud_rounded;
        break;
      case 'LIGHT_RAIN':
      case 'MODERATE_RAIN':
        icon = Icons.grain_rounded;
        break;
      case 'HEAVY_RAIN':
      case 'STORM_RAIN':
        icon = Icons.water_drop_rounded;
        break;
      case 'LIGHT_SNOW':
      case 'MODERATE_SNOW':
      case 'HEAVY_SNOW':
      case 'STORM_SNOW':
        icon = Icons.ac_unit_rounded;
        break;
      case 'WIND':
        icon = Icons.air_rounded;
        break;
      default:
        icon = Icons.wb_cloudy_rounded;
    }
    return Icon(icon, size: size, color: color);
  }
}
