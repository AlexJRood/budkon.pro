import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm/shared/models/user_contact_status_model.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';

class ClientStatusPillDropdown extends ConsumerWidget {
  final int? currentStatusId;
  final Future<void> Function(int newStatusId) onChanged;

  final double? maxPillWidth;
  final double? menuMaxHeight;
  final double? menuMaxWidth;

  const ClientStatusPillDropdown({
    super.key,
    required this.currentStatusId,
    required this.onChanged,
    this.maxPillWidth,
    this.menuMaxHeight,
    this.menuMaxWidth = 320,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final statusesAsync = ref.watch(clientStatusesProvider);

    Widget plainButton(String label, {VoidCallback? onPressed}) => ElevatedButton(
      style: elevatedButtonStyleRounded10,
      onPressed: onPressed,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        AppIcons.circlePlus(color: theme.textColor),
        const SizedBox(width: 6),
        Text(label, style: _pillTextStyle(theme)),
      ]),
    );

    return statusesAsync.when(
      loading: () => _pillFrame(
        theme: theme,
        maxWidth: maxPillWidth,
        child: SizedBox(
          height: 16, width: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: theme.textFieldColor),
        ),
      ),
      error: (_, __) => plainButton('Set status'.tr),
      data: (statuses) {
        if (statuses.isEmpty) {
          return plainButton('Set status'.tr);
        }

        // Build items once
        final items = statuses.map((s) {
          return DropdownMenuItem<int>(
            value: _statusId(s),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: menuMaxWidth ?? 320),
              child: Text(
                _statusName(s),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList();

        // Validate selected id: must appear exactly once and be > 0
        final desired = (currentStatusId != null && currentStatusId! > 0)
            ? currentStatusId
            : null;

        final countMatches = (desired == null)
            ? 0
            : items.where((it) => it.value == desired).length;

        final safeSelectedId = (desired != null && countMatches == 1)
            ? desired
            : null;

        const horizontalPad = 12.0;

        return DropdownButtonHideUnderline(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxPillWidth ?? double.infinity),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 6),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
              child: DropdownButton<int>(
                isDense: true,
                borderRadius: BorderRadius.circular(6),
                dropdownColor: theme.dashboardContainer,
                menuMaxHeight: menuMaxHeight,
                value: safeSelectedId, // <-- validated value (or null)
                icon: AppIcons.iosArrowDown(color: theme.textColor),
                style: TextStyle(
                  color: theme.dashboardContainer,
                  fontSize: 13,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w700,
                ),
                items: items,
                selectedItemBuilder: (_) => statuses.map((s) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: (maxPillWidth != null)
                            ? (maxPillWidth! - (horizontalPad * 2)).clamp(0, double.infinity)
                            : double.infinity,
                      ),
                      child: Text(
                        _statusName(s),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _pillTextStyle(theme),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (int? newId) async {
                  if (newId == null || newId == safeSelectedId) return;
                  await onChanged(newId);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- helpers ----------

  TextStyle _pillTextStyle(ThemeColors theme) => TextStyle(
    color: theme.textColor,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  Widget _pillFrame({
    required ThemeColors theme,
    required Widget child,
    double? maxWidth,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
            child: child,
          ),
          const SizedBox(width: 4),
          AppIcons.arrowDown(color: theme.textColor),
        ],
      ),
    );
  }

  // Model accessors to be resilient to field naming
  String _statusName(UserContactStatusModel s) {
    final d = s as dynamic;
    return (d.statusName ?? d.name ?? d.label ?? d.title ?? '-').toString();
  }

  int _statusId(UserContactStatusModel s) {
    final d = s as dynamic;
    final v = (d.statusId ?? d.id);
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? -1;
  }
}





// class ContactTypePillDropdown extends ConsumerWidget {
//   final int? currentTypeId;
//   final Future<void> Function(int newTypeId) onChanged;

//   final double? maxPillWidth;
//   final double? menuMaxHeight;
//   final double? menuMaxWidth;

//   const ContactTypePillDropdown({
//     super.key,
//     required this.currentTypeId,
//     required this.onChanged,
//     this.maxPillWidth,
//     this.menuMaxHeight,
//     this.menuMaxWidth =200,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final theme = ref.watch(themeColorsProvider);

//     ref.watch(contactTypesFetchProvider); // trigger fetch
//     final meta = ref.watch(contactTypeProvider);

//     final items = meta.contactType
//         .map((t) => IdName(_typeId(t), _typeName(t)))
//         .toList();

//     if (items.isEmpty) {
//       return _plainPill(theme, '-');
//     }

//     return PillDropdown(
//       theme: theme,
//       currentId: currentTypeId,
//       items: items,
//       maxPillWidth: maxPillWidth,
//       menuMaxHeight: menuMaxHeight,
//       menuMaxWidth: menuMaxWidth,
//       onChanged: onChanged,
//     );
//   }

//   String _typeName(ContactTypeModel m) {
//     final d = m as dynamic;
//     return (d.name ?? d.label ?? d.title ?? '-').toString();
//   }

//   int _typeId(ContactTypeModel m) {
//     final d = m as dynamic;
//     final v = d.id;
//     if (v is int) return v;
//     return int.tryParse(v?.toString() ?? '') ?? -1;
//   }

//   Widget _plainPill(ThemeColors theme, String text) => Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         decoration: BoxDecoration(
//           color: theme.textColor.withAlpha(50),
//           borderRadius: BorderRadius.circular(6),
//         ),
//         child: Text(
//           text,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           style: TextStyle(color: theme.textFieldColor, fontSize: 13, fontWeight: FontWeight.w700),
//         ),
//       );
// }





// class ServiceTypePillDropdown extends ConsumerWidget {
//   final int? currentServiceTypeId;
//   final Future<void> Function(int newServiceTypeId) onChanged;

//   final double? maxPillWidth;
//   final double? menuMaxHeight;
//   final double? menuMaxWidth;

//   const ServiceTypePillDropdown({
//     super.key,
//     required this.currentServiceTypeId,
//     required this.onChanged,
//     this.maxPillWidth,
//     this.menuMaxHeight,
//     this.menuMaxWidth,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final theme = ref.watch(themeColorsProvider);

//     ref.watch(serviceTypesFetchProvider); // trigger fetch
//     final meta = ref.watch(contactTypeProvider);

//     final items = meta.contactServiceType
//         .map((t) => IdName(_serviceId(t), _serviceName(t)))
//         .toList();

//     if (items.isEmpty) {
//       return _plainPill(theme, '-');
//     }

//     return PillDropdown(
//       theme: theme,
//       currentId: currentServiceTypeId,
//       items: items,
//       maxPillWidth: maxPillWidth,
//       menuMaxHeight: menuMaxHeight,
//       menuMaxWidth: menuMaxWidth,
//       onChanged: onChanged,
//     );
//   }

//   String _serviceName(ServiceTypeModel m) {
//     final d = m as dynamic;
//     return (d.name ?? d.label ?? d.title ?? '-').toString();
//   }

//   int _serviceId(ServiceTypeModel m) {
//     final d = m as dynamic;
//     final v = d.id;
//     if (v is int) return v;
//     return int.tryParse(v?.toString() ?? '') ?? -1;
//   }

//   Widget _plainPill(ThemeColors theme, String text) => Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         decoration: BoxDecoration(
//           color: theme.textColor.withAlpha(50),
//           borderRadius: BorderRadius.circular(6),
//         ),
//         child: Text(
//           text,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           style: TextStyle(color: theme.textFieldColor, fontSize: 13, fontWeight: FontWeight.w700),
//         ),
//       );
// }



// // // Status klienta – zapis idzie do backendu (ClientNotifier.updateClientStatus)
// // ClientStatusPillDropdown(
// //   clientId: client.id,
// //   maxPillWidth: 180,
// //   menuMaxHeight: 300,
// //   menuMaxWidth: 320,
// // ),

// // // Typ kontaktu – Ty decydujesz jak zapisać (np. PATCH do klienta)
// // ContactTypePillDropdown(
// //   currentTypeId: client.contactTypeId, // lub null gdy brak
// //   onChanged: (newId) async {
// //     await ref.read(clientProvider.notifier).updateClient(
// //       client.id,
// //       client.copyWith(contactTypeId: newId),
// //     );
// //   },
// //   maxPillWidth: 180,
// // ),

// // // Typ usługi – podobnie:
// // ServiceTypePillDropdown(
// //   currentServiceTypeId: client.serviceTypeId,
// //   onChanged: (newId) async {
// //     await ref.read(clientProvider.notifier).updateClient(
// //       client.id,
// //       client.copyWith(serviceTypeId: newId),
// //     );
// //   },
// // ),
