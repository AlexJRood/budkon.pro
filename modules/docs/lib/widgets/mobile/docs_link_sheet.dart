
import 'package:docs/emma/anchors/docs_emma_anchors.dart';
import 'package:docs/widgets/sheet_scaffold.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:core/theme/apptheme.dart';


class DocsLinkSheet extends StatefulWidget {
  const DocsLinkSheet({
    super.key,
    required this.scrollController,
    required this.quillController,
    required this.theme,
  });

  final ScrollController scrollController;
  final QuillController quillController;
  final ThemeColors theme;

  @override
  State<DocsLinkSheet> createState() => _DocsLinkSheetState();
}

class _DocsLinkSheetState extends State<DocsLinkSheet> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();

    final attrs = widget.quillController.getSelectionStyle().attributes;
    final currentLink = attrs[Attribute.link.key]?.value?.toString() ?? '';
    _urlController = TextEditingController(text: currentLink);
  }

  bool get _hasSelection {
    final sel = widget.quillController.selection;
    return sel.baseOffset != sel.extentOffset;
  }

  String _normalizeUrl(String v) {
    final t = v.trim();
    if (t.isEmpty) return t;
    final parsed = Uri.tryParse(t);
    if (parsed == null) return t;
    if (parsed.hasScheme) return t;
    return 'https://$t';
  }

  void _apply() {
    if (!_hasSelection) return;

    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    final normalized = _normalizeUrl(url);
    final linkAttr = Attribute.fromKeyValue(Attribute.link.key, normalized);
    if (linkAttr != null) widget.quillController.formatSelection(linkAttr);

    Navigator.of(context).pop();
  }

  void _remove() {
    final linkAttr = Attribute.fromKeyValue(Attribute.link.key, null);
    if (linkAttr != null) widget.quillController.formatSelection(linkAttr);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final url = _urlController.text.trim();
    final canApply = _hasSelection && url.isNotEmpty;

    return EmmaUiAnchorTarget(
      anchorKey: DocsEmmaAnchors.linkSheet.anchorKey,

      spec: DocsEmmaAnchors.linkSheet,
      runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
        child: SheetScaffold(
          scrollController: widget.scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Insert link",
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (!_hasSelection)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    "Select some text first to apply a link.",
                    style: TextStyle(color: theme.textColor.withAlpha(200)),
                  ),
                ),
              EmmaUiAnchorTarget(
                anchorKey: DocsEmmaAnchors.linkUrlField.anchorKey,

                spec: DocsEmmaAnchors.linkUrlField,
                runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                child: TextFormField(
                  controller: _urlController,
                  autofocus: true,
                  cursorColor: theme.textColor,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.textFieldColor, // ✅ same as title sheet
                    hintText: "https://example.com",
                    hintStyle: TextStyle(color: theme.textColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (canApply) _apply();
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                url.isEmpty
                    ? "Tip: paste a URL, we’ll keep it."
                    : "Will be saved as: ${_normalizeUrl(url)}",
                style: TextStyle(color: theme.textColor.withAlpha(200)),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child:
                        Text("Cancel", style: TextStyle(color: theme.textColor)),
                  ),
                  const SizedBox(width: 8),
                  EmmaUiAnchorTarget(
                     anchorKey: DocsEmmaAnchors.removeLinkButton.anchorKey,

                     spec: DocsEmmaAnchors.removeLinkButton,
                     runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                     tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                    child: TextButton(
                      onPressed: _remove,
                      child:
                          Text("Remove", style: TextStyle(color: theme.textColor)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  EmmaUiAnchorTarget(
                     anchorKey: DocsEmmaAnchors.applyLinkButton.anchorKey,

                     spec: DocsEmmaAnchors.applyLinkButton,
                    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.themeColor,
                      ),
                      onPressed: canApply ? _apply : null,
                      child:
                          Text("Apply", style: TextStyle(color: theme.textColor)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
