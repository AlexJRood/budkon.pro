import 'package:crm/contact_panel/tabs/transactions/tx_client_provider.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // sound + haptic
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:core/platform/api/api_buttons.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

import 'manage_transaction_dialog.dart';
import 'package:crm/invoices/form/screen/add_invoice_screen.dart';

class ManageTransaction extends ConsumerStatefulWidget {
  final AgentTransactionModel transaction;
  final Color textColor;
  final bool isClientView;

  const ManageTransaction({
    super.key,
    required this.transaction,
    this.isClientView = false,
    required this.textColor,
  });

  @override
  ConsumerState<ManageTransaction> createState() => _ManageTransactionState();
}

class _ManageTransactionState extends ConsumerState<ManageTransaction> {
  Map<String, dynamic>? _completePayload;

  final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  // -------------------------
  // Helpers
  // -------------------------
  String _currencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'PLN':
        return 'PLN';
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      default:
        return code;
    }
  }

  double? _parseNumber(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim().replaceAll(',', '.');
    final cleaned = s.replaceAll(RegExp(r'[^0-9\.\-]'), '');
    return double.tryParse(cleaned);
  }

  String _formatMoneyNum(num? v, String currencyCode) {
    if (v == null) return '-';
    final fmt = NumberFormat.currency(
      locale: 'pl_PL',
      symbol: _currencySymbol(currencyCode),
      decimalDigits: 2,
    );
    return fmt.format(v);
  }

  String _formatMoney(String? raw, String currencyCode) {
    final n = _parseNumber(raw);
    return _formatMoneyNum(n, currencyCode);
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return _dateFmt.format(dt);
  }

  void _playSuccessFeedback() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  void _playFailureFeedback() {
    HapticFeedback.lightImpact();
  }

  // -------------------------
  // Dialog openers
  // -------------------------
  Future<CompleteTransactionResult?> _showCompleteTransactionDialog({
    AgentTransactionModel? initial,
    bool isEditMode = false,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return showModalBottomSheet<CompleteTransactionResult?>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: CompleteTransactionDialog(
            textColor: widget.textColor,
            initial: initial,
            isEditMode: isEditMode,
            isMobile: true,
          ),
        ),
      );
    }

    return showDialog<CompleteTransactionResult?>(
      context: context,
      useRootNavigator: true,
      builder: (_) => CompleteTransactionDialog(
        textColor: widget.textColor,
        initial: initial,
        isEditMode: isEditMode,
      ),
    );
  }

  Future<bool> _openCompleteDialog() async {
    final res = await _showCompleteTransactionDialog();

    if (!mounted) return false;
    if (res == null) return false;

    setState(() => _completePayload = res.payload);
    debugPrint('✅ CompleteTransactionDialog payload = $_completePayload');
    return true;
  }

  Future<bool> _openEditCompleteDialog(AgentTransactionModel tx) async {
    final res = await _showCompleteTransactionDialog(
      initial: tx,
      isEditMode: true,
    );

    if (!mounted) return false;
    if (res == null) return false;

    setState(() => _completePayload = res.payload);
    debugPrint('✏️ Edit completion payload = $_completePayload');
    return true;
  }

  // -------------------------
  // Invoice opening
  // -------------------------
  Future<void> _openInvoiceFromTransaction({
    required AgentTransactionModel transaction,
    Map<String, dynamic>? payloadOverride,
  }) async {
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 30));
    if (!mounted) return;

    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      await showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (sheetCtx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(sheetCtx).size.height * 0.95,
            child: AddInvoiceScreen(
              isMobile: true,
              initialClientId: transaction.client.id,
              initialTransaction: transaction,
            ),
          ),
        ),
      );
    } else {
      await showDialog(
        context: context,
        useRootNavigator: true,
        barrierDismissible: true,
        builder: (dialogContext) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SizedBox(
              width: MediaQuery.of(dialogContext).size.width * 0.7,
              height: MediaQuery.of(dialogContext).size.height * 0.85,
              child: AddInvoiceScreen(
                isMobile: false,
                initialClientId: transaction.client.id,
                initialTransaction: transaction,
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _openInvoiceIfNeededAfterComplete(AgentTransactionModel tx) async {
    final shouldCreateInvoice = _completePayload?['create_invoice'] == true;
    debugPrint('🧾 shouldCreateInvoice=$shouldCreateInvoice');
    if (!shouldCreateInvoice) return;

    await _openInvoiceFromTransaction(
      transaction: tx,
      payloadOverride: _completePayload,
    );
  }

  // -------------------------
  // ✅ Commission computed from final_amount (sale price)
  // -------------------------

  /// Sale price (final sale value) = final_amount
  double? _salePrice(AgentTransactionModel tx) => _parseNumber(tx.finalAmount);

  /// Commission base = commission field (string)
  double? _commissionBase(AgentTransactionModel tx) => _parseNumber(tx.commission);

  /// Final commission:
  /// - %: salePrice * commission / 100
  /// - fixed: commission
  double? _calcFinalCommission(AgentTransactionModel tx) {
    final base = _commissionBase(tx);
    if (base == null) return null;

    if (tx.isCommisssionPercentage) {
      final price = _salePrice(tx);
      if (price == null) return null;
      // you keep 33, full number -> classic percent
      return price * (base / 100.0);
    }

    return base;
  }

  // -------------------------
  // UI bits
  // -------------------------
  Widget _detailRow(dynamic theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Text(
            label,
            style: TextStyle(
              color: theme.textColor.withAlpha(170),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(dynamic theme, {required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dashboardBoarder),
        color: theme.adPopBackground,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _completionDetailsCard(AgentTransactionModel tx) {
    final theme = ref.watch(themeColorsProvider);

    final isSuccess = tx.isSuccess == true;
    final isFail = tx.isSuccess == false;

    final statusText = isSuccess
        ? 'Success'.tr
        : (isFail ? 'unsuccessful_status'.tr : 'completed_status'.tr);

    final statusIcon = isSuccess
        ? AppIcons.verifiedUser(color: theme.textColor)
        : (isFail
            ? AppIcons.circleCloseOutlined(color: theme.textColor)
            : AppIcons.circleQuestion(color: theme.textColor));

    final borderColor = isSuccess ? AppColors.revenueGreen : theme.dashboardBoarder;

    final salePriceText = _formatMoney(tx.finalAmount, tx.currency);

    final commissionNum = _calcFinalCommission(tx);
    final commissionText = _formatMoneyNum(commissionNum, tx.currency);

    final netGrossText = tx.isCommissionNetValue ? 'netto_label'.tr : 'brutto_label'.tr;
    final modeText = tx.isCommisssionPercentage ? '%'.tr : 'PLN'.tr; // just a hint badge

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        color: theme.dashboardContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              statusIcon,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'completion_details_title'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  color: theme.textColor.withAlpha(200),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            color: isSuccess ? AppColors.revenueGreen : theme.textColor.withAlpha(70),
          ),
          const SizedBox(height: 10),

          _detailRow(theme, 'close_date_label'.tr, _formatDate(tx.dateClosed)),
          const SizedBox(height: 8),

          // ✅ sale price = final_amount
          _detailRow(theme, 'property_final_price_label'.tr, salePriceText),
          const SizedBox(height: 8),

          // ✅ commission computed from final_amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 180,
                child: Text(
                  'final_commission_label'.tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(170),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        commissionText,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _badge(theme, text: modeText),
                    const SizedBox(width: 8),
                    _badge(theme, text: netGrossText),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if ((tx.propertyUrl ?? '').trim().isNotEmpty) ...[
            _detailRow(theme, 'property_url_label'.tr, tx.propertyUrl!.trim()),
            const SizedBox(height: 8),
          ],

          if (tx.propertyNmAdId != null) ...[
            _detailRow(theme, 'nm_offer_id_label'.tr, tx.propertyNmAdId.toString()),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  // -------------------------
  // Local update helper
  // - final_amount is the sale price (your rule)
  // -------------------------
  void _applyCompletionPayloadToLocal({
    required int clientId,
    required AgentTransactionModel transaction,
  }) {
    final success = _completePayload?["success"];
    final dateClosed = _completePayload?["date_closed"];

    // ✅ final_amount = property sale price
    final finalAmount = _completePayload?["final_amount"];

    final propertyUrl = _completePayload?["property_url"];
    final nmId = _completePayload?["property_nm_ad_id"];

    ref.read(transactionListProvider(clientId).notifier).updateLocal(
      transaction.id,
      (t) => t.copyWith(
        isComplete: true,
        isSuccess: success is bool ? success : t.isSuccess,
        dateClosed: dateClosed is String ? DateTime.tryParse(dateClosed) : t.dateClosed,
        finalAmount: finalAmount?.toString(),
        propertyUrl: propertyUrl?.toString(),
        propertyNmAdId: nmId is int
            ? nmId
            : (nmId is String ? int.tryParse(nmId) : t.propertyNmAdId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final clientId = transaction.client.id;
    final theme = ref.read(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5,
        children: [
          if (!widget.isClientView)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                'manage_transaction_title'.tr,
                style: TextStyle(color: widget.textColor, fontSize: 20),
              ),
            ),

          if (transaction.isComplete) _completionDetailsCard(transaction),

          if (!transaction.isComplete)
            ApiButton(
              endpoint: "https://www.superbee.cloud/agent/transaction/${transaction.id}/complete/",
              method: ApiMethod.patch,
              hasToken: true,
              label: 'completed_status'.tr,
              icon: AppIcons.verifiedUser(color: widget.textColor),
              hasConfirm: false,
              confirmReturnMode: ConfirmReturnMode.gate,
              onConfirm: (ctx) async => await _openCompleteDialog(),
              payloadBuilder: ({confirmResult, baseData}) {
                final merged = {...?baseData, ...?_completePayload};
                debugPrint('📦 PATCH payload merged = $merged');
                return merged;
              },
              onSuccess: (_) async {
                final success = _completePayload?["success"];

                if (success == true) {
                  _playSuccessFeedback();
                } else if (success == false) {
                  _playFailureFeedback();
                } else {
                  HapticFeedback.selectionClick();
                }

                _applyCompletionPayloadToLocal(
                  clientId: clientId,
                  transaction: transaction,
                );

                await _openInvoiceIfNeededAfterComplete(transaction);
              },
            )
          else ...[
            ApiButton(
              endpoint: "https://www.superbee.cloud/agent/transaction/${transaction.id}/complete/",
              method: ApiMethod.patch,
              hasToken: true,
              label: 'edit_completion_button'.tr,
              icon: AppIcons.copySimple(color: widget.textColor),
              hasConfirm: false,
              confirmReturnMode: ConfirmReturnMode.gate,
              onConfirm: (ctx) async => await _openEditCompleteDialog(transaction),
              payloadBuilder: ({confirmResult, baseData}) {
                final merged = {...?baseData, ...?_completePayload};
                debugPrint('📦 EDIT PATCH payload merged = $merged');
                return merged;
              },
              onSuccess: (_) {
                HapticFeedback.selectionClick();
                _applyCompletionPayloadToLocal(
                  clientId: clientId,
                  transaction: transaction,
                );
              },
            ),

            ElevatedButton(
              style: elevatedButtonStyleRounded10,
              child: Row(
                spacing: 10,
                children: [
                  AppIcons.document(color: widget.textColor),
                  Text('create_invoice_button'.tr, style: TextStyle(color: theme.textColor)),
                ],
              ),
              onPressed: () async => await _openInvoiceFromTransaction(transaction: transaction),
            ),

            ApiButton(
              endpoint: "https://www.superbee.cloud/agent/transaction/${transaction.id}/complete/",
              method: ApiMethod.patch,
              hasToken: true,
              label: 'set_as_unsuccessful_button'.tr,
              hasConfirm: true,
              confirmMessage: 'confirm_set_unsuccessful'.tr,
              confirmYesLabel: 'yes_button'.tr,
              confirmNoLabel: 'Cancel'.tr,
              confirmReturnMode: ConfirmReturnMode.gate,
              payloadBuilder: ({confirmResult, baseData}) => {'success': false, ...?baseData},
              icon: AppIcons.circleCloseOutlined(color: widget.textColor),
              onSuccess: (_) {
                _playFailureFeedback();
                ref.read(transactionListProvider(clientId).notifier).updateLocal(
                  transaction.id,
                  (t) => t.copyWith(isComplete: true, isSuccess: false),
                );
              },
            ),

            ApiButton(
              endpoint: "https://www.superbee.cloud/agent/transaction/${transaction.id}/reopen/",
              method: ApiMethod.patch,
              hasToken: true,
              label: 'reopen_button'.tr,
              hasConfirm: true,
              confirmMessage: 'confirm_reopen_transaction'.tr,
              icon: AppIcons.copySimple(color: widget.textColor),
              onSuccess: (_) {
                HapticFeedback.selectionClick();
                ref.read(transactionListProvider(clientId).notifier).updateLocal(
                  transaction.id,
                  (t) => t.copyWith(isComplete: false, isSuccess: null, dateClosed: null),
                );
              },
            ),
          ],

          if (!transaction.isArchive)
            ApiButton(
              endpoint: "https://www.superbee.cloud/agent/transaction/${transaction.id}/archive/",
              method: ApiMethod.patch,
              hasToken: true,
              data: {"archive": true},
              label: 'archive_button'.tr,
              hasConfirm: true,
              confirmMessage: 'confirm_archive_transaction'.tr,
              icon: AppIcons.archive(color: widget.textColor),
              onSuccess: (_) {
                HapticFeedback.selectionClick();
                ref.read(transactionListProvider(clientId).notifier).updateLocal(
                  transaction.id,
                  (t) => t.copyWith(isArchive: true),
                );
              },
            )
          else
            ApiButton(
              endpoint: "https://www.superbee.cloud/agent/transaction/${transaction.id}/archive/",
              method: ApiMethod.patch,
              hasToken: true,
              data: {"archive": false},
              label: 'back_from_archive_button'.tr,
              hasConfirm: true,
              confirmMessage: 'confirm_restore_from_archive'.tr,
              icon: AppIcons.arrowTrendUp(color: widget.textColor),
              onSuccess: (_) {
                HapticFeedback.selectionClick();
                ref.read(transactionListProvider(clientId).notifier).updateLocal(
                  transaction.id,
                  (t) => t.copyWith(isArchive: false),
                );
              },
            ),
        ],
      ),
    );
  }
}
