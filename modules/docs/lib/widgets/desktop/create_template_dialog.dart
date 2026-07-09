import 'package:docs/api/cloud_docs_service.dart';
import 'package:docs/emma/anchors/docs_emma_anchors.dart';
import 'package:docs/provider/cloud_doc_provider.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';


class CreateTemplateDialog extends ConsumerStatefulWidget {
  const CreateTemplateDialog({super.key});

  @override
  ConsumerState<CreateTemplateDialog> createState() =>
      _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends ConsumerState<CreateTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  Future<void> _createTemplate(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(documentLoadingProvider.notifier).state = true;

    try {
      final template = await DocumentService.createTemplate(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        deltaJson: {
          'ops': [
            {'insert': '\n'}
          ]
        },
        styleJson: {},
        ref: ref,
      );

      if (mounted) {
        Navigator.of(context).pop({
          'type': 'template',
          'template': template,
          
        });
      }
      ref.invalidate(documentTemplatesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating template: $e')),
        );
      }
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
        ref.read(documentLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final isLoading = ref.watch(documentLoadingProvider);

    return EmmaUiAnchorTarget(
      anchorKey: DocsEmmaAnchors.createTemplateDialog.anchorKey,

      spec: DocsEmmaAnchors.createTemplateDialog,
      runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: 500,
          height: 400,
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.dashboardContainer,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create New Template'.tr,
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.textColor),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EmmaUiAnchorTarget(
                           anchorKey: DocsEmmaAnchors.templateNameField.anchorKey,

                           spec: DocsEmmaAnchors.templateNameField,
                           runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                           tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                          child: TextFormField(
                            controller: _nameController,
                            cursorColor: theme.textColor,
                            decoration: InputDecoration(
                              hintText: 'Template Name'.tr,
                              filled: true,
                              fillColor: theme.adPopBackground,
                              hintStyle: TextStyle(color: theme.textColor),
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
                            style: TextStyle(color: theme.textColor),
                            validator: (value) => value?.trim().isEmpty ?? true
                                ? 'Name is required'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        EmmaUiAnchorTarget(
                           anchorKey: DocsEmmaAnchors.templateDescriptionField.anchorKey,

                           spec: DocsEmmaAnchors.templateDescriptionField,
                           runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                           tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                          child: TextFormField(
                            controller: _descriptionController,
                            cursorColor: theme.textColor,
                            decoration: InputDecoration(
                              hintText: 'Description'.tr,
                              filled: true,
                              fillColor: theme.adPopBackground,
                              hintStyle: TextStyle(color: theme.textColor),
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
                            style: TextStyle(color: theme.textColor),
                            maxLines: 3,
                            validator: (value) => null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Content will start blank. You can edit it after creation.'.tr,
                          style: TextStyle(
                              color: theme.textColor.withAlpha(178),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      EmmaUiAnchorTarget(
                          anchorKey: DocsEmmaAnchors.cancelTemplateButton.anchorKey,

                          spec: DocsEmmaAnchors.cancelTemplateButton,
                          runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                          tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancel'.tr,
                              style: TextStyle(color: theme.textColor)),
                        ),
                      ),
                      EmmaUiAnchorTarget(
                         anchorKey: DocsEmmaAnchors.createTemplateConfirmButton.anchorKey,

                         spec: DocsEmmaAnchors.createTemplateConfirmButton,
                         runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                         tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => _createTemplate(ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.themeColor,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white)),
                                )
                              : Text('Create'.tr,
                                  style: TextStyle(color: theme.themeColorText)),
                        ),
                      ),
                    ],
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
