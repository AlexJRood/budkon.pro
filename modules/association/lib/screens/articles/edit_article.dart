// lib/article/edit_association_article_page.dart
import 'dart:io';
import 'package:association/providers/articles.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/text_field.dart';

/// Detail provider (local): fetch single article by id.
/// Returns full article JSON (Map) from backend.
final articleDetailProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, articleId) async {
  return ArticleApi.getArticle(ref: ref, articleId: articleId);
});

// na górze pliku
const kAllowedStatuses = <String>[
  'draft',
  'published',
  'new', // <-- backend zwraca "new"
  'archived', // <-- jeżeli używasz
];

String _labelForStatus(String s) {
  switch (s) {
    case 'draft':
      return 'Szkic';
    case 'published':
      return 'Opublikowany';
    case 'new':
      return 'Nowy';
    case 'archived':
      return 'Zarchiwizowany';
    default:
      return s;
  }
}

/// Edit page for an association article.
/// We pass associationId (for list invalidation) and articleId to edit.
class EditAssociationArticlePage extends ConsumerStatefulWidget {
  final int associationId;
  final int articleId;
  const EditAssociationArticlePage({
    super.key,
    required this.associationId,
    required this.articleId,
  });

  @override
  ConsumerState<EditAssociationArticlePage> createState() =>
      _EditAssociationArticlePageState();
}

class _EditAssociationArticlePageState
    extends ConsumerState<EditAssociationArticlePage> {
  final _formKey = GlobalKey<FormState>();

  // status trzymamy jako string
  String _status = 'draft'; // or 'published'

  // Core text controllers
  final _titleCtrl = TextEditingController();
  final _seoTitleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _seoTagsCtrl = TextEditingController();
  File? _thumbnailFile;

  bool _initializedFromData = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _seoTitleCtrl.dispose();
    _bodyCtrl.dispose();
    _tagsCtrl.dispose();
    _seoTagsCtrl.dispose();
    super.dispose();
  }

  // --- helpers ---
  List<int> _parseIds(String raw) {
    return raw
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .where((v) => v != null)
        .cast<int>()
        .toList();
  }

  String _idsToCsv(dynamic list) {
    if (list is List) {
      final ints = list
          .map((e) {
            if (e is int) return e;
            if (e is Map && e['id'] != null) return e['id'] as int;
            if (e is String) return int.tryParse(e);
            return null;
          })
          .where((e) => e != null)
          .cast<int>()
          .toList();
      return ints.join(',');
    }
    return '';
  }

  Future<void> _pickThumbnail() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image);
    if (res != null && res.files.single.path != null) {
      setState(() => _thumbnailFile = File(res.files.single.path!));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleCtrl.text.trim();
    final seoTitle = _seoTitleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    final updater = ref.read(updateArticleControllerProvider.notifier);

    try {
      final updated = await updater.update(
        articleId: widget.articleId,
        title: title,
        body: body,
        status: _status,
        seoTitle: seoTitle.isEmpty ? null : seoTitle,
        tagIds: _parseIds(_tagsCtrl.text),
        seoTagIds: _parseIds(_seoTagsCtrl.text),
      );

      // optional thumbnail upload
      if (_thumbnailFile != null && updated['id'] != null) {
        await ArticleApi.uploadThumbnail(
          ref: ref,
          articleId: updated['id'] as int,
          file: _thumbnailFile!,
        );
      }

      // refresh article detail + association list
      ref.invalidate(articleDetailProvider(widget.articleId));
      ref.invalidate(
        associationArticlesProvider(
          ArticleListArgs(associationId: widget.associationId),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zapisano zmiany ✅')),
      );
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: $e')),
      );
    }
  }

  void _prefillFromData(Map<String, dynamic> data) {
    // title, body, status, seoTitle
    final title = (data['title'] ?? '') as String;
    final body = (data['body'] ?? '') as String;
    final status = (data['status'] ?? 'draft') as String;
    final seoTitle = (data['seoTitle'] ?? '') as String;

    _titleCtrl.text = title;
    _bodyCtrl.text = body;
    _seoTitleCtrl.text = seoTitle;
    _status = status;

    // tags/seoTags come various shapes; convert to CSV for text fields
    _tagsCtrl.text = _idsToCsv(data['tags']);
    _seoTagsCtrl.text = _idsToCsv(data['seoTags']);
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(articleDetailProvider(widget.articleId));
    final updateState = ref.watch(updateArticleControllerProvider);
    final isSubmitting = updateState.isLoading;
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        // Header row (used on PC + mobile)
        Widget buildHeader() {
          return Row(
            children: [
              if (isMobile)
                IconButton(
                  icon: Icon(Icons.arrow_back, color: theme.textColor),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              Text(
                'Edytuj artykuł #${widget.articleId}',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (v) => setState(() => _status = v),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'draft', child: Text('Ustaw: Szkic')),
                  PopupMenuItem(
                      value: 'published', child: Text('Ustaw: Opublikowany')),
                ],
                icon: Icon(Icons.tune, color: theme.textColor),
              ),
            ],
          );
        }

        // Główne body zależne od stanu providera
        Widget buildDetailBody() {
          return detail.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Błąd wczytania: $e')),
            data: (data) {
              // initialize form once from fetched data
              if (!_initializedFromData) {
                _prefillFromData(data);
                _initializedFromData = true;
              }

              return Expanded(
                child: AbsorbPointer(
                  absorbing: isSubmitting,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          // Context chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                  label: Text(
                                      'Stowarzyszenie ID: ${widget.associationId}')),
                              Chip(
                                  label:
                                      Text('Status: ${_status.toUpperCase()}')),
                              if (data['publisher_public']?['company_name'] !=
                                  null)
                                Chip(
                                  label: Text(
                                      'Publisher: ${data['publisher_public']['company_name']}'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Title
                          CoreTextFormField(
                            label: 'Tytuł',
                            controller: _titleCtrl,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Wpisz tytuł'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // SEO Title
                          CoreTextFormField(
                            label: 'SEO Title (opcjonalnie)',
                            controller: _seoTitleCtrl,
                          ),
                          const SizedBox(height: 12),

                          // Body
                          CoreTextFormField(
                            label: 'Treść',
                            controller: _bodyCtrl,
                            maxLines: 10,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Wpisz treść'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Status dropdown
                          DropdownButtonFormField<String>(
                            value: kAllowedStatuses.contains(_status)
                                ? _status
                                : 'draft',
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: kAllowedStatuses
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(_labelForStatus(s)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _status = v ?? 'draft'),
                          ),
                          const SizedBox(height: 12),

                          // Tags / SEO tags CSV
                          CoreTextFormField(
                            label: 'Tag IDs (CSV)',
                            hintText: 'np. 1,2,5',
                            controller: _tagsCtrl,
                          ),
                          const SizedBox(height: 12),

                          CoreTextFormField(
                            label: 'SeoTag IDs (CSV)',
                            hintText: 'np. 3,4',
                            controller: _seoTagsCtrl,
                          ),
                          const SizedBox(height: 12),

                          // Thumbnail picker
                          Row(
                            children: [
                              ElevatedButton(
                                style: elevatedButtonStyleRounded10,
                                onPressed: _pickThumbnail,
                                child: Row(
                                  children: [
                                    Icon(Icons.image,
                                        color: theme.textColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Wybierz miniaturę',
                                      style:
                                          TextStyle(color: theme.textColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _thumbnailFile?.path
                                          .split(Platform.pathSeparator)
                                          .last ??
                                      'Brak pliku',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Submit
                          ElevatedButton(
                            style: elevatedButtonStyleRounded10,
                            onPressed: isSubmitting ? null : _submit,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSubmitting)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                else
                                  Icon(Icons.save, color: theme.textColor),
                                const SizedBox(width: 8),
                                Text(
                                  isSubmitting
                                      ? 'Zapisuję…'
                                      : 'Zapisz zmiany',
                                  style: TextStyle(color: theme.textColor),
                                ),
                              ],
                            ),
                          ),

                          if (updateState.hasError) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Błąd: ${updateState.error}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        return BarManager(
          sideMenuKey: sideMenuKey,
          appModule: AppModule.association,
          paddingPc: 10,
          paddingMobile: 8,

          // DESKTOP
          childrenPc: [
            buildHeader(),
            buildDetailBody(),
          ],

          // MOBILE
          childrenMobile: [
            const SizedBox(height: 4),
            buildHeader(),
            const SizedBox(height: 4),
            buildDetailBody(),
          ],
        );
      },
    );
  }
}
