import 'package:flutter/material.dart';
import 'core/control/superfocus/focus_manager.dart';
import '_deprecated_ui/kitchen/kitchen_view.dart';
import '_deprecated_ui/corridor/corridor_view.dart';
import '_deprecated_ui/gym/gym_view.dart';
import '_deprecated_ui/sky_garden/sky_garden_view.dart';
import 'core/layout/grid/grid_scope.dart';
import 'core/layout/grid/grid_context.dart';
import 'core/layout/grid/grid_tokens.dart';
import 'core/engine/theme/theme_provider.dart';
import 'core/engine/theme/theme_factory.dart';
import 'core/engine/theme/theme_colors.dart';
import 'ui/visual/cursor/floating_cursor.dart';
import 'ui/visual/background/silk_background.dart';

void main() {
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
          ),
          darkTheme: ThemeFactory.createTheme(
            Brightness.dark,
            ThemeProvider.instance.visualStyle,
          ),
          themeMode: ThemeProvider.instance.themeMode,
          builder: (context, child) {
            final viewportSize = MediaQuery.sizeOf(context);
            final gridContext = GridContext.fromViewport(viewportSize);
            final gridTokens = GridTokens.fromContext(gridContext);

            return Focus(
              debugLabel: 'GlobalHandshakeGuard',
              descendantsAreFocusable: true,
              onKeyEvent: (node, event) =>
                  SuperFocusManager.instance.handleKeyEvent(node, event),
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

class BuildingPage extends StatelessWidget {
  const BuildingPage({super.key});
  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<ThemeColors>()!;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final silkColor = isDark
        ? const Color.fromARGB(94, 255, 255, 255)
        : Colors.black;
    final bgColor = isDark ? const Color.fromARGB(95, 0, 0, 0) : Colors.white;

    return Stack(
      children: [
        // 核心背景色
        Positioned.fill(child: Container(color: bgColor)),
        // 核心全屏底层：动态丛生游丝纹理
        Positioned.fill(child: SilkBackground(color: silkColor)),
        // 漂浮的圆圈装饰
        Positioned(
          top: 100,
          left: -50,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeColors.adormColor.withValues(alpha: 0.08),
            ),
          ),
        ),
        // 主界面
        Scaffold(
          backgroundColor: Colors.transparent, // 必须透明以显示背景
          appBar: AppBar(
            title: null,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                tooltip: '切换颜色模式',
                icon: const Icon(Icons.brightness_6),
                onPressed: () => ThemeProvider.instance.toggleMode(),
              ),
              IconButton(
                tooltip: '切换视觉风格 (扁平/玻璃/拟态)',
                icon: const Icon(Icons.palette_outlined),
                onPressed: () => ThemeProvider.instance.nextVisualStyle(),
              ),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CorridorView(
                    onGoToKitchen: () {},
                    onGoToLivingRoom: () {},
                    onGoToGym: () {},
                  ),
                  const SizedBox(height: 40),
                  const KitchenView(),
                  const SizedBox(height: 40),
                  const GymView(),
                  const SizedBox(height: 40),
                  const SkyGardenView(),
                  const SizedBox(height: 60),
                  const Text(
                    '--- 2D 扫描引擎将自动处理跨区域移动 ---',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 全局游标：必须在最顶层 Stack 且 parent at (0,0) 才能保证坐标对齐
        const FloatingHighlightBox(),
      ],
    );
  }
}
