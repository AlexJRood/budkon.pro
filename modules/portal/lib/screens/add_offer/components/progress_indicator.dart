import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';

final progressProvider = StateProvider<double>((ref) => 0.5);

/// Najdalszy krok, na którym user już był.
final maxVisitedStepProvider = StateProvider<int>((ref) => 0);



int progressToPageIndex(double progress, int pageCount) {
  final rawIndex = (progress - 0.5).floor();
  if (rawIndex < 0) return 0;
  if (rawIndex >= pageCount) return pageCount - 1;
  return rawIndex;
}

double pageIndexToProgress(int pageIndex) => pageIndex + 0.5;

class ProgressIndicatorWidget extends ConsumerWidget {
  const ProgressIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<String> steps = [
      "Choose the property type".tr,
      "Basic information".tr,
      "General information".tr,
      "Details Information".tr,
      "Plan for add".tr,
      "Confirm ad".tr,
    ];
    final currentStep = ref.watch(progressProvider);
    final maxVisitedStep = ref.watch(maxVisitedStepProvider);

    final currentPageIndex = progressToPageIndex(currentStep, steps.length);
    final isHalfStep = (currentStep % 1) == 0.5;
    final screenWidth = MediaQuery.of(context).size.width;
    final dynamicPadding = screenWidth / 7;
    final isMobile = screenWidth < 700;

    if (currentPageIndex > maxVisitedStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final latestMaxVisited = ref.read(maxVisitedStepProvider);
        if (currentPageIndex > latestMaxVisited) {
          ref.read(maxVisitedStepProvider.notifier).state = currentPageIndex;
        }
      });
    }

    void goToStep(int index) {
      final allowedMax = ref.read(maxVisitedStepProvider);
      if (index <= allowedMax) {
        ref.read(progressProvider.notifier).state = pageIndexToProgress(index);
      }
    }

    final activeTextColor = CustomColors.secondaryWidgetTextColor(context, ref);
    final inactiveTextColor = activeTextColor.withAlpha(153);

    const completedColor = Colors.greenAccent;
    final visitedColor = Colors.greenAccent.withAlpha(128);
    final notVisitedColor = Colors.grey.withAlpha(128);

    if (isMobile) {
      return Material(
        color: Colors.transparent,
        child: Container(
          color: CustomColors.secondaryWidgetColor(context, ref),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${"Step".tr} ${currentPageIndex + 1} ${"of".tr} ${steps.length}',
                style: TextStyle(
                  color: inactiveTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                steps[currentPageIndex],
                style: TextStyle(
                  color: activeTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: List.generate(steps.length * 2 - 1, (index) {
                  if (index % 2 == 0) {
                    final circleIndex = index ~/ 2;
                    final canNavigate = circleIndex <= maxVisitedStep;

                    final isCompleted =
                        circleIndex < currentPageIndex ||
                            (circleIndex == currentPageIndex && isHalfStep);

                    final isVisitedOnly =
                        !isCompleted && circleIndex <= maxVisitedStep;

                    final isCurrent = circleIndex == currentPageIndex;

                    return GestureDetector(
                      onTap: canNavigate ? () => goToStep(circleIndex) : null,
                      child: Container(
                        width: isCurrent ? 18 : 16,
                        height: isCurrent ? 18 : 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? completedColor
                              : isVisitedOnly
                              ? visitedColor
                              : Colors.transparent,
                          border: Border.all(
                            color: isCompleted || isVisitedOnly
                                ? completedColor
                                : notVisitedColor,
                            width: isCurrent ? 2.5 : 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(
                          Icons.check,
                          size: 10,
                          color: Colors.black,
                        )
                            : null,
                      ),
                    );
                  } else {
                    final lineIndex = index ~/ 2;
                    final isLineCompleted = lineIndex < currentPageIndex;
                    final isLineVisited = lineIndex < maxVisitedStep;

                    if (lineIndex == currentPageIndex && isHalfStep) {
                      return Expanded(
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: 2,
                              color: notVisitedColor,
                            ),
                            FractionallySizedBox(
                              widthFactor: 0.5,
                              child: Container(
                                height: 2,
                                color: completedColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Expanded(
                      child: Container(
                        height: 2,
                        color: isLineCompleted
                            ? completedColor
                            : isLineVisited
                            ? visitedColor
                            : notVisitedColor,
                      ),
                    );
                  }
                }),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 100,
        color: CustomColors.secondaryWidgetColor(context, ref),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: dynamicPadding * 0.5),
              child: Row(
                children: List.generate(steps.length, (index) {
                  final isCurrent = index == currentPageIndex;
                  final canNavigate = index <= maxVisitedStep;
                  final isVisited = index <= maxVisitedStep;

                  return Expanded(
                    child: MouseRegion(
                      cursor: canNavigate
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      child: GestureDetector(
                        onTap: canNavigate ? () => goToStep(index) : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            steps[index],
                            style: TextStyle(
                              color: isVisited
                                  ? activeTextColor
                                  : inactiveTextColor,
                              fontSize: 12,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              decoration: canNavigate
                                  ? TextDecoration.underline
                                  : null,
                              decorationColor: canNavigate
                                  ? activeTextColor.withAlpha(180)
                                  : null,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: dynamicPadding),
              child: Row(
                children: List.generate(steps.length * 2 - 1, (index) {
                  if (index % 2 == 0) {
                    final circleIndex = index ~/ 2;
                    final canNavigate = circleIndex <= maxVisitedStep;

                    final isCompleted =
                        circleIndex < currentPageIndex ||
                            (circleIndex == currentPageIndex && isHalfStep);

                    final isVisitedOnly =
                        !isCompleted && circleIndex <= maxVisitedStep;

                    return MouseRegion(
                      cursor: canNavigate
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      child: GestureDetector(
                        onTap: canNavigate ? () => goToStep(circleIndex) : null,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? completedColor
                                : isVisitedOnly
                                ? visitedColor
                                : Colors.transparent,
                            border: isVisitedOnly
                                ? Border.all(
                              color: completedColor,
                              width: 2,
                            )
                                : (!canNavigate
                                ? Border.all(
                              color: notVisitedColor,
                              width: 2,
                            )
                                : null),
                          ),
                        ),
                      ),
                    );
                  } else {
                    final lineIndex = index ~/ 2;

                    final isLineCompleted = lineIndex < currentPageIndex;
                    final isLineVisited = lineIndex < maxVisitedStep;

                    if (lineIndex == currentPageIndex && isHalfStep) {
                      return Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: notVisitedColor,
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: 0.5,
                              child: Container(
                                height: 2,
                                decoration: const BoxDecoration(
                                  color: completedColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Expanded(
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: isLineCompleted
                                ? completedColor
                                : isLineVisited
                                ? visitedColor
                                : notVisitedColor,
                          ),
                        ),
                      );
                    }
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}