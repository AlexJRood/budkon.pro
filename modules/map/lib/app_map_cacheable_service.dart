import 'package:flutter/material.dart';

class AppMapCacheSummary {
  final int memoryEntries;
  final int persistentEntries;
  final int approxBytes;
  final String? note;

  final int? memoryBytes;
  final int? persistentBytes;

  final int? cacheHits;
  final int? cacheMisses;
  final int? networkFetches;
  final DateTime? lastWarmupAt;

  const AppMapCacheSummary({
    required this.memoryEntries,
    required this.persistentEntries,
    required this.approxBytes,
    this.note,
    this.memoryBytes,
    this.persistentBytes,
    this.cacheHits,
    this.cacheMisses,
    this.networkFetches,
    this.lastWarmupAt,
  });

  int? get totalLookups {
    if (cacheHits == null && cacheMisses == null) return null;
    return (cacheHits ?? 0) + (cacheMisses ?? 0);
  }

  double? get hitRate {
    final total = totalLookups;
    if (total == null || total <= 0) return null;
    return (cacheHits ?? 0) / total;
  }
}

abstract class AppMapCacheableService {
  String get cacheDisplayName;
  String get cacheDescription;
  bool get supportsMemoryCache;
  bool get supportsPersistentCache;

  Future<AppMapCacheSummary> getCacheSummary();

  Future<void> clearMemoryCache({bool clearVisibleState = true});
  Future<void> clearPersistentCache({bool clearVisibleState = false});
  Future<void> clearAllCache({bool clearVisibleState = true});
}

String formatApproxBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}

String formatPercent(double value) {
  return '${(value * 100).toStringAsFixed(1)}%';
}

String formatDateTimeShort(DateTime value) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}