import 'dart:async';
import 'dart:io' show Directory, File;
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Safely clears cache if total size in bytes exceeds [maxBytes].
/// - No-ops on Web.
/// - Swallows I/O errors (logs only in debug).
/// - Avoids hardcoded 'libCachedImageData' path when possible.
Future<void> clearCacheIfTooBig({
  required CacheManager manager,
  int maxBytes = 100 * 1024 * 1024, // 100 MB
  int? maxFileCountFallback, // e.g. 2_000; if size scan fails, use count
}) async {
  if (kIsWeb) return; // dart:io/path_provider are unsupported on web

  try {
    // 1) Spróbuj znaleźć katalog cache managera w sposób przenośny
    // W najnowszych wersjach flutter_cache_manager katalogiem jest zazwyczaj tmp + storeKey
    final tmpDir = await getTemporaryDirectory();

    // preferowany root: tmp/<storeKey>. Jeśli chcesz zostać przy swojej strukturze,
    // możesz zostawić libCachedImageData, ale to detal implementacyjny:
    final candidates = <Directory>[
      Directory('${tmpDir.path}/${manager.store.storeKey}'),
      // Twój dotychczasowy wariant (fallback – może nie istnieć na każdym OS):
      Directory('${tmpDir.path}/libCachedImageData/${manager.store.storeKey}'),
    ];

    Directory? cacheDir;
    for (final d in candidates) {
      if (await d.exists()) {
        cacheDir = d;
        break;
      }
    }
    if (cacheDir == null) {
      // Nie znaleziono katalogu – nic do czyszczenia
      return;
    }

    // 2) Policz rozmiar – asynchronicznie, bez wykrzaczenia
    int totalSize = 0;
    int fileCount = 0;

    await for (final entity in cacheDir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          totalSize += await entity.length();
          fileCount++;
        } catch (_) {
          // zignoruj pojedyncze błędy plików
        }
      }
    }

    // 3) Decyzja o czyszczeniu
    final shouldClearBySize = totalSize > maxBytes;
    final shouldClearByCount =
        !shouldClearBySize && maxFileCountFallback != null && fileCount > maxFileCountFallback;

    if (shouldClearBySize || shouldClearByCount) {
      await manager.emptyCache();
      if (kDebugMode) {
        debugPrint(
          shouldClearBySize
              ? '🧹 Cache cleared (size ${_fmtMB(totalSize)} > ${_fmtMB(maxBytes)})'
              : '🧹 Cache cleared (fileCount $fileCount > $maxFileCountFallback)',
        );
      }
    }
  } catch (e, st) {
    // Nigdy nie zabijaj UI – tylko zaloguj w debug
    if (kDebugMode) {
      debugPrint('clearCacheIfTooBig error: $e\n$st');
    }
  }
}


String _fmtMB(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';






class CacheManagerDetailAdsPhotos {
  static CacheManager? _instance;

  static CacheManager get instance => _instance ??= _build();

  static CacheManager _build() {
    return CacheManager(
      Config(
        'CacheManagerDetailAdsPhotos',
        stalePeriod: const Duration(days: 2),
        maxNrOfCacheObjects: 200,
        // Ważne: NIE ustawiaj repo na siłę – wtedy działa i na Web, i na mobile.
        fileService: HttpFileService(),
      ),
    );
  }

  static Future<void> dispose() async {
    await _instance?.dispose();
    _instance = null;
  }
}

class CacheManagerFeedAdsPhotos {
  static CacheManager? _instance;

  static CacheManager get instance => _instance ??= _build();

  static CacheManager _build() {
    return CacheManager(
      Config(
        'CacheManagerFeedAdsPhotos',
        stalePeriod: const Duration(days: 14),
        maxNrOfCacheObjects: 500,
        // Ważne: NIE ustawiaj repo na siłę – wtedy działa i na Web, i na mobile.
        fileService: HttpFileService(),
      ),
    );
  }

  static Future<void> dispose() async {
    await _instance?.dispose();
    _instance = null;
  }
}