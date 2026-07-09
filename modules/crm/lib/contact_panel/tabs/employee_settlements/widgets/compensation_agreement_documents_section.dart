import "package:cloud/explorer.dart";
import "package:cloud/models/file.dart";
import "package:cloud/models/query_params.dart";
import "package:cloud/providers/providers.dart";
import "package:cloud/widgets/file_viewer.dart";
import "package:crm/contact_panel/tabs/employee_settlements/provider/employee_settlement_dashboard_provider.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:get/get_utils/get_utils.dart";
import "package:pie_menu/pie_menu.dart";
import "package:core/theme/apptheme.dart";
import "package:core/theme/text_field.dart";
import "package:get/get.dart";

const List<String> compensationAgreementDocumentTypes = [
  "compensation_agreement_contract",
  "compensation_agreement_annex",
  "compensation_agreement_nda",
  "compensation_agreement_termination",
  "compensation_agreement_other",
];

Future<void> showCompensationAgreementDocumentsDialog({
  required BuildContext context,
  required CompensationAgreementModel agreement,
  bool isMobile = false,
}) {
  if (isMobile) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AgreementDocumentsSheet(
        agreement: agreement,
        isMobile: isMobile,
      ),
    );
  }

  return showDialog<void>(
    context: context,
    builder: (_) => _AgreementDocumentsDialog(
      agreement: agreement,
      isMobile: isMobile,
    ),
  );
}

class CompensationAgreementDocumentsSection
    extends ConsumerStatefulWidget {
  final CompensationAgreementModel? agreement;
  final bool isMobile;
  final bool embedded;

  const CompensationAgreementDocumentsSection({
    super.key,
    required this.agreement,
    this.isMobile = false,
    this.embedded = true,
  });

  @override
  ConsumerState<CompensationAgreementDocumentsSection> createState() =>
      _CompensationAgreementDocumentsSectionState();
}

class _CompensationAgreementDocumentsSectionState
    extends ConsumerState<CompensationAgreementDocumentsSection> {
  String _relationType = "compensation_agreement_contract";

  @override
  void initState() {
    super.initState();
    _relationType =
        widget.agreement?.documentBinding?.defaultRelationType ??
            "compensation_agreement_contract";
  }

  @override
  void didUpdateWidget(
    covariant CompensationAgreementDocumentsSection oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.agreement?.id != widget.agreement?.id) {
      _relationType =
          widget.agreement?.documentBinding?.defaultRelationType ??
              "compensation_agreement_contract";
    }
  }

  FolderQueryParams _params(
    CompensationDocumentBindingModel binding,
  ) {
    return FolderQueryParams(
      appLabel: binding.appLabel,
      model: binding.model,
      objectId: binding.objectId,
      relationType: _relationType,
      additionalSection: "assigned",
    );
  }

  @override
  Widget build(BuildContext context) {
    final agreement = widget.agreement;

    if (agreement == null) {
      return const _AgreementMustBeSavedCard();
    }

    final binding = agreement.documentBinding;
    if (binding == null || !binding.canView) {
      return const _NoAgreementDocumentAccessCard();
    }

    final params = _params(binding);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DocumentToolbar(
          relationType: _relationType,
          documentsCount: agreement.documentsCount,
          onChanged: (value) {
            setState(() => _relationType = value);
          },
          onOpenFullScreen: widget.embedded
              ? () {
                  showCompensationAgreementDocumentsDialog(
                    context: context,
                    agreement: agreement,
                    isMobile: widget.isMobile,
                  );
                }
              : null,
        ),
        const SizedBox(height: 12),
        Container(
          height: widget.embedded
              ? (widget.isMobile ? 430 : 360)
              : (widget.isMobile ? 620 : 560),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
          ),
          child: binding.canManage
              ? CloudExplorer(
                  key: ValueKey(
                    "agreement-documents-${agreement.id}-$_relationType",
                  ),
                  isMobile: widget.isMobile,
                  isClient: true,
                  params: params,
                )
              : _ReadOnlyAgreementDocumentsList(
                  params: params,
                  isMobile: widget.isMobile,
                ),
        ),
        const SizedBox(height: 10),
        _SecurityHint(canManage: binding.canManage),
      ],
    );
  }
}

class _ReadOnlyAgreementDocumentsList extends ConsumerWidget {
  final FolderQueryParams params;
  final bool isMobile;

  const _ReadOnlyAgreementDocumentsList({
    required this.params,
    required this.isMobile,
  });

  Future<void> _openFile(
    BuildContext context,
    CloudFile file,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => FileViewerDialog(
        file: file,
        isMobile: isMobile,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final asyncValue = ref.watch(
      clientFileExplorerProvider(params),
    );

    return asyncValue.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Text(
          error.toString(),
          style: TextStyle(color: theme.textColor),
        ),
      ),
      data: (response) {
        final files = response.files;

        if (files.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "agreement_documents_empty".tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textColor.withAlpha(145),
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(10),
          itemCount: files.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final file = files[index];

            return Material(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _openFile(context, file),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.dashboardBoarder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (file.mimeType?.toLowerCase().contains("pdf") ?? false)
                            ? Icons.picture_as_pdf_outlined
                            : Icons.description_outlined,
                        color: theme.themeColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.textColor,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              file.mimeType ?? "",
                              style: TextStyle(
                                color:
                                    theme.textColor.withAlpha(135),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.open_in_new_rounded,
                        color: theme.textColor.withAlpha(125),
                        size: 19,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}




class _AgreementDocumentsDialog extends ConsumerWidget {
  final CompensationAgreementModel agreement;
  final bool isMobile;

  const _AgreementDocumentsDialog({
    required this.agreement,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final size = MediaQuery.of(context).size;

    

    return PieCanvas(

      child: Dialog(
        insetPadding: EdgeInsets.all(isMobile ? 8 : 22),
        backgroundColor: theme.dashboardContainer,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: theme.dashboardBoarder),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 1120,
            maxHeight: size.height * 0.94,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 15, 10, 15),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dashboardBoarder,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_shared_outlined,
                      color: theme.themeColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            "agreement_documents".tr,
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            agreement.title,
                            style: TextStyle(
                              color:
                                  theme.textColor.withAlpha(145),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CoreIconButton(
                      icon: Icons.close_rounded,
                      onPressed: () =>
                          Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: CompensationAgreementDocumentsSection(
                    agreement: agreement,
                    isMobile: isMobile,
                    embedded: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgreementDocumentsSheet extends ConsumerWidget {
  final CompensationAgreementModel agreement;
  final bool isMobile;

  const _AgreementDocumentsSheet({
    required this.agreement,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return PieCanvas(
          child: Container(
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textColor.withAlpha(60),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 15, 10, 15),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dashboardBoarder,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_shared_outlined,
                        color: theme.themeColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              "agreement_documents".tr,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              agreement.title,
                              style: TextStyle(
                                color:
                                    theme.textColor.withAlpha(145),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CoreIconButton(
                        icon: Icons.close_rounded,
                        onPressed: () =>
                            Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: CompensationAgreementDocumentsSection(
                      agreement: agreement,
                      isMobile: isMobile,
                      embedded: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DocumentToolbar extends ConsumerWidget {
  final String relationType;
  final int documentsCount;
  final ValueChanged<String> onChanged;
  final VoidCallback? onOpenFullScreen;

  const _DocumentToolbar({
    required this.relationType,
    required this.documentsCount,
    required this.onChanged,
    required this.onOpenFullScreen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);


    
    String _agreementDocumentsCountLabel(int count) {
      final languageCode = Get.locale?.languageCode ?? "pl";

      if (languageCode != "pl") {
        return count == 1
            ? "agreement_documents_count_one".tr
            : "agreement_documents_count_many".tr;
      }

      if (count == 1) {
        return "agreement_documents_count_one".tr;
      }

      final lastDigit = count % 10;
      final lastTwoDigits = count % 100;

      if (lastDigit >= 2 &&
          lastDigit <= 4 &&
          !(lastTwoDigits >= 12 && lastTwoDigits <= 14)) {
        return "agreement_documents_count_few".tr;
      }

      return "agreement_documents_count_many".tr;
    }


    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;

        final selector = CoreDropdown<String>(
          label: "agreement_document_type".tr,
          value: relationType,
          options: compensationAgreementDocumentTypes,
          display: (value) =>
              "agreement_document_type_$value".tr,
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        );

        final counter = Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: theme.themeColor.withAlpha(18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: theme.themeColor.withAlpha(50),
            ),
          ),
          child: Text(
            "$documentsCount ${_agreementDocumentsCountLabel(documentsCount)}",
            style: TextStyle(
              color: theme.themeColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              selector,
              const SizedBox(height: 9),
              Row(
                children: [
                  counter,
                  const Spacer(),
                  if (onOpenFullScreen != null)
                    CoreOutlinedButton(
                      onPressed: onOpenFullScreen,
                      child: Text("open_documents".tr),
                    ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: selector),
            const SizedBox(width: 10),
            counter,
            if (onOpenFullScreen != null) ...[
              const SizedBox(width: 10),
              CoreOutlinedButton(
                onPressed: onOpenFullScreen,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.open_in_full_rounded,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Text("open_documents".tr),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SecurityHint extends ConsumerWidget {
  final bool canManage;

  const _SecurityHint({
    required this.canManage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(10),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: theme.themeColor.withAlpha(35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: theme.themeColor,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              canManage
                  ? "agreement_documents_manager_security_hint".tr
                  : "agreement_documents_employee_security_hint".tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(160),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgreementMustBeSavedCard extends ConsumerWidget {
  const _AgreementMustBeSavedCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.save_outlined,
            color: theme.themeColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "save_agreement_before_documents".tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "save_agreement_before_documents_hint".tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(145),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoAgreementDocumentAccessCard extends ConsumerWidget {
  const _NoAgreementDocumentAccessCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: theme.textColor.withAlpha(140),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "agreement_documents_no_access".tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(155),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
