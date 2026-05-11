import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';
import 'views_components/theme_setting_view.dart';

class SettingPageView extends StatelessWidget {
  const SettingPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.card,
      child: ListenableBuilder(
        listenable: ThemeProvider.instance,
        builder: (context, _) {
          return const SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [ThemeSettingView()],
            ),
          );
        },
      ),
    );
  }
}
