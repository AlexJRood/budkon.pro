
import 'package:docs/emma/anchors/docs_emma_anchors.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';



class VersionCommentSheet extends ConsumerStatefulWidget {
  const VersionCommentSheet({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  ConsumerState<VersionCommentSheet> createState() =>
      _VersionCommentSheetState();
}

class _VersionCommentSheetState extends ConsumerState<VersionCommentSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  void _submit() {
    final text = _controller.text.trim();
    Navigator.pop(context, text.isEmpty ? "Version saved" : text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return EmmaUiAnchorTarget(
        anchorKey: DocsEmmaAnchors.versionCommentSheet.anchorKey,

        spec: DocsEmmaAnchors.versionCommentSheet,
        runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
        tapMode: EmmaUiAnchorTapMode.disabled,
      child: Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
        child: ListView(
          controller: widget.scrollController,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            // drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.textColor.withAlpha(80),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
      
            // header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Save Version",
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: theme.textColor),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
      
            const SizedBox(height: 10),
      
            EmmaUiAnchorTarget(
                anchorKey: DocsEmmaAnchors.versionCommentField.anchorKey,

                spec: DocsEmmaAnchors.versionCommentField,
                runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
              child: TextFormField(
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
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
            ),
      
            const SizedBox(height: 14),
      
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
                const SizedBox(width: 10),
                EmmaUiAnchorTarget(
                   anchorKey: DocsEmmaAnchors.saveVersionConfirmButton.anchorKey,

                   spec: DocsEmmaAnchors.saveVersionConfirmButton,
                   runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                   tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                    child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.themeColor,
                    ),
                    onPressed: _submit,
                    child: Text(
                      "Save Version",
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
