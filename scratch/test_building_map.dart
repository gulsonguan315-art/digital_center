import 'dart:io';
import '../lib/core/control/superfocus/building_map.dart';

void main() {
  print('Resolving Nav Target...');
  final res = BuildingMap.resolveNavTarget('music_control', 'music_fullscreen');
  print('Result: $res');
}
