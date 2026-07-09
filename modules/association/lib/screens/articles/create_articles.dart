// lib/article/create_association_article_page.dart
import 'dart:io';
import 'package:association/providers/articles.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/text_field.dart';
import 'package:get/get_utils/get_utils.dart';

/// Create article page for a given association.
/// We already have associationId in the route, so we do NOT fetch associations here.
class CreateAssociationArticlePage extends ConsumerStatefulWidget {
  final int associationId;

  const CreateAssociationArticlePage({
    super.key,
    required this.associationId,
  });

  @override
  ConsumerState<CreateAssociationArticlePage> createState() =>
      _CreateAssociationArticlePageState();
}

// at the top of the file
const kAllowedStatuses = <String>[
  'draft',
  'published',
  'new', // backend returns "new"
  'archived', // if used
];

String _labelForStatus(String s) {
  switch (s) {
    case 'draft':
      return 'draft_status'.tr;
    case 'published':
      return 'published_status'.tr;
    case 'new':
      return 'new_status'.tr;
    case 'archived':
      return 'archived_status'.tr;
    default:
      return s;
  }
}

class _CreateAssociationArticlePageState
    extends ConsumerState<CreateAssociationArticlePage> {
  final _formKey = GlobalKey<FormState>();

  String _title = '';
  String _seoTitle = '';
  String _body = '';
  String _status = 'draft';

  final _titleCtrl = TextEditingController();
  final _seoTitleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _seoTagsCtrl = TextEditingController();

  File? _thumbnailFile;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _seoTitleCtrl.dispose();
    _bodyCtrl.dispose();
    _tagsCtrl.dispose();
    _seoTagsCtrl.dispose();
    super.dispose();
  }

  List<int> _parseIds(String raw) {
    return raw
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .where((v) => v != null)
        .cast<int>()
        .toList();
  }

  Future<void> _pickThumbnail() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image);
    if (res != null && res.files.single.path != null) {
      setState(() => _thumbnailFile = File(res.files.single.path!));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _title = _titleCtrl.text.trim();
    _seoTitle = _seoTitleCtrl.text.trim();
    _body = _bodyCtrl.text.trim();

    final createCtrl = ref.read(createArticleControllerProvider.notifier);

    try {
      final created = await createCtrl.create(
        associationId: widget.associationId,
        title: _title,
        body: _body,
        status: _status,
        seoTitle: _seoTitle.isEmpty ? null : _seoTitle,
        tagIds: _parseIds(_tagsCtrl.text),
        seoTagIds: _parseIds(_seoTagsCtrl.text),
      );

      if (_thumbnailFile != null && created['id'] != null) {
        await ArticleApi.uploadThumbnail(
          ref: ref,
          articleId: created['id'] as int,
          file: _thumbnailFile!,
        );
      }

      ref.invalidate(
        associationArticlesProvider(
          ArticleListArgs(associationId: widget.associationId),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('article_created'.tr)),
      );
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'error'.tr}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createArticleControllerProvider);
    final isSubmitting = createState.isLoading;
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);
    final borderColor = theme.textColor.withAlpha((255 * 0.5).toInt());
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        Widget buildHeader() {
          return Row(
            children: [
              Text(
                'create_association_article'.tr,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (v) => setState(() => _status = v),
                color: theme.adPopBackground,
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'draft',
                    child: Text('set_draft'.tr,   style: TextStyle(color: theme.textColor),),
                  ),
                  PopupMenuItem(
                    value: 'published',
                    child: Text('set_published'.tr,   style: TextStyle(color: theme.textColor),),
                  ),
                ],
                icon: Icon(Icons.tune, color: theme.textColor),
              ),
            ],
          );
        }

        Widget buildFormBody() {
          return Expanded(
            child: AbsorbPointer(
              absorbing: isSubmitting,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        label: Text(
                          'association_id'.trParams({
                            'id': widget.associationId.toString(),
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    CoreTextFormField(
                      label: 'title'.tr,
                      controller: _titleCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'enter_title'.tr
                          : null,
                    ),
                    const SizedBox(height: 12),

                    CoreTextFormField(
                      label: 'seo_title_optional'.tr,
                      controller: _seoTitleCtrl,
                    ),
                    const SizedBox(height: 12),

                    CoreTextFormField(
                      label: 'content'.tr,
                      controller: _bodyCtrl,
                      maxLines: 10,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'enter_content'.tr
                          : null,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value:
                      kAllowedStatuses.contains(_status) ? _status : 'draft',
                      style: TextStyle(color: theme.textColor),
                      dropdownColor: theme.adPopBackground,
                      decoration: InputDecoration(
                        labelText: 'Status'.tr,
                        filled: true,
                        fillColor: theme.adPopBackground,
                        floatingLabelStyle: AppTextStyles.interMedium14.copyWith(color: theme.textColor),
                        labelStyle: AppTextStyles.interMedium14.copyWith(color: theme.textColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: theme.themeColor, width: 1.5),
                        ),

                      ),
                      items: kAllowedStatuses
                          .map(
                            (s) => DropdownMenuItem(
                          value: s,
                          child: Text(_labelForStatus(s), style: AppTextStyles.interMedium14.copyWith(color: theme.textColor),),
                        ),
                      )
                          .toList(),
                      onChanged: (v) => setState(() => _status = v ?? 'draft'),
                    ),
                    const SizedBox(height: 12),

                    CoreTextFormField(
                      label: 'tag_ids'.tr,
                      hintText: 'example_tags'.tr,
                      controller: _tagsCtrl,
                    ),
                    const SizedBox(height: 12),

                    CoreTextFormField(
                      label: 'seo_tag_ids'.tr,
                      hintText: 'example_seo_tags'.tr,
                      controller: _seoTagsCtrl,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        ElevatedButton(
                          style: elevatedButtonStyleRounded10,
                          onPressed: _pickThumbnail,
                          child: Row(
                            children: [
                              Icon(Icons.image, color: theme.textColor),
                              const SizedBox(width: 6),
                              Text(
                                'choose_thumbnail'.tr,
                                style: TextStyle(color: theme.textColor),
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
                                'no_file'.tr,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(Icons.publish, color: theme.textColor),
                          const SizedBox(width: 8),
                          Text(
                            isSubmitting ? 'sending'.tr : 'publish'.tr,
                            style: TextStyle(color: theme.textColor),
                          ),
                        ],
                      ),
                    ),

                    if (createState.hasError) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${'error'.tr}: ${createState.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        return BarManager(
          sideMenuKey: sideMenuKey,
          appModule: AppModule.association,
          paddingPc: 10,
          paddingMobile: 8,
          childrenPc: [
            buildHeader(),
            buildFormBody(),
          ],
          childrenMobile: [
            const SizedBox(height: 60),
            buildHeader(),
            const SizedBox(height: 4),
            buildFormBody(),
          ],
        );
      },
    );
  }
}