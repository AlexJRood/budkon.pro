import 'dart:async';

import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';

import '../import_state.dart';

// ignore: unused_import
import 'package:importer/emma/anchors/anchors_importer.dart';

class ImportTabJobs extends ConsumerStatefulWidget {
  final AsyncValue<List<ImportJobSummary>> jobsAsync;

  const ImportTabJobs({
    super.key,
    required this.jobsAsync,
  });

  @override
  ConsumerState<ImportTabJobs> createState() => _ImportTabJobsState();
}

class _ImportTabJobsState extends ConsumerState<ImportTabJobs> {
  Timer? _autoRefreshTimer;

  @override
  void didUpdateWidget(covariant ImportTabJobs oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _syncAutoRefresh() {
    final jobs = widget.jobsAsync.valueOrNull ?? [];
    final hasProcessing =
        jobs.any((j) => j.status.toLowerCase() == 'processing' ||
            j.status.toLowerCase() == 'pending');

    if (hasProcessing && _autoRefreshTimer == null) {
      _autoRefreshTimer =
          Timer.periodic(const Duration(seconds: 10), (_) => _refreshJobs());
    } else if (!hasProcessing && _autoRefreshTimer != null) {
      _autoRefreshTimer?.cancel();
      _autoRefreshTimer = null;
    }
  }

  Future<void> _refreshJobs() async {
    ref.invalidate(importJobsProvider);
    await ref.read(importJobsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    _syncAutoRefresh();

    return EmmaUiAnchorTarget(
      // @emma-backend: ImporterEmmaAnchors.importJobsRoot
      anchorKey: 'importer.jobs.root',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 0,
          color: theme.dashboardContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: theme.dashboardBoarder.withAlpha(145)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: widget.jobsAsync.when(
              data: (jobs) {
                final total = jobs.length;
                final completed = jobs
                    .where((j) => j.status.toLowerCase() == 'completed')
                    .length;
                final failed = jobs
                    .where(
                      (j) =>
                          j.failedRows > 0 ||
                          j.status.toLowerCase() == 'failed',
                    )
                    .length;
                final processing = jobs
                    .where((j) => j.status.toLowerCase() == 'processing')
                    .length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EmmaUiAnchorTarget(
                      // @emma-backend: ImporterEmmaAnchors.importJobsHeader
                      anchorKey: 'importer.jobs.header',
                      child: Row(
                        children: [
                          Text(
                            'Ostatnie importy'.tr,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: theme.textColor,
                            ),
                          ),
                          const Spacer(),
                          EmmaUiAnchorTarget(
                            // @emma-backend: ImporterEmmaAnchors.importJobsRefreshButton
                            anchorKey: 'importer.jobs.refresh_button',
                            child: IconButton(
                              tooltip: 'Odśwież'.tr,
                              onPressed: _refreshJobs,
                              icon: Icon(
                                Icons.refresh_rounded,
                                color: theme.themeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EmmaUiAnchorTarget(
                      // @emma-backend: ImporterEmmaAnchors.importJobsStats
                      anchorKey: 'importer.jobs.stats',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _JobsStatChip(
                            anchorKey: 'importer.jobs.stats.total',
                            theme: theme,
                            icon: Icons.inventory_2_outlined,
                            label: 'Wszystkie'.tr,
                            value: '$total',
                          ),
                          _JobsStatChip(
                            anchorKey: 'importer.jobs.stats.completed',
                            theme: theme,
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Zakończone'.tr,
                            value: '$completed',
                            accentColor: Colors.greenAccent,
                          ),
                          _JobsStatChip(
                            anchorKey: 'importer.jobs.stats.processing',
                            theme: theme,
                            icon: Icons.sync_rounded,
                            label: 'W toku'.tr,
                            value: '$processing',
                            accentColor: Colors.orangeAccent,
                          ),
                          _JobsStatChip(
                            anchorKey: 'importer.jobs.stats.failed',
                            theme: theme,
                            icon: Icons.error_outline_rounded,
                            label: 'Z błędami'.tr,
                            value: '$failed',
                            accentColor: Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: jobs.isEmpty
                          ? EmmaUiAnchorTarget(
                              // @emma-backend: ImporterEmmaAnchors.importJobsEmptyState
                              anchorKey: 'importer.jobs.empty_state',
                              child: _EmptyJobsState(theme: theme),
                            )
                          : EmmaUiAnchorTarget(
                              // @emma-backend: ImporterEmmaAnchors.importJobsList
                              anchorKey: 'importer.jobs.list',
                              child: RefreshIndicator(
                                onRefresh: _refreshJobs,
                                child: ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: jobs.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final job = jobs[index];

                                    return _JobCard(
                                      theme: theme,
                                      job: job,
                                    );
                                  },
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              },
              loading: () => EmmaUiAnchorTarget(
                // @emma-backend: ImporterEmmaAnchors.importJobsLoading
                anchorKey: 'importer.jobs.loading',
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => EmmaUiAnchorTarget(
                // @emma-backend: ImporterEmmaAnchors.importJobsError
                anchorKey: 'importer.jobs.error',
                child: Center(
                  child: Text(
                    'Błąd pobierania zadań: $err'.tr,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JobCard extends ConsumerStatefulWidget {
  final ThemeColors theme;
  final ImportJobSummary job;

  const _JobCard({
    required this.theme,
    required this.job,
  });

  @override
  ConsumerState<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends ConsumerState<_JobCard> {
  bool _loadingDetails = false;
  List<RowImportError> _details = [];
  bool _detailsFetched = false;

  Future<void> _fetchDetails() async {
    if (_detailsFetched || _loadingDetails) return;
    setState(() => _loadingDetails = true);
    try {
      final res = await ApiServices.get(
        ImportApiUrls.jobStatus(widget.job.id),
        hasToken: true,
        ref: ref,
      );
      if (res == null) return;
      final body = res.data;
      if (body is Map) {
        final errorsRaw = body['errors'];
        if (errorsRaw is List) {
          setState(() {
            _details = errorsRaw
                .whereType<Map>()
                .map((e) =>
                    RowImportError.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _loadingDetails = false;
          _detailsFetched = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final job = widget.job;
    final status = job.status.toLowerCase();
    final progress = (job.progress / 100).clamp(0.0, 1.0).toDouble();

    final bool isCompleted = status == 'completed';
    final bool isFailed = status == 'failed' || job.failedRows > 0;
    final bool isRunning = status == 'processing' || status == 'pending';

    final Color accent = isFailed
        ? Colors.redAccent
        : isRunning
            ? Colors.orangeAccent
            : Colors.greenAccent;

    return EmmaUiAnchorTarget(
      anchorKey: 'importer.jobs.card.${job.id}',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dashboardBoarder.withAlpha(130)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            childrenPadding:
                const EdgeInsets.only(left: 14, right: 14, bottom: 14),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            onExpansionChanged: (open) {
              if (open && !_detailsFetched && isFailed) {
                _fetchDetails();
              }
            },
            title: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent.withAlpha(18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isFailed
                            ? Icons.error_outline_rounded
                            : isRunning
                                ? Icons.sync_rounded
                                : Icons.check_circle_outline_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          if (job.createdAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2, bottom: 2),
                              child: Text(
                                _formatDate(job.createdAt!),
                                style: TextStyle(
                                  color: theme.textColor.withAlpha(130),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              _StatusBadge(
                                theme: theme,
                                label: _humanStatus(job.status),
                                color: accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${job.successfulRows}/${job.totalRows} OK • błędy: ${job.failedRows}'
                                      .tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.textColor.withAlpha(176),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${job.progress}%',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: theme.textColor.withAlpha(30),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MiniInfo(
                      theme: theme,
                      label: 'Wszystkie'.tr,
                      value: '${job.totalRows}',
                    ),
                    const SizedBox(width: 10),
                    _MiniInfo(
                      theme: theme,
                      label: 'Poprawne'.tr,
                      value: '${job.successfulRows}',
                    ),
                    const SizedBox(width: 10),
                    _MiniInfo(
                      theme: theme,
                      label: 'Błędy'.tr,
                      value: '${job.failedRows}',
                      danger: job.failedRows > 0,
                    ),
                    const Spacer(),
                    if (isCompleted || isFailed)
                      Text(
                        isFailed ? 'Wymaga sprawdzenia'.tr : 'Gotowe'.tr,
                        style: TextStyle(
                          color: isFailed
                              ? Colors.redAccent
                              : Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            children: [
              if (isFailed) ...[
                const Divider(height: 1),
                const SizedBox(height: 10),
                if (_loadingDetails)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.themeColor,
                        ),
                      ),
                    ),
                  )
                else if (_details.isEmpty)
                  Text(
                    _detailsFetched
                        ? 'Brak szczegółów błędów z serwera.'.tr
                        : 'Rozwiń, żeby pobrać szczegóły błędów.'.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(160),
                      fontSize: 12,
                    ),
                  )
                else
                  Column(
                    children: _details.map((err) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withAlpha(10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.redAccent.withAlpha(60),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${'Wiersz'.tr} ${err.row}',
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                err.error,
                                style: TextStyle(
                                  color: theme.textColor.withAlpha(200),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _humanStatus(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return 'Oczekuje'.tr;
      case 'processing':
        return 'Przetwarzanie'.tr;
      case 'completed':
        return 'Zakończony'.tr;
      case 'failed':
        return 'Błąd'.tr;
      case 'cancelled':
        return 'Anulowany'.tr;
      default:
        return value.tr;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'przed chwilą'.tr;
    if (diff.inHours < 1) return 'przed ${diff.inMinutes} min'.tr;
    if (diff.inDays < 1) {
      return 'dziś ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) {
      return 'wczoraj ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final Color color;

  const _StatusBadge({
    required this.theme,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final String value;
  final bool danger;

  const _MiniInfo({
    required this.theme,
    required this.label,
    required this.value,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textColor.withAlpha(150),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: danger ? Colors.redAccent : theme.textColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _JobsStatChip extends StatelessWidget {
  final String anchorKey;
  final ThemeColors theme;
  final IconData icon;
  final String label;
  final String value;
  final Color? accentColor;

  const _JobsStatChip({
    required this.anchorKey,
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? theme.themeColor;

    return EmmaUiAnchorTarget(
      anchorKey: anchorKey,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: accent.withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withAlpha(75)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 8),
            Text(
              '$label: $value',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyJobsState extends StatelessWidget {
  final ThemeColors theme;

  const _EmptyJobsState({
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 30,
              color: theme.themeColor,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Brak zadań importu'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Po uruchomieniu pierwszego importu zobaczysz tutaj historię i statusy.'
                  .tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}