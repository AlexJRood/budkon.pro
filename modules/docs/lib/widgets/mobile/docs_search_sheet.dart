
import 'package:docs/emma/anchors/docs_emma_anchors.dart';
import 'package:docs/widgets/sheet_scaffold.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:core/theme/apptheme.dart';


class DocsSearchSheet extends StatefulWidget {
  const DocsSearchSheet({
    super.key,
    required this.scrollController,
    required this.quillController,
    required this.theme,
  });

  final ScrollController scrollController;
  final QuillController quillController;
  final ThemeColors theme;

  @override
  State<DocsSearchSheet> createState() => _DocsSearchSheetState();
}

class _DocsSearchSheetState extends State<DocsSearchSheet> {
  late final TextEditingController _textController;
  List<int> _matches = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  void _computeMatches(String q) {
    _matches = [];
    _currentIndex = 0;

    if (q.trim().isEmpty) return;

    final plain = widget.quillController.document.toPlainText();
    var start = 0;

    while (true) {
      final found = plain.indexOf(q, start);
      if (found == -1) break;
      _matches.add(found);
      start = found + q.length;
    }
  }

  void _goTo(int idx) {
    if (_matches.isEmpty) return;

    final start = _matches[idx];
    final end = start + _textController.text.length;

    widget.quillController.updateSelection(
      TextSelection(baseOffset: start, extentOffset: end),
      ChangeSource.local,
    );
  }

  void _next() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _matches.length;
      _goTo(_currentIndex);
    });
  }

  void _prev() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + _matches.length) % _matches.length;
      _goTo(_currentIndex);
    });
  }

  void _close() {
    widget.quillController.updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final q = _textController.text.trim();
    final hasMatches = _matches.isNotEmpty;

    return EmmaUiAnchorTarget(
      anchorKey: DocsEmmaAnchors.searchSheet.anchorKey,

      spec: DocsEmmaAnchors.searchSheet,
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
                "Search",
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              EmmaUiAnchorTarget(
               anchorKey: DocsEmmaAnchors.searchTextField.anchorKey,

               spec: DocsEmmaAnchors.searchTextField,
                runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                child: TextFormField(
                  controller: _textController,
                  autofocus: true,
                  cursorColor: theme.textColor,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.textFieldColor,
                    hintText: 'Find text in document...',
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
                  onChanged: (value) {
                    setState(() {
                      _computeMatches(value);
                      if (_matches.isNotEmpty) {
                        _currentIndex = 0;
                        _goTo(_currentIndex);
                      } else {
                        widget.quillController.updateSelection(
                          const TextSelection.collapsed(offset: 0),
                          ChangeSource.local,
                        );
                      }
                    });
                  },
                  onFieldSubmitted: (_) => _next(),
                  textInputAction: TextInputAction.search,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      q.isEmpty
                          ? "Type to search…"
                          : hasMatches
                              ? "Match ${_currentIndex + 1} of ${_matches.length}"
                              : "No matches",
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                  EmmaUiAnchorTarget(
                     anchorKey: DocsEmmaAnchors.searchPreviousButton.anchorKey,

                     spec: DocsEmmaAnchors.searchPreviousButton,
                     runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                     tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                    child: IconButton(
                      onPressed: hasMatches ? _prev : null,
                      icon: Icon(Icons.arrow_back, color: theme.textColor),
                    ),
                  ),
                  EmmaUiAnchorTarget(
                    anchorKey: DocsEmmaAnchors.searchNextButton.anchorKey,

                    spec: DocsEmmaAnchors.searchNextButton,
                    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                    child: IconButton(
                      onPressed: hasMatches ? _next : null,
                      icon: Icon(Icons.arrow_forward, color: theme.textColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _close,
                    child:
                        Text("Close", style: TextStyle(color: theme.textColor)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: hasMatches ? _next : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.themeColor,
                    ),
                    child: Text("Next", style: TextStyle(color: theme.textColor)),
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
    _textController.dispose();
    super.dispose();
  }
}
