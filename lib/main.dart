import 'package:flutter/material.dart';
import 'core/control/superfocus/focus_manager.dart';
import '_deprecated_ui/kitchen/kitchen_view.dart';
import '_deprecated_ui/corridor/corridor_view.dart';
import '_deprecated_ui/gym/gym_view.dart';
import '_deprecated_ui/sky_garden/sky_garden_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SuperFocus Building Demo',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      builder: (context, child) {
        return Focus(
          debugLabel: 'GlobalHandshakeGuard',
          descendantsAreFocusable: true,
          onKeyEvent: (node, event) =>
              SuperFocusManager.instance.handleKeyEvent(node, event),
          child: FocusTraversalGroup(
            policy: SuperFocusManager.instance.policy,
            child: child!,
          ),
        );
      },
      home: const BuildingPage(),
    );
  }
}

class BuildingPage extends StatelessWidget {
  const BuildingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(title: const Text('SuperFocus: 全景视角 (2D 自由通行)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              CorridorView(
                onGoToKitchen: () {
                  // 点击逻辑已交给黑盒：ID 匹配 '厨房' 自动进入厨房首个家具
                },
                onGoToLivingRoom: () {
                  // 点击逻辑已交给黑盒：ID 匹配 '客厅' 自动进入客厅首个家具
                },
                onGoToGym: () {
                  // 点击逻辑已交给黑盒
                },
              ),
              const SizedBox(height: 60),
              Wrap(
                spacing: 40,
                runSpacing: 40,
                alignment: WrapAlignment.center,
                children: const [
                  KitchenView(),
                  GymView(),
                  SkyGardenView(),
                ],
              ),
              const SizedBox(height: 60),
              const Text(
                '--- 2D 扫描引擎将自动处理跨区域移动 ---',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
