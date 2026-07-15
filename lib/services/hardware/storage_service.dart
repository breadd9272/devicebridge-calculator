import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/utils/logger.dart';
import '../../models/command_result_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;
  StorageService._();

  Future<bool> checkPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      return status.isGranted;
    }
    return true;
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  Future<CommandResult> browse(Map<String, dynamic> payload) async {
    final commandId = payload['commandId'] as String? ?? '';
    final directory = payload['path'] as String? ?? '/storage/emulated/0';
    final page = payload['page'] as int? ?? 0;
    final perPage = payload['per_page'] as int? ?? 50;

    try {
      if (!await checkPermission()) {
        final granted = await requestPermission();
        if (!granted) {
          return CommandResult.failure(commandId, 'permission_denied: Storage permission not granted');
        }
      }

      final dir = Directory(directory);
      if (!await dir.exists()) {
        return CommandResult.failure(commandId, 'directory_not_found: $directory');
      }

      final entities = await dir.list().toList();
      final files = <Map<String, dynamic>>[];
      final directories = <Map<String, dynamic>>[];

      for (final entity in entities) {
        final stat = await entity.stat();
        final isDir = entity is Directory;
        final item = <String, dynamic>{
          'name': entity.path.split('/').last,
          'path': entity.path,
          'is_directory': isDir,
          'size_bytes': stat.size,
          'modified': stat.modified.toIso8601String(),
        };
        if (isDir) {
          directories.add(item);
        } else {
          files.add(item);
        }
      }

      // Sort: directories first, then files
      directories.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      files.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      final allItems = [...directories, ...files];
      final start = page * perPage;
      final end = (start + perPage).clamp(0, allItems.length);
      final pageItems = start < allItems.length ? allItems.sublist(start, end) : <Map<String, dynamic>>[];

      return CommandResult.success({
        'commandId': commandId,
        'path': directory,
        'items': pageItems,
        'total': allItems.length,
        'page': page,
        'per_page': perPage,
        'total_pages': (allItems.length / perPage).ceil(),
      });
    } catch (e) {
      AppLogger.e('StorageService', 'Browse failed', e);
      return CommandResult.failure(commandId, 'browse_failed: ${e.toString()}');
    }
  }

  Future<CommandResult> getFileInfo(Map<String, dynamic> payload) async {
    final commandId = payload['commandId'] as String? ?? '';
    final filePath = payload['path'] as String?;

    if (filePath == null) {
      return CommandResult.failure(commandId, 'missing_path: File path required');
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return CommandResult.failure(commandId, 'file_not_found: $filePath');
      }

      final stat = await file.stat();
      return CommandResult.success({
        'commandId': commandId,
        'name': filePath.split('/').last,
        'path': filePath,
        'size_bytes': stat.size,
        'is_directory': false,
        'modified': stat.modified.toIso8601String(),
        'accessed': stat.accessed.toIso8601String(),
      });
    } catch (e) {
      AppLogger.e('StorageService', 'Get file info failed', e);
      return CommandResult.failure(commandId, 'file_info_failed: ${e.toString()}');
    }
  }
}