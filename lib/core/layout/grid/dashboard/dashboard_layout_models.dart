class ModuleConfig {
  final String moduleId;
  final int x;
  final int y;
  final int spanX;
  final int spanY;

  const ModuleConfig({
    required this.moduleId,
    required this.x,
    required this.y,
    required this.spanX,
    required this.spanY,
  });

  ModuleConfig copyWith({
    String? moduleId,
    int? x,
    int? y,
    int? spanX,
    int? spanY,
  }) {
    return ModuleConfig(
      moduleId: moduleId ?? this.moduleId,
      x: x ?? this.x,
      y: y ?? this.y,
      spanX: spanX ?? this.spanX,
      spanY: spanY ?? this.spanY,
    );
  }

  factory ModuleConfig.fromJson(Map<String, dynamic> json) {
    return ModuleConfig(
      moduleId: json['moduleId'] as String,
      x: json['x'] as int,
      y: json['y'] as int,
      spanX: json['spanX'] as int,
      spanY: json['spanY'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleId': moduleId,
      'x': x,
      'y': y,
      'spanX': spanX,
      'spanY': spanY,
    };
  }
}
