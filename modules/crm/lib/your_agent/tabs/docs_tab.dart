import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';





class DocumentsTab extends ConsumerWidget {
  final List<dynamic> documents;

  const DocumentsTab({required this.documents});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    if (documents.isEmpty) {
      return Center(
        child: Text(
          'no_documents_message'.tr,
          style: TextStyle(color: theme.textColor),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final doc = documents[i];
        final label = (doc is Map && doc['label'] != null)
            ? doc['label'].toString()
            :'${'document_default_label'.tr} ${i + 1}';
        final url = (doc is Map && doc['url'] != null)
            ? doc['url'].toString()
            : null;

        return Card(
          color: theme.dashboardContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.dashboardBoarder),
          ),
          child: ListTile(
            leading: AppIcons.document(color: theme.textColor),
            title: Text(
              label,
              style: TextStyle(color: theme.textColor),
            ),
            subtitle: url != null
                ? Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.interLight10
                        .copyWith(color: theme.textColor),
                  )
                : null,
            onTap: url == null
                ? null
                : () {
                    // otwórz w nowej karcie / URL launcher
                    // ref.read(navigationService).openExternal(url);
                  },
          ),
        );
      },
    );
  }
}
