import 'package:flutter/material.dart';
import '../../core/control/superfocus/focus_api.dart';
import '../../core/engine/theme/theme_api.dart';
import '../../ui/base/input/ui_base_button.dart';
import 'gym_mock_data.dart';
import 'gym_room.dart';

class GymView extends StatelessWidget {
  const GymView({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. 使用 API 获取响应式状态
    final bool isInGym = context.useIsActive(GymRoom.roomId);

    // 2. 如果不活跃，则直接收起
    if (!isInGym) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, List<Map<String, String>>>>(
      future: GymMockData.fetchEquipment(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        // 再次确认活跃状态（用于动画）
        final bool isActive = context.useIsActive(GymRoom.roomId);

        return ThemeIdentity(
          role: ThemeRole.card,
          child: Builder(
            builder: (context) {
              final material = context.useTheme();

              return GymRoom(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isActive ? 1.0 : 0.4,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: isActive
                            ? material.colors.accent.withValues(alpha: 0.3)
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: material.shape.radius,
                    ),
                    child: Column(
                      children: [
                        if (data != null) ...[
                          Text(
                            'Gym',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isActive ? Colors.orange : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SuperFocusButton(
                                id: CardioRoom.roomId,
                                label: 'Cardio',
                                onPressed: () {},
                              ),
                              const SizedBox(width: 30),
                              SuperFocusButton(
                                id: StrengthRoom.roomId,
                                label: 'Strength',
                                onPressed: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: data.entries.map((entry) {
                              final areaName = entry.key;
                              final equipmentList = entry.value;

                              if (areaName == CardioRoom.roomId) {
                                return CardioRoom(
                                  child: _buildAreaContent(
                                    areaName,
                                    equipmentList,
                                  ),
                                );
                              }
                              return StrengthRoom(
                                child: _buildAreaContent(
                                  areaName,
                                  equipmentList,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAreaContent(
    String areaName,
    List<Map<String, String>> equipmentList,
  ) {
    return ThemeIdentity(
      role: ThemeRole.card,
      child: Builder(
        builder: (context) {
          // 使用新 API 获取子房间状态
          final isSubActive = context.useIsActive(areaName);
          final material = context.useTheme();

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isSubActive ? 1.0 : 0.4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 220,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: material.shape.radius,
                border: Border.all(
                  color: isSubActive
                      ? material.colors.accent.withValues(alpha: 0.3)
                      : Colors.white10,
                  width: isSubActive ? 2 : 1,
                ),
                boxShadow: isSubActive
                    ? [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Text(
                    areaName,
                    style: TextStyle(
                      color: isSubActive ? Colors.orange : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...equipmentList.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SuperFocusButton(
                        id: item['id']!,
                        label: item['label']!,
                        onPressed: () {},
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
