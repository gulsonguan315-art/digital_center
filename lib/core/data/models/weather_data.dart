class WeatherData {
  final RealtimeWeather? realtime;
  final List<HourlyWeather> hourly;
  final DailyWeather? today;

  WeatherData({this.realtime, this.hourly = const [], this.today});

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      realtime: json['realtime'] != null
          ? RealtimeWeather.fromJson(json['realtime'])
          : null,
      hourly:
          (json['hourly'] as List<dynamic>?)
              ?.map((e) => HourlyWeather.fromJson(e))
              .toList() ??
          [],
      today: json['today'] != null
          ? DailyWeather.fromJson(json['today'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'realtime': realtime?.toJson(),
      'hourly': hourly.map((e) => e.toJson()).toList(),
      'today': today?.toJson(),
    };
  }
}

class RealtimeWeather {
  final double temperature;
  final double apparentTemperature;
  final double humidity;
  final String skycon;
  final int aqi;
  final String aqiDesc;

  RealtimeWeather({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.skycon,
    required this.aqi,
    required this.aqiDesc,
  });

  factory RealtimeWeather.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('result')) {
      final realtime = json['result']?['realtime'] ?? {};
      final aqiData = realtime['air_quality'] ?? {};
      return RealtimeWeather(
        temperature: (realtime['temperature'] ?? 0).toDouble(),
        apparentTemperature: (realtime['apparent_temperature'] ?? 0).toDouble(),
        humidity: (realtime['humidity'] ?? 0).toDouble(),
        skycon: realtime['skycon'] ?? 'UNKNOWN',
        aqi: aqiData['aqi']?['chn'] ?? 0,
        aqiDesc: aqiData['description']?['chn'] ?? '未知',
      );
    } else {
      return RealtimeWeather(
        temperature: (json['temperature'] ?? 0).toDouble(),
        apparentTemperature: (json['apparentTemperature'] ?? 0).toDouble(),
        humidity: (json['humidity'] ?? 0).toDouble(),
        skycon: json['skycon'] ?? 'UNKNOWN',
        aqi: json['aqi'] ?? 0,
        aqiDesc: json['aqiDesc'] ?? '未知',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'apparentTemperature': apparentTemperature,
      'humidity': humidity,
      'skycon': skycon,
      'aqi': aqi,
      'aqiDesc': aqiDesc,
    };
  }
}

class HourlyWeather {
  final DateTime datetime;
  final double temperature;
  final String skycon;

  HourlyWeather({
    required this.datetime,
    required this.temperature,
    required this.skycon,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    return HourlyWeather(
      datetime: json['datetime'] != null
          ? DateTime.parse(json['datetime'])
          : DateTime.now(),
      temperature: (json['temperature'] ?? json['value'] ?? 0).toDouble(),
      skycon: json['skycon'] ?? 'UNKNOWN',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'datetime': datetime.toIso8601String(),
      'temperature': temperature,
      'skycon': skycon,
    };
  }
}

class DailyWeather {
  final double maxTemp;
  final double minTemp;
  final String sunrise;
  final String sunset;
  final String skyconDay;
  final String skyconNight;

  DailyWeather({
    required this.maxTemp,
    required this.minTemp,
    required this.sunrise,
    required this.sunset,
    required this.skyconDay,
    required this.skyconNight,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('result')) {
      final daily = json['result']?['daily'] ?? {};
      final temps = daily['temperature'] as List<dynamic>? ?? [];
      final temp0 = temps.isNotEmpty ? temps[0] : {};
      final astro = daily['astro'] as List<dynamic>? ?? [];
      final astro0 = astro.isNotEmpty ? astro[0] : {};
      final skycon0820 = daily['skycon_08h_20h'] as List<dynamic>? ?? [];
      final s0820 = skycon0820.isNotEmpty ? skycon0820[0]['value'] : 'UNKNOWN';
      final skycon2032 = daily['skycon_20h_32h'] as List<dynamic>? ?? [];
      final s2032 = skycon2032.isNotEmpty ? skycon2032[0]['value'] : 'UNKNOWN';

      return DailyWeather(
        maxTemp: (temp0['max'] ?? 0).toDouble(),
        minTemp: (temp0['min'] ?? 0).toDouble(),
        sunrise: astro0['sunrise']?['time'] ?? '--:--',
        sunset: astro0['sunset']?['time'] ?? '--:--',
        skyconDay: s0820 ?? 'UNKNOWN',
        skyconNight: s2032 ?? 'UNKNOWN',
      );
    } else {
      return DailyWeather(
        maxTemp: (json['maxTemp'] ?? 0).toDouble(),
        minTemp: (json['minTemp'] ?? 0).toDouble(),
        sunrise: json['sunrise'] ?? '--:--',
        sunset: json['sunset'] ?? '--:--',
        skyconDay: json['skyconDay'] ?? 'UNKNOWN',
        skyconNight: json['skyconNight'] ?? 'UNKNOWN',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'maxTemp': maxTemp,
      'minTemp': minTemp,
      'sunrise': sunrise,
      'sunset': sunset,
      'skyconDay': skyconDay,
      'skyconNight': skyconNight,
    };
  }
}

/// 彩云天气 Skycon 到中文名称的简单映射
String getSkyconName(String skycon) {
  switch (skycon) {
    case 'CLEAR_DAY':
      return '晴（白天）';
    case 'CLEAR_NIGHT':
      return '晴（夜间）';
    case 'PARTLY_CLOUDY_DAY':
      return '多云（白天）';
    case 'PARTLY_CLOUDY_NIGHT':
      return '多云（夜间）';
    case 'CLOUDY':
      return '阴';
    case 'LIGHT_HAZE':
      return '轻度雾霾';
    case 'MODERATE_HAZE':
      return '中度雾霾';
    case 'HEAVY_HAZE':
      return '重度雾霾';
    case 'LIGHT_RAIN':
      return '小雨';
    case 'MODERATE_RAIN':
      return '中雨';
    case 'HEAVY_RAIN':
      return '大雨';
    case 'STORM_RAIN':
      return '暴雨';
    case 'FOG':
      return '雾';
    case 'LIGHT_SNOW':
      return '小雪';
    case 'MODERATE_SNOW':
      return '中雪';
    case 'HEAVY_SNOW':
      return '大雪';
    case 'STORM_SNOW':
      return '暴雪';
    case 'DUST':
      return '浮尘';
    case 'SAND':
      return '沙尘';
    case 'WIND':
      return '大风';
    default:
      return '未知';
  }
}
