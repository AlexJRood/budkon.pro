import 'package:core/ui/device_type_util.dart';
import 'package:cloud/api/add_folder.dart';
import 'package:cloud/components/drag_n_drop.dart';
import 'package:cloud/explorer.dart';
import 'package:cloud/models/query_params.dart';
import 'package:cloud/providers/providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crm/contact_panel/tabs/transactions/transaction_view.dart';
import 'package:crm/contact_panel/tabs/transactions/view_provider.dart';
import 'package:crm/crm/clients/components/transaction_document_pipeline_widget.dart';
import 'package:crm/crm/clients/components/transaction_kw_widget.dart';
import 'package:crm/widget/your_agent_manage_tab.dart';

import 'package:crm/widget/fav_client.dart';
import 'package:crm/widget/pro_draft_detail_view_widget.dart';
import 'package:crm/widget/pro_draft_note_widget.dart';
import 'package:crm/widget/viewer_client.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

enum TransactionViewMode {
  draft,
  note,
  details,
  detailsDraft,
  search,
  docs,
  fav,
  viewer,
  yourAgent,
}

enum TransactionType { create, sell, buy }

class SelectedTransactionView extends ConsumerWidget {
  final int? clientId;
  final AgentTransactionModel transaction;
  final TransactionType type;
  final bool isMobile;

  const SelectedTransactionView({
    super.key,
    this.clientId,
    this.isMobile = false,
    required this.transaction,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(viewModeControllerProvider(type));
    final mode = vm.selected;

    switch (mode) {
      case TransactionViewMode.search:
        if (type == TransactionType.sell || type == TransactionType.create) {
          return TransactionViewSeller(
            transaction: transaction,
            isMobile: isMobile,
          );
        } else if (type == TransactionType.buy) {
          return TransactionViewBuyer(
            clientId: clientId!,
            isMobile: isMobile,
            transaction: transaction,
          );
        } else {
          return Center(child: Text('creating_new_transaction'.tr));
        }

      case TransactionViewMode.draft:
        return TransactionViewSeller(
          transaction: transaction,
          isMobile: isMobile,
        );

      case TransactionViewMode.details:
        return ProDraftDetailViewWidget(
          transaction: transaction,
          isMobile: isMobile,
        );

      case TransactionViewMode.detailsDraft:
        return ProDraftDetailViewWidget(
          transaction: transaction,
          isMobile: isMobile,
        );

      case TransactionViewMode.note:
        return ProDraftNoteWidget(
          transaction: transaction,
          isMobile: isMobile,
        );

      case TransactionViewMode.docs:
        return _TransactionDocsView(transaction: transaction, isMobile: isMobile);

      case TransactionViewMode.fav:
        return FavClientView(
          clientId: clientId!,
          transaction: transaction,
          isMobile: isMobile,
        );

      case TransactionViewMode.viewer:
        return ViewerClientView(
          clientId: clientId!,
          transaction: transaction,
          isMobile: isMobile,
        );

      case TransactionViewMode.yourAgent:
        return YourAgentManageTab(
          transaction: transaction,
          isMobile: isMobile,
        );
    }
    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------------
// Docs view — osobny widget żeby mieć dostęp do BuildContext dla paddings
// ---------------------------------------------------------------------------

class _TransactionDocsView extends ConsumerWidget {
  final AgentTransactionModel transaction;
  final bool isMobile;

  const _TransactionDocsView({
    required this.transaction,
    required this.isMobile,
  });

  FolderQueryParams get _params => FolderQueryParams(
        appLabel: 'estate_agent',
        model: 'agenttransaction',
        objectId: transaction.id.toString(),
        additionalSection: 'assigned',
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = isMobile ? TopAppBarSize.resolve(context) : 0.0;

    final pipeline = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TransactionDocumentPipelineWidget(
        transactionId: transaction.id,
        transactionType: transaction.transactionType,
      ),
    );

    if (isMobile) {
      // Single scroll for the whole tab: pipeline + explorer scroll together
      // instead of the explorer owning its own independent scroll region.
      return SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: topPadding),
            pipeline,
            const Divider(height: 1),
            CloudExplorer(
              isClient: true,
              isMobile: isMobile,
              params: _params,
              shrinkWrap: true,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(height: topPadding),
        pipeline,
        const Divider(height: 1),
        Expanded(
          child: CloudExplorer(
            isClient: true,
            isMobile: isMobile,
            params: _params,
          ),
        ),
      ],
    );
  }
}

/// Vertical button do uploadu pliku — używany w [ClientPanelVerticalButtons]
/// kiedy aktywny tryb to [TransactionViewMode.docs].
class TransactionDocsUploadFileButton extends ConsumerWidget {
  const TransactionDocsUploadFileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final params = ref.read(clientExplorerParamsProvider);

    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        color: theme.textFieldColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () async {
          final result = await FilePicker.platform.pickFiles(
            allowMultiple: true,
            withData: true,
          );
          if (result == null) return;

          final extra = UploadExtra(
            folderId: params.parent,
            appLabel: params.appLabel,
            model: params.model,
            objectId: params.objectId,
            relationType: params.relationType,
          );

          final notifier = ref.read(uploadQueueProvider.notifier);
          for (final f in result.files) {
            notifier.addFile(f, extra: extra);
          }

          if (context.mounted) showFileUploadOverlay(context, ref);
        },
        child: Icon(Icons.upload_file_outlined, color: theme.textColor, size: 22),
      ),
    );
  }
}

/// Vertical button do dodawania folderu — używany w [ClientPanelVerticalButtons]
/// kiedy aktywny tryb to [TransactionViewMode.docs].
class TransactionDocsAddFolderButton extends ConsumerWidget {
  const TransactionDocsAddFolderButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final params = ref.read(clientExplorerParamsProvider);

    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        color: theme.textFieldColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () => showAddFolderDialog(
          context,
          theme,
          isClient: true,
          appLabel: params.appLabel,
          model: params.model,
          objectId: params.objectId,
          relationType: params.relationType,
        ),
        child: Icon(Icons.create_new_folder_outlined, color: theme.textColor, size: 22),
      ),
    );
  }
}