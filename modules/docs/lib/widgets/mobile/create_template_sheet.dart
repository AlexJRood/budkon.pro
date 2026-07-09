
import 'dart:async';
import 'package:docs/api/cloud_docs_service.dart';
import 'package:docs/emma/anchors/docs_emma_anchors.dart';
import 'package:docs/provider/cloud_doc_provider.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';


class CreateTemplateSheet extends ConsumerStatefulWidget {
  const CreateTemplateSheet({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  ConsumerState<CreateTemplateSheet> createState() =>
      _CreateTemplateSheetState();
}

class _CreateTemplateSheetState extends ConsumerState<CreateTemplateSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  Future<void> _createTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(documentLoadingProvider.notifier).state = true;

    try {
      final template = await DocumentService.createTemplate(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        deltaJson: {
          'ops': [
            {'insert': '\n'}
          ],
        },
        styleJson: {},
        ref: ref,
      );

      if (!mounted) return;
      Navigator.of(context).pop({
        'type': 'template',
        'template': template,
      });

      ref.invalidate(documentTemplatesProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating template: $e')),
      );
    } finally {
      if (mounted) {
        ref.read(documentLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final isLoading = ref.watch(documentLoadingProvider);

    return EmmaUiAnchorTarget(
      anchorKey: DocsEmmaAnchors.createTemplateSheet.anchorKey,

      spec: DocsEmmaAnchors.createTemplateSheet,
      runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: widget.scrollController,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
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
      
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Create New Template".tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              EmmaUiAnchorTarget(
                 anchorKey: DocsEmmaAnchors.templateNameField.anchorKey,

                 spec: DocsEmmaAnchors.templateNameField,
                 runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                 tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                child: TextFormField(
                  controller: _nameController,
                  cursorColor: theme.textColor,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Template Name'.tr,
                    filled: true,
                    fillColor: theme.adPopBackground,
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
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
              ),
      
              const SizedBox(height: 14),
              EmmaUiAnchorTarget(
                  anchorKey: DocsEmmaAnchors.templateDescriptionField.anchorKey,

                  spec: DocsEmmaAnchors.templateDescriptionField,
                  runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                  tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                child: TextFormField(
                  controller: _descriptionController,
                  cursorColor: theme.textColor,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Description'.tr,
                    filled: true,
                    fillColor: theme.adPopBackground,
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
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                ),
              ),
      
              const SizedBox(height: 12),
      
              Text(
                'Content will start blank. You can edit it after creation.'.tr,
                style: TextStyle(
                  color: theme.textColor.withAlpha(178),
                  fontSize: 12,
                ),
              ),
      
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        isLoading ? null : () => Navigator.of(context).pop(),
                    child:
                        Text('Cancel'.tr, style: TextStyle(color: theme.textColor)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: isLoading ? null : _createTemplate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.themeColor,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Create'.tr,
                            style: TextStyle(color: theme.themeColorText)),
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
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
