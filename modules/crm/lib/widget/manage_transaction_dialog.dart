import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart'; // ✅ NEW

class CompleteTransactionResult {
  final Map<String, dynamic> payload;
  const CompleteTransactionResult(this.payload);
}

class InvoicePromptResult {
  final bool createInvoice;
  final bool dontShowAgain;
  const InvoicePromptResult({
    required this.createInvoice,
    required this.dontShowAgain,
  });
}

class CompleteTransactionDialog extends ConsumerStatefulWidget {
  final Color? textColor;

  // ✅ NEW
  final AgentTransactionModel? initial;
  final bool isEditMode;
  final bool isMobile;

  const CompleteTransactionDialog({
    super.key,
    this.textColor,
    this.initial,
    this.isEditMode = false,
    this.isMobile = false,
  });

  @override
  ConsumerState<CompleteTransactionDialog> createState() =>
      _CompleteTransactionDialogState();
}

class _CompleteTransactionDialogState
    extends ConsumerState<CompleteTransactionDialog> {
  static const String _kHideInvoicePromptPrefKey =
      'hide_invoice_prompt_complete_tx';

  bool success = true;
  late DateTime closeDate;
  String currency = 'PLN';

  bool _createInvoiceAfterSubmit = false;

  bool _hideInvoicePrompt = false;
  bool _prefsLoaded = false;

  // ✅ NEW: track whether user already answered invoice question
  bool _invoiceDecisionMade = false;

  String? _failureReason;
  final _failureReasonDetailsCtrl = TextEditingController();

  final _finalAmountCtrl = TextEditingController();
  final _propertyUrlCtrl = TextEditingController();
  final _nmOfferIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    closeDate = DateTime(now.year, now.month, now.day);

    // ✅ Prefill (edit mode OR initial provided)
    final tx = widget.initial;
    if (tx != null) {
      success = tx.isSuccess ?? true;

      if (tx.dateClosed != null) {
        final d = tx.dateClosed!;
        closeDate = DateTime(d.year, d.month, d.day);
      }

      if ((tx.currency).trim().isNotEmpty) {
        currency = tx.currency.trim();
      }

      if ((tx.finalAmount ?? '').trim().isNotEmpty) {
        _finalAmountCtrl.text = tx.finalAmount!.trim();
      }

      if ((tx.propertyUrl ?? '').trim().isNotEmpty) {
        _propertyUrlCtrl.text = tx.propertyUrl!.trim();
      }

      if (tx.propertyNmAdId != null) {
        _nmOfferIdCtrl.text = tx.propertyNmAdId.toString();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadPrefs();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _finalAmountCtrl.dispose();
    _propertyUrlCtrl.dispose();
    _nmOfferIdCtrl.dispose();
    _failureReasonDetailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    if (_prefsLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _hideInvoicePrompt = prefs.getBool(_kHideInvoicePromptPrefKey) ?? false;
    _prefsLoaded = true;
  }

  Future<void> _setHideInvoicePrompt(bool hide) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHideInvoicePromptPrefKey, hide);
    _hideInvoicePrompt = hide;
  }

  Future<void> _pickDate(BuildContext context) async {
    final theme = ref.read(themeColorsProvider);

    final picked = await showDatePicker(
      context: context,
      initialDate: closeDate,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            dialogBackgroundColor: theme.adPopBackground,
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: theme.themeColor,
              onPrimary: theme.themeTextColor,
              surface: theme.adPopBackground,
              onSurface: theme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    setState(() => closeDate = DateTime(picked.year, picked.month, picked.day));
  }

  String _toRawNumber(String formatted) {
    return formatted.replaceAll(RegExp(r'[\s,_]'), '');
  }

  Future<InvoicePromptResult?> _showInvoicePrompt({
    required BuildContext context,
    required bool isSuccess,
  }) async {
    await _loadPrefs();
    if (_hideInvoicePrompt) return null;

    final theme = ref.read(themeColorsProvider);
    bool dontShowAgain = false;

    return showDialog<InvoicePromptResult>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.adPopBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            isSuccess
                ? 'create_invoice_for_transaction_question'.tr
                : 'create_invoice_for_cancellation_question'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: StatefulBuilder(
            builder: (ctx, setLocalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isSuccess
                        ? 'invoice_generation_after_completion_info'.tr
                        : 'invoice_needed_for_fees_info'.tr,
                    style: TextStyle(color: theme.textColor.withAlpha(180)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Checkbox(
                        value: dontShowAgain,
                        onChanged: (v) {
                          setLocalState(() => dontShowAgain = v ?? false);
                        },
                      ),
                      Expanded(
                        child: Text(
                          'dont_show_again_label'.tr,
                          style: TextStyle(color: theme.textColor),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(
                InvoicePromptResult(
                  createInvoice: false,
                  dontShowAgain: dontShowAgain,
                ),
              ),
              child: Text(
                'not_now_button'.tr,
                style: TextStyle(color: theme.textColor.withAlpha(200)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.themeColor,
                foregroundColor: theme.themeTextColor,
              ),
              onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(
                InvoicePromptResult(
                  createInvoice: true,
                  dontShowAgain: dontShowAgain,
                ),
              ),
              child: Text('create_invoice_button'.tr),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _buildPayload() {
    final finalAmountRawInput = _finalAmountCtrl.text.trim();
    final propertyUrl = _propertyUrlCtrl.text.trim();
    final nmIdRaw = _nmOfferIdCtrl.text.trim();

    final dateClosedIso = DateTime(
      closeDate.year,
      closeDate.month,
      closeDate.day,
    ).toIso8601String();

    final payload = <String, dynamic>{
      'success': success,
      'date_closed': dateClosedIso,
      'create_invoice': _createInvoiceAfterSubmit,
    };

    if (finalAmountRawInput.isNotEmpty) {
      final rawNumber = _toRawNumber(finalAmountRawInput);
      payload['final_amount'] = rawNumber;
      payload['final_currency'] = currency;
    }

    if (propertyUrl.isNotEmpty) {
      payload['property_url'] = propertyUrl;
    }

    if (nmIdRaw.isNotEmpty) {
      final parsed = int.tryParse(nmIdRaw);
      payload['property_nm_ad_id'] = parsed ?? nmIdRaw;
    }

    if (!success) {
      if (_failureReason != null && _failureReason!.isNotEmpty) {
        payload['failure_reason'] = _failureReason;
      }
      final details = _failureReasonDetailsCtrl.text.trim();
      if (details.isNotEmpty) {
        payload['failure_reason_details'] = details;
      }
    }

    return payload;
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _onSuccessChanged(bool v) async {
    setState(() => success = v);

    if (v == true) {
      setState(() {
        _failureReason = null;
        _failureReasonDetailsCtrl.clear();
      });
    }
  }

  Future<void> _ensureInvoiceDecisionOnSubmit() async {
    await _loadPrefs();
    if (_hideInvoicePrompt) return;

    if (_invoiceDecisionMade) return;
    if (!success) return;

    final res = await _showInvoicePrompt(context: context, isSuccess: true);
    if (res == null) return;

    if (res.dontShowAgain) {
      await _setHideInvoicePrompt(true);
    }

    if (!mounted) return;
    setState(() {
      _invoiceDecisionMade = true;
      _createInvoiceAfterSubmit = res.createInvoice;
    });
  }

  Future<void> _onSubmit() async {
    // ✅ In edit mode: do NOT ask about invoice
    if (!widget.isEditMode) {
      if (success) {
        await _ensureInvoiceDecisionOnSubmit();
      }
    }

    // FAILURE validation + optional invoice prompt (only if not edit mode)
    if (!success) {
      if (_failureReason == null || _failureReason!.isEmpty) {
        _toast(context, 'please_select_failure_reason'.tr);
        return;
      }
      if (_failureReason == 'other' &&
          _failureReasonDetailsCtrl.text.trim().isEmpty) {
        _toast(context, 'please_provide_failure_details'.tr);
        return;
      }

      if (!widget.isEditMode) {
        await _loadPrefs();
        if (!_hideInvoicePrompt && !_invoiceDecisionMade) {
          final res = await _showInvoicePrompt(context: context, isSuccess: false);
          if (res != null) {
            if (res.dontShowAgain) {
              await _setHideInvoicePrompt(true);
            }
            if (!mounted) return;
            setState(() {
              _invoiceDecisionMade = true;
              _createInvoiceAfterSubmit = res.createInvoice;
            });
          }
        }
      }
    }

    final payload = _buildPayload();
    if (!mounted) return;

    Navigator.of(context, rootNavigator: true)
        .pop(CompleteTransactionResult(payload));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final dateLabel = DateFormat('yyyy-MM-dd').format(closeDate);

    final failureReasons = <String, String>{
      'client_withdrew': 'failure_reason_client_withdrew'.tr,
      'financing_failed': 'failure_reason_financing_failed'.tr,
      'property_issue': 'failure_reason_property_issue'.tr,
      'no_contact': 'failure_reason_no_contact'.tr,
      'price_disagreement': 'failure_reason_price_disagreement'.tr,
      'other': 'failure_reason_other'.tr,
    };

    if (widget.isMobile) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (sheetContext, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.adPopBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(color: theme.dashboardBoarder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textColor.withAlpha(60),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(theme),
                        _buildFields(theme, dateLabel, failureReasons),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        width: 560,
        decoration: BoxDecoration(
          color: theme.adPopBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dashboardBoarder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme),
            _buildFields(theme, dateLabel, failureReasons),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic theme) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.themeColor,
        borderRadius: widget.isMobile
            ? null
            : const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              (widget.isEditMode
                      ? 'edit_completion_title'.tr
                      : 'complete_transaction_title'.tr)
                  .tr,
              style: TextStyle(
                color: theme.themeTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CoreIconButton(
            icon: Icons.close,
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(null),
          ),
        ],
      ),
    );
  }

  Widget _buildFields(
    dynamic theme,
    String dateLabel,
    Map<String, String> failureReasons,
  ) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CoreSwitchRow(
            title: 'success_question'.tr,
            value: success,
            onChanged: _onSuccessChanged,
          ),
          const SizedBox(height: 10),

          _CoreDateRow(
            title: 'close_date_label'.tr,
            value: dateLabel,
            onPick: () => _pickDate(context),
          ),

          const SizedBox(height: 14),
          Divider(color: theme.textColor.withAlpha(70)),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: CoreTextField(
                  label: 'final_amount_label'.tr,
                  hintText: 'e.g. 55 000 000'.tr,
                  controller: _finalAmountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    ThousandsSpaceFormatter(),
                    LengthLimitingTextInputFormatter(20),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CoreDropdown<String>(
                  label: 'currency_label'.tr,
                  value: currency,
                  options: const ['PLN', 'EUR', 'USD'],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => currency = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          CoreTextField(
            label: 'property_url_label'.tr,
            hintText: 'https://...'.tr,
            controller: _propertyUrlCtrl,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),

          CoreTextField(
            label: 'nm_offer_id_label'.tr,
            hintText: 'e.g. 123456'.tr,
            controller: _nmOfferIdCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
          ),

          if (!success) ...[
            const SizedBox(height: 14),
            Divider(color: theme.textColor.withAlpha(70)),
            const SizedBox(height: 12),

            CoreDropdown<String>(
              label: 'failure_reason_label'.tr,
              value: _failureReason,
              options: failureReasons.keys.toList(),
              display: (v) => failureReasons[v] ?? v,
              onChanged: (v) {
                setState(() {
                  _failureReason = v;
                  if (v != 'other') {
                    _failureReasonDetailsCtrl.clear();
                  }
                });
              },
            ),

            const SizedBox(height: 12),
            if (_failureReason == 'other')
              CoreTextField(
                label: 'details_label'.tr,
                hintText: 'describe_what_happened_hint'.tr,
                controller: _failureReasonDetailsCtrl,
                keyboardType: TextInputType.text,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: CoreOutlinedButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(null),
              child: Text('cancel_button'.tr),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CoreFilledButton(
              onPressed: _onSubmit,
              child: Text('submit_button'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------- helpers -------------------

class ThousandsSpaceFormatter extends TextInputFormatter {
  const ThousandsSpaceFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');

    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final indexFromEnd = digits.length - i;
      buf.write(digits[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buf.write(' ');
      }
    }

    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CoreSwitchRow extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CoreSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(160),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.textColor,
            activeTrackColor: theme.themeColor,
          ),
        ],
      ),
    );
  }
}

class _CoreDateRow extends ConsumerWidget {
  final String title;
  final String value;
  final VoidCallback onPick;

  const _CoreDateRow({
    required this.title,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final radius = BorderRadius.circular(10);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onPick,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.adPopBackground,
            borderRadius: radius,
            border: Border.all(color: theme.dashboardBoarder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(180),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 120,
                child: CoreOutlinedButton(
                  onPressed: onPick,
                  child: Text('pick_button'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
