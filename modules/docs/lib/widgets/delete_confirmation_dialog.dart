
import 'package:docs/api/cloud_docs_service.dart';
import 'package:docs/emma/anchors/docs_emma_anchors.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:docs/provider/cloud_doc_provider.dart';


class DeleteConfirmationDialog extends ConsumerWidget {
  final String itemType; 
  final String itemId;
  final String itemName;
  final VoidCallback? onDeleted;

  const DeleteConfirmationDialog({
    super.key,
    required this.itemType,
    required this.itemId,
    required this.itemName,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final isLoading = ref.watch(documentLoadingProvider);

    return EmmaUiAnchorTarget(
       anchorKey: DocsEmmaAnchors.deleteConfirmationDialog.anchorKey,

       spec: DocsEmmaAnchors.deleteConfirmationDialog,
       runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
       tapMode: EmmaUiAnchorTapMode.disabled,
      child: AlertDialog(
        backgroundColor: theme.dashboardContainer,
        title: Text(
          'Delete $itemType',
          style: TextStyle(color: theme.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this $itemType?',
              style: TextStyle(color: theme.textColor),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.dashboardContainer.withAlpha(51),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: theme.bordercolor),
              ),
              child: Text(
                itemName,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          EmmaUiAnchorTarget(
             anchorKey: DocsEmmaAnchors.cancelDeleteButton.anchorKey,

             spec: DocsEmmaAnchors.cancelDeleteButton,
             runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
             tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
            child: TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.textColor),
              ),
            ),
          ),
          EmmaUiAnchorTarget(
             anchorKey: DocsEmmaAnchors.confirmDeleteButton.anchorKey,

             spec: DocsEmmaAnchors.confirmDeleteButton,
             runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
             tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                try {
                  if (itemType == 'document') {
                    await DocumentService.deleteDocument(
                      documentId: itemId,
                      ref: ref,
                    );
                  } else {
                    await DocumentService.deleteTemplate(
                      templateId: itemId,
                      ref: ref,
                    );
                  }
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$itemType deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  
                    onDeleted?.call();
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete $itemType: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.themeColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(6))
              ),
              child: isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.textColor,
                ),
              )
                  : Text('Delete', style: TextStyle(color: theme.themeColorText),),
            ),
          ),
        ],
      ),
    );
  }
}