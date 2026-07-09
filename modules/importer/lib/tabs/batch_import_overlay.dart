import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

import '../import_state.dart';

Future<BatchImportOverlayResult?> showBatchImportOverlay(BuildContext context) {
  return showModalBottomSheet<BatchImportOverlayResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.92,
      child: BatchImportOverlay(),
    ),
  );
}

enum BatchImportOverlayAction {
  showRowInEditor,
}

class BatchImportOverlayResult {
  final BatchImportOverlayAction action;
  final int previewRowIndex;

  const BatchImportOverlayResult({
    required this.action,
    required this.previewRowIndex,
  });
}

class _ErrorViewRow {
  final String model;
  final int row;
  final String message;

  _ErrorViewRow({
    required this.model,
    required this.row,
    required this.message,
  });
}

class BatchImportOverlay extends ConsumerStatefulWidget {
  const BatchImportOverlay({super.key});

  @override
  ConsumerState<BatchImportOverlay> createState() => _BatchImportOverlayState();
}

class _BatchImportOverlayState extends ConsumerState<BatchImportOverlay> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_started) {
      _started = true;

      Future.microtask(() async {
        final state = ref.read(importFormProvider);

        if (!state.isBatchRunning && state.batchResults.isEmpty) {
          await ref.read(importFormProvider.notifier).submitBatch(ref);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(importFormProvider);
    final notifier = ref.read(importFormProvider.notifier);

    final isRunning = state.isBatchRunning;
    final isBusy = state.isBatchRunning || state.isSubmitting;
    final progress = state.batchProgress.clamp(0.0, 1.0);
    final statusText =
        state.batchStatusText ?? (isRunning ? 'Wysyłanie danych...'.tr : '');

    return PopScope(
      canPop: !isRunning,
      child: Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OverlayHeader(
            theme: theme,
            isRunning: isRunning,
            onClose: isRunning ? null : () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isRunning
                  ? _buildProgressView(theme, progress, statusText, state)
                  : _buildResultsView(context, theme, state, notifier),
            ),
          ),
          _OverlayBottomActions(
            widgetRef: ref,
            theme: theme,
            state: state,
            notifier: notifier,
            isBusy: isBusy,
            onClose: isRunning ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildProgressView(
    ThemeColors theme,
    double progress,
    String statusText,
    ImportFormState state,
  ) {
    final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);

    int totalRows = state.selectedRowIndexes.isNotEmpty
        ? state.selectedRowIndexes.length
        : state.previewData.length;

    int okRows = 0;
    int errorRows = 0;

    for (final r in state.batchResults) {
      okRows += r.successfulRows;
      errorRows += r.failedRows;
    }

    final errorList = _buildErrorList(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OverlaySummaryRow(
          theme: theme,
          totalRows: totalRows,
          okRows: okRows,
          errorRows: errorRows,
          progress: progress,
          progressPercent: percent,
          statusText: statusText,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: errorList.isEmpty
              ? _EmptyInlineState(
                  theme: theme,
                  icon: Icons.hourglass_top_rounded,
                  title: 'Import trwa'.tr,
                  description: 'Na razie brak błędów — dane są wysyłane.'
                      .tr,
                )
              : ListView.separated(
                  itemCount: errorList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final e = errorList[idx];
                    final zeroBasedIndex = e.row - 1;

                    return _ErrorCard(
                      theme: theme,
                      title: '${e.model} • ${'wiersz'.tr} ${e.row}',
                      subtitle: e.message,
                      footer: '${'Wiersz w pliku'.tr}: ${zeroBasedIndex + 1}',
                      actionLabel: 'Pokaż w edytorze'.tr,
                      onPressed: () => _returnShowRowAction(
                        context,
                        previewRowIndex: zeroBasedIndex,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildResultsView(
    BuildContext context,
    ThemeColors theme,
    ImportFormState state,
    ImportFormNotifier notifier,
  ) {
    if (state.batchResults.isEmpty) {
      return _EmptyInlineState(
        theme: theme,
        icon: Icons.inventory_2_outlined,
        title: 'Brak wyników importu'.tr,
        description: 'Uruchom import, aby zobaczyć tutaj podsumowanie.'.tr,
      );
    }

    final anyErrors = state.batchResults.any((r) => r.failedRows > 0);
    final totalRows = state.batchResults.fold<int>(
      0,
      (sum, item) => sum + item.totalRows,
    );
    final okRows = state.batchResults.fold<int>(
      0,
      (sum, item) => sum + item.successfulRows,
    );
    final failedRows = state.batchResults.fold<int>(
      0,
      (sum, item) => sum + item.failedRows,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OverlayResultSummary(
          theme: theme,
          totalRows: totalRows,
          okRows: okRows,
          failedRows: failedRows,
          anyErrors: anyErrors,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: state.batchResults.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final result = state.batchResults[idx];
              final hasErrors = result.failedRows > 0;

              return _ResultCard(
                theme: theme,
                result: result,
                hasErrors: hasErrors,
                isBusy: state.isSubmitting || state.isBatchRunning,
                onResendFailed: hasErrors
                    ? () async {
                        await notifier.resendFailedForModel(
                          ref,
                          result.targetModel,
                        );
                      }
                    : null,
                onShowRow: (previewRowIndex) => _returnShowRowAction(
                  context,
                  previewRowIndex: previewRowIndex,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _returnShowRowAction(
    BuildContext context, {
    required int previewRowIndex,
  }) {
    Navigator.of(context).pop(
      BatchImportOverlayResult(
        action: BatchImportOverlayAction.showRowInEditor,
        previewRowIndex: previewRowIndex,
      ),
    );
  }

  List<_ErrorViewRow> _buildErrorList(ImportFormState state) {
    final errorList = <_ErrorViewRow>[];

    for (final r in state.batchResults) {
      for (final e in r.errors) {
        errorList.add(
          _ErrorViewRow(
            model: r.targetModel,
            row: e.row,
            message: _humanizeError(e.error),
          ),
        );
      }
    }

    return errorList;
  }

  static String _toCsvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static Future<void> _downloadFailedRowsCsv(ImportFormState state) async {
    final cols = state.previewColumns;
    final data = state.previewData;

    final failedIdxToMsg = <int, String>{};
    for (final result in state.batchResults) {
      for (final err in result.errors) {
        final idx = err.row - 1;
        if (idx >= 0 && idx < data.length) {
          failedIdxToMsg[idx] = err.error;
        }
      }
    }

    if (failedIdxToMsg.isEmpty) return;

    final headers = [...cols, 'Błąd importu'];
    final lines = <String>[headers.map(_toCsvCell).join(',')];

    for (final idx in failedIdxToMsg.keys.toList()..sort()) {
      final row = data[idx];
      final cells = [
        ...List.generate(cols.length, (i) => i < row.length ? row[i] : ''),
        failedIdxToMsg[idx] ?? '',
      ].map(_toCsvCell).join(',');
      lines.add(cells);
    }

    final csv = lines.join('\r\n');
    final bytes = Uint8List.fromList(utf8.encode(csv));

    await FileSaver.instance.saveAs(
      name: 'import_errors',
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.other,
    );
  }

  static String _humanizeError(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final val = entry.value;
            if (val is List && val.isNotEmpty) {
              return '${entry.key}: ${val.first}';
            }
            if (val is String && val.isNotEmpty) {
              return '${entry.key}: $val';
            }
          }
        }
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.first.toString();
        }
      } catch (_) {}
    }
    if (trimmed.length > 140) return '${trimmed.substring(0, 137)}...';
    return trimmed;
  }
}

class _OverlayHeader extends StatelessWidget {
  final ThemeColors theme;
  final bool isRunning;
  final VoidCallback? onClose;

  const _OverlayHeader({
    required this.theme,
    required this.isRunning,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          bottom: BorderSide(
            color: theme.dashboardBoarder.withAlpha(120),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isRunning ? Icons.sync_rounded : Icons.fact_check_outlined,
              color: theme.themeColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batch import'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isRunning
                      ? 'Import trwa — możesz śledzić postęp i błędy.'.tr
                      : 'Import zakończony — tutaj sprawdzisz wynik i problemy.'
                          .tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(170),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _IconActionButton(
            theme: theme,
            icon: Icons.close_rounded,
            tooltip: 'Zamknij'.tr,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}



class _OverlayBottomActions extends StatelessWidget {
  final ThemeColors theme;
  final ImportFormState state;
  final ImportFormNotifier notifier;
  final WidgetRef widgetRef;
  final bool isBusy;
  final VoidCallback? onClose;

  const _OverlayBottomActions({
    required this.theme,
    required this.state,
    required this.notifier,
    required this.widgetRef,
    required this.isBusy,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final hasResults = state.batchResults.isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          border: Border(
            top: BorderSide(
              color: theme.dashboardBoarder.withAlpha(120),
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;

            Future<void> handleRerun() async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Uruchomić import ponownie?'.tr),
                  content: Text(
                    'Spowoduje to ponowne wysłanie wszystkich zaznaczonych wierszy. Poprzednie wyniki zostaną nadpisane.'
                        .tr,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text('Anuluj'.tr),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text('Uruchom ponownie'.tr),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await notifier.submitBatch(widgetRef);
              }
            }

            final hasFailed = state.batchResults.any((r) => r.failedRows > 0);

            Future<void> handleRetryFailed() async {
              await notifier.retryFailedRows(widgetRef);
            }

            Future<void> handleDownloadErrors() async {
              await _BatchImportOverlayState._downloadFailedRowsCsv(state);
            }

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasResults) ...[
                    if (hasFailed) ...[
                      _SecondaryActionButton(
                        theme: theme,
                        icon: Icons.download_rounded,
                        label: 'Pobierz błędne'.tr,
                        onPressed: isBusy ? null : handleDownloadErrors,
                      ),
                      const SizedBox(height: 8),
                      _SecondaryActionButton(
                        theme: theme,
                        icon: Icons.redo_rounded,
                        label: 'Ponów błędne'.tr,
                        onPressed: isBusy ? null : handleRetryFailed,
                      ),
                      const SizedBox(height: 8),
                    ],
                    _SecondaryActionButton(
                      theme: theme,
                      icon: Icons.refresh_rounded,
                      label: 'Uruchom ponownie'.tr,
                      onPressed: isBusy ? null : handleRerun,
                    ),
                    const SizedBox(height: 8),
                  ],
                  _PrimaryActionButton(
                    theme: theme,
                    icon: Icons.close_rounded,
                    label: 'Zamknij'.tr,
                    onPressed: onClose,
                  ),
                ],
              );
            }

            return Row(
              children: [
                if (hasResults) ...[
                  if (hasFailed) ...[
                    _SecondaryActionButton(
                      theme: theme,
                      icon: Icons.download_rounded,
                      label: 'Pobierz błędne'.tr,
                      onPressed: isBusy ? null : handleDownloadErrors,
                    ),
                    const SizedBox(width: 8),
                    _SecondaryActionButton(
                      theme: theme,
                      icon: Icons.redo_rounded,
                      label: 'Ponów błędne'.tr,
                      onPressed: isBusy ? null : handleRetryFailed,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _SecondaryActionButton(
                    theme: theme,
                    icon: Icons.refresh_rounded,
                    label: 'Uruchom ponownie'.tr,
                    onPressed: isBusy ? null : handleRerun,
                  ),
                ],
                const Spacer(),
                _PrimaryActionButton(
                  theme: theme,
                  icon: Icons.close_rounded,
                  label: 'Zamknij'.tr,
                  onPressed: onClose,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ThemeColors theme;
  final BatchImportResult result;
  final bool hasErrors;
  final bool isBusy;
  final Future<void> Function()? onResendFailed;
  final ValueChanged<int> onShowRow;

  const _ResultCard({
    required this.theme,
    required this.result,
    required this.hasErrors,
    required this.isBusy,
    required this.onResendFailed,
    required this.onShowRow,
  });

  @override
  Widget build(BuildContext context) {
    final accent = hasErrors ? Colors.redAccent : Colors.greenAccent;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasErrors
              ? Colors.redAccent.withAlpha(120)
              : theme.dashboardBoarder.withAlpha(128),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: ExpansionTileThemeData(
            iconColor: theme.textColor,
            collapsedIconColor: theme.textColor.withAlpha(180),
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: hasErrors,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
          title: Row(
            children: [
              Icon(
                hasErrors
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${result.targetModel}: ${'OK'.tr} ${result.successfulRows}/${result.totalRows}, ${'błędy'.tr}: ${result.failedRows}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              hasErrors
                  ? 'Kliknij, aby zobaczyć problematyczne wiersze.'.tr
                  : 'Brak błędów dla tego modelu.'.tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontSize: 11,
              ),
            ),
          ),
          children: [
            if (hasErrors)
              Align(
                alignment: Alignment.centerRight,
                child: _DangerActionButton(
                  theme: theme,
                  icon: Icons.refresh_rounded,
                  label: 'Wyślij ponownie błędne'.tr,
                  onPressed: isBusy || onResendFailed == null
                      ? null
                      : () async => onResendFailed!(),
                ),
              ),
            if (hasErrors) const SizedBox(height: 10),
            if (result.errors.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Brak szczegółów błędów.'.tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(204),
                  ),
                ),
              )
            else
              Column(
                children: result.errors.map((err) {
                  final zeroBasedIndex = err.row - 1;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ErrorCard(
                      theme: theme,
                      title: '${'Wiersz'.tr} ${err.row}',
                      subtitle: _BatchImportOverlayState._humanizeError(err.error),
                      footer: '${'Wiersz w pliku'.tr}: ${err.row}',
                      actionLabel: 'Pokaż w edytorze'.tr,
                      onPressed: () => onShowRow(zeroBasedIndex),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _OverlaySummaryRow extends StatelessWidget {
  final ThemeColors theme;
  final int totalRows;
  final int okRows;
  final int errorRows;
  final double progress;
  final String progressPercent;
  final String statusText;

  const _OverlaySummaryRow({
    required this.theme,
    required this.totalRows,
    required this.okRows,
    required this.errorRows,
    required this.progress,
    required this.progressPercent,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$statusText ($progressPercent%)',
            style: TextStyle(
              color: theme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.textColor.withAlpha(24),
              color: theme.themeColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                theme: theme,
                icon: Icons.table_rows_rounded,
                label: 'Wiersze'.tr,
                value: '$totalRows',
              ),
              _SummaryChip(
                theme: theme,
                icon: Icons.check_circle_outline_rounded,
                label: 'OK'.tr,
                value: '$okRows',
                accentColor: Colors.greenAccent,
              ),
              _SummaryChip(
                theme: theme,
                icon: Icons.error_outline_rounded,
                label: 'Błędy'.tr,
                value: '$errorRows',
                accentColor: Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverlayResultSummary extends StatelessWidget {
  final ThemeColors theme;
  final int totalRows;
  final int okRows;
  final int failedRows;
  final bool anyErrors;

  const _OverlayResultSummary({
    required this.theme,
    required this.totalRows,
    required this.okRows,
    required this.failedRows,
    required this.anyErrors,
  });

  @override
  Widget build(BuildContext context) {
    final accent = anyErrors ? Colors.redAccent : Colors.greenAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withAlpha(70),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            anyErrors
                ? 'Import zakończony z błędami.'.tr
                : 'Import zakończony pomyślnie.'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                theme: theme,
                icon: Icons.table_rows_rounded,
                label: 'Wiersze'.tr,
                value: '$totalRows',
              ),
              _SummaryChip(
                theme: theme,
                icon: Icons.check_circle_outline_rounded,
                label: 'OK'.tr,
                value: '$okRows',
                accentColor: Colors.greenAccent,
              ),
              _SummaryChip(
                theme: theme,
                icon: Icons.error_outline_rounded,
                label: 'Błędy'.tr,
                value: '$failedRows',
                accentColor: Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String label;
  final String value;
  final Color? accentColor;

  const _SummaryChip({
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? theme.themeColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withAlpha(12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withAlpha(75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
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
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final String subtitle;
  final String footer;
  final String actionLabel;
  final VoidCallback onPressed;

  const _ErrorCard({
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.redAccent.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withAlpha(80)),
      ),
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 440;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContent(),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: _TinyActionButton(
                    theme: theme,
                    label: actionLabel,
                    onPressed: onPressed,
                  ),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildContent()),
              const SizedBox(width: 8),
              _TinyActionButton(
                theme: theme,
                label: actionLabel,
                onPressed: onPressed,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Colors.redAccent,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: theme.textColor.withAlpha(220),
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                footer,
                style: TextStyle(
                  color: theme.textColor.withAlpha(150),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _PrimaryActionButton({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.themeColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: theme.textColor.withAlpha(24),
        disabledForegroundColor: theme.textColor.withAlpha(90),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SecondaryActionButton({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.textColor,
        disabledForegroundColor: theme.textColor.withAlpha(90),
        side: BorderSide(
          color: onPressed == null
              ? theme.dashboardBoarder.withAlpha(80)
              : theme.dashboardBoarder.withAlpha(180),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _DangerActionButton extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _DangerActionButton({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: Colors.redAccent,
        disabledForegroundColor: theme.textColor.withAlpha(80),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TinyActionButton extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final VoidCallback onPressed;

  const _TinyActionButton({
    required this.theme,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: theme.themeColor,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _IconActionButton({
    required this.theme,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: theme.textColor,
      disabledColor: theme.textColor.withAlpha(75),
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withAlpha(8),
        disabledBackgroundColor: Colors.black.withAlpha(4),
      ),
    );
  }
}

class _EmptyInlineState extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String title;
  final String description;

  const _EmptyInlineState({
    required this.theme,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.dashboardBoarder.withAlpha(120),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: theme.themeColor,
              size: 34,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}