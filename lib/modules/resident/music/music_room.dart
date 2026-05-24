import 'package:flutter/material.dart';

import '../../../core/control/superfocus/focus_api.dart';
import 'music_model.dart';
import 'music_view.dart';

/// 📂 音乐中心主房间 (Music Room Composition Root)
class MusicRoom extends StatelessWidget {
  final Widget? child;
  const MusicRoom({super.key, this.child});

  static const String roomId = MusicModel.musicPageId;

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(
      id: MusicModel.musicPageId,
      child: child ?? const MusicView(),
    );
  }
}
