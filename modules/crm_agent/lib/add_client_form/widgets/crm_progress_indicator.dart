import 'package:crm_agent/add_client_form/widgets/crm_form_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';

class CrmProgressIndicatorWidget extends ConsumerWidget {
  final List<String> stepLabels;

  const CrmProgressIndicatorWidget({
    super.key,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(crmProgressProvider);
    final maxVisited = ref.watch(crmMaxVisitedStepProvider);
    final theme = ref.watch(themeColorsProvider);

    final currentStep = crmProgressToStep(progress);
    final isHalfStep = (progress % 1) == 0.5;
    final isMobile = MediaQuery.of(context).size.width < 700;

    // Update maxVisited when user advances
    if (currentStep > maxVisited) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (currentStep > ref.read(crmMaxVisitedStepProvider)) {
          ref.read(crmMaxVisitedStepProvider.notifier).state = currentStep;
        }
      });
    }

    void goToStep(int index) {
      if (index <= ref.read(crmMaxVisitedStepProvider)) {
        ref.read(crmProgressProvider.notifier).state = crmStepToProgress(index);
      }
    }

    final activeColor = theme.themeColor;
    final completedColor = theme.themeColor;
    final visitedColor = theme.themeColor.withAlpha(120);
    final notVisitedColor = theme.textColor.withAlpha(60);
    final activeTextColor = theme.textColor;
    final inactiveTextColor = theme.textColor.withAlpha(140);

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Text(
              stepLabels[currentStep],
              style: TextStyle(
                color: activeTextColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _StepRow(
              stepCount: stepLabels.length,
              currentStep: currentStep,
              isHalfStep: isHalfStep,
              maxVisited: maxVisited,
              activeColor: activeColor,
              completedColor: completedColor,
              visitedColor: visitedColor,
              notVisitedColor: notVisitedColor,
              onTap: goToStep,
              bigCircle: true,
            ),
          ],
        ),
      );
    }

    // Desktop / tablet
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step labels
          Row(
            children: List.generate(stepLabels.length, (i) {
              final canNavigate = i <= maxVisited;
              final isCurrent = i == currentStep;
              return Expanded(
                child: MouseRegion(
                  cursor: canNavigate
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: GestureDetector(
                    onTap: canNavigate ? () => goToStep(i) : null,
                    child: Text(
                      stepLabels[i],
                      style: TextStyle(
                        color: canNavigate ? activeTextColor : inactiveTextColor,
                        fontSize: 12,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        decoration:
                            canNavigate ? TextDecoration.underline : null,
                        decorationColor: canNavigate
                            ? activeTextColor.withAlpha(180)
                            : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          _StepRow(
            stepCount: stepLabels.length,
            currentStep: currentStep,
            isHalfStep: isHalfStep,
            maxVisited: maxVisited,
            activeColor: activeColor,
            completedColor: completedColor,
            visitedColor: visitedColor,
            notVisitedColor: notVisitedColor,
            onTap: goToStep,
            bigCircle: false,
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int stepCount;
  final int currentStep;
  final bool isHalfStep;
  final int maxVisited;
  final Color activeColor;
  final Color completedColor;
  final Color visitedColor;
  final Color notVisitedColor;
  final void Function(int) onTap;
  final bool bigCircle;

  const _StepRow({
    required this.stepCount,
    required this.currentStep,
    required this.isHalfStep,
    required this.maxVisited,
    required this.activeColor,
    required this.completedColor,
    required this.visitedColor,
    required this.notVisitedColor,
    required this.onTap,
    required this.bigCircle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(stepCount * 2 - 1, (index) {
        if (index % 2 == 0) {
          final ci = index ~/ 2;
          final canNavigate = ci <= maxVisited;
          final isCompleted = ci < currentStep ||
              (ci == currentStep && isHalfStep);
          final isVisitedOnly = !isCompleted && ci <= maxVisited;
          final isCurrent = ci == currentStep;
          final size = (bigCircle && isCurrent) ? 20.0 : 16.0;

          return GestureDetector(
            onTap: canNavigate ? () => onTap(ci) : null,
            child: Container(
              width: size,
              height: size,
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
                  ? Icon(
                      Icons.check,
                      size: size * 0.6,
                      color: Colors.white,
                    )
                  : null,
            ),
          );
        } else {
          final li = index ~/ 2;
          final isLineCompleted = li < currentStep;
          final isLineVisited = li < maxVisited;

          if (li == currentStep && isHalfStep) {
            return Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(height: 2, color: notVisitedColor),
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(height: 2, color: completedColor),
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
    );
  }
}
