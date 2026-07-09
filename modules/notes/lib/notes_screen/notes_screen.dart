import 'dart:ui' as ui;

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/text_field.dart';

import 'model/note_model.dart';
import 'provider/notes_provider.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final GlobalKey<SideMenuState> _sideMenuKey = GlobalKey<SideMenuState>();

  NoteModel? _selected;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();
  bool _isDirty = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _newNote() async {
    await _saveCurrentIfDirty();
    final note = await ref.read(notesProvider.notifier).createNote(
          title: '',
          content: '',
        );
    if (note != null) _selectNote(note);
  }

  void _selectNote(NoteModel note) {
    setState(() {
      _selected = note;
      _titleCtrl.text = note.title;
      _bodyCtrl.text = note.content;
      _isDirty = false;
    });
  }

  Future<void> _saveCurrentIfDirty() async {
    if (_selected == null || !_isDirty || _isSaving) return;
    setState(() => _isSaving = true);
    await ref.read(notesProvider.notifier).updateNote(
          id: _selected!.id,
          title: _titleCtrl.text,
          content: _bodyCtrl.text,
        );
    if (mounted) {
      setState(() {
        _isDirty = false;
        _isSaving = false;
      });
    }
  }

  Future<void> _deleteNote(NoteModel note) async {
    final ok = await ref.read(notesProvider.notifier).deleteNote(note.id);
    if (!ok || !mounted) return;
    if (_selected?.id == note.id) {
      final remaining = ref.read(notesProvider).valueOrNull ?? [];
      setState(() {
        _selected = remaining.isNotEmpty ? remaining.first : null;
        if (_selected != null) {
          _titleCtrl.text = _selected!.title;
          _bodyCtrl.text = _selected!.content;
        } else {
          _titleCtrl.clear();
          _bodyCtrl.clear();
        }
        _isDirty = false;
      });
    }
  }

  void _markDirty() => setState(() => _isDirty = true);

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);

    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.notes,
      isChildExpanded: true,
      childPc: _buildDesktop(notesAsync),
      childMobile: _buildMobile(notesAsync),
    );
  }

  Widget _buildDesktop(AsyncValue<List<NoteModel>> notesAsync) {
    return Row(
      children: [
        _NotesSidebar(
          notesAsync: notesAsync,
          selected: _selected,
          onSelect: (n) async {
            await _saveCurrentIfDirty();
            _selectNote(n);
          },
          onNew: _newNote,
          onDelete: _deleteNote,
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selected != null
              ? _NoteEditor(
                  titleCtrl: _titleCtrl,
                  bodyCtrl: _bodyCtrl,
                  isSaving: _isSaving,
                  onChanged: _markDirty,
                  onSave: _saveCurrentIfDirty,
                )
              : _EmptyState(onNew: _newNote),
        ),
      ],
    );
  }

  Widget _buildMobile(AsyncValue<List<NoteModel>> notesAsync) {
    if (_selected != null) {
      return Column(
        children: [
          _NotesMobileBar(
            isSaving: _isSaving,
            onBack: () async {
              await _saveCurrentIfDirty();
              if (mounted) setState(() { _selected = null; _isDirty = false; });
            },
            onSave: _saveCurrentIfDirty,
            onDelete: () => _deleteNote(_selected!),
          ),
          Expanded(
            child: _NoteEditor(
              titleCtrl: _titleCtrl,
              bodyCtrl: _bodyCtrl,
              isSaving: _isSaving,
              onChanged: _markDirty,
              onSave: _saveCurrentIfDirty,
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        _NotesSidebar(
          notesAsync: notesAsync,
          selected: null,
          onSelect: _selectNote,
          onNew: _newNote,
          onDelete: _deleteNote,
          fullWidth: true,
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _newNote,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _NotesSidebar extends ConsumerWidget {
  final AsyncValue<List<NoteModel>> notesAsync;
  final NoteModel? selected;
  final void Function(NoteModel) onSelect;
  final Future<void> Function(NoteModel) onDelete;
  final VoidCallback onNew;
  final bool fullWidth;

  const _NotesSidebar({
    required this.notesAsync,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
    required this.onNew,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return SizedBox(
      width: fullWidth ? double.infinity : 280,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'label_notes'.tr,
                    style: AppTextStyles.interBold.copyWith(
                      fontSize: 18,
                      color: theme.textColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: AppIcons.add(width: 22, height: 22),
                  onPressed: onNew,
                  tooltip: 'label_new_note'.tr,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: notesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  '$e',
                  style: AppTextStyles.interRegular.copyWith(
                    color: theme.textColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              data: (notes) => notes.isEmpty
                  ? Center(
                      child: Text(
                        'label_no_notes'.tr,
                        style: AppTextStyles.interRegular.copyWith(
                          color: theme.textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: notes.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16),
                      itemBuilder: (_, i) {
                        final note = notes[i];
                        final isSelected = selected?.id == note.id;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor:
                              theme.adPopBackground.withValues(alpha: 0.15),
                          title: Text(
                            note.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.interRegular.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: theme.textColor,
                            ),
                          ),
                          subtitle: note.preview.isNotEmpty
                              ? Text(
                                  note.preview,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.interLight.copyWith(
                                    fontSize: 11,
                                    color:
                                        theme.textColor.withValues(alpha: 0.6),
                                  ),
                                )
                              : null,
                          onTap: () => onSelect(note),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => onDelete(note),
                            color: theme.textColor.withValues(alpha: 0.4),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteEditor extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController bodyCtrl;
  final bool isSaving;
  final VoidCallback onChanged;
  final Future<void> Function() onSave;

  const _NoteEditor({
    required this.titleCtrl,
    required this.bodyCtrl,
    required this.isSaving,
    required this.onChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CoreTextField(
            label: 'label_note_title'.tr,
            controller: titleCtrl,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: CoreTextField(
                label: 'label_note_body'.tr,
                controller: bodyCtrl,
                maxLines: 30,
                minLines: 15,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => onChanged(),
              ),
            ),
          ),
          if (isSaving)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  final VoidCallback onNew;

  const _EmptyState({required this.onNew});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.note_outlined,
            size: 64,
            color: theme.textColor.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            'label_no_note_selected'.tr,
            style: AppTextStyles.interRegular.copyWith(
              color: theme.textColor.withValues(alpha: 0.5),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add),
            label: Text('label_new_note'.tr),
          ),
        ],
      ),
    );
  }
}

class _NotesMobileBar extends ConsumerWidget {
  final bool isSaving;
  final VoidCallback onBack;
  final Future<void> Function() onSave;
  final VoidCallback onDelete;

  const _NotesMobileBar({
    required this.isSaving,
    required this.onBack,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return SizedBox(
      height: TopAppBarSize.resolve(context),
      width: double.infinity,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: theme.sidebar,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: IconButton(
                    icon: AppIcons.iosArrowLeft(
                      color: theme.textColor,
                      height: 25,
                      width: 25,
                    ),
                    onPressed: onBack,
                  ),
                ),
                const Spacer(),
                if (isSaving)
                  const SizedBox(
                    width: 60,
                    height: 60,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: IconButton(
                      icon: Icon(Icons.check, color: theme.textColor),
                      onPressed: onSave,
                    ),
                  ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, color: theme.textColor.withValues(alpha: 0.7)),
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
