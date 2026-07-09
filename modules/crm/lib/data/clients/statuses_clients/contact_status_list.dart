// edit_status_dialog.dart
import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/shared/models/user_contact_status_model.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'package:crm/data/clients/statuses_clients/client_statuses_state.dart';


final editingStatusProvider = StateProvider<int?>((ref) => null);
final addingStatusProvider = StateProvider<bool>((ref) => false); // Nowy status
final addStatusFocusNodeProvider = Provider((ref) => FocusNode()); // FocusNode dla pola dodawania


class UserContactStatusPopUp extends ConsumerWidget {
  final UserContactModel? contact;
  final bool isFilter;
  const UserContactStatusPopUp({super.key, this.contact, required this.isFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return PopPageManager(
      isNamedRoute: true,
        tag: 'StatusPopRevenue-${UniqueKey().toString()}',
        child: UserContactStatusDialog(contact: contact, isFilter: isFilter,),
                          
    );
  }
}











class UserContactStatusDialog extends ConsumerWidget{
  final UserContactModel? contact;
  final bool isFilter;
  const UserContactStatusDialog({super.key, required this.contact, required this.isFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref,) {
    final statusState = ref.watch(userContactsProvider);
    final theme = ref.read(themeColorsProvider);


    return statusState.when(
      data: (userContactState) => Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            if(isFilter)
            ...[
              Text(
                'Filtruj statusy',
                style: AppTextStyles.interMedium22.copyWith(color: theme.textColor),
              ),


            ]
            else
            ...[
              Text(
                'Zmień Status kontaktu'.tr,
                style: AppTextStyles.interMedium22.copyWith(color: theme.textColor),
              ),
            ],


    Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
    // Gdy użytkownik kliknie poza polem, schowaj pole dodawania
    FocusScope.of(context).unfocus();
    ref.read(addingStatusProvider.notifier).state = false;
    ref.read(editingStatusProvider.notifier).state = null;
        },
        child: ReorderableListView.builder(
          cacheExtent: 300.0,
    itemCount: userContactState.contactStatuses.length + 1, // +1 dla przycisku dodawania
    onReorder: (oldIndex, newIndex) {
      if (newIndex > oldIndex) newIndex -= 1;
      _onReorder(ref, userContactState, oldIndex, newIndex);
    },
    buildDefaultDragHandles: false, // Usuwa domyślną ikonę przeciągania
    itemBuilder: (context, index) {
      if (index == userContactState.contactStatuses.length) {
        // Ostatni element - pole do dodawania nowego statusu
        final isAdding = ref.watch(addingStatusProvider);
        final focusNode = ref.watch(addStatusFocusNodeProvider);




        return KeyedSubtree(
          key: const ValueKey('add_button'), // Unikalny key dla przycisku
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 25),
            child: isAdding
                ? TextField(
                    key: const ValueKey('add_status_field'), // Klucz dla pola tekstowego
                    autofocus: true,
                    focusNode: focusNode, // Przypisujemy FocusNode
                    controller: TextEditingController(),
                    decoration: InputDecoration(
                      hintText: 'Wpisz nowy status...'.tr,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    onSubmitted: (newValue) {
                      if (newValue.isNotEmpty) {
                        final newStatus = UserContactStatusModel(
                          statusId: DateTime.now().millisecondsSinceEpoch, // Tymczasowy unikalny ID
                          statusName: newValue,
                          statusIndex: userContactState.contactStatuses.length,
                          contactIndex: [],
                        );
                        ref.read(userContactsProvider.notifier).createUserContactStatus(newStatus, ref);
                      }
                      ref.read(addingStatusProvider.notifier).state = false; // Ukryj pole po dodaniu
                    },
                    onEditingComplete: () {
                      ref.read(addingStatusProvider.notifier).state = false; // Ukryj pole po kliknięciu poza nim
                    },
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: elevatedButtonStyleRounded10,
                      onPressed: () {
                        ref.read(addingStatusProvider.notifier).state = true;
                        Future.delayed(Duration(milliseconds: 100), () {
                          focusNode.requestFocus(); // Automatyczne ustawienie focusa
                        });
                      },
                      child: AppIcons.add(color: theme.textColor),
                    ),
                  ),
          ),
        );
      }

                  final status = userContactState.contactStatuses[index];

                  return KeyedSubtree(
                    key: ValueKey(status.statusId),
                    child: DragTarget<int>(
                      onWillAcceptWithDetails: (data) => true,
                      onAcceptWithDetails: (data) {},
                      builder: (context, candidateData, rejectedData) {
                        final isBeingDragged = candidateData.isNotEmpty;
                        final isEditing = ref.watch(editingStatusProvider) == status.statusId;

                        return ReorderableDragStartListener(
                          index: index,
                          child: Container(
                            color: isBeingDragged ? theme.textFieldColor.withAlpha(125) : Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: isEditing
                                ? TextField(
                              autofocus: true,
                              controller: TextEditingController(text: status.statusName)
                                ..selection = TextSelection.fromPosition(
                                  TextPosition(offset: status.statusName.length),
                                ),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              ),
                              onSubmitted: (newValue) async {
                                if (newValue.isNotEmpty) {
                                  final updatedStatus = UserContactStatusModel(
                                    statusId: status.statusId,
                                    statusName: newValue,
                                    statusIndex: status.statusIndex,
                                    contactIndex: status.contactIndex,
                                  );

                                  // SHOW LOADING
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(child: CircularProgressIndicator()),
                                  );

                                  try {
                                    await ref.read(userContactsProvider.notifier)
                                        .updateUserContactStatus(updatedStatus, ref);

                                    // HIDE LOADING
                                    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

                                    // SUCCESS SNACKBAR
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Status updated successfully.')),
                                      );
                                    }
                                  } catch (e) {
                                    // HIDE LOADING
                                    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

                                    // ERROR SNACKBAR
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to update status: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                                ref.read(editingStatusProvider.notifier).state = null; // exit edit mode
                              },
                            )
                                : ListTile(
                              title: Text(
                                status.statusName,
                                style: AppTextStyles.interMedium14.copyWith(color: theme.textColor),
                              ),
                              onTap: () async {
                                FocusScope.of(context).unfocus();
                                ref.read(addingStatusProvider.notifier).state = false;

                                if (isFilter) {
                                  // SHOW LOADING
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(child: CircularProgressIndicator()),
                                  );
                                  try {
                                    await ref.read(clientProvider.notifier).fetchClients(status: status.statusId);
                                    if (context.mounted) Navigator.pop(context); // close bottom sheet / list dialog
                                    // HIDE LOADING
                                    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Filter applied.')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to apply filter: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                } else if (contact != null) {
                                  // SHOW LOADING
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(child: CircularProgressIndicator()),
                                  );
                                  try {
                                    await ref
                                        .read(userContactsProvider.notifier)
                                        .updateUserContactStatusById(contact!, status, ref);
                                    if (context.mounted) Navigator.pop(context); // close picker
                                    // HIDE LOADING
                                    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Status changed successfully.')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to change status: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
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
                                      ref.read(addingStatusProvider.notifier).state = false;
                                      ref.read(editingStatusProvider.notifier).state = status.statusId;
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    style: elevatedButtonStyleRounded10,
                                    icon: AppIcons.delete(color: theme.textColor),
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                      ref.read(addingStatusProvider.notifier).state = false;
                                      _deleteStatus(ref, status.statusId); // keep your existing delete; add loading there similarly if you like
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
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error'.tr)),
    );
  }


  void _onReorder(WidgetRef ref, UserContactState userContactState, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final movedStatus = userContactState.contactStatuses.removeAt(oldIndex);
    userContactState.contactStatuses.insert(newIndex, movedStatus);

    final updatedStatuses = userContactState.contactStatuses.asMap().entries.map((entry) {
      final index = entry.key;
      final status = entry.value;
      return UserContactStatusModel(
        statusId: status.statusId,
        statusName: status.statusName,
        statusIndex: index, 
        contactIndex: status.contactIndex,
      );
    }).toList();
    ref.read(userContactsProvider.notifier).reorderStatuses(updatedStatuses);
  }


  void _deleteStatus(WidgetRef ref, int id) {
    ref.read(userContactsProvider.notifier).deleteuserContactStatus(id,ref);
  }
}