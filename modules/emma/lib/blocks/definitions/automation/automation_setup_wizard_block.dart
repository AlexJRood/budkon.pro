import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';
import 'package:emma/provider/emma_notifier.dart';

class AutomationSetupWizardBlockDefinition extends EmmaBlockDefinition {
  const AutomationSetupWizardBlockDefinition();

  @override
  String get key => 'automation_setup_wizard';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.automationSetupWizard;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _AutomationSetupWizardCard(
      block: block,
      maxWidth: maxWidth,
      messageId: messageId,
    );
  }
}

// ---------------------------------------------------------------------------

class _WizardOption {
  final String id;
  final String label;
  final String? description;
  final String? icon;

  const _WizardOption({
    required this.id,
    required this.label,
    this.description,
    this.icon,
  });

  factory _WizardOption.fromMap(Map<String, dynamic> m) {
    return _WizardOption(
      id: (m['id'] ?? m['value'] ?? m['label'] ?? '').toString(),
      label: (m['label'] ?? m['title'] ?? m['name'] ?? '').toString(),
      description: m['description']?.toString(),
      icon: m['icon']?.toString(),
    );
  }
}

class _WizardQuestion {
  final String id;
  final String question;
  final String? hint;
  final String inputType;
  final List<_WizardOption> options;
  final bool multiSelect;

  const _WizardQuestion({
    required this.id,
    required this.question,
    this.hint,
    required this.inputType,
    required this.options,
    required this.multiSelect,
  });

  factory _WizardQuestion.fromMap(Map<String, dynamic> m) {
    final rawOptions = m['options'];
    final options = rawOptions is List
        ? rawOptions
            .whereType<Map>()
            .map((e) => _WizardOption.fromMap(Map<String, dynamic>.from(e)))
            .toList()
        : <_WizardOption>[];

    return _WizardQuestion(
      id: (m['id'] ?? '').toString(),
      question: (m['question'] ?? m['label'] ?? '').toString(),
      hint: m['hint']?.toString(),
      inputType: (m['input_type'] ?? 'choice').toString(),
      options: options,
      multiSelect: m['multi_select'] == true,
    );
  }
}

class _WizardPayload {
  final String title;
  final String intent;
  final int step;
  final int totalSteps;
  final List<_WizardQuestion> questions;
  final String? workflowId;

  const _WizardPayload({
    required this.title,
    required this.intent,
    required this.step,
    required this.totalSteps,
    required this.questions,
    this.workflowId,
  });

  factory _WizardPayload.fromBlock(EmmaBlockDescriptor block) {
    final root = block.raw;
    final wizard = root['wizard'] is Map
        ? Map<String, dynamic>.from(root['wizard'] as Map)
        : root;

    final rawQuestions = wizard['questions'] ?? root['questions'];
    final questions = rawQuestions is List
        ? rawQuestions
            .whereType<Map>()
            .map((e) => _WizardQuestion.fromMap(Map<String, dynamic>.from(e)))
            .toList()
        : <_WizardQuestion>[];

    return _WizardPayload(
      title: (wizard['title'] ?? root['title'] ?? 'automation_setup'.tr).toString(),
      intent: (wizard['intent'] ?? root['intent'] ?? '').toString(),
      step: (wizard['step'] as int?) ?? 1,
      totalSteps: (wizard['total_steps'] as int?) ?? 1,
      questions: questions,
      workflowId: wizard['workflow_id']?.toString() ?? root['workflow_id']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------

class _AutomationSetupWizardCard extends ConsumerStatefulWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;
  final String messageId;

  const _AutomationSetupWizardCard({
    required this.block,
    required this.maxWidth,
    required this.messageId,
  });

  @override
  ConsumerState<_AutomationSetupWizardCard> createState() =>
      _AutomationSetupWizardCardState();
}

class _AutomationSetupWizardCardState
    extends ConsumerState<_AutomationSetupWizardCard> {
  // questionId → wybrany/e option id (dla chip/choice questions)
  final Map<String, Set<String>> _selections = {};
  // questionId → wolny tekst (dla text/number questions)
  final Map<String, TextEditingController> _textCtrl = {};
  bool _submitted = false;

  Color get _accent => const Color(0xFF7C4DFF);

  @override
  void dispose() {
    for (final c in _textCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrlFor(String questionId) {
    return _textCtrl.putIfAbsent(questionId, TextEditingController.new);
  }

  void _toggle(String questionId, String optionId, bool multiSelect) {
    if (_submitted) return;
    setState(() {
      final current = _selections[questionId] ?? {};
      if (multiSelect) {
        if (current.contains(optionId)) {
          current.remove(optionId);
        } else {
          current.add(optionId);
        }
        _selections[questionId] = current;
      } else {
        _selections[questionId] = {optionId};
      }
    });
  }

  bool _isSelected(String questionId, String optionId) {
    return _selections[questionId]?.contains(optionId) ?? false;
  }

  bool _isTextType(String inputType) =>
      inputType == 'text' || inputType == 'number' || inputType == 'url' || inputType == 'email';

  bool get _canConfirm {
    final p = _WizardPayload.fromBlock(widget.block);
    for (final q in p.questions) {
      if (_isTextType(q.inputType)) {
        if ((_textCtrl[q.id]?.text ?? '').trim().isEmpty) return false;
      } else {
        if ((_selections[q.id] ?? {}).isEmpty) return false;
      }
    }
    return true;
  }

  void _confirm(_WizardPayload p) {
    if (!_canConfirm) return;
    setState(() => _submitted = true);

    final answerLines = <String>[];
    final answersMap = <String, String>{};

    for (final q in p.questions) {
      if (_isTextType(q.inputType)) {
        final value = (_textCtrl[q.id]?.text ?? '').trim();
        answerLines.add('${q.question}: $value');
        answersMap[q.id] = value;
      } else {
        final selectedIds = _selections[q.id] ?? {};
        final labels = q.options
            .where((o) => selectedIds.contains(o.id))
            .map((o) => o.label)
            .join(', ');
        answerLines.add('${q.question}: $labels');
        answersMap[q.id] = labels;
      }
    }

    final summaryText = answerLines.join('\n');

    ref.read(chatAiMessageProvider.notifier).submitAutomationWizardAnswers(
          workflowId: p.workflowId ?? '',
          answers: answersMap,
          summaryText: summaryText,
        );
  }

  @override
  Widget build(BuildContext context) {
    final p = _WizardPayload.fromBlock(widget.block);
    final accent = _accent;

    return EmmaBlockCardShell(
      maxWidth: widget.maxWidth,
      borderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // nagłówek + postęp
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 13, color: accent),
              const SizedBox(width: 5),
              Text(
                p.title,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (p.totalSteps > 1) ...[
                const Spacer(),
                Text(
                  '${p.step}/${p.totalSteps}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),

          if (p.intent.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              p.intent,
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // pytania
          ...p.questions.map((q) => _isTextType(q.inputType)
              ? _TextQuestionSection(
                  question: q,
                  controller: _ctrlFor(q.id),
                  disabled: _submitted,
                  accent: accent,
                  onChanged: (_) => setState(() {}),
                )
              : _QuestionSection(
                  question: q,
                  selections: _selections[q.id] ?? {},
                  disabled: _submitted,
                  accent: accent,
                  onToggle: (optionId) =>
                      _toggle(q.id, optionId, q.multiSelect),
                  isSelected: (optionId) => _isSelected(q.id, optionId),
                )),

          const SizedBox(height: 8),

          if (!_submitted)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canConfirm ? () => _confirm(p) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  disabledBackgroundColor: accent.withAlpha(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(
                  'automation_wizard_confirm'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 14, color: Colors.greenAccent),
                  const SizedBox(width: 5),
                  Text(
                    'automation_wizard_sent'.tr,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _QuestionSection extends StatelessWidget {
  final _WizardQuestion question;
  final Set<String> selections;
  final bool disabled;
  final Color accent;
  final void Function(String optionId) onToggle;
  final bool Function(String optionId) isSelected;

  const _QuestionSection({
    required this.question,
    required this.selections,
    required this.disabled,
    required this.accent,
    required this.onToggle,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (question.hint != null && question.hint!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              question.hint!,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: question.options.map((opt) {
              final selected = isSelected(opt.id);
              return GestureDetector(
                onTap: disabled ? null : () => onToggle(opt.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? accent.withAlpha(40)
                        : Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? accent
                          : Colors.white.withAlpha(40),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (opt.icon != null && opt.icon!.isNotEmpty) ...[
                        Text(opt.icon!, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        opt.label,
                        style: TextStyle(
                          color: selected ? accent : Colors.white70,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _TextQuestionSection extends StatelessWidget {
  final _WizardQuestion question;
  final TextEditingController controller;
  final bool disabled;
  final Color accent;
  final void Function(String) onChanged;

  const _TextQuestionSection({
    required this.question,
    required this.controller,
    required this.disabled,
    required this.accent,
    required this.onChanged,
  });

  TextInputType get _keyboardType {
    switch (question.inputType) {
      case 'number':
        return TextInputType.number;
      case 'url':
        return TextInputType.url;
      case 'email':
        return TextInputType.emailAddress;
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter>? get _formatters {
    if (question.inputType == 'number') {
      return [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (question.hint != null && question.hint!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              question.hint!,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            enabled: !disabled,
            onChanged: onChanged,
            keyboardType: _keyboardType,
            inputFormatters: _formatters,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: question.inputType == 'text' ? 3 : 1,
            minLines: 1,
            decoration: InputDecoration(
              hintText: question.hint ?? '',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
              filled: true,
              fillColor: Colors.white.withAlpha(12),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withAlpha(30)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withAlpha(30)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: accent),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withAlpha(15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
