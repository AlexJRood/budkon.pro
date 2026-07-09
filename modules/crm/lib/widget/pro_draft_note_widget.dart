// pro_draft_note_widget.dart
import 'package:core/ui/device_type_util.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

// API
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

/// Prosty wrapper – opcjonalny
class ProDraftNoteWidget extends StatelessWidget {
  final AgentTransactionModel transaction;
  final String? initialNote;
  final bool isMobile;

  const ProDraftNoteWidget({
    super.key,
    this.isMobile = false,
    required this.transaction,
    this.initialNote,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding:  EdgeInsets.only(right: isMobile ? 0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: isMobile ? TopAppBarSize.resolve(context) : 30),
            Expanded(
              child: TransactionNoteEditor(
                transaction: transaction,
                initialNote: initialNote,
                isMobile: isMobile,
              ),
            ),          
            SizedBox(height: isMobile ? BottomBarSize.resolve(context) : 0),
          ],
        ),
      ),
    );
  }
}

/// Samodzielny edytor notatki (pole + „Zapisz notatkę”)
class TransactionNoteEditor extends ConsumerStatefulWidget {
  final AgentTransactionModel transaction;
  final String? initialNote;
  final bool isMobile;

  const TransactionNoteEditor({
    super.key,
    this.isMobile = false,
    required this.transaction,
    this.initialNote,
  });

  // ⬇⬇ POPRAWKA: zwracamy ConsumerState<...>, a nie State<...>
  @override
  ConsumerState<TransactionNoteEditor> createState() => _TransactionNoteEditorState();
}

class _TransactionNoteEditorState extends ConsumerState<TransactionNoteEditor> {
  final _focusNode = FocusNode();
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.transaction.note ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      // Podmień na właściwy helper endpointu, jeśli u Ciebie nazywa się inaczej
      final url = URLs.updateRevenuesCrm(widget.transaction.id.toString());

      final resp = await ApiServices.patch(
        url,
        hasToken: true,
        data: {'note': _ctrl.text.trim()},
      );

      final sc = resp?.statusCode ?? 0;
      if (resp == null || sc >= 300) {
        throw Exception('HTTP $sc');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('note_saved_message'.tr)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'failed_to_save_note'.tr} $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0,right: 8),
      child: Column(
        crossAxisAlignment: widget.isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.end,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).requestFocus(_focusNode),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                ),
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focusNode,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.edit_calendar_rounded, color: theme.textColor),
                    fillColor: theme.dashboardContainer,
                    hintText: 'Notes...'.tr,
                    hintStyle: TextStyle(color: theme.textColor, fontSize: 16),
                    border: const OutlineInputBorder(borderSide: BorderSide.none),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide.none),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide.none),
                    disabledBorder: const OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.themeColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: _saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.dashboardContainer),
                      ),
                    )
                  : Text(
                      'save_note_button'.tr,
                      style: TextStyle(color: theme.dashboardContainer),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
