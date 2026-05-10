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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);
  // 启动设备管理模块，接管所有物理输入信号
  SuperInputManager.instance.init();
  runApp(const MyApp());
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
