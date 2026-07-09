import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:reports/reports/report_pdf_page/provider/report_notes_provider.dart';

const _primaryText = Color(0xFF171A1F);
const _secondaryText = Color(0xFF667085);
const _lightText = Color(0xFF98A2B3);
const _accent = Color(0xFF5FCDD9);
const _accentStrong = Color(0xFF2FB8C6);
const _background = Color(0xFFF6F7F9);
const _card = Colors.white;
const _border = Color(0xFFE7ECF2);
const _green = Color(0xFF16A34A);

class ReportNotesSection extends ConsumerStatefulWidget {
  final int reportId;
  final bool isMobile;

  const ReportNotesSection({
    super.key,
    required this.reportId,
    required this.isMobile,
  });

  @override
  ConsumerState<ReportNotesSection> createState() => _ReportNotesSectionState();
}

class _ReportNotesSectionState extends ConsumerState<ReportNotesSection> {
  final _controller = TextEditingController();
  bool _initialized = false;
  bool _saved = false;
  bool _dirty = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initText(String existing) {
    if (_initialized) return;
    _controller.text = existing;
    _initialized = true;
  }

  void _save() async {
    await ref
        .read(reportNotesProvider.notifier)
        .saveNote(widget.reportId, _controller.text);
    if (!mounted) return;
    setState(() {
      _saved = true;
      _dirty = false;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(reportNotesProvider);

    return notesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (notes) {
        final existing = notes[widget.reportId] ?? '';
        _initText(existing);

        return Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note_rounded,
                        size: 20, color: _accentStrong),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'agent_notes'.tr,
                          style: TextStyle(
                            fontSize: widget.isMobile ? 15 : 16,
                            fontWeight: FontWeight.w700,
                            color: _primaryText,
                          ),
                        ),
                        Text(
                          'agent_notes_subtitle'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 8,
                maxLength: 1000,
                onChanged: (_) => setState(() {
                  _dirty = true;
                  _saved = false;
                }),
                style: const TextStyle(
                  fontSize: 14,
                  color: _primaryText,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'agent_notes_placeholder'.tr,
                  hintStyle:
                      const TextStyle(fontSize: 14, color: _lightText),
                  filled: true,
                  fillColor: _background,
                  counterStyle:
                      const TextStyle(fontSize: 11, color: _lightText),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _accentStrong, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!_dirty && existing.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 14, color: _green),
                        const SizedBox(width: 5),
                        Text(
                          'note_saved'.tr,
                          style: const TextStyle(
                              fontSize: 12, color: _green),
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),
                  GestureDetector(
                    onTap: _dirty ? _save : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: _saved
                            ? _green.withOpacity(0.12)
                            : _dirty
                                ? _accentStrong.withOpacity(0.12)
                                : _border,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _saved
                              ? _green.withOpacity(0.35)
                              : _dirty
                                  ? _accentStrong.withOpacity(0.35)
                                  : _border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _saved
                                ? Icons.check_rounded
                                : Icons.save_outlined,
                            size: 15,
                            color: _saved
                                ? _green
                                : _dirty
                                    ? _accentStrong
                                    : _lightText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _saved
                                ? 'saved'.tr
                                : 'save_note'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _saved
                                  ? _green
                                  : _dirty
                                      ? _accentStrong
                                      : _lightText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
