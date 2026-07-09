

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import 'package:crm/contact_panel/viewer/viewer_provider.dart';
import 'package:core/theme/text_field.dart';









class ViewerNoteDialog extends ConsumerStatefulWidget {
  final int transactionId;
  final int viewerId;
  final String initialNote;
  const ViewerNoteDialog({
    super.key,
    required this.transactionId,
    required this.viewerId,
    required this.initialNote,
  });

  @override
  ConsumerState<ViewerNoteDialog> createState() => _ViewerNoteDialogState();
}

class _ViewerNoteDialogState extends ConsumerState<ViewerNoteDialog> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await setViewerNote(
        txId: widget.transactionId,
        viewerId: widget.viewerId,
        note: _ctrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${'failed_to_save_note'.tr} $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    return Dialog(
      backgroundColor: theme.dashboardContainer,
      child: SizedBox(
        width: 560,
        height: 360,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('viewer_note_title'.tr, style: TextStyle(color: theme.textColor, fontSize:18)),
              const SizedBox(height: 12),
              Expanded(
                child: CoreTextField(
                  controller: _ctrl,
                    label: 'enter_note_hint'.tr,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel_button'.tr, style: TextStyle(color: theme.textColor))),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: buttonStyleRounded10ThemeRedWithPadding15,
                    onPressed: _saving ? null : _save,
                    icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : AppIcons.save(color: Colors.white),
                    label: Text('save_button'.tr, style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
