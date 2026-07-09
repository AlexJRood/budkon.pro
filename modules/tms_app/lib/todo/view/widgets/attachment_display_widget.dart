import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // ⬅️ add this
import 'package:core/theme/apptheme.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';
import 'package:tms_app/todo/view/widgets/section_header_widget.dart';

import 'body_fields_widget.dart';

class AttachmentDisplay extends StatelessWidget {
  final WidgetRef ref;
  final String taskId;

  const AttachmentDisplay({super.key, required this.ref, required this.taskId});

  /// Formats ISO timestamp to dd/MM/yyyy (day/month/year).
  /// Falls back to raw string when parsing fails.
  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd/MM/yyyy').format(dt);
      // If you really want a dot after the month (dd/MM./yyyy), use:
      // return DateFormat('dd/MM./yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachments = ref.watch(taskDetailsProvider).last.files;
    final isUploading = ref.watch(taskDetailsProvider.notifier).isLoading;
    final theme = ref.read(themeColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BodyFields(
          ref: ref,
          headerIcon: Icons.attachment,
          action: () async {
            await ref.read(taskDetailsProvider.notifier).addFileToTask(taskId);
          },
          buttonLabel: isUploading ? 'Uploading'.tr : 'Add'.tr,
          header: SectionHeader('Attachments'.tr, theme: theme),
          field: Text(
            (attachments != null && attachments.isNotEmpty)
                ? '${attachments.length} attachment(s) available.'
                : 'No attachments available.'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: theme.textColor,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(minHeight: 100, maxHeight: 300),
          child: (attachments != null && attachments.isNotEmpty)
              ? ListView.builder(
            addAutomaticKeepAlives: false,
            cacheExtent: 300.0,
            shrinkWrap: true,
            itemCount: attachments.length,
            itemBuilder: (context, index) {
              final file = attachments[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    if (file.file != null && file.file!.isNotEmpty)
                      Container(
                        width: 200,
                        height: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.textColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            file.file!,
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (file.filename != null &&
                              file.filename!.isNotEmpty)
                            Text(
                              file.filename!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: theme.textColor),
                            ),
                          Text(
                            _formatDate(file.timestamp), // ⬅️ formatted
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: theme.textColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          )
              : Center(
            child: Text(
              'No attachments to display.'.tr,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: theme.textColor),
            ),
          ),
        ),
      ],
    );
  }
}
