import 'dart:io';
import '../lib/core/control/superfocus/building_map.dart';

void main() {
  Set<String> path = {};
  _fillAncestorPath('music_overlay', path);
  print('Path: $path');
}

void _fillAncestorPath(String roomId, Set<String> path) {
  if (path.contains(roomId)) return;
  path.add(roomId);
  final parent = BuildingMap.getParentRoom(roomId);
  if (parent != null) _fillAncestorPath(parent, path);
}
