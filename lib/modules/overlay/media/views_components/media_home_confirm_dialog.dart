import 'package:flutter/material.dart';
import '../../../../../core/control/superfocus/focus_api.dart';
import '../../../../../core/control/superfocus/focus_widgets.dart';

class MediaHomeConfirmDialog extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const MediaHomeConfirmDialog({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SuperFocusRoom(
        id: 'media_home_confirm',
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '确认返回主页？',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '这将会结束当前的视频播放',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FocusIdentity(
                    id: 'media_home_cancel',
                    onPressed: () {
                      FocusAPI.dispatchBackCommand();
                      onCancel();
                    },
                    builder: (ctx, hasFocus) => _buildConfirmButton(
                      title: '取消',
                      hasFocus: hasFocus,
                      isPrimary: false,
                    ),
                  ),
                  FocusIdentity(
                    id: 'media_home_ok',
                    onPressed: () {
                      FocusAPI.dispatchHomeCommand();
                      onConfirm();
                    },
                    builder: (ctx, hasFocus) => _buildConfirmButton(
                      title: '确认返回',
                      hasFocus: hasFocus,
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton({
    required String title,
    required bool hasFocus,
    required bool isPrimary,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: hasFocus 
            ? (isPrimary ? Colors.redAccent : Colors.white24) 
            : (isPrimary ? Colors.redAccent.withValues(alpha: 0.8) : Colors.transparent),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasFocus ? Colors.white : Colors.transparent,
          width: 2,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: hasFocus || isPrimary ? Colors.white : Colors.white70,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
