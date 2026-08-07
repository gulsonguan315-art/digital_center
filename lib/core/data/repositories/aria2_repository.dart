import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class Aria2Task {
  final String gid;
  final String name;
  final double downloadSpeed; // bytes per second
  final double uploadSpeed;   // bytes per second
  final String status;

  Aria2Task({
    required this.gid,
    required this.name,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.status,
  });
}

class Aria2Status {
  final int activeCount;
  final int waitingCount;
  final int stoppedCount;
  final double totalDownloadSpeed; // bytes per second
  final double totalUploadSpeed;   // bytes per second
  final List<Aria2Task> activeTasks;

  Aria2Status({
    required this.activeCount,
    required this.waitingCount,
    required this.stoppedCount,
    required this.totalDownloadSpeed,
    required this.totalUploadSpeed,
    required this.activeTasks,
  });
}

class Aria2Repository {
  Aria2Repository._();
  static final Aria2Repository instance = Aria2Repository._();

  Future<Aria2Status> fetchStatus(String baseUrl, String secret) async {
    final uri = Uri.parse(baseUrl);
    final headers = {'Content-Type': 'application/json'};

    final List<dynamic> authParams = secret.isNotEmpty ? ['token:$secret'] : [];

    // Request 1: Global Stat
    final bodyGlobal = jsonEncode({
      'jsonrpc': '2.0',
      'id': 'global_stat',
      'method': 'aria2.getGlobalStat',
      'params': authParams,
    });

    // Request 2: Active downloads
    final List<dynamic> tellActiveParams = authParams;
    final bodyActive = jsonEncode({
      'jsonrpc': '2.0',
      'id': 'active_tasks',
      'method': 'aria2.tellActive',
      'params': tellActiveParams,
    });

    final results = await Future.wait([
      http.post(uri, headers: headers, body: bodyGlobal).timeout(const Duration(seconds: 3)),
      http.post(uri, headers: headers, body: bodyActive).timeout(const Duration(seconds: 3)),
    ]);

    if (results[0].statusCode != 200) {
      throw HttpException('Failed to connect to Aria2 global stat (status: ${results[0].statusCode})');
    }
    if (results[1].statusCode != 200) {
      throw HttpException('Failed to connect to Aria2 active tasks (status: ${results[1].statusCode})');
    }

    final globalRes = jsonDecode(results[0].body);
    final activeRes = jsonDecode(results[1].body);

    if (globalRes['error'] != null) {
      throw HttpException(globalRes['error']['message'] ?? 'Aria2 RPC Error');
    }
    if (activeRes['error'] != null) {
      throw HttpException(activeRes['error']['message'] ?? 'Aria2 RPC Error');
    }

    final globalResult = globalRes['result'] as Map<String, dynamic>;
    final rawActiveResultList = activeRes['result'] as List<dynamic>;
    final activeResultList = rawActiveResultList.take(5).toList();

    final activeCount = int.tryParse(globalResult['numActive']?.toString() ?? '0') ?? 0;
    final waitingCount = int.tryParse(globalResult['numWaiting']?.toString() ?? '0') ?? 0;
    final stoppedCount = int.tryParse(globalResult['numStopped']?.toString() ?? '0') ?? 0;
    final totalDownloadSpeed = double.tryParse(globalResult['downloadSpeed']?.toString() ?? '0') ?? 0.0;
    final totalUploadSpeed = double.tryParse(globalResult['uploadSpeed']?.toString() ?? '0') ?? 0.0;

    final activeTasks = activeResultList.map((taskData) {
      final task = taskData as Map<String, dynamic>;
      final gid = task['gid']?.toString() ?? '';
      final status = task['status']?.toString() ?? '';
      final dlSpeed = double.tryParse(task['downloadSpeed']?.toString() ?? '0') ?? 0.0;
      final ulSpeed = double.tryParse(task['uploadSpeed']?.toString() ?? '0') ?? 0.0;
      final name = _getTaskName(task);

      return Aria2Task(
        gid: gid,
        name: name,
        downloadSpeed: dlSpeed,
        uploadSpeed: ulSpeed,
        status: status,
      );
    }).toList();

    return Aria2Status(
      activeCount: activeCount,
      waitingCount: waitingCount,
      stoppedCount: stoppedCount,
      totalDownloadSpeed: totalDownloadSpeed,
      totalUploadSpeed: totalUploadSpeed,
      activeTasks: activeTasks,
    );
  }

  String _getTaskName(Map<String, dynamic> task) {
    if (task['bittorrent'] != null && task['bittorrent']['info'] != null) {
      final name = task['bittorrent']['info']['name'];
      if (name != null && name.toString().isNotEmpty) {
        return name.toString();
      }
    }
    final files = task['files'] as List?;
    if (files != null && files.isNotEmpty) {
      final file = files[0] as Map?;
      if (file != null) {
        final path = file['path'] as String?;
        if (path != null && path.isNotEmpty) {
          // Get the filename from path
          return path.split(RegExp(r'[/\\]')).last;
        }
        final uris = file['uris'] as List?;
        if (uris != null && uris.isNotEmpty) {
          final uri = uris[0] as Map?;
          if (uri != null) {
            final uriStr = uri['uri'] as String?;
            if (uriStr != null && uriStr.isNotEmpty) {
              return uriStr.split('/').last;
            }
          }
        }
      }
    }
    return 'Downloading...';
  }

  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0 B/s';
    const units = ['B/s', 'KB/s', 'MB/s', 'GB/s', 'TB/s'];
    int unitIndex = 0;
    double speed = bytesPerSecond;
    while (speed >= 1024 && unitIndex < units.length - 1) {
      speed /= 1024;
      unitIndex++;
    }
    return '${speed.toStringAsFixed(1)} ${units[unitIndex]}';
  }
}
