import 'dart:io';

Future<bool> openExportFileLocation(String path) async {
  final normalizedPath = path.trim();

  if (normalizedPath.isEmpty) {
    return false;
  }

  try {
    if (Platform.isWindows) {
      await Process.run(
        'explorer.exe',
        ['/select,', normalizedPath],
        runInShell: true,
      );
      return true;
    }

    if (Platform.isMacOS) {
      await Process.run(
        'open',
        ['-R', normalizedPath],
      );
      return true;
    }

    if (Platform.isLinux) {
      final entityType = FileSystemEntity.typeSync(normalizedPath);

      final directoryPath = entityType == FileSystemEntityType.directory
          ? normalizedPath
          : File(normalizedPath).parent.path;

      final commands = <List<String>>[
        ['xdg-open', directoryPath],
        ['gio', 'open', directoryPath],
      ];

      for (final command in commands) {
        final executable = command.first;
        final args = command.skip(1).toList();

        final result = await Process.run(
          executable,
          args,
          runInShell: true,
        );

        if (result.exitCode == 0) {
          return true;
        }
      }

      return false;
    }
  } catch (_) {
    return false;
  }

  return false;
}