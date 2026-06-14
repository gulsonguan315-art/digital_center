import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/control/superfocus/interaction_manager.dart';
import 'core/control/device_manager/device_manager.dart';
import 'core/layout/grid/grid_scope.dart';
import 'core/layout/grid/grid_context.dart';
import 'core/layout/grid/grid_tokens.dart';
import 'core/engine/theme/theme_provider.dart';
import 'core/engine/theme/theme_factory.dart';
import 'ui/visual/cursor/floating_cursor.dart';
import 'ui/pages/building_page.dart';

import 'core/data/data_manager.dart';
import 'app_initializer.dart';
import 'package:media_kit/media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await windowManager.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);
  
  // 0. 初始化大管家并阻塞等待加载偏好（避免冷启动主题闪烁）
  await DataManager.instance.init();

  // 0.5 注册应用生命周期监听，确保应用在退出/挂起时同步落锁刷盘，杜绝防抖数据丢失
  WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
  
  // 1. 初始化舞台调度中心 (招商登记)
  AppInitializer.init();
  
  // 1.5 读取用户配置，并立即保存一次（确保新字段如 immersiveMode 被写入文件）
  final userSettings = await DataManager.instance.getUserSettings();
  await DataManager.instance.saveUserSettings(userSettings);

  // 根据配置设定窗口形态 (C++ 层启动时已屏蔽显示，等待这里施加最终形态)
  WindowOptions windowOptions = userSettings.immersiveMode
      ? const WindowOptions(
          fullScreen: true,
          alwaysOnTop: true,
        )
      : const WindowOptions(
          size: Size(1280, 720),
          alwaysOnTop: false,
        );

  // waitUntilReadyToShow 会等待 Flutter 渲染出第一帧。
  // 我们已经移除了 C++ 层的强制显示，现在由 Dart 独占窗口控制权。
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    if (!userSettings.immersiveMode) {
      await windowManager.center(); // 等窗口真正 show 出来后再居中，防止坐标系计算错误
    }
  });

  // 初始化双模交互系统
  SuperInteractionManager.instance.init(mode: userSettings.interactionMode);
  
  // 2. 启动设备管理模块，接管所有物理输入信号
  SuperInputManager.instance.init();
  runApp(MyApp(immersiveMode: userSettings.immersiveMode));
}

/// 🔋 临终落锁刷盘生命周期监控器 (App Teardown Lifecycle Observer)
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      DataManager.instance.flush(); // 切后台时同步落锁刷盘，不关闭 Stream
    } else if (state == AppLifecycleState.detached) {
      DataManager.instance.dispose(); // 真正关闭退出时释放所有资源
    }
  }
}

class MyApp extends StatelessWidget {
  final bool immersiveMode;
  const MyApp({super.key, required this.immersiveMode});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SuperFocus Building Demo',
          theme: ThemeFactory.createTheme(
            Brightness.light,
            ThemeProvider.instance.visualStyle,
            ThemeProvider.instance.shapeStyle,
          ),
          darkTheme: ThemeFactory.createTheme(
            Brightness.dark,
            ThemeProvider.instance.visualStyle,
            ThemeProvider.instance.shapeStyle,
          ),
          themeMode: ThemeProvider.instance.themeMode,
          builder: (context, child) {
            final viewportSize = MediaQuery.sizeOf(context);
            final gridContext = GridContext.fromViewport(viewportSize);
            final gridTokens = GridTokens.fromContext(gridContext);

            Widget appBody = ExcludeSemantics(
              child: Focus(
                debugLabel: 'GlobalDeviceInputGuard',
                descendantsAreFocusable: true,
                autofocus: true,
                // 利用 Flutter 事件冒泡：TextField 等原生输入组件先消费自己的按键，
                // 未消费的才冒泡到这里，由 DeviceManager 翻译为 InputSignal 下发焦点系统。
                onKeyEvent: (node, event) =>
                    SuperInputManager.instance.handleRootKeyEvent(node, event),
                child: FocusTraversalGroup(
                  policy: SuperFocusManager.instance.policy,
                child: GridScope(
                  gridContext: gridContext,
                  gridTokens: gridTokens,
                  child: Stack(
                    children: [child!, const FloatingHighlightBox()],
                  ),
                ),
              ),
            ));

            // 如果是沉浸模式，说明通常是在无桌面/Kiosk环境下运行（如数字大屏），
            // 将整个 APP 强制设为无鼠标指针状态，避免屏幕中间一直有个鼠标。
            if (immersiveMode) {
              appBody = MouseRegion(
                cursor: SystemMouseCursors.none,
                child: appBody,
              );
            }

            return appBody;
          },
          home: const BuildingPage(),
        );
      },
    );
  }
}
