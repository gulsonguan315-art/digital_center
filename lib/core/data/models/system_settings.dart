/// Represents all system-wide preferences (Theme, Visual Style, Shape, Logs).
class SystemSettings {
  final String themeMode; // 'light', 'night', or 'system'
  final String visualStyle; // 'flat', 'glass', 'neumorphic'
  final String shapeStyle; // 'rightAngle', 'round', 'soft'
  final String customMode; // 'a', 'b', 'c'
  final List<String> enabledLogGroups; // ['Focus', 'Network', 'UI', 'System']

  const SystemSettings({
    required this.themeMode,
    required this.visualStyle,
    required this.shapeStyle,
    required this.customMode,
    required this.enabledLogGroups,
  });

  /// Default starting settings when no configuration file exists.
  static const SystemSettings defaultSettings = SystemSettings(
    themeMode: 'system',
    visualStyle: 'neumorphic',
    shapeStyle: 'soft',
    customMode: 'a',
    enabledLogGroups: ['Focus', 'Network', 'UI', 'System'],
  );

  /// Converts the settings object into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'visualStyle': visualStyle,
      'shapeStyle': shapeStyle,
      'customMode': customMode,
      'enabledLogGroups': enabledLogGroups,
    };
  }

  /// Restores settings from a JSON map with safe fallbacks to default values.
  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      themeMode: (json['themeMode'] ?? 'system') as String,
      visualStyle: (json['visualStyle'] ?? 'neumorphic') as String,
      shapeStyle: (json['shapeStyle'] ?? 'soft') as String,
      customMode: (json['customMode'] ?? 'a') as String,
      enabledLogGroups: List<String>.from(
        json['enabledLogGroups'] ?? ['Focus', 'Network', 'UI', 'System'],
      ),
    );
  }

  /// Helper to duplicate settings with updated fields.
  SystemSettings copyWith({
    String? themeMode,
    String? visualStyle,
    String? shapeStyle,
    String? customMode,
    List<String>? enabledLogGroups,
  }) {
    return SystemSettings(
      themeMode: themeMode ?? this.themeMode,
      visualStyle: visualStyle ?? this.visualStyle,
      shapeStyle: shapeStyle ?? this.shapeStyle,
      customMode: customMode ?? this.customMode,
      enabledLogGroups: enabledLogGroups ?? this.enabledLogGroups,
    );
  }
}
