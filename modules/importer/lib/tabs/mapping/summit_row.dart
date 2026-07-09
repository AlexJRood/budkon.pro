


// lib/importer/tabs/mapping/summit_row.dart
import 'package:flutter/material.dart';
// TextSelection
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:importer/import_state.dart';
import 'package:core/theme/apptheme.dart';







// ========================
// Submit row
// ========================

class SubmitRow extends StatelessWidget {
  final ThemeColors theme;
  final ImportFormState formState;
  final ImportFormNotifier formNotifier;
  final WidgetRef ref;

  const SubmitRow({
    required this.theme,
    required this.formState,
    required this.formNotifier,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        if (formState.error != null)
          Padding(
            padding:
                const EdgeInsets.only(bottom: 8.0),
            child: Text(
              formState.error!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (formState.lastMessage != null)
          Padding(
            padding:
                const EdgeInsets.only(bottom: 8.0),
            child: Text(
              formState.lastMessage!,
              style: TextStyle(
                color: Colors.greenAccent.shade200,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (formState.isSubmitting)
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: formState.uploadProgress ==
                            0
                        ? null
                        : formState.uploadProgress,
                    minHeight: 6,
                    backgroundColor:
                        theme.textColor
                            .withAlpha(26),
                  ),
                ),
              ),
            if (formState.isSubmitting)
              const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: formState.isSubmitting
                  ? null
                  : () async {
                      await formNotifier
                          .submit(ref);
                    },
              icon: formState.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.play_arrow_rounded, color: theme.textColor),
              label: Text('Start importu'.tr, style: TextStyle(color: theme.textColor)),
            ),
          ],
        ),
        if (formState.lastJobId != null)
          Padding(
            padding:
                const EdgeInsets.only(top: 8.0),
            child: Text(
              'Ostatnie ID zadania: ${formState.lastJobId}',
              style: TextStyle(
                color: theme.textColor
                    .withAlpha(178),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
