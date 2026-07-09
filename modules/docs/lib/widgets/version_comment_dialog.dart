import 'package:docs/emma/anchors/docs_emma_anchors.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

class VersionCommentDialog extends ConsumerStatefulWidget {
  const VersionCommentDialog({super.key});

  @override
  ConsumerState<VersionCommentDialog> createState() =>
      _VersionCommentDialogState();
}

class _VersionCommentDialogState extends ConsumerState<VersionCommentDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return EmmaUiAnchorTarget(
        anchorKey: DocsEmmaAnchors.versionCommentDialog.anchorKey,

        spec: DocsEmmaAnchors.versionCommentDialog,
        runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
        tapMode: EmmaUiAnchorTapMode.disabled,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: 500,
          height: 260,
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Save Version',
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  cursorColor: theme.textColor,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'e.g. "Added payment terms"',
                    hintStyle: TextStyle(color: theme.textColor.withAlpha(153)),
                    filled: true,
                    fillColor: theme.adPopBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 3,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.themeColor,
                      ),
                      onPressed: () {
                        final text = _controller.text.trim();
                        Navigator.pop(
                            context, text.isEmpty ? "Version saved" : text);
                      },
                      child: Text('Save Version',
                          style: TextStyle(color: theme.textColor)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
