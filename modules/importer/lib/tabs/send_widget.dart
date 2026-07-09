// lib/importer/tabs/import_tab_upload.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

import '../import_state.dart';


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


/// Overlay z postępem batch importu i zarządzaniem błędami
class BatchImportOverlay extends ConsumerStatefulWidget {
  const BatchImportOverlay({super.key});

  @override
  ConsumerState<BatchImportOverlay> createState() =>
      _BatchImportOverlayState();
}

class _BatchImportOverlayState extends ConsumerState<BatchImportOverlay> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // uruchamiamy batch import tylko raz, po wejściu w overlay
    if (!_started) {
      _started = true;
      Future.microtask(() async {
        await ref.read(importFormProvider.notifier).submitBatch(ref);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(importFormProvider);
    final notifier = ref.read(importFormProvider.notifier);

    final isRunning = state.isBatchRunning;
    final progress = state.batchProgress.clamp(0.0, 1.0);
    final statusText =
        state.batchStatusText ?? (isRunning ? 'Wysyłanie danych...' : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // HEADER
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              Text(
                'Batch import – postęp i błędy'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: isRunning
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // BODY
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isRunning
                ? _buildProgressView(theme, progress, statusText)
                : _buildResultsView(context, theme, state, notifier),
          ),
        ),

        // FOOTER – przycisk zamknięcia
        Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isRunning
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            child: Text(
              'Zamknij'.tr,
              style: TextStyle(color: theme.themeColor),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildProgressView(
    ThemeColors theme,
    double progress,
    String statusText,
  ) {
    final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);

    // Liczniki z batchResults
    int totalRows = ref
        .read(importFormProvider)
        .previewData
        .length; // fallback: liczba wierszy w pliku
    int okRows = 0;
    int errorRows = 0;

    final state = ref.read(importFormProvider);
    for (final r in state.batchResults) {
      totalRows = totalRows == 0 ? r.totalRows : totalRows;
      okRows += r.successfulRows;
      errorRows += r.failedRows;
    }

    // Spłaszczamy błędy do jednej listy
    final List<_ErrorViewRow> errorList = [];
    for (final r in state.batchResults) {
      for (final e in r.errors) {
        errorList.add(
          _ErrorViewRow(
            model: r.targetModel,
            row: e.row,
            message: e.error,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Center(
          child: LinearProgressIndicator(
            backgroundColor: theme.themeColor,
            color: theme.themeColor,
            value: progress > 0 && progress < 1 ? progress : null,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            '$statusText ($percent%)',
            style: TextStyle(
              color: theme.textColor,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Operacje OK: $okRows • błędy: $errorRows',
            style: TextStyle(
              color: theme.textColor.withAlpha(230),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'W trakcie importu możesz od razu reagować na błędy. Nowe błędy będą pojawiały się na liście poniżej.'
              .tr,
          style: TextStyle(
            color: theme.textColor.withAlpha(178),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: errorList.isEmpty
              ? Center(
                  child: Text(
                    'Na razie brak błędów – import w toku...'.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(178),
                      fontSize: 12,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: errorList.length,
                  itemBuilder: (ctx, idx) {
                    final e = errorList[idx];
                    final zeroBasedIndex = e.row - 1;

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 0,
                      ),
                      title: Text(
                        '${e.model} • wiersz ${e.row}: ${e.message}',
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 12,
                        ),
                      ),
                      subtitle: Text(
                        'Index w podglądzie: $zeroBasedIndex'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(153),
                          fontSize: 10,
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: () {
                          // TODO: tu możesz:
                          //  - zapisać focusedRowIndex w stanie
                          //  - przełączyć tab na "Edytor pliku"
                          //  - scrollować do tego wiersza
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Odszukaj ten wiersz w edytorze po numerze: ${e.row}'
                                    .tr,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Ogarniam'.tr,
                          style: TextStyle(
                            color: theme.themeColor,
                            fontSize: 11,
                          ),
                        ),
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
      return Center(
        child: Text(
          'Brak wyników batch importu.'.tr,
          style: TextStyle(
            color: theme.textColor.withAlpha(204),
          ),
        ),
      );
    }

    final anyErrors = state.batchResults.any((r) => r.failedRows > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (anyErrors)
          Text(
            'Import zakończony. Część wierszy zawiera błędy – możesz nimi zarządzać poniżej.'
                .tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 13,
            ),
          )
        else
          Text(
            'Import zakończony. Wszystkie wiersze zostały poprawnie zapisane.'
                .tr,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 13,
            ),
          ),
        const SizedBox(height: 12),

        // Lista wyników per model
        Expanded(
          child: ListView.builder(
            itemCount: state.batchResults.length,
            itemBuilder: (ctx, idx) {
              final result = state.batchResults[idx];
              final hasErrors = result.failedRows > 0;

              return Card(
                color: theme.dashboardContainer.withAlpha(247),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: hasErrors
                        ? Colors.redAccent.withAlpha(128)
                        : theme.dashboardBoarder.withAlpha(128),
                  ),
                ),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  childrenPadding:
                      const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                  title: Text(
                    '${result.targetModel}: OK ${result.successfulRows}/${result.totalRows}, błędy: ${result.failedRows}',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: hasErrors
                      ? Text(
                          'Kliknij, aby zobaczyć błędne wiersze. Po poprawkach możesz wysłać je ponownie.'
                              .tr,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(178),
                            fontSize: 11,
                          ),
                        )
                      : Text(
                          'Brak błędów dla tego modelu.'.tr,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(178),
                            fontSize: 11,
                          ),
                        ),
                  trailing: hasErrors
                      ? TextButton.icon(
                          onPressed: state.isSubmitting
                              ? null
                              : () async {
                                  await notifier.resendFailedForModel(
                                      ref, result.targetModel);
                                },
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            'Wyślij ponownie błędne'.tr,
                            style: TextStyle(
                              color: theme.themeColor,
                              fontSize: 11,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  children: [
                    if (result.errors.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
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
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 0,
                            ),
                            title: Text(
                              'Wiersz ${err.row}: ${err.error}',
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Text(
                              'Index w podglądzie: $zeroBasedIndex'.tr,
                              style: TextStyle(
                                color: theme.textColor.withAlpha(153),
                                fontSize: 10,
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: () {
                                // TODO: możesz tutaj:
                                //  - zapisać "focusedRowIndex" w stanie
                                //  - przełączyć tab na "Edytor pliku"
                                //  - scrollować do tego wiersza
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Odszukaj ten wiersz w edytorze po numerze: ${err.row}'
                                          .tr,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Pokaż w edytorze'.tr,
                                style: TextStyle(
                                  color: theme.themeColor,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
