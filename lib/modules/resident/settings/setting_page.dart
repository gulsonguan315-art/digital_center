import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_widgets.dart';
import '../../../ui/base/input/super_focus_button.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  static const String roomId = 'settingPage';
  static const String actionId = 'settingAction';

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(
      id: roomId,
      child: Center(
        child: SuperFocusButton(
          id: actionId,
          label: 'Run setting action',
          onPressed: () {
            print('Setting action pressed');
          },
        ),
      ),
    );
  }
}
