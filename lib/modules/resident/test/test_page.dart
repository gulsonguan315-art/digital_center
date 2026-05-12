import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../ui/base/text/surface_text.dart';

class TestPageRoom extends StatelessWidget {
  const TestPageRoom({super.key});

  static const String roomId = 'testPage';

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(
      id: roomId,
      child: const TestPageView(),
    );
  }
}

class TestPageView extends StatelessWidget {
  const TestPageView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.useTheme().colors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SurfaceText(
            'TEST PAGE',
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          FocusIdentity(
            id: 'card1',
            autofocus: true,
            builder: (context, isFocused) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 300,
                height: 200,
                decoration: BoxDecoration(
                  color: isFocused ? colors.accent : colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: isFocused ? Border.all(color: Colors.white, width: 4) : null,
                ),
                child: const Center(
                  child: SurfaceText('FOCUSED CARD'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
