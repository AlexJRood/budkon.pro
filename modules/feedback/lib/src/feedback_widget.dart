// ignore_for_file: public_member_api_docs
import 'dart:math' as math;

import 'package:feedback/feedback.dart';
import 'package:feedback/src/controls_column.dart';
import 'package:feedback/src/feedback_bottom_sheet.dart';
import 'package:feedback/src/filters_button_widget.dart';
import 'package:feedback/src/issue_details/issue_details_dialog.dart';
import 'package:feedback/src/paint_on_background.dart';
import 'package:feedback/src/painter.dart';
import 'package:feedback/src/provider/open_issues_provider.dart';
import 'package:feedback/src/scale_and_clip.dart';
import 'package:feedback/src/scale_and_fade.dart';
import 'package:feedback/src/screenshot.dart';
import 'package:feedback/src/theme/feedback_theme.dart';
import 'package:feedback/src/utilities/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/user/user/user_provider.dart';

typedef FeedbackButtonPress = void Function(BuildContext context);
final selectedMemberIdsProvider = StateProvider<Set<int>?>((ref) => null);

// See alignment.dart.
const kScaleOrigin = Alignment(-.3, -.65);
const kScaleFactor = .65;

class FeedbackWidget extends ConsumerStatefulWidget {
  const FeedbackWidget({
    super.key,
    required this.child,
    required this.isFeedbackVisible,
    required this.drawColors,
    required this.mode,
    required this.pixelRatio,
    required this.feedbackBuilder,
  }) : assert(
  drawColors.length > 0,
  'There must be at least one color to draw',
  );

  final bool isFeedbackVisible;
  final FeedbackMode mode;
  final double pixelRatio;
  final Widget child;
  final List<Color> drawColors;
  final FeedbackBuilder feedbackBuilder;

  @override
  FeedbackWidgetState createState() => FeedbackWidgetState();
}

@visibleForTesting
class FeedbackWidgetState extends ConsumerState<FeedbackWidget>
    with SingleTickerProviderStateMixin {
  final double padding = 8;
  String _cachedFeedbackPath = Uri.base.path;

  String _resolveCurrentPathSafely() {
    try {
      final nav = ref.read(navigationService);
      return nav.currentPath;
    } catch (_) {
      return Uri.base.path;
    }
  }

  ValueNotifier<double> sheetProgress = ValueNotifier(0);

  @visibleForTesting
  late PainterController painterController = create();

  ScreenshotController screenshotController = ScreenshotController();
  TextEditingController textEditingController = TextEditingController();

  late FeedbackMode mode = widget.mode;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  PainterController create() {
    final controller = PainterController();
    controller.thickness = 5.0;
    controller.drawColor = widget.drawColors[0];
    return controller;
  }

  void _openMobileIssuesSheet() {
    final nav = ref.read(navigationService);
    final sheetContext = nav.navigatorKey.currentContext ?? context;

    showModalBottomSheet(
      context: sheetContext,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.50,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _ScreenIssuesPanel(
              currentPath: _cachedFeedbackPath,
              isBottomSheet: true,
              scrollController: scrollController,
              onOpenIssue: () {
                Navigator.of(context).pop();
                setState(() {
                  mode = FeedbackMode.navigate;
                });
                _hideKeyboard();
              },
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(backButtonIntercept);
  }

  @override
  void dispose() {
    _controller.dispose();
    BackButtonInterceptor.remove(backButtonIntercept);
    super.dispose();
  }

  @visibleForTesting
  bool backButtonIntercept() {
    if (mode == FeedbackMode.draw && widget.isFeedbackVisible) {
      if (painterController.getStepCount() > 0) {
        painterController.undo();
      } else {
        BetterFeedback.of(context).hide();
      }
      return true;
    }
    return false;
  }

  @override
  void didUpdateWidget(FeedbackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    mode = widget.mode;

    if (oldWidget.isFeedbackVisible != widget.isFeedbackVisible &&
        oldWidget.isFeedbackVisible == false) {
      _cachedFeedbackPath = _resolveCurrentPathSafely();
      debugPrint('=== FEEDBACK OPENED ===');
      debugPrint('cached path: $_cachedFeedbackPath');
      _controller.forward();
    }

    if (oldWidget.isFeedbackVisible != widget.isFeedbackVisible &&
        oldWidget.isFeedbackVisible == true) {
      debugPrint('=== FEEDBACK CLOSED ===');
      _controller.reverse();
      sheetProgress.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final animation = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: Curves.easeInSine))
        .animate(_controller);

    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 900;

    final FeedbackThemeData feedbackThemeData = FeedbackTheme.of(context);
    final ThemeData theme = ThemeData(
      brightness: feedbackThemeData.brightness,
      cardColor: feedbackThemeData.feedbackSheetColor,
      colorScheme: feedbackThemeData.colorScheme,
    );
    final canStuff = ref.watch(canAccessModuleProvider('stuff'));

    return Theme(
      data: theme,
      child: Material(
        color: FeedbackTheme.of(context).background,
        child: AnimatedBuilder(
          animation: _controller,
          child: Screenshot(
            controller: screenshotController,
            child: PaintOnChild(
              controller: painterController,
              isPaintingActive:
              mode == FeedbackMode.draw && widget.isFeedbackVisible,
              child: widget.child,
            ),
          ),
          builder: (context, screenshotChild) {
            return Stack(
              children: [
                if (!animation.isDismissed)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => BetterFeedback.of(context).hide(),
                    ),
                  ),
                if (!animation.isDismissed && canStuff && isMobile)
                  Positioned(
                    top: mediaQuery.padding.top + 8,
                    left: 8,
                    child: SafeArea(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _openMobileIssuesSheet,
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: feedbackThemeData.feedbackSheetColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: feedbackThemeData.colorScheme.onSurface
                                    .withOpacity(0.12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bug_report_outlined,
                                  color:
                                  feedbackThemeData.colorScheme.onSurface,
                                  size: 18,
                                ),

                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                CustomMultiChildLayout(
                  delegate: _FeedbackLayoutDelegate(
                    displayFeedback: !animation.isDismissed,
                    query: mediaQuery,
                    sheetFraction: feedbackThemeData.feedbackSheetHeight,
                    animationProgress: animation.value,
                    isMobile: isMobile,
                  ),
                  children: [
                    LayoutId(
                      id: _screenshotId,
                      child: animation.isDismissed
                          ? screenshotChild!
                          : Padding(
                        padding:
                        EdgeInsets.symmetric(horizontal: padding),
                        child: ScaleAndFade(
                          progress: sheetProgress,
                          minScale: .7,
                          minOpacity: .01,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size = MediaQuery.of(context).size;
                              return OverflowBox(
                                maxWidth: size.width,
                                maxHeight: size.height,
                                child: ScaleAndClip(
                                  progress: animation.value,
                                  scaleFactor:
                                  constraints.maxWidth / size.width,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return screenshotChild!;
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    if (!animation.isDismissed && canStuff && !isMobile)
                      LayoutId(
                        id: _issuesPanelId,
                        child: ScaleAndFade(
                          progress: sheetProgress,
                          minScale: .7,
                          child: _ScreenIssuesPanel(
                            currentPath: _cachedFeedbackPath,
                            onOpenIssue: () {
                              setState(() {
                                mode = FeedbackMode.navigate;
                              });
                              _hideKeyboard();
                            },
                          ),
                        ),
                      ),
                    if (!animation.isDismissed)
                      LayoutId(
                        id: _controlsColumnId,
                        child: Padding(
                          padding: EdgeInsets.only(left: padding),
                          child: ScaleAndFade(
                            progress: sheetProgress,
                            minScale: .7,
                            child: ControlsColumn(
                              mode: mode,
                              activeColor: painterController.drawColor,
                              colors: widget.drawColors,
                              onColorChanged: (color) {
                                setState(() {
                                  painterController.drawColor = color;
                                });
                                _hideKeyboard();
                              },
                              onUndo: () {
                                painterController.undo();
                                _hideKeyboard();
                              },
                              onClearDrawing: () {
                                painterController.clear();
                                _hideKeyboard();
                              },
                              onControlModeChanged: (mode) {
                                setState(() {
                                  this.mode = mode;
                                  _hideKeyboard();
                                });
                              },
                              onCloseFeedback: () {
                                _hideKeyboard();
                                BetterFeedback.of(context).hide();
                              },
                            ),
                          ),
                        ),
                      ),
                    if (!animation.isDismissed)
                      LayoutId(
                        id: _sheetId,
                        child: NotificationListener<
                            DraggableScrollableNotification>(
                          onNotification: (notification) {
                            sheetProgress.value =
                                (notification.extent - notification.minExtent) /
                                    (notification.maxExtent -
                                        notification.minExtent);
                            return false;
                          },
                          child: FeedbackBottomSheet(
                            key: const Key('feedback_bottom_sheet'),
                            feedbackBuilder: widget.feedbackBuilder,
                            onSubmit: (
                                String feedback, {
                                  Map<String, dynamic>? extras,
                                }) async {
                              try {
                                await _sendFeedback(
                                  context,
                                  BetterFeedback.of(context).onFeedback!,
                                  screenshotController,
                                  feedback,
                                  widget.pixelRatio,
                                  extras: extras,
                                );
                                painterController.clear();
                              } catch (e, st) {
                                debugPrint('SEND FEEDBACK ERROR: $e');
                                debugPrintStack(stackTrace: st);
                              }
                            },
                            sheetProgress: sheetProgress,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @visibleForTesting
  static Future<void> sendFeedback(
      OnFeedbackCallback onFeedbackSubmitted,
      ScreenshotController controller,
      String feedback,
      double pixelRatio, {
        Duration delay = const Duration(milliseconds: 2000),
        Map<String, dynamic>? extras,
      }) async {
    await Future.delayed(
      delay,
          () async {
        final screenshot = await controller.capture(
          pixelRatio: pixelRatio,
          delay: const Duration(milliseconds: 0),
        );

        await onFeedbackSubmitted(
          UserFeedback(
            text: feedback,
            screenshot: screenshot,
            extra: extras,
          ),
        );

        debugPrint('=== sendFeedback END ===');
      },
    );
  }

  static Future<void> _sendFeedback(
      BuildContext context,
      OnFeedbackCallback onFeedbackSubmitted,
      ScreenshotController controller,
      String feedback,
      double pixelRatio, {
        Duration delay = const Duration(milliseconds: 200),
        bool showKeyboard = false,
        Map<String, dynamic>? extras,
      }) async {
    if (!showKeyboard) {
      _hideKeyboard();
    }

    final feedbackController = BetterFeedback.of(context);

    await sendFeedback(
      onFeedbackSubmitted,
      controller,
      feedback,
      pixelRatio,
      delay: delay,
      extras: extras,
    );

    feedbackController.hide();
  }

  static void _hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

const _screenshotId = 'screenshot_id';
const _issuesPanelId = 'issues_panel_id';
const _controlsColumnId = 'controls_column_id';
const _sheetId = 'sheet_id';

class _ScreenIssuesPanel extends ConsumerWidget {
  final VoidCallback onOpenIssue;
  final String currentPath;
  final bool isBottomSheet;
  final ScrollController? scrollController;

  const _ScreenIssuesPanel({
    super.key,
    required this.onOpenIssue,
    required this.currentPath,
    this.isBottomSheet = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackTheme = FeedbackTheme.of(context);
    final colorScheme = feedbackTheme.colorScheme;
    final problemsAsync = ref.watch(feedbackProblemsProvider);
    final issuesAsync = ref.watch(feedbackIssuesByPathProvider(currentPath));
    final theme = ref.watch(themeColorsProvider);

    void openMobileFilters(List<FeedbackProblemModel> problems) {
      final nav = ref.read(navigationService);
      final sheetContext = nav.navigatorKey.currentContext ?? context;

      showModalBottomSheet(
        context: sheetContext,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: theme.dashboardContainer,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              return DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (_, scroll) {
                  return FiltersButtonWidget(
                    scroll: scroll,
                    problems: problems,
                  );
                },
              );
            },
          );
        },
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        problemsAsync.when(
          loading: () => Row(
            children: [
              Text(
                'Open issues',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          error: (_, __) => Row(
            children: [
              Text(
                'Open issues',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          data: (problems) => Row(
            children: [
              Expanded(
                child: Text(
                  'Open issues',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => openMobileFilters(problems),
                icon: Icon(Icons.tune, color: theme.textColor),
                label: Text(
                  'Filters',
                  style: TextStyle(color: theme.textColor),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.dashboardContainer,
                  side: BorderSide(color: theme.dashboardBoarder),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: issuesAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(
                color: colorScheme.onSurface,
              ),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Failed to load issues',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ),
            data: (issues) {
              if (issues.isEmpty) {
                return Center(
                  child: Text(
                    'No open issues for this screen',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                );
              }

              return ListView.separated(
                controller: scrollController,
                itemCount: issues.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final issue = issues[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      final nav = ref.read(navigationService);
                      final dialogContext =
                          nav.navigatorKey.currentContext ?? context;

                      onOpenIssue();

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!dialogContext.mounted) return;

                        showDialog(
                          context: dialogContext,
                          useRootNavigator: true,
                          builder: (_) => IssueDetailsDialog(issue: issue),
                        );
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.10),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (issue.image != null && issue.image!.isNotEmpty)
                            Container(
                              height: 140,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(
                                issue.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color:
                                    colorScheme.primary.withOpacity(0.18),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (issue.image != null && issue.image!.isNotEmpty)
                            const SizedBox(height: 10),
                          Text(
                            issue.title ?? 'Untitled issue',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            issue.description ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.75),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    if (isBottomSheet) {
      return Container(
        decoration: BoxDecoration(
          color: feedbackTheme.feedbackSheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.12)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: content,
          ),
        ),
      );
    }

    return Container(
      width: 300,
      height: 620,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: feedbackTheme.feedbackSheetColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.12)),
      ),
      child: content,
    );
  }
}

class _FeedbackLayoutDelegate extends MultiChildLayoutDelegate {
  _FeedbackLayoutDelegate({
    required this.displayFeedback,
    required this.query,
    required this.sheetFraction,
    required this.animationProgress,
    required this.isMobile,
  });

  final bool displayFeedback;
  final MediaQueryData query;
  final double sheetFraction;
  final double animationProgress;
  final bool isMobile;

  double get safeAreaHeight => query.padding.top;

  double get keyboardHeight => query.viewInsets.bottom;

  double get screenHeight => query.size.height;

  double get screenshotFraction =>
      1 - sheetFraction - (safeAreaHeight / screenHeight);

  double get screenshotHeight => screenshotFraction * screenHeight;

  @override
  void performLayout(Size size) {
    if (!displayFeedback) {
      layoutChild(_screenshotId, BoxConstraints.tight(size));
      positionChild(_screenshotId, Offset.zero);
      return;
    }

    final double availableHeight =
    math.max(0, size.height - query.viewInsets.bottom);

    Size issuesPanelSize = Size.zero;
    if (hasChild(_issuesPanelId)) {
      issuesPanelSize = layoutChild(
        _issuesPanelId,
        BoxConstraints.loose(
          Size(360, screenshotHeight),
        ),
      );
    }

    final Size controlsSize = layoutChild(
      _controlsColumnId,
      BoxConstraints.loose(
        Size(size.width, screenshotHeight),
      ),
    );

    if (isMobile) {
      final double horizontalPadding = 8;
      final double screenshotMaxWidth =
      math.max(120, size.width - (horizontalPadding * 2));
      final double screenshotMaxHeight = math.max(
        100,
        size.height - animationProgress * (size.height - screenshotHeight),
      );

      final Size screenShotSize = layoutChild(
        _screenshotId,
        BoxConstraints.tight(
          applyBoxFit(
            BoxFit.scaleDown,
            query.size,
            Size(
              screenshotMaxWidth,
              screenshotMaxHeight,
            ),
          ).destination,
        ),
      );

      positionChild(
        _screenshotId,
        Offset(
          (size.width - screenShotSize.width) / 2,
          animationProgress * safeAreaHeight,
        ),
      );

      positionChild(
        _controlsColumnId,
        Offset(
          math.max(0, size.width - controlsSize.width - 8),
          safeAreaHeight + 8,
        ),
      );

      final double sheetHeight = layoutChild(
        _sheetId,
        BoxConstraints.loose(
          Size(
            size.width,
            availableHeight,
          ),
        ),
      ).height;

      positionChild(
        _sheetId,
        Offset(
          0,
          size.height -
              animationProgress * (sheetHeight + query.viewInsets.bottom),
        ),
      );

      return;
    }

    final double leftPanelSpacing = -180;
    final double reservedLeftWidth = hasChild(_issuesPanelId)
        ? animationProgress * (issuesPanelSize.width + leftPanelSpacing)
        : 0;

    final double screenshotAvailableWidth = math.max(
      120,
      size.width - reservedLeftWidth - animationProgress * controlsSize.width,
    );

    final Size screenShotSize = layoutChild(
      _screenshotId,
      BoxConstraints.tight(
        applyBoxFit(
          BoxFit.scaleDown,
          query.size,
          Size(
            screenshotAvailableWidth - 20,
            math.max(
              100,
              size.height -
                  animationProgress * (size.height - screenshotHeight),
            ),
          ),
        ).destination,
      ),
    );

    final double remainingWidth = math.max(
      0,
      query.size.width - screenShotSize.width - controlsSize.width,
    );

    if (hasChild(_issuesPanelId)) {
      positionChild(
        _issuesPanelId,
        Offset(
          animationProgress * 5,
          safeAreaHeight + (screenshotHeight - issuesPanelSize.height) / 2,
        ),
      );
    }

    positionChild(
      _screenshotId,
      Offset(
        reservedLeftWidth + animationProgress * remainingWidth / 2,
        animationProgress * safeAreaHeight,
      ),
    );

    positionChild(
      _controlsColumnId,
      Offset(
        size.width -
            animationProgress *
                (controlsSize.width + remainingWidth / 2 - 130),
        safeAreaHeight + (screenshotHeight - controlsSize.height) / 2,
      ),
    );

    final double sheetHeight = layoutChild(
      _sheetId,
      BoxConstraints.loose(
        Size(
          size.width,
          availableHeight,
        ),
      ),
    ).height;

    positionChild(
      _sheetId,
      Offset(
        0,
        size.height -
            animationProgress * (sheetHeight + query.viewInsets.bottom),
      ),
    );
  }

  @override
  bool shouldRelayout(covariant _FeedbackLayoutDelegate oldDelegate) {
    return query != oldDelegate.query ||
        sheetFraction != oldDelegate.sheetFraction ||
        animationProgress != oldDelegate.animationProgress ||
        isMobile != oldDelegate.isMobile;
  }
}

class MembersDropdown extends ConsumerStatefulWidget {
  const MembersDropdown({super.key});

  @override
  ConsumerState<MembersDropdown> createState() => MembersDropdownState();
}

class MembersDropdownState extends ConsumerState<MembersDropdown> {
  final GlobalKey _anchorKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final user = ref.read(userProvider).value;
      final selected = ref.read(selectedMemberIdsProvider);

      if (user != null && selected == null) {
        ref.read(selectedMemberIdsProvider.notifier).state =
            user.companyMembers.map((m) => m.id).toSet();
      }
    });
  }

  String _tooltipFor(dynamic m) {
    final first = (m.firstName ?? '').toString();
    final last = (m.lastName ?? '').toString();
    final id = (m.id ?? '').toString();
    final parts = <String>[];
    final full =
    [first, last].where((s) => s.trim().isNotEmpty).join(' ').trim();
    if (full.isNotEmpty) parts.add('Name: $full');
    if (id.isNotEmpty) parts.add('ID: $id');
    return parts.isEmpty ? 'Member' : parts.join('\n');
  }

  void _openMenu() {
    final theme = ref.read(themeColorsProvider);
    final box = _anchorKey.currentContext!.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final offset = box.localToGlobal(Offset.zero, ancestor: overlay);
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(offset.dx, offset.dy + box.size.height, box.size.width, 0),
      Offset.zero & overlay.size,
    );

    showMenu<void>(
      context: context,
      position: position,
      color: theme.textFieldColor,
      items: [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: 260,
            child: _MembersMenu(buildTooltip: _tooltipFor),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final user = ref.watch(userProvider).value;
    final selected = ref.watch(selectedMemberIdsProvider);

    if (user == null) return const SizedBox.shrink();

    final current = selected ?? const <int>{};
    final selectedMembers =
    user.companyMembers.where((m) => current.contains(m.id)).toList();

    const double avatarDiameter = 24;
    const double step = 16;
    const int maxAvatars = 3;
    final show = selectedMembers.take(maxAvatars).toList();
    final overflowCount = math.max(0, selectedMembers.length - show.length);

    final double width = show.isEmpty
        ? 40
        : avatarDiameter +
        (show.length - 1) * step +
        (overflowCount > 0 ? 22 : 0);

    final lines = <String>[];
    for (final m in show) {
      lines.add(_tooltipFor(m));
      lines.add('');
    }
    if (overflowCount > 0) lines.add('+$overflowCount more selected');
    final tooltip = lines.join('\n').trim();

    return Tooltip(
      message: tooltip.isEmpty ? 'Members' : tooltip,
      waitDuration: const Duration(milliseconds: 300),
      showDuration: const Duration(seconds: 8),
      textStyle: TextStyle(color: theme.themeTextColor),
      decoration: BoxDecoration(
        color: theme.themeColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
      ),
      preferBelow: false,
      child: GestureDetector(
        key: _anchorKey,
        behavior: HitTestBehavior.translucent,
        onTap: _openMenu,
        child: SizedBox(
          height: avatarDiameter,
          width: width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < show.length; i++)
                Positioned(
                  right: i * step.toDouble(),
                  child: _AvatarRing(
                    member: show[i],
                    tooltip: _tooltipFor(show[i]),
                  ),
                ),
              if (show.isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Members',
                    style: TextStyle(color: theme.textColor, fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarRing extends ConsumerWidget {
  final dynamic member;
  final String tooltip;
  const _AvatarRing({required this.member, required this.tooltip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final String? imageUrl =
    (member.avatar is String && (member.avatar as String).isNotEmpty)
        ? member.avatar as String
        : null;
    final initials = (() {
      final f = (member.firstName ?? '').toString();
      final l = (member.lastName ?? '').toString();
      return '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'
          .toUpperCase();
    })();

    final avatar = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.dashboardContainer,
      ),
      padding: const EdgeInsets.all(1.5),
      child: CircleAvatar(
        radius: 12,
        backgroundColor: theme.dashboardBoarder,
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
        child: imageUrl == null
            ? Text(
          initials,
          style: TextStyle(fontSize: 10, color: theme.textColor),
        )
            : null,
      ),
    );

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 250),
      showDuration: const Duration(seconds: 8),
      textStyle: TextStyle(color: theme.themeTextColor),
      decoration: BoxDecoration(
        color: theme.themeColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
      ),
      child: avatar,
    );
  }
}

class _MembersMenu extends ConsumerWidget {
  const _MembersMenu({required this.buildTooltip});
  final String Function(dynamic member) buildTooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final user = ref.watch(userProvider).value;
    final selected = ref.watch(selectedMemberIdsProvider) ?? <int>{};

    if (user == null) return const SizedBox.shrink();

    final allIds = user.companyMembers.map((m) => m.id).toSet();
    final allSelected = selected.isNotEmpty && selected.length == allIds.length;

    void toggleAll(bool value) {
      ref.read(selectedMemberIdsProvider.notifier).state =
      value ? allIds : <int>{};
    }

    void toggleOne(int id, bool value) {
      final curr = ref.read(selectedMemberIdsProvider) ?? <int>{};
      final next = <int>{...curr};
      value ? next.add(id) : next.remove(id);
      ref.read(selectedMemberIdsProvider.notifier).state = next;
    }

    return Material(
      color: theme.textFieldColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: theme.themeColor,
            checkColor: theme.themeTextColor,
            title: Text(
              'Select all',
              style: TextStyle(color: theme.textColor),
            ),
            value: allSelected,
            onChanged: (v) => toggleAll(v ?? false),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: user.companyMembers.length,
              itemBuilder: (context, i) {
                final m = user.companyMembers[i];
                final isOn = selected.contains(m.id);
                final initials = (() {
                  final f = (m.firstName).toString();
                  final l = (m.lastName).toString();
                  return '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'
                      .toUpperCase();
                })();

                final row = CheckboxListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: theme.themeColor,
                  checkColor: theme.themeTextColor,
                  value: isOn,
                  onChanged: (v) => toggleOne(m.id, v ?? false),
                  title: Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: theme.dashboardBoarder,
                        backgroundImage:
                        (m.avatar != null &&
                            (m.avatar as String).isNotEmpty)
                            ? NetworkImage(m.avatar as String)
                            : null,
                        child: (m.avatar == null || (m.avatar as String).isEmpty)
                            ? Text(
                          initials,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textColor,
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${m.firstName} ${m.lastName}'.trim(),
                          style: TextStyle(color: theme.textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );

                return Tooltip(
                  message: buildTooltip(m),
                  waitDuration: const Duration(milliseconds: 250),
                  showDuration: const Duration(seconds: 10),
                  textStyle: TextStyle(color: theme.themeTextColor),
                  decoration: BoxDecoration(
                    color: theme.themeColor.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  preferBelow: false,
                  child: row,
                );
              },
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}