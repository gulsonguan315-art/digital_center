/// 大楼树状图配置文件 (Building Map Data)
/// 这是 UI 层唯一需要手动注册房间的地方。
/// ## 前缀语法速查

/// | 前缀    | 示例               | 含义                             | FocusScope  |
/// |---------|--------------------|----------------------------------|-------------|
/// | `/`     | `/客厅`            | 子房间（独立作用域）              | 独立         |
/// | `+`     | `+有氧区`          | Zone 分区（与父房间共享作用域）   | 共用父 Room  |
/// | `*名`   | `*餐桌`            | 静态叶子节点                      | 共用父 Room  |
/// | `*`     | `*`                | 动态叶子节点通配符                | 共用父 Room  |
/// | `->`    | `->空中花园`       | 静态传送门按钮（back 弹栈飞回）   | 共用父 Room  |
/// | `*->`   | `*->播放器`        | 动态传送门（`*` 节点统一传送）    | 共用父   |

abstract class FocusSyntax {
  static const String navTarget = '=>';
  static const String dynamicPortal = '*->';
  static const String staticPortal = '->';
  static const String room = '/';
  static const String dynamicRoom = '/*';
  static const String zone = '+';
  static const String staticNode = '*';
}

class BuildingMapData {
  static const Set<String> roots = {'sidebar'};

  static final Map<String, List<String>> structure = {
    // ── [0] 侧边栏 & 导航根节点 ──────────────────────────────────────────────
    'sidebar': [
      '*dashboard=>dashboardPage',
      '+media',
      '*music=>musicPage',
      '+book',
      '*setting=>settingPage',
      '*exit=>exitPage',
    ],

    // ── [1] 退出页面 ──────────────────────────────────────────────
    'exitPage': ['*btn_shutdown_pc', '*btn_update', '*btn_exit_app'],

    // ── [2] 影视页面 ──────────────────────────────────────────────
    'media': [
      '*mov=>mediaPage',
      '*tv=>mediaPage',
      '*ani=>mediaPage',
      '*doc=>mediaPage',
      '*adt=>mediaPage',
    ],

    'mediaPage': ['*', '/*', '->media_overlay'],
    'media_overlay': [
      '*media_overlay_air_node=>media_menu',
      '*media_home_trigger=>media_home_confirm',
    ],
    'media_menu': [
      '/media_menu_speed',
      '/media_menu_skip',
      '*media_menu_subtitle',
      '*media_menu_audio',
    ],
    'media_menu_speed': [
      '*media_menu_speed_back',
      '*media_menu_speed_1.0',
      '*media_menu_speed_1.25',
      '*media_menu_speed_1.5',
      '*media_menu_speed_1.75',
      '*media_menu_speed_2.0',
    ],
    'media_menu_skip': [
      '*media_menu_skip_back',
      '*media_menu_skip_toggle',
      '*media_menu_skip_intro',
      '*media_menu_skip_outro',
    ],
    'media_home_confirm': ['*media_home_cancel', '*media_home_ok'],

    // ── [3] 音乐模块 (Music) ──────────────────────────────────────────────────
    'musicPage': [
      '/music_control',
      '/music_folder',
      '/music_list',
      '/music_lyrics',
    ],
    'music_folder': ['*'],
    'music_list': ['*'],
    'music_lyrics': [
      '*music_lyrics_offset_minus',
      '*music_lyrics_offset_minus_small',
      '*music_lyrics_offset_plus_small',
      '*music_lyrics_offset_plus',
      '*music_lyrics_export',
    ],
    'music_control': [
      '*music_play', // 置于首位，进入房间时默认获取焦点
      '*music_play_mode',
      '*music_fast_rewind',
      '*music_prev',
      '*music_next',
      '*music_fast_forward',
      '*music_fullscreen=>music_overlay',
    ],
    'music_overlay': ['*music_overlay_air_node=>music_menu'],
    'music_menu': ['*style_scrolling', '*style_single_line', '*style_mood'],

    // ── [4] 仪表盘模块 (Dashboard) ─────────────────────────────────────────────
    'dashboardPage': [
      '*dash_weather',
      '*dash_music',
      '*dash_clock',
      '*dash_stats',
      '*dash_lights',
      '*dash_air_conditioner',
      '*dash_security',
      '*dash_energy',
      '*dash_poetry=>poetry_overlay', // 🌟 注册静态导航跳转链接到古诗沉浸空间
      '/dash_widget_manager', // 🌟 挂件中控直接作为一个子房间
    ],
    'poetry_overlay': ['*'], // 🌟 注册沉浸 Overlay 房间，使用通配符以动态支持行点击高亮
    'dash_widget_manager': ['*'], // 🌟 挂件中控房间，支持内部元素进行焦点交互
    // ── [5] 图书模块 (Book) ──────────────────────────────────────────────
    'book': [
      '*sci_fi=>bookPage',
      '*Humanities=>bookPage',
      '*Power_Fantasy=>bookPage',
    ],
    'bookPage': ['*', '/*', '->book_overlay'],
    'book_overlay': ['*book_overlay_air_node=>book_menu'],
    'book_menu': [
      '*', // 动态章节节点
    ],

    // ── [6] 设置模块 (Settings) ──────────────────────────────────────────────
    'settingPage': ['/theme_setting', '/custom_setting', '/log_setting'],

    'theme_setting': ['+color_mode', '+visual_mode', '+shape_mode'],
    'color_mode': ['*light_mode', '*night_mode'],
    'visual_mode': ['*flat', '*glassy', '*neumorphic'],
    'shape_mode': ['*rightangle', '*round', '*soft'],

    'custom_setting': ['*setting_a', '*setting_b', '*setting_c'],
    'log_setting': [
      '*log_focus',
      '*log_network',
      '*log_ui',
      '*log_system',
      '*log_music',
      '*log_media',
      '*log_book',
    ],

    // ── [7] 调试 & 区域模拟测试 ───────────────────────────────────────────────
    'testPage': ['*card1', '/explorer'],
    'explorer': ['/*', '*'],
    'work_setting': ['*work_a', '*work_b', '/work_grop'],
    'work_grop': ['*work_c', '*work_d'],

    // ── [8] 物理空间模拟区域 (Physical Zones) ─────────────────────────────────────
    '公共区域': ['/空中花园'],
    '空中花园': ['*秋千', '*花盆'],
    '走廊': ['/厨房', '/健身房'],
    '厨房': ['*灶台', '*冰箱', '->空中花园'],
    '健身房': ['+有氧区', '+力量区'],
    '有氧区': ['*'],
    '力量区': ['*'],
  };
}
