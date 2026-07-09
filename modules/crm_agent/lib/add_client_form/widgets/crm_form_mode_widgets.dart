import 'package:crm_agent/add_client_form/widgets/crm_form_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

/// Pill-shaped toggle between full-form and steps mode.
class CrmModeToggle extends ConsumerWidget {
  final bool stepsEnabled;
  const CrmModeToggle({super.key, required this.stepsEnabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Tooltip(
      message: stepsEnabled ? 'full_form'.tr : 'step_by_step'.tr,
      child: GestureDetector(
        onTap: () {
          ref.read(crmFormStepsEnabledProvider.notifier).toggle();
          crmResetProgress(ref);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: stepsEnabled
                ? theme.themeColor
                : theme.themeColor.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            stepsEnabled ? Icons.view_agenda : Icons.view_stream,
            size: 18,
            color: stepsEnabled ? Colors.white : theme.themeColor,
          ),
        ),
      ),
    );
  }
}

/// "Dalej →" button — full-width, used as floating bar on mobile step 0.
class CrmStepNextButton extends StatelessWidget {
  final ThemeColors theme;
  final VoidCallback onNext;
  const CrmStepNextButton(
      {super.key, required this.theme, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onNext,
      icon: const Icon(Icons.arrow_forward, size: 18),
      label: Text('next'.tr),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.themeColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// Back / Next navigation row — used in left column of PC and Tablet.
class CrmStepNavRow extends ConsumerWidget {
  final int step;
  final ThemeColors theme;
  final bool isLastStep;
  const CrmStepNavRow({
    super.key,
    required this.step,
    required this.theme,
    this.isLastStep = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        if (step > 0)
          OutlinedButton.icon(
            onPressed: () => ref.read(crmProgressProvider.notifier).state -= 1,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: Text('back'.tr),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.textColor,
              side: BorderSide(color: theme.textColor.withAlpha(80)),
            ),
          ),
        const Spacer(),
        if (!isLastStep)
          ElevatedButton.icon(
            onPressed: () => ref.read(crmProgressProvider.notifier).state += 1,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: Text('next'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.themeColor,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}
