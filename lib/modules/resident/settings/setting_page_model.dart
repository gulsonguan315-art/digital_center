import '../../../ui/base/input/ui_base_switch.dart';

/// 设置页面的所有静态数据声明：ID、标题、选项配置表。
/// 视图层（View）通过引用这些常量来避免硬编码字符串。
class SettingPageModel {
  // --- Room & Gate IDs ---
  static const String settingPageId = 'settingPage';
  static const String themeGroupId = 'theme_setting';
  static const String colorSelectId = 'color_mode';
  static const String visualSelectId = 'visual_mode';
  static const String shapeSelectId = 'shape_mode';
  
  static const String customGroupId = 'custom_setting';
  static const String customSelectId = 'custom_setting';

  // --- Leaf Node IDs ---
  static const String lightModeId = 'light_mode';
  static const String nightModeId = 'night_mode';
  
  static const String flatId = 'flat';
  static const String glassyId = 'glassy';
  static const String neumorphicId = 'neumorphic';
  
  static const String rightangleId = 'rightangle';
  static const String roundId = 'round';
  static const String softId = 'soft';

  static const String settingAId = 'setting_a';
  static const String settingBId = 'setting_b';
  static const String settingCId = 'setting_c';

  // --- Group Titles ---
  static const String themeGroupTitle = 'THEME SETTING';
  static const String colorSelectTitle = 'COLOR MODE';
  static const String visualSelectTitle = 'VISUAL MODE';
  static const String shapeSelectTitle = 'SHAPE MODE';

  static const String customGroupTitle = 'CUSTOM SETTING';
  static const String customSelectTitle = 'CUSTOM MODE';

  // --- Options Configuration ---
  
  static const List<SelectOption<String>> colorOptions = [
    SelectOption(
      value: 'light',
      label: 'LIGHT',
      id: lightModeId,
    ),
    SelectOption(
      value: 'night',
      label: 'NIGHT',
      id: nightModeId,
    ),
  ];

  static const List<SelectOption<String>> visualOptions = [
    SelectOption(
      value: 'flat',
      label: 'FLAT',
      id: flatId,
    ),
    SelectOption(
      value: 'glass',
      label: 'GLASSY',
      id: glassyId,
    ),
    SelectOption(
      value: 'neumorphic',
      label: 'NEUMORPHIC',
      id: neumorphicId,
    ),
  ];

  static const List<SelectOption<String>> shapeOptions = [
    SelectOption(
      value: 'rightAngle',
      label: 'RIGHT',
      id: rightangleId,
    ),
    SelectOption(
      value: 'round',
      label: 'ROUND',
      id: roundId,
    ),
    SelectOption(
      value: 'soft',
      label: 'SOFT',
      id: softId,
    ),
  ];

  static const List<SelectOption<String>> customOptions = [
    SelectOption(
      value: 'a',
      label: 'SETTING A',
      id: settingAId,
    ),
    SelectOption(
      value: 'b',
      label: 'SETTING B',
      id: settingBId,
    ),
    SelectOption(
      value: 'c',
      label: 'SETTING C',
      id: settingCId,
    ),
  ];
}
