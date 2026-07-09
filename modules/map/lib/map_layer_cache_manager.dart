import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

import 'app_map_cacheable_service.dart';
import 'app_map_layer_service.dart';

class MapLayerCacheManagerPanel extends StatefulWidget {
  final List<AppMapLayerService> services;
  final ThemeColors theme;

  const MapLayerCacheManagerPanel({
    super.key,
    required this.services,
    required this.theme,
  });

  @override
  State<MapLayerCacheManagerPanel> createState() =>
      _MapLayerCacheManagerPanelState();
}

class _MapLayerCacheManagerPanelState extends State<MapLayerCacheManagerPanel> {
  late final List<AppMapCacheableService> _services;
  final Map<String, AppMapCacheSummary> _summaries = {};

  bool _loading = true;
  bool _busy = false;

  ThemeColors get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _services = widget.services.whereType<AppMapCacheableService>().toList();
    _reload();
  }

  int get _totalMemoryEntries =>
      _summaries.values.fold(0, (sum, item) => sum + item.memoryEntries);

  int get _totalPersistentEntries =>
      _summaries.values.fold(0, (sum, item) => sum + item.persistentEntries);

  int get _totalBytes =>
      _summaries.values.fold(0, (sum, item) => sum + item.approxBytes);

  int get _totalMemoryBytes =>
      _summaries.values.fold(0, (sum, item) => sum + (item.memoryBytes ?? 0));

  int get _totalPersistentBytes => _summaries.values
      .fold(0, (sum, item) => sum + (item.persistentBytes ?? 0));

  int get _totalHits =>
      _summaries.values.fold(0, (sum, item) => sum + (item.cacheHits ?? 0));

  int get _totalMisses =>
      _summaries.values.fold(0, (sum, item) => sum + (item.cacheMisses ?? 0));

  int get _totalNetworkFetches => _summaries.values
      .fold(0, (sum, item) => sum + (item.networkFetches ?? 0));

  double? get _totalHitRate {
    final total = _totalHits + _totalMisses;
    if (total <= 0) return null;
    return _totalHits / total;
  }

  DateTime? get _lastWarmupAt {
    DateTime? latest;
    for (final item in _summaries.values) {
      final warmup = item.lastWarmupAt;
      if (warmup == null) continue;
      if (latest == null || warmup.isAfter(latest)) {
        latest = warmup;
      }
    }
    return latest;
  }

  Future<void> _reload() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    final results = await Future.wait(
      _services.map((service) => service.getCacheSummary()),
    );

    final next = <String, AppMapCacheSummary>{};
    for (int i = 0; i < _services.length; i++) {
      next[_services[i].cacheDisplayName] = results[i];
    }

    if (!mounted) return;

    setState(() {
      _summaries
        ..clear()
        ..addAll(next);
      _loading = false;
    });
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: theme.dashboardContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: theme.dashboardBoarder),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: theme.textColor.withAlpha(220),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel'.tr,
                style: TextStyle(color: theme.textColor),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.themeColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> _run(
      Future<void> Function() action, {
        bool confirm = false,
        String? confirmTitle,
        String? confirmMessage,
        String? confirmLabel,
      }) async {
    if (confirm) {
      final accepted = await _confirmAction(
        title: confirmTitle ?? 'confirm_action'.tr,
        message: confirmMessage ?? 'confirm_continue'.tr,
        confirmLabel: confirmLabel ?? 'execute'.tr,
      );

      if (!accepted) return;
    }

    if (!mounted) return;

    setState(() {
      _busy = true;
    });

    try {
      await action();
      await _reload();
    } finally {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _clearAllPersistent() async {
    await _run(
          () async {
        for (final service in _services) {
          await service.clearPersistentCache(clearVisibleState: false);
        }
      },
      confirm: true,
      confirmTitle: 'clear_local_cache_title'.tr,
      confirmMessage: 'clear_local_cache_message'.tr,
      confirmLabel: 'clear_local'.tr,
    );
  }

  Future<void> _clearAllMemory() async {
    await _run(
          () async {
        for (final service in _services) {
          await service.clearMemoryCache(clearVisibleState: false);
        }
      },
      confirm: true,
      confirmTitle: 'clear_ram_cache_title'.tr,
      confirmMessage: 'clear_ram_cache_message'.tr,
      confirmLabel: 'clear_ram'.tr,
    );
  }

  Future<void> _clearAll() async {
    await _run(
          () async {
        for (final service in _services) {
          await service.clearAllCache(clearVisibleState: true);
        }
      },
      confirm: true,
      confirmTitle: 'clear_everything_title'.tr,
      confirmMessage: 'clear_everything_message'.tr,
      confirmLabel: 'clear_everything'.tr,
    );
  }

  Widget _summaryChip(
      String label,
      String value, {
        IconData? icon,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: theme.textColor),
            const SizedBox(width: 6),
          ],
          Text(
            '$label: $value',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _capabilityChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.textColor.withAlpha(210),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _serviceActionButton({
    required String label,
    required Future<void> Function() onPressed,
    bool filled = false,
  }) {
    if (filled) {
      return FilledButton.tonal(
        style: FilledButton.styleFrom(
          backgroundColor: theme.themeColor,
          foregroundColor: Colors.white,
        ),
        onPressed: _busy ? null : onPressed,
        child: Text(label),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.textColor,
        side: BorderSide(color: theme.textColor.withAlpha(60)),
      ),
      onPressed: _busy ? null : onPressed,
      child: Text(label),
    );
  }

  Widget _serviceCard(AppMapCacheableService service) {
    final summary = _summaries[service.cacheDisplayName];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  service.cacheDisplayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: theme.textColor,
                  ),
                ),
              ),
              if (service.supportsMemoryCache)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.memory_rounded,
                    size: 18,
                    color: theme.textColor,
                  ),
                ),
              if (service.supportsPersistentCache)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.storage_rounded,
                    size: 18,
                    color: theme.textColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            service.cacheDescription,
            style: TextStyle(
              color: theme.textColor.withAlpha(190),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (service.supportsMemoryCache) _capabilityChip('ram_cache'.tr),
              if (service.supportsPersistentCache) _capabilityChip('local_cache'.tr),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _summaryChip(
                'ram_entries'.tr,
                summary == null ? '...' : '${summary.memoryEntries}',
                icon: Icons.memory_rounded,
              ),
              _summaryChip(
                'local_entries'.tr,
                summary == null ? '...' : '${summary.persistentEntries}',
                icon: Icons.storage_rounded,
              ),
              _summaryChip(
                'ram_size'.tr,
                summary == null
                    ? '...'
                    : formatApproxBytes(summary.memoryBytes ?? 0),
                icon: Icons.memory_outlined,
              ),
              _summaryChip(
                'local_size'.tr,
                summary == null
                    ? '...'
                    : formatApproxBytes(summary.persistentBytes ?? 0),
                icon: Icons.sd_storage_rounded,
              ),
              _summaryChip(
                'total_size'.tr,
                summary == null ? '...' : formatApproxBytes(summary.approxBytes),
                icon: Icons.data_object_rounded,
              ),
              if (summary?.hitRate != null)
                _summaryChip(
                  'hit_rate'.tr,
                  formatPercent(summary!.hitRate!),
                  icon: Icons.speed_rounded,
                ),
              if (summary?.cacheHits != null)
                _summaryChip(
                  'hits'.tr,
                  '${summary!.cacheHits}',
                  icon: Icons.check_circle_outline_rounded,
                ),
              if (summary?.cacheMisses != null)
                _summaryChip(
                  'misses'.tr,
                  '${summary!.cacheMisses}',
                  icon: Icons.error_outline_rounded,
                ),
              if (summary?.networkFetches != null)
                _summaryChip(
                  'api_fetches'.tr,
                  '${summary!.networkFetches}',
                  icon: Icons.cloud_download_outlined,
                ),
              if (summary?.lastWarmupAt != null)
                _summaryChip(
                  'last_warmup'.tr,
                  formatDateTimeShort(summary!.lastWarmupAt!),
                  icon: Icons.schedule_rounded,
                ),
            ],
          ),
          if (summary?.note != null) ...[
            const SizedBox(height: 10),
            Text(
              summary!.note!,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (service.supportsMemoryCache)
                _serviceActionButton(
                  label: 'clear_ram'.tr,
                  onPressed: () => _run(
                        () => service.clearMemoryCache(
                      clearVisibleState: false,
                    ),
                    confirm: true,
                    confirmTitle: 'clear_ram_cache_title'.tr,
                    confirmMessage: 
                    '${'clear_ram_layer_message'.tr}${service.cacheDisplayName}".',
                    confirmLabel: 'clear_ram'.tr,
                  ),
                ),
              if (service.supportsPersistentCache)
                _serviceActionButton(
                  label: 'clear_local'.tr,
                  onPressed: () => _run(
                        () => service.clearPersistentCache(
                      clearVisibleState: false,
                    ),
                    confirm: true,
                    confirmTitle: 'clear_local_cache_title'.tr,
                    confirmMessage:
                    '${'clear_local_layer_message'.tr}${service.cacheDisplayName}".',
                    confirmLabel: 'clear_local'.tr,
                  ),
                ),
              _serviceActionButton(
                label: 'clear_all'.tr,
                filled: true,
                onPressed: () => _run(
                      () => service.clearAllCache(
                    clearVisibleState: true,
                  ),
                  confirm: true,
                  confirmTitle: 'clear_all_layer_title'.tr,
                  confirmMessage: 
                  'clear_all_layer_message'.tr + service.cacheDisplayName + 'if_service_supports_it'.tr,
                  confirmLabel: 'clear_all'.tr,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _summaryChip(
            'layers'.tr,
            '${_services.length}',
            icon: Icons.layers_rounded,
          ),
          _summaryChip(
            'ram_entries'.tr,
            '$_totalMemoryEntries',
            icon: Icons.memory_rounded,
          ),
          _summaryChip(
            'local_entries'.tr,
            '$_totalPersistentEntries',
            icon: Icons.storage_rounded,
          ),
          _summaryChip(
            'ram_size'.tr,
            formatApproxBytes(_totalMemoryBytes),
            icon: Icons.memory_outlined,
          ),
          _summaryChip(
            'local_size'.tr,
            formatApproxBytes(_totalPersistentBytes),
            icon: Icons.sd_storage_rounded,
          ),
          _summaryChip(
            'total_size'.tr,
            formatApproxBytes(_totalBytes),
            icon: Icons.data_object_rounded,
          ),
          if (_totalHitRate != null)
            _summaryChip(
              'hit_rate'.tr,
              formatPercent(_totalHitRate!),
              icon: Icons.speed_rounded,
            ),
          _summaryChip(
            'hits'.tr,
            '$_totalHits',
            icon: Icons.check_circle_outline_rounded,
          ),
          _summaryChip(
            'misses'.tr,
            '$_totalMisses',
            icon: Icons.error_outline_rounded,
          ),
          _summaryChip(
            'api_fetches'.tr,
            '$_totalNetworkFetches',
            icon: Icons.cloud_download_outlined,
          ),
          if (_lastWarmupAt != null)
            _summaryChip(
              'last_warmup'.tr,
              formatDateTimeShort(_lastWarmupAt!),
              icon: Icons.schedule_rounded,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedServices = [..._services]
      ..sort((a, b) {
        final aSummary = _summaries[a.cacheDisplayName];
        final bSummary = _summaries[b.cacheDisplayName];

        final aBytes = aSummary?.approxBytes ?? 0;
        final bBytes = bSummary?.approxBytes ?? 0;
        return bBytes.compareTo(aBytes);
      });

    return Stack(
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxHeight: 760,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'map_cache_manager'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'refresh_stats'.tr,
                    onPressed: _busy ? null : _reload,
                    icon: Icon(Icons.refresh, color: theme.textColor),
                  ),
                  IconButton(
                    tooltip: 'close'.tr,
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.close, color: theme.textColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!_loading) _buildTopSummary(),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.textColor,
                      side: BorderSide(color: theme.textColor.withAlpha(60)),
                    ),
                    onPressed: _busy ? null : _clearAllMemory,
                    icon: Icon(Icons.memory_rounded, color: theme.textColor),
                    label: Text('clear_all_ram'.tr),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.textColor,
                      side: BorderSide(color: theme.textColor.withAlpha(60)),
                    ),
                    onPressed: _busy ? null : _clearAllPersistent,
                    icon: Icon(Icons.storage_rounded, color: theme.textColor),
                    label: Text('clear_all_local'.tr),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.themeColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _busy ? null : _clearAll,
                    icon: const Icon(Icons.delete_sweep_rounded),
                    label: Text('clear_everything'.tr),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _services.isEmpty
                    ? Center(
                  child: Text(
                    'no_cache_services'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                )
                    : Scrollbar(
                  thumbVisibility: true,
                  child: ListView(
                    children: sortedServices.map(_serviceCard).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_busy)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(90),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'working_on_cache'.tr,
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}