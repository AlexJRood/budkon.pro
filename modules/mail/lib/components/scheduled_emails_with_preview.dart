// scheduled_emails_with_preview.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:mail/components/email_meta_expandable.dart';
import 'package:mail/components/mail_detail.dart';
import 'package:mail/models/mail_scheduled_models.dart';
import 'package:mail/utils/utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';
import '../utils/mail_filters.dart';
import '../utils/api_services.dart';

class ScheduledEmailsWithPreview extends ConsumerStatefulWidget {
  final bool isMobile;
  const ScheduledEmailsWithPreview({super.key, this.isMobile = false});

  @override
  ConsumerState<ScheduledEmailsWithPreview> createState() =>
      _ScheduledEmailsWithPreviewState();
}

class _ScheduledEmailsWithPreviewState
    extends ConsumerState<ScheduledEmailsWithPreview> {
  int? selectedScheduledId;

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    final pendingAsync = ref.watch(scheduledPendingEmailsProvider);
    final sentAsync = ref.watch(scheduledSentEmailsProvider);

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
            SizedBox(width: 10,),
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
                  color: theme.textColor.withAlpha(180), fontSize: 12),
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

    Widget tile(ScheduledEmail e) {
      final isSelected = selectedScheduledId == e.id;
      final toPreview = e.to.isNotEmpty ? e.to.first : '';

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: SizedBox(
          width: double.infinity, // ✅ IMPORTANT: full width background
          child: TextButton(
            style: ButtonStyle(
              alignment: Alignment.centerLeft, // ✅ keeps content aligned left
              backgroundColor: WidgetStateProperty.all(
                isSelected ? theme.adPopBackground : Colors.transparent,
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            onPressed: () => setState(() => selectedScheduledId = e.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.subject.isEmpty ? '(no subject)'.tr : e.subject,
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
                    toPreview.isEmpty ? _formatDateTime(e.sendAt) : '$toPreview • ${_formatDateTime(e.sendAt)}',
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
            return Center(
              child: AppLottie.noResults(),
            );
          }
          final items = List.of(data.results.reversed);
          return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items.map(tile).toList());
        },
        loading: () => Center(
          child: AppLottie.loading(),
        ),
        error: (e, _) => Center(
          child: Column(
            children: [AppLottie.loading(), Text(e.toString())],
          ),
        ),
      );
    }

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

    return Row(
      children: [
        // LEFT
        Expanded(
          flex: 2,
          child: Padding(
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
                    // ✅ Tabs on top
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
                        tabs:  [
                          Tab(text: 'Pending'.tr),
                          Tab(text: 'Sent'.tr),
                        ],
                      ),
                    ),

                    // ✅ Tab content
                    Expanded(
                      child: TabBarView(
                        children: [
                          // ===== Pending TAB =====
                          Column(
                            children: [
                              sectionHeader(
                                title: 'Pending'.tr,
                                isSent: false,
                                page: pendingPage,
                                count: pendingCount,
                                onSync: () {
                                  ref.invalidate(scheduledPendingEmailsProvider);

                                  // refresh preview if selected
                                  if (selectedScheduledId != null) {
                                    ref.invalidate(scheduledEmailDetailsProvider(selectedScheduledId!));
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

                          // ===== Sent TAB =====
                          Column(
                            children: [
                              sectionHeader(
                                title: 'Sent'.tr,
                                isSent: true,
                                page: sentPage,
                                count: sentCount,
                                onSync: () {
                                  ref.invalidate(scheduledSentEmailsProvider);

                                  // refresh preview if selected
                                  if (selectedScheduledId != null) {
                                    ref.invalidate(scheduledEmailDetailsProvider(selectedScheduledId!));
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
          ),
        ),

        // RIGHT Preview
        Expanded(
          flex: 5,
          child: selectedScheduledId == null
              ? Center(
                  child: Text(
                    'Select scheduled email'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                )
              : ScheduledEmailDetailById(
                  id: selectedScheduledId!,
                  isMobile: widget.isMobile,
                  onDeleted: () => setState(() => selectedScheduledId = null),
                ),
        ),
      ],
    );
  }
  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';

    // Check if ISO-like string
    final looksIso = RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(raw);
    if (!looksIso) return raw;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    // ✅ THIS is the key line
    final local = parsed.toLocal();

    return
      '${local.day.toString().padLeft(2, '0')}.'
          '${local.month.toString().padLeft(2, '0')}.'
          '${local.year} '
          '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
  }

}

class ScheduledEmailDetail extends ConsumerWidget {
  final ScheduledEmail email;
  final bool isMobile;
  final VoidCallback onDeleted;

  const ScheduledEmailDetail({
    super.key,
    required this.email,
    required this.isMobile,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    // pick html if available, otherwise plain
    final body = (email.htmlBody.isNotEmpty ? email.htmlBody : email.body);
    final bool isHtml = containsHtml(body);

    // We don't have real sender in scheduled response, so use a stable label
    final sender = 'Scheduled Email'.tr;
    final senderDisplayName = 'Scheduled Email'.tr;

    Widget bodyContainer({required Widget child}) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          border: Border.all(color: theme.dashboardBoarder, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 0 : 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ✅ Same header row style like EmailDetail (subject + button area)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: isMobile ? 8.0 : 0.0),
                      child: Text(
                        email.subject.isEmpty ? 'no_subject'.tr : email.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(180),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // If later you want actions like "Edit schedule" / "Send now",
                  // you can replace this with a real button. For now keep layout consistent.
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.dashboardBoarder
                      ),
                      borderRadius: BorderRadius.circular(6)
                    ),
                    child: ElevatedButton(
                      style: elevatedButtonStyleRounded10.copyWith(
                        backgroundColor: WidgetStatePropertyAll(theme.dashboardContainer),
                      ),
                      onPressed: email.isSent
                          ? null
                          : () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                  backgroundColor: theme.dashboardContainer,
                                  title: Text(
                                    'Cancel scheduled email?'.tr,
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                  content: Text(
                                    'This will delete the schedule entry.'.tr,
                                    style: TextStyle(color: theme.textColor),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(
                                        'No'.tr,
                                        style: TextStyle(color: theme.textColor),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => Navigator.pop(context, true),
                                      child: Container(
                                        width: 110,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 10),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            color: theme.themeColor),
                                        child: Center(
                                          child: Text(
                                            'Yes, delete'.tr,
                                            style: TextStyle(
                                                color: theme.themeTextColor),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (ok != true) return;

                              try {
                                await EmailService.deleteScheduledEmail(
                                  id: email.id,
                                );

                                // ✅ refresh both tabs
                                ref.invalidate(scheduledPendingEmailsProvider);
                                ref.invalidate(scheduledSentEmailsProvider);
                                onDeleted();
                                // ✅ if you use detail-by-id preview, also clear it (see step 4)
                                ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(
                                      content: Text('Scheduled email deleted'.tr)),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: AppIcons.delete(color: theme.textColor),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 0.0),
                child: Divider(
                  height: isMobile ? 8 : 32,
                  color: theme.dashboardBoarder,
                ),
              ),

              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    // ✅ Desktop/tablet view (same structure)
    return Padding(
      padding: EdgeInsets.all(isMobile ? 5 : 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmailMetaExpandable(
            sender: sender,
            senderDisplayName: senderDisplayName,
            recipients: email.to,
            cc: email.cc,
            bcc: email.bcc,
            // Scheduled email has sendAt and optionally sentAt
            sentAt: email.sentAt ?? email.sendAt,
            receivedAt: null,
            theme: theme,
            initiallyExpanded: false,
            useCard: true,
            cardColor: theme.dashboardContainer,
            cardBorderColor: theme.dashboardBoarder,
            // You can also force date display to show sendAt:
            dateOverride:
                email.isSent ? (email.sentAt ?? email.sendAt) : email.sendAt,
          ),
          SizedBox(height: isMobile ? 5 : 16),
          Expanded(
            child: bodyContainer(
              child: isHtml
                  ? ScheduledHtmlBodyFill(
                      html: body,
                      theme: theme,
                    )
                  : PlainBodyWithLinkButtons(
                      rawText: body,
                      theme: theme,
                      controller: null,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ Public HTML body widget for scheduled emails (same idea as _HtmlEmailBodyFill)
class ScheduledHtmlBodyFill extends StatefulWidget {
  final String html;
  final ThemeColors theme;

  const ScheduledHtmlBodyFill({
    super.key,
    required this.html,
    required this.theme,
  });

  @override
  State<ScheduledHtmlBodyFill> createState() => _ScheduledHtmlBodyFillState();
}

class _ScheduledHtmlBodyFillState extends State<ScheduledHtmlBodyFill> {
  InAppWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    final injected = _injectCss(widget.html, widget.theme);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: InAppWebView(
        initialData: InAppWebViewInitialData(data: injected),
        initialSettings: InAppWebViewSettings(
          disableVerticalScroll: false,
          disableHorizontalScroll: true,
          javaScriptEnabled: true,
          transparentBackground: true,
          useHybridComposition: true,
          supportZoom: false,
        ),
        onWebViewCreated: (c) => _controller = c,
      ),
    );
  }

  String _injectCss(String html, ThemeColors theme) {
    final safe = _basicSanitize(html);
    final textColor = _toCssColor(theme.textColor);

    const viewport =
        '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">';

    final css = """
<style>
  html, body {
    margin: 0; padding: 0;
    background: transparent !important;
    color: $textColor !important;
    font-size: 14px;
    line-height: 1.35;
    -webkit-text-size-adjust: 100%;
  }
  * { box-sizing: border-box; }
  img, video { max-width: 100% !important; height: auto !important; }
  table { max-width: 100% !important; }
  a { color: $textColor !important; }
</style>
""";

    final headInjection = '$viewport$css';

    if (safe.contains('</head>')) {
      return safe.replaceFirst('</head>', '$headInjection</head>');
    }

    return """
<!doctype html>
<html>
<head>$headInjection</head>
<body>$safe</body>
</html>
""";
  }

  String _basicSanitize(String html) {
    var s = html;

    s = s.replaceAll(
      RegExp(
        r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>',
        caseSensitive: false,
      ),
      '',
    );
    s = s.replaceAll(
      RegExp(
        r'<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>',
        caseSensitive: false,
      ),
      '',
    );

    return s;
  }

  String _toCssColor(Color c) {
    final a = c.alpha / 255.0;
    return 'rgba(${c.red}, ${c.green}, ${c.blue}, $a)';
  }
}

class ScheduledEmailDetailById extends ConsumerWidget {
  final int id;
  final bool isMobile;
  final VoidCallback onDeleted;

  const ScheduledEmailDetailById(
      {super.key,
      required this.id,
      required this.isMobile,
      required this.onDeleted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEmail = ref.watch(scheduledEmailDetailsProvider(id));

    return asyncEmail.when(
      loading: () => Center(child: AppLottie.loading()),
      error: (e, _) => Center(child: AppLottie.error()),
      data: (email) {
        // ✅ Reuse your preview widget that matches EmailDetail style
        return ScheduledEmailDetail(
            email: email, isMobile: isMobile, onDeleted: onDeleted);
      },
    );
  }
}
