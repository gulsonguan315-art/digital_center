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
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: colors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  SurfaceText(
                    '暂无天气数据\n请检查网络或 api_endpoints.json',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final rt = data.realtime!;
        final today = data.today;

        // 2x1 紧凑型均衡卡片 UI
        return DashboardCard(
          layer: ThemeLayer.base,
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: SizedBox.expand(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左侧：超大气温 + 天气描述和极值
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SurfaceText(
                      '${rt.temperature.round()}°',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SurfaceText(
                      '${getSkyconName(rt.skycon)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (today != null)
                      SurfaceText(
                        '${today.minTemp.round()}° ~ ${today.maxTemp.round()}°',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),

                // 右侧：大图标 + 湿度空气质量
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _getSkyconIcon(rt.skycon, size: 72, color: colors.accent),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.water_drop_rounded,
                          size: 14,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        SurfaceText(
                          '湿度 ${(rt.humidity * 100).round()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.eco_rounded,
                          size: 14,
                          color: _getAqiColor(rt.aqi),
                        ),
                        const SizedBox(width: 4),
                        SurfaceText(
                          '${rt.aqiDesc} ${rt.aqi}',
                          style: TextStyle(
                            fontSize: 13,
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
