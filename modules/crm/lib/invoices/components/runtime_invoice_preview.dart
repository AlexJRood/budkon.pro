import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

typedef InvoiceRelationAction =
    FutureOr<void> Function(RevenueInvoicePreviewVm vm);

enum RuntimeInvoicePreviewLayoutMode {
  auto,
  summaryOnly,
  paperOnly,
  stackedEmbedded,
}

class RuntimeInvoicePreview extends StatelessWidget {
  final Map<String, dynamic> revenueJson;
  final ThemeColors? appTheme;
  final EdgeInsetsGeometry padding;
  final RuntimeInvoicePreviewLayoutMode layoutMode;
  final ScrollController? scrollController;

  final InvoiceRelationAction? onOpenClient;
  final InvoiceRelationAction? onAttachClient;
  final InvoiceRelationAction? onOpenContractor;
  final InvoiceRelationAction? onAttachContractor;
  final InvoiceRelationAction? onOpenTransaction;
  final InvoiceRelationAction? onAttachTransaction;

  const RuntimeInvoicePreview({
    super.key,
    required this.revenueJson,
    this.appTheme,
    this.padding = const EdgeInsets.all(20),
    this.layoutMode = RuntimeInvoicePreviewLayoutMode.auto,
    this.scrollController,
    this.onOpenClient,
    this.onAttachClient,
    this.onOpenContractor,
    this.onAttachContractor,
    this.onOpenTransaction,
    this.onAttachTransaction,
  });

  @override
  Widget build(BuildContext context) {
    final vm = RevenueInvoicePreviewVm.fromJson(revenueJson);

    if (layoutMode == RuntimeInvoicePreviewLayoutMode.summaryOnly) {
      return RuntimeInvoiceSummaryCard.fromVm(
        vm: vm,
        appTheme: appTheme,
        onOpenClient: onOpenClient,
        onAttachClient: onAttachClient,
        onOpenContractor: onOpenContractor,
        onAttachContractor: onAttachContractor,
        onOpenTransaction: onOpenTransaction,
        onAttachTransaction: onAttachTransaction,
      );
    }

    if (layoutMode == RuntimeInvoicePreviewLayoutMode.paperOnly) {
      return _InvoicePaperPreview(vm: vm, appTheme: appTheme);
    }

    if (layoutMode == RuntimeInvoicePreviewLayoutMode.stackedEmbedded) {
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RuntimeInvoiceSummaryCard.fromVm(
              vm: vm,
              appTheme: appTheme,
              onOpenClient: onOpenClient,
              onAttachClient: onAttachClient,
              onOpenContractor: onOpenContractor,
              onAttachContractor: onAttachContractor,
              onOpenTransaction: onOpenTransaction,
              onAttachTransaction: onAttachTransaction,
            ),
            const SizedBox(height: 16),
            _InvoicePaperPreview(vm: vm, appTheme: appTheme),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1100;

        if (isNarrow) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RuntimeInvoiceSummaryCard.fromVm(
                  vm: vm,
                  appTheme: appTheme,
                  onOpenClient: onOpenClient,
                  onAttachClient: onAttachClient,
                  onOpenContractor: onOpenContractor,
                  onAttachContractor: onAttachContractor,
                  onOpenTransaction: onOpenTransaction,
                  onAttachTransaction: onAttachTransaction,
                ),
                const SizedBox(height: 16),
                _InvoicePaperPreview(vm: vm, appTheme: appTheme),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          controller: scrollController,
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 360,
                child: RuntimeInvoiceSummaryCard.fromVm(
                  vm: vm,
                  appTheme: appTheme,
                  onOpenClient: onOpenClient,
                  onAttachClient: onAttachClient,
                  onOpenContractor: onOpenContractor,
                  onAttachContractor: onAttachContractor,
                  onOpenTransaction: onOpenTransaction,
                  onAttachTransaction: onAttachTransaction,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(child: _InvoicePaperPreview(vm: vm, appTheme: appTheme)),
            ],
          ),
        );
      },
    );
  }
}

class RuntimeInvoiceSummaryCard extends StatelessWidget {
  final RevenueInvoicePreviewVm vm;
  final ThemeColors? appTheme;

  final InvoiceRelationAction? onOpenClient;
  final InvoiceRelationAction? onAttachClient;
  final InvoiceRelationAction? onOpenContractor;
  final InvoiceRelationAction? onAttachContractor;
  final InvoiceRelationAction? onOpenTransaction;
  final InvoiceRelationAction? onAttachTransaction;

  RuntimeInvoiceSummaryCard({
    super.key,
    required Map<String, dynamic> revenueJson,
    this.appTheme,
    this.onOpenClient,
    this.onAttachClient,
    this.onOpenContractor,
    this.onAttachContractor,
    this.onOpenTransaction,
    this.onAttachTransaction,
  }) : vm = RevenueInvoicePreviewVm.fromJson(revenueJson);

  RuntimeInvoiceSummaryCard.fromVm({
    super.key,
    required this.vm,
    required this.appTheme,
    this.onOpenClient,
    this.onAttachClient,
    this.onOpenContractor,
    this.onAttachContractor,
    this.onOpenTransaction,
    this.onAttachTransaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = appTheme;

    final bg = theme?.dashboardContainer ?? const Color(0xFF232327);
    final border = theme?.dashboardBoarder ?? const Color(0xFF3A3A40);
    final text = theme?.textColor ?? Colors.white;
    final muted = text.withAlpha(170);

    final relationCards = _buildRelationCards(
      context: context,
      text: text,
      muted: muted,
      border: border,
      bg: bg,
    );

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryLine('title_label'.tr, vm.displayTitle, text, muted),
          const SizedBox(height: 10),
          _summaryLine('number_label'.tr, vm.invoiceNumberOrDash, text, muted),
          const SizedBox(height: 10),
          _summaryLine('type_label'.tr, vm.transactionTypeOrDash, text, muted),
          Divider(height: 28, color: text.withAlpha(120)),
          _summaryLine(
            'seller_label'.tr,
            vm.seller?.resolvedName.isNotEmpty == true
                ? vm.seller!.resolvedName
                : '—',
            text,
            muted,
          ),
          const SizedBox(height: 10),
          _summaryLine(
            'buyer_label'.tr,
            vm.buyer?.resolvedName.isNotEmpty == true
                ? vm.buyer!.resolvedName
                : '—',
            text,
            muted,
          ),
          if (relationCards.isNotEmpty) ...[
            Divider(height: 28, color: text.withAlpha(120)),
            ...relationCards,
          ],
          Divider(height: 28, color: text.withAlpha(120)),
          _summaryLine('issue_date_label'.tr, vm.issueDateLabel, text, muted),
          const SizedBox(height: 10),
          _summaryLine('due_date_label'.tr, vm.paymentDateLabel, text, muted),
          const SizedBox(height: 10),
          _summaryLine(
            'payment_method_label'.tr,
            vm.paymentMethodOrDash,
            text,
            muted,
          ),
          Divider(height: 28, color: text.withAlpha(120)),
          _summaryLine('net_amount_label'.tr, vm.netLabel, text, muted),
          const SizedBox(height: 10),
          _summaryLine('vat_label'.tr, vm.taxLabel, text, muted),
          const SizedBox(height: 10),
          _summaryLine(
            'gross_amount_label'.tr,
            vm.grossLabel,
            text,
            muted,
            emphasize: true,
          ),
          if (vm.noteOrFooter.isNotEmpty) ...[
            Divider(height: 28, color: text.withAlpha(120)),
            Text(
              'note_label'.tr,
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vm.noteOrFooter,
              style: TextStyle(color: text, fontSize: 13, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildRelationCards({
    required BuildContext context,
    required Color text,
    required Color muted,
    required Color border,
    required Color bg,
  }) {
    final cards = <Widget>[];

    final showClientCard =
        vm.hasClientReference || onOpenClient != null || onAttachClient != null;
    final showContractorCard =
        vm.hasContractorReference ||
        onOpenContractor != null ||
        onAttachContractor != null;
    final showTransactionCard =
        vm.hasTransactionReference ||
        onOpenTransaction != null ||
        onAttachTransaction != null;

    if (showClientCard) {
      cards.add(
        _RelationCard(
          icon: Icons.person_outline,
          title: 'client_label'.tr,
          name: vm.clientNameOrDash,
          subtitle: vm.clientSecondaryLine,
          isAttached: vm.hasClientReference,
          textColor: text,
          mutedColor: muted,
          borderColor: border,
          backgroundColor: bg.withAlpha(80),
          onCardTap:
              vm.hasClientReference && onOpenClient != null
                  ? () => onOpenClient!(vm)
                  : (!vm.hasClientReference && onAttachClient != null)
                  ? () => onAttachClient!(vm)
                  : null,
          primaryActionLabel:
              vm.hasClientReference ? 'open_button'.tr : 'attach_button'.tr,
          onPrimaryAction:
              vm.hasClientReference && onOpenClient != null
                  ? () => onOpenClient!(vm)
                  : (!vm.hasClientReference && onAttachClient != null)
                  ? () => onAttachClient!(vm)
                  : null,
          secondaryActionLabel:
              vm.hasClientReference && onAttachClient != null
                  ? 'change_button'.tr
                  : null,
          onSecondaryAction:
              vm.hasClientReference && onAttachClient != null
                  ? () => onAttachClient!(vm)
                  : null,
        ),
      );
    }

    if (showClientCard && (showContractorCard || showTransactionCard)) {
      cards.add(const SizedBox(height: 12));
    }

    if (showContractorCard) {
      cards.add(
        _RelationCard(
          icon: Icons.business_center_outlined,
          title: 'contractor_label'.tr,
          name: vm.contractorNameOrDash,
          subtitle: vm.contractorSecondaryLine,
          isAttached: vm.hasContractorReference,
          textColor: text,
          mutedColor: muted,
          borderColor: border,
          backgroundColor: bg.withAlpha(80),
          onCardTap:
              vm.hasContractorReference && onOpenContractor != null
                  ? () => onOpenContractor!(vm)
                  : (!vm.hasContractorReference && onAttachContractor != null)
                  ? () => onAttachContractor!(vm)
                  : null,
          primaryActionLabel:
              vm.hasContractorReference ? 'open_button'.tr : 'attach_button'.tr,
          onPrimaryAction:
              vm.hasContractorReference && onOpenContractor != null
                  ? () => onOpenContractor!(vm)
                  : (!vm.hasContractorReference && onAttachContractor != null)
                  ? () => onAttachContractor!(vm)
                  : null,
          secondaryActionLabel:
              vm.hasContractorReference && onAttachContractor != null
                  ? 'change_button'.tr
                  : null,
          onSecondaryAction:
              vm.hasContractorReference && onAttachContractor != null
                  ? () => onAttachContractor!(vm)
                  : null,
        ),
      );
    }

    if (showContractorCard && showTransactionCard) {
      cards.add(const SizedBox(height: 12));
    }

    if (showTransactionCard) {
      cards.add(
        _RelationCard(
          icon: Icons.account_tree_outlined,
          title: 'transaction_label'.tr,
          name: vm.transactionReferenceOrDash,
          subtitle: vm.transactionSecondaryLine,
          isAttached: vm.hasTransactionReference,
          textColor: text,
          mutedColor: muted,
          borderColor: border,
          backgroundColor: bg.withAlpha(80),
          onCardTap:
              vm.hasTransactionReference && onOpenTransaction != null
                  ? () => onOpenTransaction!(vm)
                  : (!vm.hasTransactionReference && onAttachTransaction != null)
                  ? () => onAttachTransaction!(vm)
                  : null,
          primaryActionLabel:
              vm.hasTransactionReference
                  ? 'open_button'.tr
                  : 'attach_button'.tr,
          onPrimaryAction:
              vm.hasTransactionReference && onOpenTransaction != null
                  ? () => onOpenTransaction!(vm)
                  : (!vm.hasTransactionReference && onAttachTransaction != null)
                  ? () => onAttachTransaction!(vm)
                  : null,
          secondaryActionLabel:
              vm.hasTransactionReference && onAttachTransaction != null
                  ? 'change_button'.tr
                  : null,
          onSecondaryAction:
              vm.hasTransactionReference && onAttachTransaction != null
                  ? () => onAttachTransaction!(vm)
                  : null,
        ),
      );
    }

    return cards;
  }

  Widget _summaryLine(
    String label,
    String value,
    Color text,
    Color muted, {
    bool emphasize = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text('$label:', style: TextStyle(color: muted, fontSize: 13)),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Text(
            value.isEmpty ? '—' : value,
            textAlign: TextAlign.right,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: text,
              fontSize: emphasize ? 18 : 14,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RelationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String name;
  final String? subtitle;
  final bool isAttached;
  final Color textColor;
  final Color mutedColor;
  final Color borderColor;
  final Color backgroundColor;
  final FutureOr<void> Function()? onCardTap;
  final String? primaryActionLabel;
  final FutureOr<void> Function()? onPrimaryAction;
  final String? secondaryActionLabel;
  final FutureOr<void> Function()? onSecondaryAction;

  const _RelationCard({
    required this.icon,
    required this.title,
    required this.name,
    required this.subtitle,
    required this.isAttached,
    required this.textColor,
    required this.mutedColor,
    required this.borderColor,
    required this.backgroundColor,
    required this.onCardTap,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.secondaryActionLabel,
    required this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final isClickable = onCardTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            isClickable
                ? () async {
                  await onCardTap?.call();
                }
                : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor.withAlpha(180)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: textColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: textColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isAttached
                              ? const Color(0xFF1F8B4C).withAlpha(40)
                              : const Color(0xFFB26A00).withAlpha(40),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isAttached
                          ? 'attached_status'.tr
                          : 'not_attached_status'.tr,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (primaryActionLabel != null ||
                  secondaryActionLabel != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (primaryActionLabel != null && onPrimaryAction != null)
                      OutlinedButton(
                        onPressed: () async {
                          await onPrimaryAction?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor),
                          foregroundColor: textColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(primaryActionLabel!),
                      ),
                    if (secondaryActionLabel != null &&
                        onSecondaryAction != null)
                      TextButton(
                        onPressed: () async {
                          await onSecondaryAction?.call();
                        },
                        style: TextButton.styleFrom(foregroundColor: textColor),
                        child: Text(secondaryActionLabel!),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoicePaperPreview extends StatelessWidget {
  final RevenueInvoicePreviewVm vm;
  final ThemeColors? appTheme;

  const _InvoicePaperPreview({required this.vm, required this.appTheme});

  @override
  Widget build(BuildContext context) {
    final template = vm.template;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 980),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 28,
              offset: Offset(0, 16),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: DefaultTextStyle(
          style: TextStyle(
            color: template.textColor,
            fontSize: 13,
            height: 1.35,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (template.showHeaderSection) _buildHeader(template),
              if (template.showHeaderSection) const SizedBox(height: 20),
              if (template.showPartiesSection) _buildParties(template),
              if (template.showPartiesSection) const SizedBox(height: 18),
              if (template.showItemsSection) _buildItemsTable(template),
              if (vm.shouldShowBottomInfo) ...[
                const SizedBox(height: 18),
                _buildBottomCards(template),
              ],
              if (vm.noteOrFooter.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  vm.template.extraNotesLabel,
                  style: TextStyle(
                    color: template.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  vm.noteOrFooter,
                  style: TextStyle(
                    color: template.textColor.withAlpha(220),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(InvoiceTemplateResolved template) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (template.resolvedLogoUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    template.resolvedLogoUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INVOICE',
                      style: TextStyle(
                        color: template.primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (vm.invoiceNumberOrDash != '—')
                      Text(
                        vm.invoiceNumberOrDash,
                        style: TextStyle(
                          color: template.textColor.withAlpha(170),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      vm.displayTitle,
                      style: TextStyle(
                        color: template.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (vm.template.name.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Template: ${vm.template.name}',
                        style: TextStyle(
                          color: template.textColor.withAlpha(140),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _headerDateLine('Issue date', vm.issueDateLabel, template),
              const SizedBox(height: 6),
              _headerDateLine('Due date', vm.paymentDateLabel, template),
              if (vm.paymentMethodOrDash != '—') ...[
                const SizedBox(height: 6),
                _headerDateLine('Payment', vm.paymentMethodOrDash, template),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerDateLine(
    String label,
    String value,
    InvoiceTemplateResolved template,
  ) {
    return RichText(
      textAlign: TextAlign.right,
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              color: template.textColor.withAlpha(140),
              fontSize: 12,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: template.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParties(InvoiceTemplateResolved template) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _PartyCard(
            title: 'Seller',
            party: vm.seller,
            template: template,
            emptyText: 'no_seller_data'.tr,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _PartyCard(
            title: 'Buyer',
            party: vm.buyer,
            template: template,
            emptyText: 'no_buyer_data'.tr,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable(InvoiceTemplateResolved template) {
    final rows = vm.items;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: template.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: template.primaryColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(flex: 5, child: _headerCell('Item')),
                Expanded(flex: 2, child: _headerCell('Qty', alignEnd: true)),
                Expanded(
                  flex: 3,
                  child: _headerCell('Net price', alignEnd: true),
                ),
                Expanded(flex: 2, child: _headerCell('VAT %', alignEnd: true)),
                Expanded(flex: 3, child: _headerCell('Gross', alignEnd: true)),
              ],
            ),
          ),
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final showDivider = index != rows.length - 1;

            return Container(
              decoration: BoxDecoration(
                border:
                    showDivider
                        ? Border(
                          bottom: BorderSide(color: template.borderColor),
                        )
                        : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayName,
                          style: TextStyle(
                            color: template.textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: TextStyle(
                              color: template.textColor.withAlpha(160),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _bodyCell(
                      item.quantityLabelWithUnit,
                      template,
                      alignEnd: true,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _bodyCell(
                      item.netUnitPriceLabel,
                      template,
                      alignEnd: true,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _bodyCell(
                      item.vatRateLabel,
                      template,
                      alignEnd: true,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _bodyCell(item.grossLabel, template, alignEnd: true),
                  ),
                ],
              ),
            );
          }),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: template.borderColor)),
              color: template.sectionFill,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(11),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Total',
                    style: TextStyle(
                      color: template.textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _bodyCell('', template, alignEnd: true),
                ),
                Expanded(
                  flex: 3,
                  child: _bodyCell(
                    vm.netLabel,
                    template,
                    alignEnd: true,
                    bold: true,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _bodyCell(
                    vm.taxLabel,
                    template,
                    alignEnd: true,
                    bold: true,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: _bodyCell(
                    vm.grossLabel,
                    template,
                    alignEnd: true,
                    bold: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCards(InvoiceTemplateResolved template) {
    final cards = <Widget>[];

    if (vm.template.showPaymentTermsBlock) {
      cards.add(
        Expanded(
          child: _InfoBlock(
            title: vm.template.paymentTermsLabel,
            body: vm.paymentTermsText,
            template: template,
          ),
        ),
      );
    }

    if (vm.template.showBankAccountBlock && vm.seller?.hasBankData == true) {
      if (cards.isNotEmpty) {
        cards.add(const SizedBox(width: 14));
      }

      cards.add(
        Expanded(
          child: _InfoBlock(
            title: 'Bank account',
            body: vm.seller!.bankText,
            template: template,
          ),
        ),
      );
    }

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: cards);
  }

  Widget _headerCell(String text, {bool alignEnd = false}) {
    return Text(
      text,
      textAlign: alignEnd ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }

  Widget _bodyCell(
    String text,
    InvoiceTemplateResolved template, {
    bool alignEnd = false,
    bool bold = false,
  }) {
    return Text(
      text,
      textAlign: alignEnd ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        color: template.textColor,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12.5,
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  final String title;
  final InvoicePartyVm? party;
  final InvoiceTemplateResolved template;
  final String emptyText;

  const _PartyCard({
    required this.title,
    required this.party,
    required this.template,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final lines = party?.displayLines ?? const <String>[];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: template.sectionFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: template.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: template.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          if (party == null || (!party!.hasVisibleData && lines.isEmpty))
            Text(
              emptyText,
              style: TextStyle(
                color: template.textColor.withAlpha(150),
                fontSize: 12,
              ),
            )
          else
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  line,
                  style: TextStyle(
                    color: template.textColor,
                    fontSize: 12.5,
                    fontWeight:
                        line == party!.resolvedName
                            ? FontWeight.w700
                            : FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final String body;
  final InvoiceTemplateResolved template;

  const _InfoBlock({
    required this.title,
    required this.body,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: template.sectionFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: template.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: template.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: template.textColor.withAlpha(220),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class RevenueInvoicePreviewVm {
  final int? id;
  final String name;
  final String transactionType;
  final double grossAmount;
  final double taxAmount;
  final String currency;
  final String invoiceNumber;
  final String issueDate;
  final String paymentDate;
  final bool isPaid;
  final String paymentMethods;
  final String note;
  final InvoicePartyVm? buyer;
  final InvoicePartyVm? seller;
  final InvoiceTemplateResolved template;
  final List<InvoiceItemVm> items;

  final int? relatedClientId;
  final int? relatedContractorId;
  final int? relatedTransactionId;
  final String relatedTransactionReference;

  RevenueInvoicePreviewVm({
    required this.id,
    required this.name,
    required this.transactionType,
    required this.grossAmount,
    required this.taxAmount,
    required this.currency,
    required this.invoiceNumber,
    required this.issueDate,
    required this.paymentDate,
    required this.isPaid,
    required this.paymentMethods,
    required this.note,
    required this.buyer,
    required this.seller,
    required this.template,
    required this.items,
    required this.relatedClientId,
    required this.relatedContractorId,
    required this.relatedTransactionId,
    required this.relatedTransactionReference,
  });

  factory RevenueInvoicePreviewVm.fromJson(Map<String, dynamic> json) {
    final seller = InvoicePartyVm.fromJson(_asMap(json['seller_data']));
    final buyer = InvoicePartyVm.fromJson(
      _asMap(json['buyer_data']) ?? _asMap(json['client_data']),
    );

    final template = InvoiceTemplateResolved.fromJson(
      _asMap(json['invoice_template_data']),
      fallbackSellerLogo: seller?.logoUrl ?? '',
    );

    final gross = _asDouble(json['total_amount']);
    final tax = _asDouble(json['tax_amount']);

    final fallbackTitle = _resolvedInvoiceTitle(
      name: _asString(json['name']),
      transactionType: _asString(json['transaction_type']),
    );

    var items = InvoiceItemVm.parseList(
      raw: json['invoice_items_display'],
      fallbackCurrency: _asString(json['currency'], fallback: 'PLN'),
      fallbackTitle: fallbackTitle,
      fallbackGross: gross,
      fallbackTax: tax,
    );

    if (items.isEmpty && gross > 0) {
      items = [
        InvoiceItemVm.synthetic(
          currency: _asString(json['currency'], fallback: 'PLN'),
          fallbackTitle: fallbackTitle,
          gross: gross,
          tax: tax,
        ),
      ];
    }

    return RevenueInvoicePreviewVm(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      transactionType: _asString(json['transaction_type']),
      grossAmount: gross,
      taxAmount: tax,
      currency: _asString(json['currency'], fallback: 'PLN'),
      invoiceNumber: _asString(json['invoice_number']),
      issueDate: _asString(json['date']),
      paymentDate: _asString(json['payment_date']),
      isPaid: _asBool(json['is_paid']),
      paymentMethods: _asString(json['payment_methods']),
      note: _asString(json['note']),
      buyer: buyer,
      seller: seller,
      template: template,
      items: items,
      relatedClientId:
          buyer?.id ??
          _asInt(json['client_id']) ??
          _asInt(json['clients']) ??
          _asInt(_asMap(json['client_data'])?['id']) ??
          _asInt(_asMap(json['buyer_data'])?['id']),
      relatedContractorId:
          seller?.id ??
          _asInt(json['contractor_id']) ??
          _asInt(_asMap(json['seller_data'])?['id']),
      relatedTransactionId:
          _asInt(json['transaction_id']) ??
          _asInt(json['object_id']) ??
          _asInt(_asMap(json['transaction'])?['id']),
      relatedTransactionReference: _resolvedTransactionReference(
        explicit: _asString(json['transaction_name']),
        objectId: _asString(json['object_id']),
      ),
    );
  }

  String get displayTitle =>
      name.trim().isNotEmpty
          ? name.trim()
          : _resolvedInvoiceTitle(name: name, transactionType: transactionType);

  String get invoiceNumberOrDash =>
      invoiceNumber.trim().isNotEmpty ? invoiceNumber.trim() : '—';

  String get transactionTypeOrDash =>
      transactionType.trim().isNotEmpty ? transactionType.trim() : '—';

  double get netAmount {
    if (grossAmount > 0) {
      final v = grossAmount - taxAmount;
      if (v >= 0) return v;
    }

    return items.fold<double>(0, (sum, item) => sum + item.netValue);
  }

  String get issueDateLabel => _formatDate(issueDate);
  String get paymentDateLabel => _formatDate(paymentDate);

  String get paymentMethodOrDash =>
      paymentMethods.trim().isNotEmpty ? paymentMethods.trim() : '—';

  String get netLabel => _formatMoney(netAmount, currency);
  String get taxLabel => _formatMoney(taxAmount, currency);
  String get grossLabel => _formatMoney(grossAmount, currency);

  String get noteOrFooter {
    if (note.trim().isNotEmpty) return note.trim();
    if (template.footerText.trim().isNotEmpty)
      return template.footerText.trim();
    return '';
  }

  bool get shouldShowBottomInfo =>
      template.showPaymentTermsBlock ||
      (template.showBankAccountBlock && seller?.hasBankData == true);

  String get paymentTermsText {
    if (isPaid) {
      final method =
          paymentMethodOrDash == '—' ? '' : ' • $paymentMethodOrDash';
      return '${'invoice_marked_paid_text'.tr}${paymentDateLabel != '—' ? ' ${'on_date_prefix'.tr} $paymentDateLabel' : ''}$method.';
    }

    if (paymentDateLabel != '—') {
      return '${'payment_by_date'.tr} $paymentDateLabel${paymentMethodOrDash != '—' ? ' • $paymentMethodOrDash' : ''}.';
    }

    return 'payment_due_date_not_set'.tr;
  }

  bool get hasClientReference =>
      relatedClientId != null || (buyer?.hasVisibleData ?? false);

  bool get hasContractorReference =>
      relatedContractorId != null || (seller?.hasVisibleData ?? false);

  bool get hasTransactionReference =>
      relatedTransactionId != null || relatedTransactionReference.isNotEmpty;

  String get clientNameOrDash {
    final value = buyer?.resolvedName.trim() ?? '';
    return value.isNotEmpty ? value : 'no_client_attached'.tr;
  }

  String get contractorNameOrDash {
    final value = seller?.resolvedName.trim() ?? '';
    return value.isNotEmpty ? value : 'no_contractor_attached'.tr;
  }

  String get transactionReferenceOrDash {
    if (relatedTransactionReference.trim().isNotEmpty) {
      return relatedTransactionReference.trim();
    }
    if (relatedTransactionId != null) {
      return 'Transaction #$relatedTransactionId';
    }
    return 'no_transaction_attached'.tr;
  }

  String? get clientSecondaryLine {
    final email = buyer?.email.trim() ?? '';
    final phone = buyer?.phone.trim() ?? '';
    final city = buyer?.city.trim() ?? '';

    final parts = [email, phone, city].where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.join(' • ');
  }

  String? get contractorSecondaryLine {
    final email = seller?.email.trim() ?? '';
    final phone = seller?.phone.trim() ?? '';
    final city = seller?.city.trim() ?? '';

    final parts = [email, phone, city].where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.join(' • ');
  }

  String? get transactionSecondaryLine {
    final parts = <String>[];

    if (transactionType.trim().isNotEmpty) {
      parts.add(transactionType.trim());
    }
    if (invoiceNumber.trim().isNotEmpty) {
      parts.add(invoiceNumber.trim());
    }

    if (parts.isEmpty) return null;
    return parts.join(' • ');
  }
}

class InvoicePartyVm {
  final int? id;
  final String name;
  final String companyName;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String street;
  final String houseNumber;
  final String apartmentNumber;
  final String postalCode;
  final String city;
  final String country;
  final String taxNumber;
  final String bankName;
  final String bankAccount;
  final String iban;
  final String swift;
  final String logoUrl;

  InvoicePartyVm({
    required this.id,
    required this.name,
    required this.companyName,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.street,
    required this.houseNumber,
    required this.apartmentNumber,
    required this.postalCode,
    required this.city,
    required this.country,
    required this.taxNumber,
    required this.bankName,
    required this.bankAccount,
    required this.iban,
    required this.swift,
    required this.logoUrl,
  });

  factory InvoicePartyVm.fromJson(Map<String, dynamic>? json) {
    if (json == null) return InvoicePartyVm.empty();

    return InvoicePartyVm(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      companyName: _asString(json['company_name']),
      firstName: _asString(json['first_name']),
      lastName: _asString(json['last_name']),
      email: _asString(json['email']),
      phone: _asString(json['phone']),
      street: _asString(json['street']),
      houseNumber: _asString(json['house_number']),
      apartmentNumber: _asString(json['apartment_number']),
      postalCode: _asString(json['postal_code']),
      city: _asString(json['city']),
      country: _asString(json['country']),
      taxNumber: _asString(json['tax_number']),
      bankName: _asString(json['bank_name']),
      bankAccount: _asString(json['bank_account']),
      iban: _asString(json['iban']),
      swift: _asString(json['swift']),
      logoUrl: _asString(json['logo_url']),
    );
  }

  factory InvoicePartyVm.empty() {
    return InvoicePartyVm(
      id: null,
      name: '',
      companyName: '',
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      street: '',
      houseNumber: '',
      apartmentNumber: '',
      postalCode: '',
      city: '',
      country: '',
      taxNumber: '',
      bankName: '',
      bankAccount: '',
      iban: '',
      swift: '',
      logoUrl: '',
    );
  }

  String get resolvedName {
    if (companyName.trim().isNotEmpty) return companyName.trim();

    final fullName =
        [
          firstName.trim(),
          lastName.trim(),
        ].where((e) => e.isNotEmpty).join(' ').trim();
    if (fullName.isNotEmpty) return fullName;

    if (name.trim().isNotEmpty) return name.trim();
    if (email.trim().isNotEmpty) return email.trim();

    return '';
  }

  String get addressLine1 {
    final streetPart = street.trim();
    final numberPart =
        [
          houseNumber.trim(),
          apartmentNumber.trim().isNotEmpty ? '/${apartmentNumber.trim()}' : '',
        ].join();

    if (streetPart.isEmpty && numberPart.isEmpty) return '';
    return '$streetPart $numberPart'.trim();
  }

  String get addressLine2 {
    final line = [
      postalCode.trim(),
      city.trim(),
    ].where((e) => e.isNotEmpty).join(' ');
    return line.trim();
  }

  bool get hasBankData =>
      bankName.trim().isNotEmpty ||
      bankAccount.trim().isNotEmpty ||
      iban.trim().isNotEmpty ||
      swift.trim().isNotEmpty;

  String get bankText {
    final lines = <String>[];

    if (bankName.trim().isNotEmpty) lines.add('Bank: ${bankName.trim()}');
    if (bankAccount.trim().isNotEmpty) {
      lines.add('Account: ${bankAccount.trim()}');
    } else if (iban.trim().isNotEmpty) {
      lines.add('IBAN: ${iban.trim()}');
    }
    if (swift.trim().isNotEmpty) lines.add('SWIFT: ${swift.trim()}');

    return lines.join('\n');
  }

  bool get hasVisibleData =>
      resolvedName.isNotEmpty ||
      addressLine1.isNotEmpty ||
      addressLine2.isNotEmpty ||
      country.trim().isNotEmpty ||
      taxNumber.trim().isNotEmpty ||
      email.trim().isNotEmpty ||
      phone.trim().isNotEmpty;

  List<String> get displayLines {
    final lines = <String>[];

    if (resolvedName.isNotEmpty) lines.add(resolvedName);
    if (addressLine1.isNotEmpty) lines.add(addressLine1);
    if (addressLine2.isNotEmpty) lines.add(addressLine2);
    if (country.trim().isNotEmpty) lines.add(country.trim());
    if (taxNumber.trim().isNotEmpty) lines.add('NIP: ${taxNumber.trim()}');
    if (email.trim().isNotEmpty) lines.add(email.trim());
    if (phone.trim().isNotEmpty) lines.add(phone.trim());

    return lines;
  }
}

class InvoiceItemVm {
  final String name;
  final String description;
  final double quantity;
  final String unit;
  final double vatRate;
  final double unitNetPrice;
  final double netValue;
  final double vatAmount;
  final double grossValue;
  final String currency;
  final int orderIndex;

  InvoiceItemVm({
    required this.name,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.vatRate,
    required this.unitNetPrice,
    required this.netValue,
    required this.vatAmount,
    required this.grossValue,
    required this.currency,
    required this.orderIndex,
  });

  factory InvoiceItemVm.fromJson(
    Map<String, dynamic> json, {
    required String fallbackCurrency,
    required String fallbackTitle,
    required int fallbackOrderIndex,
  }) {
    final qtyRaw = _asDouble(json['quantity']);
    final qty = qtyRaw <= 0 ? 1.0 : qtyRaw;

    final lineNet = _firstPositiveOrAny([
      _asDouble(json['line_net_amount']),
      _asDouble(json['net_value']),
    ]);

    final lineVat = _firstPositiveOrAny([
      _asDouble(json['line_vat_amount']),
      _asDouble(json['vat_amount']),
    ]);

    final lineGross = _firstPositiveOrAny([
      _asDouble(json['line_gross_amount']),
      _asDouble(json['gross_value']),
      lineNet + lineVat,
    ]);

    final unitNet = _firstPositiveOrAny([
      _asDouble(json['unit_net_price']),
      _asDouble(json['unit_price']),
      qty > 0 ? lineNet / qty : 0,
    ]);

    final itemName = _resolvedItemName(
      [_asString(json['name']), _asString(json['product_name'])],
      fallbackTitle,
      lineGross,
    );

    return InvoiceItemVm(
      name: itemName,
      description: _asString(json['description']),
      quantity: qty,
      unit: _asString(
        json['unit'],
        fallback: _asString(json['iu'], fallback: 'szt'),
      ),
      vatRate: _asDouble(json['vat_rate']),
      unitNetPrice: unitNet,
      netValue: lineNet,
      vatAmount: lineVat,
      grossValue: lineGross,
      currency: _asString(json['currency'], fallback: fallbackCurrency),
      orderIndex: _asInt(json['order_index']) ?? fallbackOrderIndex,
    );
  }

  factory InvoiceItemVm.synthetic({
    required String currency,
    required String fallbackTitle,
    required double gross,
    required double tax,
  }) {
    final net = (gross - tax) >= 0 ? (gross - tax) : gross;
    final rate = net > 0 && tax > 0 ? (tax / net) * 100 : 0.0;

    return InvoiceItemVm(
      name: fallbackTitle,
      description: '',
      quantity: 1,
      unit: 'szt',
      vatRate: rate,
      unitNetPrice: net,
      netValue: net,
      vatAmount: tax,
      grossValue: gross,
      currency: currency,
      orderIndex: 0,
    );
  }

  static List<InvoiceItemVm> parseList({
    required dynamic raw,
    required String fallbackCurrency,
    required String fallbackTitle,
    required double fallbackGross,
    required double fallbackTax,
  }) {
    final list = raw is List ? raw : const [];

    final parsed = <InvoiceItemVm>[];
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is! Map) continue;

      final vm = InvoiceItemVm.fromJson(
        Map<String, dynamic>.from(item),
        fallbackCurrency: fallbackCurrency,
        fallbackTitle: fallbackTitle,
        fallbackOrderIndex: i,
      );

      final isTrash =
          vm.name.trim().isEmpty &&
          vm.netValue == 0 &&
          vm.vatAmount == 0 &&
          vm.grossValue == 0;

      if (!isTrash) {
        parsed.add(vm);
      }
    }

    parsed.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    if (parsed.isEmpty && fallbackGross > 0) {
      return [
        InvoiceItemVm.synthetic(
          currency: fallbackCurrency,
          fallbackTitle: fallbackTitle,
          gross: fallbackGross,
          tax: fallbackTax,
        ),
      ];
    }

    return parsed;
  }

  String get displayName =>
      name.trim().isNotEmpty ? name.trim() : 'service_default_name'.tr;

  String get quantityLabelWithUnit {
    final q = _formatQuantity(quantity);
    final u = unit.trim().isNotEmpty ? unit.trim() : 'szt';
    return '$q $u';
  }

  String get vatRateLabel =>
      '${vatRate.toStringAsFixed(vatRate % 1 == 0 ? 0 : 2)}%';
  String get netUnitPriceLabel => _formatMoney(unitNetPrice, currency);
  String get grossLabel => _formatMoney(grossValue, currency);
}

class InvoiceTemplateResolved {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;
  final Color borderColor;
  final Color sectionFill;
  final String resolvedLogoUrl;
  final String footerText;
  final String extraNotesLabel;
  final String paymentTermsLabel;
  final Map<String, dynamic> sectionsConfig;

  InvoiceTemplateResolved({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
    required this.borderColor,
    required this.sectionFill,
    required this.resolvedLogoUrl,
    required this.footerText,
    required this.extraNotesLabel,
    required this.paymentTermsLabel,
    required this.sectionsConfig,
  });

  factory InvoiceTemplateResolved.fromJson(
    Map<String, dynamic>? json, {
    String fallbackSellerLogo = '',
  }) {
    final source = json ?? const <String, dynamic>{};
    final sections =
        _asMap(source['sections_config']) ?? const <String, dynamic>{};

    final primary = _colorFromHex(
      _asString(source['primary_color']),
      const Color(0xFF2F80ED),
    );
    final secondary = _colorFromHex(
      _asString(source['secondary_color']),
      const Color(0xFFD8DEE8),
    );
    final accent = _colorFromHex(
      _asString(source['accent_color']),
      const Color(0xFF111827),
    );

    final logoUrl =
        _asString(source['logo_url']).trim().isNotEmpty
            ? _asString(source['logo_url']).trim()
            : fallbackSellerLogo.trim();

    return InvoiceTemplateResolved(
      name: _asString(source['name']),
      primaryColor: primary,
      secondaryColor: secondary,
      textColor: accent,
      borderColor: secondary.withAlpha(210),
      sectionFill: const Color(0xFFF8FAFC),
      resolvedLogoUrl: logoUrl,
      footerText: _asString(source['footer_text']),
      extraNotesLabel: _asString(
        source['extra_notes_label'],
        fallback: 'Additional notes',
      ),
      paymentTermsLabel: _asString(
        source['payment_terms_label'],
        fallback: 'Payment terms',
      ),
      sectionsConfig: sections,
    );
  }

  bool _sectionVisible(String id, {bool fallback = true}) {
    final rawSections = sectionsConfig['sections'];
    if (rawSections is! List) return fallback;

    for (final section in rawSections) {
      if (section is! Map) continue;
      final sid = _asString(section['id']);
      if (sid == id) {
        final visible = section['visible'];
        if (visible is bool) return visible;
        return fallback;
      }
    }

    return fallback;
  }

  bool get showHeaderSection => _sectionVisible('header', fallback: true);
  bool get showPartiesSection => _sectionVisible('parties', fallback: true);
  bool get showItemsSection => _sectionVisible('items', fallback: true);

  bool get showPaymentTermsBlock {
    final raw = sectionsConfig['show_payment_terms'];
    final defaultValue = _sectionVisible('payments', fallback: true);
    return raw is bool ? raw : defaultValue;
  }

  bool get showBankAccountBlock {
    final raw = sectionsConfig['show_bank_account'];
    final defaultValue = _sectionVisible('payments', fallback: true);
    return raw is bool ? raw : defaultValue;
  }
}

String _resolvedInvoiceTitle({
  required String name,
  required String transactionType,
}) {
  if (name.trim().isNotEmpty) return name.trim();
  if (transactionType.trim().isNotEmpty) {
    return '${'invoice_prefix'.tr}${transactionType.trim()}';
  }
  return 'invoice_label'.tr;
}

String _resolvedItemName(
  List<String> candidates,
  String fallbackTitle,
  double gross,
) {
  for (final candidate in candidates) {
    if (candidate.trim().isNotEmpty) return candidate.trim();
  }

  if (gross > 0 && fallbackTitle.trim().isNotEmpty) {
    return fallbackTitle.trim();
  }
  return '';
}

String _resolvedTransactionReference({
  required String explicit,
  required String objectId,
}) {
  if (explicit.trim().isNotEmpty) return explicit.trim();
  if (objectId.trim().isNotEmpty)
    return '${'transaction_hash_prefix'.tr}${objectId.trim()}';
  return '';
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

double _asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();

  final raw = value.toString().trim();
  if (raw.isEmpty) return 0;

  final normalized = raw.replaceAll(' ', '').replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  final s = value?.toString().trim().toLowerCase();
  return s == 'true' || s == '1';
}

double _firstPositiveOrAny(List<double> values) {
  for (final v in values) {
    if (v > 0) return v;
  }
  for (final v in values) {
    if (v != 0) return v;
  }
  return 0;
}

String _formatMoney(double value, String currency) {
  return '${value.toStringAsFixed(2)} ${currency.trim().isNotEmpty ? currency.trim() : 'PLN'}';
}

String _formatQuantity(double value) {
  if (value % 1 == 0) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}

String _formatDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '—';

  try {
    final normalized =
        value.contains('T')
            ? DateTime.parse(value).toLocal()
            : DateTime.parse('${value}T00:00:00');
    final d = normalized.day.toString().padLeft(2, '0');
    final m = normalized.month.toString().padLeft(2, '0');
    final y = normalized.year.toString();
    return '$d.$m.$y';
  } catch (_) {
    return value;
  }
}

Color _colorFromHex(String hex, Color fallback) {
  var value = hex.trim();
  if (value.isEmpty) return fallback;
  if (!value.startsWith('#')) value = '#$value';

  if (value.length == 4) {
    final r = value[1];
    final g = value[2];
    final b = value[3];
    value = '#$r$r$g$g$b$b';
  }

  if (value.length != 7) return fallback;

  try {
    final parsed = int.parse(value.substring(1), radix: 16);
    return Color(0xFF000000 | parsed);
  } catch (_) {
    return fallback;
  }
}
