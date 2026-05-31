import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/control/superfocus/focus_manager.dart';
import 'core/control/device_manager/device_manager.dart';
import 'core/layout/grid/grid_scope.dart';
import 'core/layout/grid/grid_context.dart';
import 'core/layout/grid/grid_tokens.dart';
import 'core/engine/theme/theme_provider.dart';
import 'core/engine/theme/theme_factory.dart';
import 'ui/visual/cursor/floating_cursor.dart';
import 'ui/pages/building_page.dart';

import 'core/data/data_manager.dart';
import 'core/stage/stage_initializer.dart';
import 'package:media_kit/media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);
  
  // 0. 初始化大管家并阻塞等待加载偏好（避免冷启动主题闪烁）
  await DataManager.instance.init();

  // 0.5 注册应用生命周期监听，确保应用在退出/挂起时同步落锁刷盘，杜绝防抖数据丢失
  WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
  
  // 1. 初始化舞台调度中心 (招商登记)
  StageInitializer.init();
  
  // 2. 启动设备管理模块，接管所有物理输入信号
  SuperInputManager.instance.init();
  runApp(const MyApp());
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
  const MyApp({super.key});

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

            return Focus(
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
            );
          },
          home: const BuildingPage(),
        );
      },
    );
  }
}
