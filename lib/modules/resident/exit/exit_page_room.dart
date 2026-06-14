import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/data/data_manager.dart';
import '../../../core/stage/stage_contract.dart';
import '../../../core/stage/stage_models.dart';
import '../../../core/stage/stage_registry.dart';

class ExitPageRoom extends StatelessWidget {
  static const String roomId = 'exitPage';
  const ExitPageRoom({super.key});

  static void register() {
    StageRegistry.register(
      StageContract(
        roomId: roomId,
        zone: StageZone.firstFloor_main,
        keepAlive: false,
        builder: (context) => const ExitPageRoom(),
      ),
    );
  }

  Future<void> _executeUpdate() async {
    try {
      final String exePath = Platform.resolvedExecutable;
      final String appDir = File(exePath).parent.path;
      
      // 注意转义和空格处理
      final String batContent = '''
@echo off
title Updating Digital Center...
echo Please wait while Digital Center is updating...
echo Waiting for the main application to exit...
timeout /t 3 /nobreak >nul

echo Synchronizing files from NAS...
robocopy "\\\\192.168.0.2\\data\\Gulson_Lab\\digital_center" "$appDir" /MIR /XF user_settings.json update_digital_center.bat

echo Restarting Digital Center...
start "" "$exePath"
exit
''';
      
      // 按照您的规划，存放在 \AppData\Roaming\digital_center\ 下
      final String roamingDir = DataManager.instance.configDirPath;
      final String batFilePath = '$roamingDir\\update_digital_center.bat';
      final File batFile = File(batFilePath);
      
      if (!batFile.parent.existsSync()) {
        batFile.parent.createSync(recursive: true);
      }
      await batFile.writeAsString(batContent);
      
      // 以后台 detached 模式启动，加上 '""' 防止路径中带有空格导致 start 命令解析为 title
      await Process.start(
        'cmd.exe',
        ['/c', 'start', '""', batFile.path],
        mode: ProcessStartMode.detached,
      );
      
      // 立刻自杀退出，让出文件锁
      exit(0);
    } catch (e) {
      debugPrint('Update failed: $e');
    }
  }

  void _executeExit() {
    exit(0);
  }

  void _executeShutdown() {
    // 强制关机，并使用 runSync 确保在 Dart 虚拟机退出前把命令发出去
    Process.runSync('shutdown', ['/s', '/f', '/t', '0']);
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(
      id: roomId,
      child: Container(
        color: Colors.black45, // 半透明背景
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '系统操作', 
                style: TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 60),
              _buildButton(
                id: 'btn_shutdown_pc',
                label: '关闭电脑',
                icon: Icons.power_settings_new,
                activeColor: Colors.redAccent,
                onPressed: _executeShutdown,
              ),
              const SizedBox(height: 30),
              _buildButton(
                id: 'btn_update',
                label: '更新系统',
                icon: Icons.system_update_alt,
                onPressed: _executeUpdate,
              ),
              const SizedBox(height: 30),
              _buildButton(
                id: 'btn_exit_app',
                label: '退出系统',
                icon: Icons.exit_to_app,
                onPressed: _executeExit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String id,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color activeColor = Colors.blueAccent,
  }) {
    return FocusIdentity(
      id: id,
      onPressed: onPressed,
      builder: (context, hasFocus) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 280,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: hasFocus ? activeColor.withOpacity(0.8) : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasFocus ? Colors.white : Colors.white30,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 24, 
                  fontWeight: FontWeight.w500
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
