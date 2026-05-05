enum ThemeRole {
  sidebar,
  card,
  appBackground,
  button,
  defaultRole, // 👈 增加默认身份
}

enum ThemeLayer {
  /// The main surface level (Surface)
  base,

  /// Concave / Sunken into the surface (Slot)
  under,

  /// Convex / Floating above the surface (Over)
  above,
}
