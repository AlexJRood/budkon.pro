import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';

import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';

import 'package:crm/shared/models/contact_type_model.dart';
import 'package:crm/shared/models/service_type_model.dart';
import 'package:crm/data/clients/contact_type_provider.dart';

/// Contact Type (pill dropdown)
class ContactTypePillDropdown extends ConsumerWidget {
  final int? currentTypeId;
  final Future<void> Function(int newTypeId) onChanged;

  /// Optional sizing
  final double? maxPillWidth;
  final double? menuMaxHeight;
  final double? menuMaxWidth;

  const ContactTypePillDropdown({
    super.key,
    required this.currentTypeId,
    required this.onChanged,
    this.maxPillWidth,
    this.menuMaxHeight,
    this.menuMaxWidth = 320,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final nav = ref.watch(navigationService);
    final path = nav.currentPath;

    // Trigger fetch
    ref.watch(contactTypesFetchProvider);
    final meta = ref.watch(contactTypeProvider);

    final types = meta.contactType;
    if (types.isEmpty) {
      return _pillFrame(
        theme: theme,
        maxWidth: maxPillWidth,
        child: Text('set_contact_type_button'.tr, style: _pillTextStyle(theme)),
        onPressed: (){
          nav.pushNamedScreen('$path/${Routes.contactTypes}',
                                      data: {'isFilter': false},
          );
          }
          );
    }

    final selectedId = currentTypeId;
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
            value: selectedId,
            icon: AppIcons.iosArrowDown(color: theme.textColor),
            style: TextStyle(
              color: theme.dashboardContainer,
              fontSize: 13,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w700,
            ),
            items: types.map((t) {
              return DropdownMenuItem<int>(
                value: _typeId(t),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: menuMaxWidth ?? 320),
                  child: Text(
                    _typeName(t),
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
            }).toList(),
            selectedItemBuilder: (_) => types.map((t) {
              return Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: (maxPillWidth != null)
                        ? (maxPillWidth! - (horizontalPad * 2)).clamp(0, double.infinity)
                        : double.infinity,
                  ),
                  child: Text(
                    _typeName(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _pillTextStyle(theme),
                  ),
                ),
              );
            }).toList(),
            onChanged: (int? newId) async {
              if (newId == null || newId == selectedId) return;
              await onChanged(newId);
            },
          ),
        ),
      ),
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
  VoidCallback? onPressed, // <-- correct type
  }) {
    return ElevatedButton(
      style: elevatedButtonStyleRounded10,
      onPressed: onPressed,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcons.circlePlus(color: theme.textColor),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  String _typeName(ContactTypeModel m) {
    // Prefer label, then contactType
    final name = m.label.isNotEmpty ? m.label : m.contactType;
    return (name.isNotEmpty ? name : '-');
  }

  int _typeId(ContactTypeModel m) => m.id;
}

/// Service Type (pill dropdown)
class ServiceTypePillDropdown extends ConsumerWidget {
  final int? currentServiceTypeId;
  final Future<void> Function(int newServiceTypeId) onChanged;

  /// Optional sizing
  final double? maxPillWidth;
  final double? menuMaxHeight;
  final double? menuMaxWidth;

  const ServiceTypePillDropdown({
    super.key,
    required this.currentServiceTypeId,
    required this.onChanged,
    this.maxPillWidth,
    this.menuMaxHeight,
    this.menuMaxWidth = 320,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    // Trigger fetch
    ref.watch(serviceTypesFetchProvider);
    final meta = ref.watch(contactTypeProvider);

    final services = meta.contactServiceType;
    if (services.isEmpty) {
      return _pillFrame(
        theme: theme,
        maxWidth: maxPillWidth,
        child: Text('set_contact_type_button'.tr, style: _pillTextStyle(theme)),
      );
    }

    final selectedId = currentServiceTypeId;
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
            value: selectedId,
            icon: AppIcons.iosArrowDown(color: theme.textColor),
            style: TextStyle(
              color: theme.dashboardContainer,
              fontSize: 13,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w700,
            ),
            items: services.map((s) {
              return DropdownMenuItem<int>(
                value: _serviceId(s),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: menuMaxWidth ?? 320),
                  child: Text(
                    _serviceName(s),
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
            }).toList(),
            selectedItemBuilder: (_) => services.map((s) {
              return Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: (maxPillWidth != null)
                        ? (maxPillWidth! - (horizontalPad * 2)).clamp(0, double.infinity)
                        : double.infinity,
                  ),
                  child: Text(
                    _serviceName(s),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _pillTextStyle(theme),
                  ),
                ),
              );
            }).toList(),
            onChanged: (int? newId) async {
              if (newId == null || newId == selectedId) return;
              await onChanged(newId);
            },
          ),
        ),
      ),
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
          AppIcons.iosArrowDown(color: theme.textColor),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
            child: child,
          ),
        ],
      ),
    );
  }

  String _serviceName(ServiceTypeModel m) {
    final d = m as dynamic;
    final name = (d.name ?? d.label ?? d.title ?? '').toString();
    return name.isNotEmpty ? name : '-';
  }

  int _serviceId(ServiceTypeModel m) {
    final d = m as dynamic;
    final v = d.id;
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? -1;
  }
}
