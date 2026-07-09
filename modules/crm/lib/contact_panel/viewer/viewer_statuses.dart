// viewer_status_types.dart
import 'package:crm/contact_panel/viewer/viewer_provider.dart';
import 'package:crm/crm_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';
import 'package:core/platform/status_dropdown.dart'; // StatusOption
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/text_field.dart';



// ───────────────── PROVIDERY (lokalny stan edycji) ─────────────────
final viewerEditingStatusIdProvider = StateProvider<int?>((ref) => null);
final viewerAddingStatusProvider = StateProvider<bool>((ref) => false);


// pod PROVIDERY stanu
final viewerAddTextControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});



// ───────────────── CRUD helpers ─────────────────
Future<void> createViewerStatusType(WidgetRef ref, String label) async {
  final resp = await ApiServices.post(
    URLs.transactionViewersStatusTypes, // POST /contacts/viewers/status-types/
    hasToken: true,
    data: {'label': label},
  );
  if (resp == null || (resp.statusCode ?? 0) >= 300) {
    throw Exception('failed_to_add_status'.tr);
  }
  ref.invalidate(viewerStatusTypesProvider);
}

Future<void> updateViewerStatusType(
  WidgetRef ref,
  int id, {
  required String label,
  int? index,
}) async {
  final resp = await ApiServices.patch(
    URLs.transactionViewersStatusTypesEdit(id), // PATCH /contacts/viewers/status-types/{id}/
    hasToken: true,
    data: {'label': label, if (index != null) 'index': index},
  );
  if (resp == null || (resp.statusCode ?? 0) >= 300) {
    throw Exception('failed_to_update_status'.tr);
  }
  ref.invalidate(viewerStatusTypesProvider);
}

Future<void> deleteViewerStatusType(WidgetRef ref, int id) async {
  final resp = await ApiServices.delete(
    URLs.transactionViewersStatusTypesDelete(id), // DELETE /contacts/viewers/status-types/{id}/
    hasToken: true,
  );
  if (resp == null || (resp.statusCode ?? 0) >= 300) {
    throw Exception('failed_to_delete_status'.tr);
  }
  ref.invalidate(viewerStatusTypesProvider);
}

Future<void> reorderViewerStatusTypes(WidgetRef ref, List<StatusOption> ordered) async {
  final payload = [
    for (var i = 0; i < ordered.length; i++)
      if (ordered[i].id != null) {'id': ordered[i].id, 'index': i},
  ];
  // preferowany endpoint aliasu, który dodałeś:
  final resp = await ApiServices.post(
    CrmUrls.transactionViewersStatusTypesReorder, // POST /contacts/viewers/statuses/reorder/
    hasToken: true,
    data: {'items': payload},
  );
  final sc = resp?.statusCode ?? 0;
  if (resp == null || (sc >= 300 && sc != 204)) {
    // fallback: per-item PATCH (gdyby alias nie był dostępny)
    for (final it in payload) {
      await ApiServices.patch(
        URLs.transactionViewersStatusTypesEdit(it['id'] as int),
        hasToken: true,
        data: {'index': it['index'] as int},
      );
    }
  }
  ref.invalidate(viewerStatusTypesProvider);
}

// ───────────────── Dialog „Manage statuses” ─────────────────
class ViewerStatusDialog extends ConsumerWidget {
  const ViewerStatusDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final asyncOpts = ref.watch(viewerStatusTypesProvider);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            'manage_statuses_title'.tr,
            style: AppTextStyles.interMedium22.copyWith(color: theme.textColor),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: asyncOpts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('${'Error'.tr} $e')),
              data: (options) => _ViewerStatusBody(options: options),
            ),
          ),
        ],
      ),
    );
  }
}


class _ViewerStatusBody extends ConsumerWidget {
  const _ViewerStatusBody({required this.options});
  final List<StatusOption> options;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme    = ref.read(themeColorsProvider);
    final isAdding = ref.watch(viewerAddingStatusProvider);
    final addCtrl  = ref.watch(viewerAddTextControllerProvider); // ⬅️ NEW

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
        ref.read(viewerAddingStatusProvider.notifier).state = false;
        ref.read(viewerEditingStatusIdProvider.notifier).state = null;
      },
      child: ReorderableListView.builder(
        cacheExtent: 300,
        buildDefaultDragHandles: false,
        itemCount: options.length + 1,
        onReorder: (oldIndex, newIndex) async { /* ... */ },
        itemBuilder: (context, index) {
          if (index == options.length) {
            return KeyedSubtree(
              key: const ValueKey('viewer_add_button'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 25),
                child: isAdding
                    ? CoreTextField(
                        key: const ValueKey('viewer_add_field'),
                        label: 'new_status_label'.tr,
                        hintText: 'enter_new_status_hint'.tr,
                        autofocus: true,
                        controller: addCtrl,            // ⬅️ NEW (wymagany)
                        onSubmitted: (value) async {
                          final label = value.trim();
                          if (label.isEmpty) {
                            ref.read(viewerAddingStatusProvider.notifier).state = false;
                            return;
                          }
                          try {
                            await createViewerStatusType(ref, label);
                            addCtrl.clear();             // ⬅️ czyścimy po zapisie
                            ref.read(viewerAddingStatusProvider.notifier).state = false;
                            ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text('status_added_message'.tr)),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${'failed_to_add_status_error'.tr} $e')),
                            );
                          }
                        },
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: elevatedButtonStyleRounded10,
                          onPressed: () {
                            ref.read(viewerAddingStatusProvider.notifier).state = true;
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppIcons.add(color: theme.textColor),
                              const SizedBox(width: 8),
                              Text('add_status_button'.tr, style: TextStyle(color: theme.textColor)),
                            ],
                          ),
                        ),
                      ),
              ),
            );
          }


          // wiersz
          final s = options[index];
          final isEditing = ref.watch(viewerEditingStatusIdProvider) == s.id;

          return KeyedSubtree(
            key: ValueKey('viewer_status_${s.id}'),
            child: ReorderableDragStartListener(
              index: index,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: isEditing
                    ? _ViewerEditRow(option: s)
                    : ListTile(
                        title: Text(
                          s.label,
                          style: AppTextStyles.interMedium14.copyWith(color: theme.textColor),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              style: elevatedButtonStyleRounded10,
                              icon: AppIcons.pencil(color: theme.textColor),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                ref.read(viewerAddingStatusProvider.notifier).state = false;
                                ref.read(viewerEditingStatusIdProvider.notifier).state = s.id;
                              },
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              style: elevatedButtonStyleRounded10,
                              icon: AppIcons.delete(color: theme.textColor),
                              onPressed: () async {
                                FocusScope.of(context).unfocus();
                                ref.read(viewerAddingStatusProvider.notifier).state = false;
                                try {
                                  await deleteViewerStatusType(ref, s.id!);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${'failed_to_delete_status_error'.tr} $e')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ViewerEditRow extends ConsumerStatefulWidget {
  const _ViewerEditRow({required this.option});
  final StatusOption option;

  @override
  ConsumerState<_ViewerEditRow> createState() => _ViewerEditRowState();
}

class _ViewerEditRowState extends ConsumerState<_ViewerEditRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.option.label)
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: widget.option.label.length),
      );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CoreTextField(
      label: 'name_label'.tr,
      controller: _ctrl,
      autofocus: true,
      onSubmitted: (newValue) async {
        final label = newValue.trim();
        if (label.isNotEmpty) {
          try {
            await updateViewerStatusType(ref, widget.option.id!, label: label);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('changes_saved_message'.tr)),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${'save_error_message'.tr} $e')),
            );
          }
        }
        ref.read(viewerEditingStatusIdProvider.notifier).state = null;
      },
    );
  }
}
