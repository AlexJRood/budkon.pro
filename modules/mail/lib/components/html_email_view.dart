import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:core/theme/apptheme.dart';

import '../utils/Link_handler.dart';

class HtmlEmailView extends ConsumerStatefulWidget {
  final String html;
  final ThemeColors theme;

  /// Kept for compatibility with current callers.
  /// The WebView itself no longer manually drives the sheet.
  final DraggableScrollableController? sheetController;

  /// Use this inside DraggableScrollableSheet/mobile.
  ///
  /// When true:
  /// - WebView internal vertical scroll is disabled
  /// - WebView height is measured from HTML content
  /// - parent ListView/DraggableScrollableSheet handles scrolling
  final bool shrinkToContent;

  final double initialHeight;
  final double minHeight;

  const HtmlEmailView({
    super.key,
    required this.html,
    required this.theme,
    this.sheetController,
    this.shrinkToContent = false,
    this.initialHeight = 260,
    this.minHeight = 160,
  });

  @override
  ConsumerState<HtmlEmailView> createState() => _HtmlEmailViewState();
}

class _HtmlEmailViewState extends ConsumerState<HtmlEmailView> {
  InAppWebViewController? _controller;

  bool _disposed = false;
  double _contentHeight = 260;

  @override
  void initState() {
    super.initState();
    _disposed = false;
    _contentHeight = widget.initialHeight;
  }

  @override
  void didUpdateWidget(covariant HtmlEmailView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.html != widget.html ||
        oldWidget.shrinkToContent != widget.shrinkToContent ||
        oldWidget.initialHeight != widget.initialHeight) {
      _contentHeight = widget.initialHeight;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _controller = null;
    super.dispose();
  }

  void _safeSetHeight(double rawHeight) {
    if (_disposed || !mounted || !widget.shrinkToContent) return;

    final nextHeight = rawHeight.clamp(widget.minHeight, 120000.0).toDouble();

    if ((nextHeight - _contentHeight).abs() < 2) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !mounted) return;

      setState(() {
        _contentHeight = nextHeight;
      });
    });
  }

  void _safeHandleLink(String url) {
    if (_disposed || !mounted) return;

    final localRef = ref;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !mounted) return;

      LinkHandler.handleLinkPress(
        url,
        localRef,
        context,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final injected = _injectCssAndScrollBridge(
      widget.html,
      widget.theme,
      shrinkToContent: widget.shrinkToContent,
    );

    final webView = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: InAppWebView(
        key: ValueKey<int>(
          Object.hash(
            widget.html,
            widget.theme.textColor.value,
            widget.shrinkToContent,
          ),
        ),
        initialData: InAppWebViewInitialData(
          data: injected,
          mimeType: 'text/html',
          encoding: 'utf-8',
          baseUrl: WebUri('https://email.local/'),
        ),
        initialSettings: InAppWebViewSettings(
          disableVerticalScroll: widget.shrinkToContent,
          disableHorizontalScroll: true,
          javaScriptEnabled: true,
          transparentBackground: false,
          useHybridComposition: true,
          supportZoom: false,
          verticalScrollBarEnabled: !widget.shrinkToContent,
          horizontalScrollBarEnabled: false,
          mediaPlaybackRequiresUserGesture: true,
          allowsInlineMediaPlayback: false,
        ),

        /// Important:
        /// In shrink mode WebView receives taps only.
        /// Vertical drag goes to parent ListView / DraggableScrollableSheet.
        gestureRecognizers: widget.shrinkToContent
            ? <Factory<OneSequenceGestureRecognizer>>{
                Factory<TapGestureRecognizer>(
                  () => TapGestureRecognizer(),
                ),
              }
            : null,

        onWebViewCreated: (controller) {
          _controller = controller;

          controller.addJavaScriptHandler(
            handlerName: 'contentHeight',
            callback: (args) {
              if (_disposed || !mounted || args.isEmpty) return 0;

              final value = args.first;
              double height = widget.initialHeight;

              if (value is num) {
                height = value.toDouble();
              } else if (value is String) {
                height = double.tryParse(value) ?? widget.initialHeight;
              }

              _safeSetHeight(height + 8);
              return height;
            },
          );

          controller.addJavaScriptHandler(
            handlerName: 'linkClick',
            callback: (args) {
              if (_disposed || !mounted || args.isEmpty) return null;

              final url = args.first?.toString();
              if (url != null && url.trim().isNotEmpty) {
                _safeHandleLink(url.trim());
              }

              return null;
            },
          );
        },

        onLoadStop: (controller, _) async {
          if (_disposed || !mounted) return;

          await controller.evaluateJavascript(
            source: '''
              window.__flutterReportHeight && window.__flutterReportHeight();

              document.addEventListener('click', function(e) {
                var target = e.target.closest('a');

                if (target && target.href) {
                  e.preventDefault();

                  if (
                    window.flutter_inappwebview &&
                    window.flutter_inappwebview.callHandler
                  ) {
                    window.flutter_inappwebview.callHandler(
                      'linkClick',
                      target.href
                    );
                  }
                }
              }, false);
            ''',
          );
        },

        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final url = navigationAction.request.url?.toString();

          if (url != null && !_disposed && mounted) {
            final normalized = url.trim();

            if (normalized.isNotEmpty &&
                !normalized.startsWith('about:blank') &&
                !normalized.startsWith('https://email.local/')) {
              _safeHandleLink(normalized);
              return NavigationActionPolicy.CANCEL;
            }
          }

          return NavigationActionPolicy.ALLOW;
        },
      ),
    );

    if (!widget.shrinkToContent) {
      return webView;
    }

    return SizedBox(
      width: double.infinity,
      height: _contentHeight,
      child: webView,
    );
  }

  String _injectCssAndScrollBridge(
    String html,
    ThemeColors theme, {
    required bool shrinkToContent,
  }) {
    final safe = _basicSanitize(html);
    final textColor = _toCssColor(theme.textColor);
    final backgroundColor = _toCssColor(theme.dashboardContainer);

    const viewport =
        '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">';

    final overflowY = shrinkToContent ? 'hidden' : 'auto';

    final css = """
<style>
  html, body {
    margin: 0 !important;
    padding: 0 !important;
    width: 100% !important;
    min-height: 1px !important;
    background: $backgroundColor !important;
    color: $textColor !important;
    font-size: 14px !important;
    line-height: 1.35 !important;
    -webkit-text-size-adjust: 100%;
    overflow-x: hidden !important;
    overflow-y: $overflowY !important;
  }

  * {
    box-sizing: border-box !important;
  }

  body {
    word-break: break-word;
    overflow-wrap: anywhere;
  }

  img,
  video {
    max-width: 100% !important;
    height: auto !important;
  }

  table {
    max-width: 100% !important;
    width: auto !important;
    border-collapse: collapse;
  }

  td,
  th {
    max-width: 100% !important;
    word-break: break-word;
    overflow-wrap: anywhere;
  }

  pre {
    white-space: pre-wrap !important;
    word-break: break-word !important;
    overflow-wrap: anywhere !important;
  }

  a {
    color: $textColor !important;
    text-decoration: underline;
  }
</style>
""";

    final js = """
<script>
(function() {
  var active = true;
  var lastHeight = 0;
  var pending = false;

  function docHeight() {
    var body = document.body || {};
    var html = document.documentElement || {};

    return Math.max(
      body.scrollHeight || 0,
      body.offsetHeight || 0,
      body.clientHeight || 0,
      html.scrollHeight || 0,
      html.offsetHeight || 0,
      html.clientHeight || 0
    );
  }

  function sendHeight() {
    if (!active) return;

    pending = false;

    var height = Math.ceil(docHeight());

    if (!height || Math.abs(height - lastHeight) < 2) {
      return;
    }

    lastHeight = height;

    if (
      window.flutter_inappwebview &&
      window.flutter_inappwebview.callHandler
    ) {
      window.flutter_inappwebview.callHandler('contentHeight', height);
    }
  }

  function scheduleHeightReport() {
    if (pending) return;

    pending = true;

    if (window.requestAnimationFrame) {
      window.requestAnimationFrame(sendHeight);
    } else {
      setTimeout(sendHeight, 16);
    }
  }

  window.__flutterReportHeight = scheduleHeightReport;

  window.addEventListener('load', scheduleHeightReport);
  window.addEventListener('resize', scheduleHeightReport);

  Array.prototype.forEach.call(document.images || [], function(img) {
    img.addEventListener('load', scheduleHeightReport);
    img.addEventListener('error', scheduleHeightReport);
  });

  if (window.ResizeObserver && document.body) {
    var resizeObserver = new ResizeObserver(scheduleHeightReport);
    resizeObserver.observe(document.body);
    resizeObserver.observe(document.documentElement);
  }

  if (window.MutationObserver && document.body) {
    var mutationObserver = new MutationObserver(scheduleHeightReport);
    mutationObserver.observe(document.body, {
      childList: true,
      subtree: true,
      attributes: true,
      characterData: true
    });
  }

  setTimeout(scheduleHeightReport, 50);
  setTimeout(scheduleHeightReport, 250);
  setTimeout(scheduleHeightReport, 600);
  setTimeout(scheduleHeightReport, 1200);

  window.addEventListener('beforeunload', function() {
    active = false;
  });
})();
</script>
""";

    final headInjection = '$viewport$css$js';

    if (safe.toLowerCase().contains('</head>')) {
      return safe.replaceFirst(
        RegExp(r'</head>', caseSensitive: false),
        '$headInjection</head>',
      );
    }

    if (safe.toLowerCase().contains('<html')) {
      return safe.replaceFirst(
        RegExp(r'<html[^>]*>', caseSensitive: false),
        '<html><head>$headInjection</head>',
      );
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