// edit_contact_type_dialog.dart
import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';

import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/data/clients/client_provider.dart';

import 'package:crm/shared/models/contact_type_model.dart';
import 'package:crm/data/clients/contact_type_provider.dart';

// Local UI state (like in statuses dialog)
final editingTypeProvider   = StateProvider<int?>((ref) => null);
final addingTypeProvider    = StateProvider<bool>((ref) => false);
final addTypeFocusNodeProvider = Provider((ref) => FocusNode());

/// Wrapper to show as PopPage
class UserContactTypesPopUp extends ConsumerWidget {
  final UserContactModel? contact;
  final bool isFilter; // mirror of your statuses code usage

  const UserContactTypesPopUp({
    super.key,
    this.contact,
    this.isFilter = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopPageManager(
      isNamedRoute: true,
      tag: 'ContactTypesPop-${UniqueKey()}',
      child: UserContactTypesDialog(contact: contact, isFilter: isFilter),
    );
  }
}

/// Dialog body – 1:1 behavior with statuses version
class UserContactTypesDialog extends ConsumerWidget {
  final UserContactModel? contact;
  final bool isFilter;

  const UserContactTypesDialog({
    super.key,
    required this.contact,
    required this.isFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    // Ensure we have fresh list
    ref.watch(contactTypesFetchProvider);
    final typesState = ref.watch(contactTypeProvider);
    final clientsAsync = ref.watch(clientProvider);

    Widget loadingPill() => Center(
      child: SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: theme.textFieldColor),
      ),
    );

    // Prosty kontener ramkujący treść dialogu (analogicznie do innych miejsc)
    Widget _frame(ThemeColors theme, Widget child) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: DefaultTextStyle(
          style: TextStyle(color: theme.textColor),
          child: child,
        ),
      );
    }


    return clientsAsync.when(
      loading: () => loadingPill(),
      error: (_, __) => _frame(theme, const Text('-')),
      data: (clients) {
        final currentContact = (contact != null)
            ? clients.firstWhereOrNull((c) => c.id == contact!.id) ?? contact
            : null;

        final types = typesState.contactType; // List<ContactTypeModel>

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(
                'edit_contact_types_title'.tr,
                style: AppTextStyles.interMedium22.copyWith(color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    // Blur and close editors
                    FocusScope.of(context).unfocus();
                    ref.read(addingTypeProvider.notifier).state = false;
                    ref.read(editingTypeProvider.notifier).state = null;
                  },
                  child: ReorderableListView.builder(
                    itemCount: types.length + 1, // +1 for "add new"
                    buildDefaultDragHandles: false,
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex -= 1;
                      await _onReorder(ref, types, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      // Add new at the end
                      if (index == types.length) {
                        final isAdding = ref.watch(addingTypeProvider);
                        final focusNode = ref.watch(addTypeFocusNodeProvider);

                        return KeyedSubtree(
                          key: const ValueKey('add_type_button'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 25),
                            child: isAdding
                                ? _AddTypeTextField(
                                    focusNode: focusNode,
                                    onSubmit: (val) async {
                                      if (val.isNotEmpty) {
                                        await ref.read(contactTypeProvider).createContactType(
                                          ref,
                                          // new type (server will assign id)
                                          ContactTypeModel(
                                            id: DateTime.now().millisecondsSinceEpoch, // temp local id
                                            contactType: val,
                                            label: val,
                                            index: types.length,
                                            contactIndex: const {},
                                            user: null,
                                          ),
                                        );
                                      }
                                      ref.read(addingTypeProvider.notifier).state = false;
                                    },
                                    onEditingComplete: () {
                                      ref.read(addingTypeProvider.notifier).state = false;
                                    },
                                  )
                                : SizedBox(
                                    width: double.infinity,
                                    height: 45,
                                    child: ElevatedButton(
                                      style: elevatedButtonStyleRounded10,
                                      onPressed: () {
                                        ref.read(addingTypeProvider.notifier).state = true;
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

                      final t = types[index];
                      final isEditing = ref.watch(editingTypeProvider) == t.id;

                      return KeyedSubtree(
                        key: ValueKey('contact_type_${t.id}'),
                        child: DragTarget<int>(
                          onWillAcceptWithDetails: (_) => true,
                          onAcceptWithDetails: (_) {},
                          builder: (context, candidateData, rejectedData) {
                            final isBeingDragged = candidateData.isNotEmpty;

                            return ReorderableDragStartListener(
                              index: index,
                              child: Container(
                                color: isBeingDragged ? theme.textFieldColor.withAlpha(125) : Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: isEditing
                                    ? _EditTypeTextField(
                                        initial: _typeName(t),
                                        onSubmit: (newVal) async {
                                          if (newVal.isNotEmpty) {
                                            await ref.read(contactTypeProvider).updateContactType(
                                              ref,
                                              t.copyWith(
                                                label: newVal,
                                                contactType: newVal,
                                              ),
                                            );
                                          }
                                          ref.read(editingTypeProvider.notifier).state = null;
                                        },
                                      )
                                    : ListTile(
                                        title: Text(
                                          _typeName(t),
                                          style: AppTextStyles.interMedium14.copyWith(color: theme.textColor),
                                        ),
                                        onTap: () async {
                                          FocusScope.of(context).unfocus();
                                          ref.read(addingTypeProvider.notifier).state = false;

                                          if (isFilter) {
                                            // If you filter by type in your list:
                                            await ref.read(clientProvider.notifier).fetchClients(status: const Object()); // no-op to keep signature
                                            await ref.read(clientProvider.notifier).fetchClients(searchQuery: const Object()); // no-op
                                            // Replace above with your real filter e.g. .fetchClients(contactType: t.id)
                                            ref.read(navigationService).beamPop();
                                          } else if (currentContact != null) {
                                            // Save to contact: contactType = id
                                            await ref.read(clientProvider.notifier).updateClient(
                                              currentContact.id,
                                              currentContact.copyWith(contactType: t.id),
                                            );
                                            ref.read(navigationService).beamPop();
                                          }
                                        },
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              style: elevatedButtonStyleRounded10,
                                              icon: AppIcons.pencil(color: theme.textColor),
                                              onPressed: () {
                                                FocusScope.of(context).unfocus();
                                                ref.read(addingTypeProvider.notifier).state = false;
                                                ref.read(editingTypeProvider.notifier).state = t.id;
                                              },
                                            ),
                                            const SizedBox(width: 10),
                                            IconButton(
                                              style: elevatedButtonStyleRounded10,
                                              icon: AppIcons.delete(color: theme.textColor),
                                              onPressed: () async {
                                                FocusScope.of(context).unfocus();
                                                ref.read(addingTypeProvider.notifier).state = false;
                                                await ref.read(contactTypeProvider).deleteContactType(ref, t.id);
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- helpers ----------

  Future<void> _onReorder(
    WidgetRef ref,
    List<ContactTypeModel> types,
    int oldIndex,
    int newIndex,
  ) async {
    // Local reorder
    final list = [...types];
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);

    // Rebuild indices and send to backend
    final updated = list.asMap().entries.map((e) {
      final idx = e.key;
      final t = e.value;
      return t.copyWith(index: idx);
    }).toList();

    await ref.read(contactTypeProvider).reorderContactTypes(ref, updated);
  }

  String _typeName(ContactTypeModel m) =>
      (m.label.isNotEmpty ? m.label : m.contactType).trim().isNotEmpty
          ? (m.label.isNotEmpty ? m.label : m.contactType)
          : '-';
}

/// Inline editor for "add new"
class _AddTypeTextField extends StatelessWidget {
  final FocusNode focusNode;
  final ValueChanged<String> onSubmit;
  final VoidCallback onEditingComplete;

  const _AddTypeTextField({
    required this.focusNode,
    required this.onSubmit,
    required this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('add_contact_type_field'),
      autofocus: true,
      focusNode: focusNode,
      controller: TextEditingController(),
      decoration: InputDecoration(
        hintText: 'enter_new_type_hint'.tr,
// border + paddings keep same visual language
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
      onSubmitted: onSubmit,
      onEditingComplete: onEditingComplete,
    );
  }
}

/// Inline editor for "rename"
class _EditTypeTextField extends StatelessWidget {
  final String initial;
  final ValueChanged<String> onSubmit;

  const _EditTypeTextField({
    required this.initial,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: initial)
      ..selection = TextSelection.fromPosition(TextPosition(offset: initial.length));

    return TextField(
      autofocus: true,
      controller: controller,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
      onSubmitted: onSubmit,
    );
  }
}
