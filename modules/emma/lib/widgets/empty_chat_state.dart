import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:get/get_utils/get_utils.dart';

import 'send_message_box.dart';
import 'package:emma/provider/emma_provider.dart';
import 'package:emma/provider/send_message_box_provider.dart';



class EmptyChatState extends ConsumerWidget {
  const EmptyChatState({super.key});


    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final theme = ref.watch(themeColorsProvider);
      final boot = ref.watch(emmaChatBootstrappingProvider);

      void focusInput() {
        try {
          final focusNode = ref.read(emmaChatInputFocusNodeProvider);

          FocusScope.of(context).requestFocus(focusNode);
          focusNode.requestFocus();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            focusNode.requestFocus();
          });

          Future.delayed(const Duration(milliseconds: 60), () {
            focusNode.requestFocus();
          });
        } catch (_) {}
      }

      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => focusInput(),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: focusInput,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'where_do_we_start'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    boot
                      ? 'creating_chat_and_connecting_to_emma'.tr
                      : 'write_first_message_to_create_chat'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(170),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (boot) ...[
                    _SkeletonList(theme: theme),
                    const SizedBox(height: 18),
                  ] else ...[
                    const SizedBox(height: 8),
                  ],
                  const SendMessageBox(centerMode: true),
                  
                    const SizedBox(height: 68),
                ],
              ),
            ),
          ),
        ),
      );
    }
}

class _SkeletonList extends StatelessWidget {
  final ThemeColors theme;
  const _SkeletonList({required this.theme});

  @override
  Widget build(BuildContext context) {
    Widget line(double w) => Container(
          height: 14,
          width: w,
          decoration: BoxDecoration(
            color: theme.textColor.withAlpha(35),
            borderRadius: BorderRadius.circular(8),
          ),
        );

    Widget bubble({required bool right}) => Align(
          alignment: right ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            width: right ? 320 : 360,
            decoration: BoxDecoration(
              color: theme.textColor.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                line(right ? 240 : 260),
                const SizedBox(height: 10),
                line(right ? 200 : 300),
              ],
            ),
          ),
        );

    return Column(
      children: [
        bubble(right: true),
        bubble(right: false),
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                'loading'.tr,
                style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
