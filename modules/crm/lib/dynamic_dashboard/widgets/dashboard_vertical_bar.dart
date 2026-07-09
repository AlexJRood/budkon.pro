import 'package:crm/dynamic_dashboard/models/catalog_models.dart';
import 'package:crm/dynamic_dashboard/models/dashboard_models.dart';
import 'package:crm/dynamic_dashboard/providers/dashboard_layout_provider.dart';
import 'package:crm/dynamic_dashboard/registry/dashboard_widget_registry.dart';
import 'package:crm/dynamic_dashboard/widgets/dashboard_grid_settings_sheet.dart';
import 'package:crm/dynamic_dashboard/widgets/widget_catalog.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';

class DashboardVerticalBar extends ConsumerWidget {
  const DashboardVerticalBar({
    super.key,
    required this.dashboardKey,
  });

  final String dashboardKey;

  void _showSnackSafe(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message)),
        );
    });
  }

  DashboardBreakpoint _breakpointFor(double width) {
    if (width < 800) return DashboardBreakpoint.mobile;
    if (width < 1200) return DashboardBreakpoint.tablet;
    return DashboardBreakpoint.desktop;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(dashboardLayoutProvider(dashboardKey));
    final notifier = ref.read(dashboardLayoutProvider(dashboardKey).notifier);
    final breakpoint = _breakpointFor(MediaQuery.sizeOf(context).width);

    final existingTypes =
        state.config?.instances.map((e) => e.type).toSet() ?? <String>{};

    Widget buildButton({
      required Widget icon,
      required VoidCallback? onPressed,
      String? tooltip,
    }) {
      return Tooltip(
        message: tooltip ?? '',
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: theme.adPopBackground,
            borderRadius: const BorderRadius.all(Radius.circular(6)),
          ),
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed: onPressed,
            child: icon,
          ),
        ),
      );
    }

    return EmmaUiAnchorTarget(
      // @emma-backend: DashboardVerticalBarEmmaAnchors.root(dashboardKey)
      anchorKey: 'dynamic_dashboard.$dashboardKey.vertical_bar.root',
      child: Column(
        spacing: 4,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          EmmaUiAnchorTarget(
            // @emma-backend: DashboardVerticalBarEmmaAnchors.toggleBuilder(dashboardKey)
            anchorKey:
                'dynamic_dashboard.$dashboardKey.vertical_bar.toggle_builder',
            child: buildButton(
              tooltip: state.isEditMode
                  ? 'Exit builder'.tr
                  : 'Open builder'.tr,
              onPressed: state.isLoading
                  ? null
                  : () {
                      notifier.toggleEditMode();
                      _showSnackSafe(
                        context,
                        state.isEditMode
                            ? 'Builder closed'.tr
                            : 'Builder opened'.tr,
                      );
                    },
              icon: state.isEditMode
                  ? Icon(Icons.close_rounded, color: theme.textColor)
                  : Icon(Icons.edit_rounded, color: theme.textColor),
            ),
          ),

          EmmaUiAnchorTarget(
            // @emma-backend: DashboardVerticalBarEmmaAnchors.refresh(dashboardKey)
            anchorKey: 'dynamic_dashboard.$dashboardKey.vertical_bar.refresh',
            child: buildButton(
              tooltip: 'Refresh dashboard'.tr,
              onPressed: () async {
                try {
                  await notifier.load(forceRefresh: true);
                  _showSnackSafe(context, 'Dashboard refreshed'.tr);
                } catch (e) {
                  _showSnackSafe(context, 'Refresh error: $e'.tr);
                }
              },
              icon: AppIcons.refresh(color: theme.textColor),
            ),
          ),

          if (state.isEditMode)
            EmmaUiAnchorTarget(
              // @emma-backend: DashboardVerticalBarEmmaAnchors.addWidget(dashboardKey)
              anchorKey:
                  'dynamic_dashboard.$dashboardKey.vertical_bar.add_widget',
              child: buildButton(
                tooltip: 'Add widget'.tr,
                onPressed: () {
                  final isWide = MediaQuery.sizeOf(context).width >= 800;

                  Future<void> handleAdd(DashboardCatalogItem item) async {
                    final instanceId = notifier.addCatalogWidget(
                      item,
                      zoneKey: 'main',
                    );
                    if (instanceId.isEmpty) return;

                    final spec = ref
                        .read(dashboardWidgetRegistryProvider)
                        .byType(item.componentKey);

                    if (spec == null || !spec.needsFirstSetup) {
                      _showSnackSafe(context, 'Widget added'.tr);
                      return;
                    }

                    await Future.delayed(const Duration(milliseconds: 250));

                    if (!context.mounted) {
                      notifier.removeWidget(instanceId);
                      return;
                    }

                    final settings = await spec.runFirstSetup(
                      context,
                      ref,
                      instanceId,
                      dashboardKey,
                      'main',
                    );

                    if (settings == null) {
                      notifier.removeWidget(instanceId);
                    } else {
                      notifier.updateWidgetSettings(
                        instanceId: instanceId,
                        settings: settings,
                      );
                      if (context.mounted) {
                        _showSnackSafe(context, 'Widget added'.tr);
                      }
                    }
                  }

                  if (isWide) {
                    showDialog<void>(
                      context: context,
                      builder: (_) => Dialog(
                        insetPadding: const EdgeInsets.symmetric(
                          horizontal: 60,
                          vertical: 60,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: theme.dashboardContainer,
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: DashboardWidgetMarketplaceSheet(
                            dashboardKey: dashboardKey,
                            zoneKey: 'main',
                            existingTypes: existingTypes,
                            onAdd: handleAdd,
                          ),
                        ),
                      ),
                    );
                  } else {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => DraggableScrollableSheet(
                        initialChildSize: 0.75,
                        minChildSize: 0.4,
                        maxChildSize: 0.95,
                        snap: true,
                        snapSizes: const [0.5, 0.75, 0.95],
                        builder: (_, __) => ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: ColoredBox(
                            color: theme.dashboardContainer,
                            child: DashboardWidgetMarketplaceSheet(
                              dashboardKey: dashboardKey,
                              zoneKey: 'main',
                              existingTypes: existingTypes,
                              onAdd: handleAdd,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.widgets_rounded, color: theme.textColor),
              ),
            ),

          if (state.isEditMode)
            EmmaUiAnchorTarget(
              // @emma-backend: DashboardVerticalBarEmmaAnchors.saveLayout(dashboardKey)
              anchorKey:
                  'dynamic_dashboard.$dashboardKey.vertical_bar.save_layout',
              child: buildButton(
                tooltip: 'Save layout'.tr,
                onPressed: state.isSaving
                    ? null
                    : () async {
                        await notifier.saveNow();
                        if (context.mounted) {
                          _showSnackSafe(context, 'Dashboard saved'.tr);
                        }
                      },
                icon: Icon(Icons.save_rounded, color: theme.textColor),
              ),
            ),

          if (state.isEditMode)
            EmmaUiAnchorTarget(
              // @emma-backend: DashboardVerticalBarEmmaAnchors.resetLayout(dashboardKey)
              anchorKey:
                  'dynamic_dashboard.$dashboardKey.vertical_bar.reset_layout',
              child: buildButton(
                tooltip: 'Reset layout'.tr,
                onPressed: state.isSaving
                    ? null
                    : () async {
                        await notifier.resetToDefault();
                        if (context.mounted) {
                          _showSnackSafe(context, 'Layout reset'.tr);
                        }
                      },
                icon: Icon(Icons.restart_alt_rounded, color: theme.textColor),
              ),
            ),

          if (state.isEditMode)
            buildButton(
              tooltip: 'Grid settings'.tr,
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => DashboardGridSettingsSheet(
                    dashboardKey: dashboardKey,
                    breakpoint: breakpoint,
                  ),
                );
              },
              icon: Icon(Icons.tune_rounded, color: theme.textColor),
            ),

          if (state.isEditMode)
            EmmaUiAnchorTarget(
              // @emma-backend: DashboardVerticalBarEmmaAnchors.preview(dashboardKey)
              anchorKey: 'dynamic_dashboard.$dashboardKey.vertical_bar.preview',
              child: buildButton(
                tooltip: 'Preview final look'.tr,
                onPressed: () {
                  notifier.setEditMode(false);
                  _showSnackSafe(context, 'Preview mode'.tr);
                },
                icon: Icon(Icons.visibility_rounded, color: theme.textColor),
              ),
            ),
        ],
      ),
    );
  }
}