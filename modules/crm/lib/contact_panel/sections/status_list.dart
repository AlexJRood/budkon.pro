import 'package:flutter/material.dart';
import 'package:crm/crm_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/design.dart';
import 'package:core/platform/status_dropdown.dart'; // StatusOption
import 'package:crm/contact_panel/sections/fav_status.dart'; // favStatusTypesProvider, create/delete...
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';
import 'package:core/theme/text_field.dart';

// --- lokalny stan (jak w Twojej wersji) ---
final favEditingStatusIdProvider = StateProvider<int?>((ref) => null);
final favAddingStatusProvider = StateProvider<bool>((ref) => false);
final favAddFocusNodeProvider = Provider<FocusNode>((ref) => FocusNode());
// --- provider kontrolera do pola "Dodaj status" ---
final favAddTextControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});


// --- helpery API (bez pola index w UI; index tylko do reorder) ---
Future<void> updateFavStatusType(
  WidgetRef ref,
  int id, {
  required String label,
  int? index, // opcjonalnie używane wewnętrznie przy reorder
}) async {
  final resp = await ApiServices.patch(
    URLs.favoriteStatusTypesEdit(id),
    hasToken: true,
    data: {
      'label': label,
      if (index != null) 'index': index,
    },
  );
  if (resp == null || (resp.statusCode ?? 0) >= 300) {
    throw Exception('Nie udało się zaktualizować statusu');
  }
  ref.invalidate(favStatusTypesProvider);
}



Future<void> reorderFavStatusTypes(WidgetRef ref, List<StatusOption> ordered) async {
  // payload: [{"id": 1, "index": 0}, ...]
    final payload = [
      for (var i = 0; i < ordered.length; i++)
        if (ordered[i].id != null) {'id': ordered[i].id, 'index': i},
    ];

    // wrap w mapę:
    final resp = await ApiServices.post(
      CrmUrls.favoriteStatusTypesReorder,
      hasToken: true,
      data: {'items': payload}, // teraz jest Map<String,dynamic>
    );


  // niektóre backendy zwracają 204 bez body – potraktuj jako sukces
  final sc = resp?.statusCode ?? 0;
  if (resp == null || (sc >= 300 && sc != 204)) {
    // fallback: per-item PATCH (na wszelki wypadek, np. gdy akcja nie jest wdrożona)
    for (final item in payload) {
      await ApiServices.patch(
        URLs.favoriteStatusTypesEdit(item['id'] as int),
        hasToken: true,
        data: {'index': item['index'] as int},
      );
    }
  }

  // odśwież listę
  ref.invalidate(favStatusTypesProvider);
}


// --- DIALOG W STYLU ORYGINAŁU ---
class FavStatusDialog extends ConsumerWidget {
  const FavStatusDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final asyncOpts = ref.watch(favStatusTypesProvider);

    return Padding(
      padding: const EdgeInsets.all(12.0),
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
              error: (e, _) => Center(child: Text('${'error_prefix'.tr} $e')),
              data: (options) => _Body(options: options),
            ),
          ),
        ],
      ),
    );
  }
}









// ==================== BODY ====================
class _Body extends ConsumerWidget {
  const _Body({required this.options});
  final List<StatusOption> options;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdding  = ref.watch(favAddingStatusProvider);
    final focusNode = ref.watch(favAddFocusNodeProvider);
    final addCtrl   = ref.watch(favAddTextControllerProvider);
    final theme     = ref.read(themeColorsProvider);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
        ref.read(favAddingStatusProvider.notifier).state = false;
        ref.read(favEditingStatusIdProvider.notifier).state = null;
      },
      child: ReorderableListView.builder(
        cacheExtent: 300.0,
        buildDefaultDragHandles: false,
        itemCount: options.length + 1, // + przycisk/field dodawania
        onReorder: (oldIndex, newIndex) async {
          if (newIndex > oldIndex) newIndex -= 1;
          final reordered = [...options];
          final moved = reordered.removeAt(oldIndex);
          reordered.insert(newIndex, moved);

          try {
            await reorderFavStatusTypes(ref, reordered);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${'failed_to_reorder_statuses'.tr} $e')),
            );
          }
        },
        itemBuilder: (context, index) {
          // --- ostatnia pozycja: add ---
          if (index == options.length) {
            return KeyedSubtree(
              key: const ValueKey('fav_add_button'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 25),
                child: isAdding
                    ? FocusScope(
                        canRequestFocus: true,
                        child: CoreTextField(
                          key: const ValueKey('fav_add_field'),
                          label: 'new_status_label'.tr,
                          hintText: 'enter_new_status_hint'.tr,
                          controller: addCtrl,
                          autofocus: true,
                          // jeśli chcesz, możesz też podać focusNode do CoreTextField:
                          // (dodaj pole focusNode do komponentu CoreTextField – jeżeli go nie ma,
                          // to ten requestFocus poniżej załatwi sprawę)
                          onSubmitted: (value) async {
                            final label = value.trim();
                            if (label.isEmpty) {
                              ref.read(favAddingStatusProvider.notifier).state = false;
                              return;
                            }
                            try {
                              await createFavStatusType(ref, label);
                              addCtrl.clear();
                              ref.read(favAddingStatusProvider.notifier).state = false;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('status_added_message'.tr)),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${'failed_to_add_status_error'.tr} $e')),
                              );
                            }
                          },
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: elevatedButtonStyleRounded10,
                          onPressed: () {
                            ref.read(favAddingStatusProvider.notifier).state = true;
                            // odrocz, by layout się zbudował i dopiero wtedy focus
                            Future.delayed(const Duration(milliseconds: 100), () {
                              focusNode.requestFocus();
                            });
                          },
                          child: AppIcons.add(color: theme.textColor),
                        ),
                      ),
              ),
            );
          }

          // --- zwykłe wiersze ---
          final s = options[index];
          final isEditing = ref.watch(favEditingStatusIdProvider) == s.id;

          return KeyedSubtree(
            key: ValueKey('fav_status_${s.id}'),
            child: DragTarget<int>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (_) {},
              builder: (context, candidate, rejected) {
                final isBeingDragged = candidate.isNotEmpty;
                return ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    color: isBeingDragged
                        ? theme.textFieldColor.withAlpha(125)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: isEditing
                        ? _EditRow(option: s)
                        : ListTile(
                            title: Text(
                              s.label,
                              style: AppTextStyles.interMedium14
                                  .copyWith(color: theme.textColor),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  style: elevatedButtonStyleRounded10,
                                  icon: AppIcons.pencil(color: theme.textColor),
                                  onPressed: () {
                                    FocusScope.of(context).unfocus();
                                    ref.read(favAddingStatusProvider.notifier).state = false;
                                    ref.read(favEditingStatusIdProvider.notifier).state = s.id;
                                  },
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  style: elevatedButtonStyleRounded10,
                                  icon: AppIcons.delete(color: theme.textColor),
                                  onPressed: () async {
                                    FocusScope.of(context).unfocus();
                                    ref.read(favAddingStatusProvider.notifier).state = false;
                                    try {
                                      await deleteFavStatusType(ref, s.id!);
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
                );
              },
            ),
          );
        },
      ),
    );
  }
}



// ==================== EDIT ROW ====================
class _EditRow extends ConsumerStatefulWidget {
  const _EditRow({required this.option});
  final StatusOption option;

  @override
  ConsumerState<_EditRow> createState() => _EditRowState();
}

class _EditRowState extends ConsumerState<_EditRow> {
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
            await updateFavStatusType(ref, widget.option.id!, label: label);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('changes_saved_message'.tr)),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${'save_error_message'.tr} $e')),
            );
          }
        }
        ref.read(favEditingStatusIdProvider.notifier).state = null;
      },
    );
  }
}
