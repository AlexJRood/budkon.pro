
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:mail/components/scheduled_emails_with_preview.dart';
import 'package:mail/models/mail_scheduled_models.dart';
import 'package:mail/utils/api_services.dart';
import 'package:mail/utils/mail_filters.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

class ScheduledEmailsWithPreviewMobile extends ConsumerStatefulWidget {
  final bool isMobile;
  const ScheduledEmailsWithPreviewMobile({super.key, this.isMobile = true});

  @override
  ConsumerState<ScheduledEmailsWithPreviewMobile> createState() =>
      _ScheduledEmailsWithPreviewMobileState();
}

class _ScheduledEmailsWithPreviewMobileState
    extends ConsumerState<ScheduledEmailsWithPreviewMobile> {
  int? _selectedScheduledId;

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    final pendingAsync = ref.watch(scheduledPendingEmailsProvider);
    final sentAsync = ref.watch(scheduledSentEmailsProvider);

    final pendingPage = ref.watch(scheduledPendingPageProvider);
    final sentPage = ref.watch(scheduledSentPageProvider);

    final pendingCount = pendingAsync.maybeWhen(
      data: (d) => d.count,
      orElse: () => 0,
    );

    final sentCount = sentAsync.maybeWhen(
      data: (d) => d.count,
      orElse: () => 0,
    );

    Widget sectionHeader({
      required String title,
      required bool isSent,
      required int page,
      required int count,
      required VoidCallback onSync,
    }) {
      final pageSize = ref.watch(mailPageSizeProvider);
      final maxPage = count <= 0 ? 1 : ((count + pageSize - 1) ~/ pageSize);

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Sync'.tr,
              icon: Icon(Icons.refresh, color: theme.textColor),
              onPressed: onSync,
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.chevron_left, color: theme.textColor),
              onPressed: page <= 1
                  ? null
                  : () {
                if (isSent) {
                  ref.read(scheduledSentPageProvider.notifier).state =
                      page - 1;
                  ref.invalidate(scheduledSentEmailsProvider);
                } else {
                  ref.read(scheduledPendingPageProvider.notifier).state =
                      page - 1;
                  ref.invalidate(scheduledPendingEmailsProvider);
                }
              },
            ),
            Text(
              '$page/$maxPage',
              style: TextStyle(
                color: theme.textColor.withAlpha(180),
                fontSize: 12,
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: theme.textColor),
              onPressed: page >= maxPage
                  ? null
                  : () {
                if (isSent) {
                  ref.read(scheduledSentPageProvider.notifier).state =
                      page + 1;
                  ref.invalidate(scheduledSentEmailsProvider);
                } else {
                  ref.read(scheduledPendingPageProvider.notifier).state =
                      page + 1;
                  ref.invalidate(scheduledPendingEmailsProvider);
                }
              },
            ),
          ],
        ),
      );
    }

    String formatDate(String? raw) {
      if (raw == null || raw.isEmpty) return '';
      final looksIso = RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(raw);
      if (!looksIso) return raw;

      final parsed = DateTime.tryParse(raw);
      if (parsed == null) return raw;

      final local = parsed.toLocal();

      return '${local.day.toString().padLeft(2, '0')}.'
          '${local.month.toString().padLeft(2, '0')}.'
          '${local.year} '
          '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
    }

    void openPreview(int id) {
      _selectedScheduledId = id;

      final sheetCtrl = DraggableScrollableController();

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
            controller: sheetCtrl,
            initialChildSize: 0.85,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, sc) {
              return ScheduledEmailDetailById(
                id: id,
                isMobile: true,
                onDeleted: () {
                  // ✅ close sheet and clear selection after delete
                  Navigator.pop(context);
                  setState(() => _selectedScheduledId = null);
                },
              );
            },
          );
        },
      );
    }

    Widget tile(ScheduledEmail e) {
      final bool isSelected = _selectedScheduledId == e.id;
      final toPreview = e.to.isNotEmpty ? e.to.first : '';

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: SizedBox(
          width: double.infinity,
          child: TextButton(
            style: ButtonStyle(
              alignment: Alignment.centerLeft,
              backgroundColor: WidgetStateProperty.all(
                isSelected ? theme.adPopBackground : Colors.transparent,
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            onPressed: () {
              setState(() => _selectedScheduledId = e.id);
              openPreview(e.id);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.subject.isEmpty ? 'no_subject'.tr : e.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    toPreview.isEmpty
                        ? formatDate(e.sendAt)
                        : '$toPreview • ${formatDate(e.sendAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(150),
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget listFromAsync(AsyncValue<PaginatedScheduledEmailResponse> asyncVal) {
      return asyncVal.when(
        data: (data) {
          if (data.results.isEmpty) {
            return Center(child: AppLottie.noResults());
          }
          final items = List.of(data.results.reversed);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items.map(tile).toList(),
          );
        },
        loading: () => Center(child: AppLottie.loading()),
        error: (e, _) => Center(
          child: Column(
            children: [AppLottie.loading(), Text(e.toString())],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          border: Border.all(color: theme.dashboardBoarder, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: theme.textColor,
                  unselectedLabelColor: theme.textColor.withAlpha(140),
                  indicator: BoxDecoration(
                    color: theme.adPopBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tabs: [
                    Tab(text: 'Pending'.tr),
                    Tab(text: 'Sent'.tr),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    Column(
                      children: [
                        sectionHeader(
                          title: 'Pending'.tr,
                          isSent: false,
                          page: pendingPage,
                          count: pendingCount,
                          onSync: () {
                            ref.invalidate(scheduledPendingEmailsProvider);
                            if (_selectedScheduledId != null) {
                              ref.invalidate(
                                scheduledEmailDetailsProvider(
                                  _selectedScheduledId!,
                                ),
                              );
                            }
                          },
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: listFromAsync(pendingAsync),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                    Column(
                      children: [
                        sectionHeader(
                          title: 'Sent'.tr,
                          isSent: true,
                          page: sentPage,
                          count: sentCount,
                          onSync: () {
                            ref.invalidate(scheduledSentEmailsProvider);
                            if (_selectedScheduledId != null) {
                              ref.invalidate(
                                scheduledEmailDetailsProvider(
                                  _selectedScheduledId!,
                                ),
                              );
                            }
                          },
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: listFromAsync(sentAsync),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}