import 'package:flutter/material.dart';
import '../../ui/base/input/ui_base_button.dart';
import '../../core/control/superfocus/focus_widgets.dart';
import '../../core/control/superfocus/focus_manager.dart';
import '../../core/engine/theme/del_theme_colors.dart';
import '../../core/engine/theme/del_theme_visuals.dart';
import 'gym_room.dart';
import 'gym_mock_data.dart';

class GymView extends StatelessWidget {
  const GymView({super.key});

  @override
  Widget build(BuildContext context) {
    // 用 activeRoomPathNotifier 监听：只要焦点在健身房的任意层级
    // （含子 Zone 如有氧区、力量区），健身房视图都保持挂载，不卸载节点。
    // 修复：原来用 currentRoomId == 健身房 判断，进入子 zone 后条件变假，
    // 导致整棵树被卸载，焦点被踢回走廊。
    return ValueListenableBuilder<FocusTopology>(
      valueListenable: SuperFocusManager.instance.topologyNotifier,
      builder: (context, topology, _) {
        final activePath = topology.activePath;
        return ValueListenableBuilder<String?>(
          valueListenable: SuperFocusManager.instance.intentionRoomId,
          builder: (context, intentionId, _) {
            final bool isTargeting =
                intentionId == GymRoom.roomId ||
                intentionId == CardioRoom.roomId ||
                intentionId == StrengthRoom.roomId;

            // 只有在健身房层级之外、且没有导航意图时才卸载
            final bool isInGym = activePath.contains(GymRoom.roomId);
            if (!isInGym && !isTargeting) {
              return const SizedBox.shrink();
            }

            return FutureBuilder<Map<String, List<Map<String, String>>>>(
              future: GymMockData.fetchEquipment(),
              builder: (context, snapshot) {
                final data = snapshot.data;
                // 健身房高亮：activePath 包含健身房时点亮（含子 zone 场景）
                final bool isActive = activePath.contains(GymRoom.roomId);
                final themeColors = Theme.of(context).extension<ThemeColors>()!;
                final themeVisuals = Theme.of(
                  context,
                ).extension<ThemeVisuals>()!;

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
                              ? themeColors.adormColor.withValues(alpha: 0.3)
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: themeVisuals.defaultRadius,
                      ),
                      child: Column(
                        children: [
                          if (data != null) ...[
                            Text(
                              '健身房',
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
                                  label: '进入有氧区',
                                  onPressed: () {},
                                ),
                                const SizedBox(width: 30),
                                SuperFocusButton(
                                  id: StrengthRoom.roomId,
                                  label: '进入力量区',
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: data.entries.map((entry) {
                                final String areaName = entry.key;
                                final equipmentList = entry.value;

                                if (areaName == CardioRoom.roomId) {
                                  return CardioRoom(
                                    child: _buildAreaContent(
                                      areaName,
                                      equipmentList,
                                    ),
                                  );
                                } else {
                                  return StrengthRoom(
                                    child: _buildAreaContent(
                                      areaName,
                                      equipmentList,
                                    ),
                                  );
                                }
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAreaContent(
    String areaName,
    List<Map<String, String>> equipmentList,
  ) {
    return Builder(
      builder: (context) {
        final bool isSubActive = RoomScope.of(context)?.isActive ?? false;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isSubActive ? 1.0 : 0.4,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 220,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: Theme.of(
                context,
              ).extension<ThemeVisuals>()!.defaultRadius,
              border: Border.all(
                color: isSubActive
                    ? Theme.of(context)
                          .extension<ThemeColors>()!
                          .adormColor
                          .withValues(alpha: 0.3)
                    : Colors.white10,
                width: isSubActive ? 2 : 1,
              ),
              boxShadow: isSubActive
                  ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.1),
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
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SuperFocusButton(
                      id: item['id']!,
                      label: item['label']!,
                      onPressed: () => print('使用 ${item['label']}'),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
