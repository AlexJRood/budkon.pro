// network_monitoring/components/open_nm_ad.dart

import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:core/settings/settings.dart';
import 'package:flutter/foundation.dart'
    show Factory, TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/platforms/html_utils_stub.dart'
    if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pie_menu/network_monitoring.dart';
import '../providers/active_check_provider.dart';
import 'package:get/get_utils/get_utils.dart';


// JS injected into the WebView after page load to detect stale/inactive listings.
// Returns true when the page clearly indicates the ad is no longer available.
const _kStaleDetectionJs = r'''
(function(){
  try {
    var t = (document.body && document.body.innerText || '').toLowerCase();
    var phrases = [
      // generic access blocks
      'access has been blocked', 'access denied',
      'your ip has been blocked', 'blocked due to the violation',
      '403 forbidden',
      // polish real-estate portals — expired listing signals
      'ogłoszenie nieaktualne', 'ogłoszenie wygasło', 'ogłoszenie zostało usunięte',
      'ogłoszenie jest nieaktywne', 'oferta nieaktualna', 'oferta wygasła',
      'oferta niedostępna', 'oferta została usunięta', 'oferta jest nieaktywna',
      'to ogłoszenie nie jest już dostępne', 'nieruchomość sprzedana',
      'nieruchomość wynajęta', 'mieszkanie sprzedane', 'dom sprzedany',
      'sprzedane', 'wynajęte', 'niedostępne',
      // english equivalents
      'this listing is no longer available', 'listing expired',
      'listing removed', 'listing not found', 'ad has been removed',
      'ad is no longer available', 'property sold', 'property rented',
      'no longer available', 'page not found', '404 not found',
      // otodom / olx specific
      'to ogłoszenie już nie istnieje', 'szukana strona nie istnieje',
      'strona nie istnieje', 'nie znaleziono ogłoszenia',
    ];
    for (var i = 0; i < phrases.length; i++) {
      if (t.includes(phrases[i])) return phrases[i];
    }
    return null;
  } catch(e) { return null; }
})();
''';

class OpenNmAdMeta {
  final String? savedSearchTitle;
  final int? savedSearchId;

  final String? clientLabel;
  final int? clientId;

  final String? transactionLabel;
  final int? transactionId;

  final bool fromNotification;

  const OpenNmAdMeta({
    this.savedSearchTitle,
    this.savedSearchId,
    this.clientLabel,
    this.clientId,
    this.transactionLabel,
    this.transactionId,
    this.fromNotification = false,
  });

  bool get hasAnyInfo =>
      (savedSearchTitle?.trim().isNotEmpty ?? false) ||
      (clientLabel?.trim().isNotEmpty ?? false) ||
      (transactionLabel?.trim().isNotEmpty ?? false);

  String get debugTag {
    return [
      savedSearchId,
      clientId,
      transactionId,
      fromNotification,
    ].join('|');
  }
}

Future<void> openAdUrl(
  BuildContext context,
  WidgetRef ref,
  dynamic ad,
  int? transactionId,
  int? clientId,
  String? tag, {
  OpenNmAdMeta? meta,
}) async {
  final raw = (ad?.url ?? '').toString().trim();
  if (raw.isEmpty) return;

  final url = raw;

  // Track display / viewed state in your existing NM flow.
  handleDisplayedActionNM(ref, ad, transactionId, clientId, context);

  // Keep current web behavior:
  // web opens in a new tab because this is the safest path
  // with the current app flow and platform support.
  if (kIsWeb) {
    await openNewTabAndRoute(url);
    return;
  }

  // On phone / tablet you already support external opening by preference.
  final openExternally = ref.read(openAdsInNewTabProvider);
  if (openExternally) {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return;
  }

  if (!context.mounted) return;

  bool fallbackTriggered = false;

  String getSourcePlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'mobile_android';
      case TargetPlatform.iOS:
        return 'mobile_ios';
      default:
        return 'mobile';
    }
  }

  Future<void> fallbackToExternal(
    BuildContext ctx, {
    String? reason,
  }) async {
    if (fallbackTriggered) return;
    fallbackTriggered = true;

    // Single request per stale signal — Superbee deduplicates by URL/adId
    // on the task queue, so many users reporting the same ad sends only one
    // Extractly check.
    ref.read(activeCheckProvider.notifier).requestActiveCheck(
          url: url,
          source: getSourcePlatform(),
          reason: reason ?? 'suspected_inactive',
          detectedAt: DateTime.now(),
        );

    if (Navigator.of(ctx).canPop()) {
      Navigator.of(ctx).pop();
    }

    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  final media = MediaQuery.of(context);
  final bool isMobileSheet = media.size.width < 600;

  // ===================== MOBILE =====================
  if (isMobileSheet) {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final theme = ref.watch(themeColorsProvider);

            return DraggableScrollableSheet(
              initialChildSize: 0.90,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (BuildContext ctx, ScrollController sc) {
                return ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                  child: Material(
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            _OverlayHeader(
                              theme: theme,
                              title: (ad?.safeTitle ?? ad?.title ?? '')
                                  .toString(),
                              onClose: () => Navigator.of(ctx).pop(),
                            ),
                            _NotificationContextBanner(
                              theme: theme,
                              meta: meta,
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: PrimaryScrollController(
                                controller: sc,
                                child: InAppWebView(
                                  gestureRecognizers: {
                                    Factory<OneSequenceGestureRecognizer>(
                                      () => EagerGestureRecognizer(),
                                    ),
                                  },
                                  initialUrlRequest:
                                      URLRequest(url: WebUri(url)),
                                  initialSettings: InAppWebViewSettings(
                                    useShouldOverrideUrlLoading: true,
                                    mediaPlaybackRequiresUserGesture: true,
                                    javaScriptEnabled: true,
                                    useHybridComposition: true,
                                  ),
                                  shouldOverrideUrlLoading:
                                      (controller, navAction) async {
                                    return NavigationActionPolicy.ALLOW;
                                  },
                                  onLoadError:
                                      (controller, failingUrl, code, message) async {
                                    await fallbackToExternal(
                                      ctx,
                                      reason: 'webview_load_error',
                                    );
                                  },
                                  onLoadHttpError: (
                                    controller,
                                    failingUrl,
                                    statusCode,
                                    description,
                                  ) async {
                                    if (statusCode >= 400) {
                                      await fallbackToExternal(
                                        ctx,
                                        reason: 'http_$statusCode',
                                      );
                                    }
                                  },
                                  onLoadStop: (controller, uri) async {
                                    try {
                                      await Future.delayed(
                                        const Duration(milliseconds: 500),
                                      );

                                      final matchedPhrase =
                                          await controller.evaluateJavascript(
                                        source: _kStaleDetectionJs,
                                      );

                                      if (matchedPhrase != null &&
                                          matchedPhrase != false) {
                                        await fallbackToExternal(
                                          ctx,
                                          reason: 'stale_phrase_detected',
                                        );
                                      }
                                    } catch (_) {}
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: _PieVerticalActionsConsumer(
                            theme: theme,
                            builder: (r) => buildPieMenuActionsNM(
                              r,
                              ad,
                              ctx,
                              transactionId,
                              clientId,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    return;
  }

  // ===================== DESKTOP / TABLET =====================
  await PopPageManager.show(
    context,
    isBig: true,
    tag: 'nm_web_${ad?.id ?? tag ?? meta?.debugTag ?? url.hashCode}',
    shouldBeADrawer: true,
    wrapChildInListView: false,
    child: const SizedBox.shrink(),
    childBuilder: (ctx, sc) {
      return _AdWebViewPopContent(
        ad: ad,
        url: url,
        transactionId: transactionId,
        clientId: clientId,
        scrollController: sc,
        fallbackToExternal: (c) => fallbackToExternal(c),
        meta: meta,
      );
    },
  );
}

class _OverlayHeader extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final VoidCallback onClose;

  const _OverlayHeader({
    required this.theme,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: theme.themeColor),
      height: 48,
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.interMedium.copyWith(
                fontSize: 16,
                color: theme.themeTextColor,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close'.tr,
            onPressed: onClose,
            icon: Icon(Icons.close, color: theme.themeTextColor),
          ),
        ],
      ),
    );
  }
}

class _NotificationContextBanner extends StatelessWidget {
  final ThemeColors theme;
  final OpenNmAdMeta? meta;

  const _NotificationContextBanner({
    required this.theme,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    if (meta == null || !meta!.hasAnyInfo) {
      return const SizedBox.shrink();
    }

    final chips = <Widget>[];

    if ((meta!.savedSearchTitle ?? '').trim().isNotEmpty) {
      chips.add(
        _ctxChip(
          theme,
          icon: Icons.saved_search,
          text: meta!.savedSearchTitle!,
        ),
      );
    }

    if ((meta!.clientLabel ?? '').trim().isNotEmpty) {
      chips.add(
        _ctxChip(
          theme,
          icon: Icons.person_outline,
          text: meta!.clientLabel!,
        ),
      );
    }

    if ((meta!.transactionLabel ?? '').trim().isNotEmpty) {
      chips.add(
        _ctxChip(
          theme,
          icon: Icons.account_tree_outlined,
          text: meta!.transactionLabel!,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: theme.themeColor.withOpacity(0.08),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (meta!.fromNotification)
            _ctxChip(
              theme,
              icon: Icons.notifications_active_outlined,
              text: 'Opened from notification'.tr,
            ),
          ...chips,
        ],
      ),
    );
  }

  Widget _ctxChip(
    ThemeColors theme, {
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.themeColor.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Consumer that rebuilds when any provider used inside builder changes.
class _PieVerticalActionsConsumer extends ConsumerWidget {
  const _PieVerticalActionsConsumer({
    super.key,
    required this.theme,
    required this.builder,
  });

  final ThemeColors theme;
  final List<PieAction> Function(WidgetRef) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = builder(ref);

    return Column(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          _PieRectButton(action: actions[i], theme: theme),
          if (i < actions.length - 1) const SizedBox(height: 2),
        ],
      ],
    );
  }
}

class _PieRectButton extends StatelessWidget {
  const _PieRectButton({
    super.key,
    required this.action,
    required this.theme,
  });

  final PieAction action;
  final ThemeColors theme;

  String? _tooltipText() {
    final t = action.tooltip;
    if (t is Text) return t.data;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const double size = 40;

    final ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    );

    final widget = Material(
      color: theme.themeColor.withAlpha((255 * 0.85).toInt()),
      shape: shape,
      elevation: 2,
      child: InkWell(
        customBorder: shape,
        onTap: action.onSelect,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: IconTheme(
              data: const IconThemeData(
                color: AppColors.white,
                size: 20,
              ),
              child: action.child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );

    final tooltip = _tooltipText();
    return (tooltip != null && tooltip.isNotEmpty)
        ? Tooltip(message: tooltip, child: widget)
        : widget;
  }
}

class _AdWebViewPopContent extends ConsumerWidget {
  const _AdWebViewPopContent({
    required this.ad,
    required this.url,
    required this.transactionId,
    required this.clientId,
    required this.scrollController,
    required this.fallbackToExternal,
    required this.meta,
  });

  final dynamic ad;
  final String url;
  final int? transactionId;
  final int? clientId;
  final ScrollController? scrollController;
  final Future<void> Function(BuildContext ctx) fallbackToExternal;
  final OpenNmAdMeta? meta;

  Widget _webView(BuildContext ctx) {
    return InAppWebView(
      gestureRecognizers: {
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: true,
        javaScriptEnabled: true,
        useHybridComposition: true,
      ),
      shouldOverrideUrlLoading: (controller, navAction) async {
        return NavigationActionPolicy.ALLOW;
      },
      onLoadError: (controller, failingUrl, code, message) async {
        await fallbackToExternal(ctx);
      },
      onLoadHttpError: (controller, failingUrl, statusCode, description) async {
        if (statusCode >= 400) {
          await fallbackToExternal(ctx);
        }
      },
      onLoadStop: (controller, uri) async {
        try {
          await Future.delayed(const Duration(milliseconds: 500));
          final matchedPhrase = await controller.evaluateJavascript(
            source: _kStaleDetectionJs,
          );
          if (matchedPhrase != null && matchedPhrase != false) {
            await fallbackToExternal(ctx);
          }
        } catch (_) {}
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final title = (ad?.safeTitle ?? ad?.title ?? '').toString();
    final sc = scrollController;

    final content = (sc != null)
        ? CustomScrollView(
            controller: sc,
            slivers: [
              SliverToBoxAdapter(
                child: _OverlayHeader(
                  theme: theme,
                  title: title,
                  onClose: () => Navigator.of(context).maybePop(),
                ),
              ),
              SliverToBoxAdapter(
                child: _NotificationContextBanner(
                  theme: theme,
                  meta: meta,
                ),
              ),
              const SliverToBoxAdapter(child: Divider(height: 1)),
              SliverFillRemaining(
                hasScrollBody: true,
                child: _webView(context),
              ),
            ],
          )
        : Column(
            children: [
              _OverlayHeader(
                theme: theme,
                title: title,
                onClose: () => Navigator.of(context).maybePop(),
              ),
              _NotificationContextBanner(
                theme: theme,
                meta: meta,
              ),
              const Divider(height: 1),
              Expanded(child: _webView(context)),
            ],
          );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            content,
            Positioned(
              right: 10,
              bottom: 16,
              child: _PieVerticalActionsConsumer(
                theme: theme,
                builder: (r) => buildPieMenuActionsNM(
                  r,
                  ad,
                  context,
                  transactionId,
                  clientId,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
