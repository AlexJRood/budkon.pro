import 'package:calendar/state_managers/appointments_provider.dart';
import 'package:calendar/state_managers/popup_calendar_provider.dart';
import 'package:calendar/widgets/save_event_widget.dart';
import 'package:crm/contact_panel/components/client_calendar.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_client_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

/// Dashboard-grid aware version of the client events widget: unlike
/// [NewClientEvent]/[NewClientEventMobile] (which assume a generous fixed
/// height on the static client tab), this adapts to whatever height/width
/// the dashboard grid cell actually grants it, and exposes layout options
/// (list only / calendar only / both, compact stacking, transparent
/// background, header visibility) the same way other dashboard widgets do.
class DashboardClientEventsWidget extends ConsumerWidget {
  const DashboardClientEventsWidget({
    super.key,
    required this.clientId,
    required this.isMobile,
    this.layout = 'both',
    this.backgroundMode = 'card',
    this.showHeader = true,
    this.compact = false,
    this.isEditMode = false,
  });

  final String clientId;
  final bool isMobile;
  final String layout;
  final String backgroundMode;
  final bool showHeader;
  final bool compact;
  final bool isEditMode;

  bool get _transparentBackground => backgroundMode == 'transparent';
  bool get _showList => layout != 'calendar';
  bool get _showCalendar => layout != 'list';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return _ClientEventsFrame(
      theme: theme,
      transparent: _transparentBackground,
      showHeader: showHeader,
      onAddEvent: isEditMode ? null : () => _addEvent(context, ref),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final list = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ClientEvettile(clientId: clientId, isMobile: true),
          );

          if (!_showCalendar) return list;

          final calendar = Padding(
            padding: const EdgeInsets.all(8),
            child: CustomTableCalendarPc(
              clientId: clientId,
              primaryColor: Theme.of(context).primaryColor,
              fillColor: Colors.white,
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
            ),
          );

          if (!_showList) return calendar;

          final stacked = compact || isMobile || constraints.maxWidth < 520;

          if (stacked) {
            return Column(
              children: [
                Expanded(flex: 4, child: list),
                const SizedBox(height: 8),
                Expanded(flex: 5, child: calendar),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 10, child: list),
              Expanded(flex: 7, child: calendar),
            ],
          );
        },
      ),
    );
  }

  bool get _useBottomSheet {
    if (kIsWeb) return false;
    return isMobile;
  }

  void _addEvent(BuildContext context, WidgetRef ref) {
    ref.read(appointmentsProvider).isEdit = false;
    ref.read(popupCalendarProvider.notifier).clearAllFields();

    final cid = int.tryParse(clientId);
    if (cid != null) {
      final ev = ref.read(popupCalendarProvider).event;
      ref.read(popupCalendarProvider).event = ev.copyWith(client: cid);
    }

    if (_useBottomSheet) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (ctx) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.55,
            maxChildSize: 0.95,
            expand: false,
            shouldCloseOnMinExtent: true,
            builder: (context, scrollController) {
              return SaveEventWidget(
                index: 0,
                clientId: clientId,
                isClientDashboard: true,
                isMobile: true,
                scrollController: scrollController,
              );
            },
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: SaveEventWidget(
            index: 0,
            clientId: clientId,
            isClientDashboard: true,
          ),
        ),
      );
    }
  }
}

class _ClientEventsFrame extends StatelessWidget {
  const _ClientEventsFrame({
    required this.theme,
    required this.child,
    this.transparent = false,
    this.showHeader = true,
    this.onAddEvent,
  });

  final ThemeColors theme;
  final Widget child;
  final bool transparent;
  final bool showHeader;
  final VoidCallback? onAddEvent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: transparent
          ? null
          : BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: theme.dashboardBoarder),
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Column(
          children: [
            if (showHeader)
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: transparent
                      ? Colors.transparent
                      : theme.dashboardContainer,
                  border: Border(
                    bottom: BorderSide(
                      color: transparent
                          ? Colors.transparent
                          : theme.dashboardBoarder.withAlpha(150),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'planned_events_label'.tr,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (onAddEvent != null)
                      IconButton(
                        onPressed: onAddEvent,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.add,
                          size: 18,
                          color: theme.textColor,
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class ClientEventsSettingsPanel extends StatelessWidget {
  const ClientEventsSettingsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final Map<String, dynamic> settings;
  final ValueChanged<Map<String, dynamic>> onSettingsChanged;

  String get _layout => (settings['layout'] ?? 'both').toString();

  bool get _transparentBackground {
    return (settings['backgroundMode'] ?? 'card').toString() == 'transparent';
  }

  bool get _showHeader {
    final raw = settings['showHeader'];
    if (raw is bool) return raw;
    return true;
  }

  bool get _compact {
    final raw = settings['compact'];
    if (raw is bool) return raw;
    return false;
  }

  void _patch(Map<String, dynamic> patch) {
    onSettingsChanged({
      ...settings,
      ...patch,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'Layout'.tr,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text('Events list + calendar'.tr),
          value: 'both',
          groupValue: _layout,
          onChanged: (value) {
            if (value != null) _patch({'layout': value});
          },
        ),
        RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text('Events list only'.tr),
          value: 'list',
          groupValue: _layout,
          onChanged: (value) {
            if (value != null) _patch({'layout': value});
          },
        ),
        RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text('Calendar only'.tr),
          value: 'calendar',
          groupValue: _layout,
          onChanged: (value) {
            if (value != null) _patch({'layout': value});
          },
        ),
        const Divider(height: 1),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('Transparent background'.tr),
          subtitle: Text('Remove widget background and border'.tr),
          value: _transparentBackground,
          onChanged: (value) {
            _patch({'backgroundMode': value ? 'transparent' : 'card'});
          },
        ),
        const Divider(height: 1),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('Show header'.tr),
          subtitle: Text('Show title and add-event button'.tr),
          value: _showHeader,
          onChanged: (value) {
            _patch({'showHeader': value});
          },
        ),
        const Divider(height: 1),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('Compact layout'.tr),
          subtitle: Text('Always stack list and calendar vertically'.tr),
          value: _compact,
          onChanged: (value) {
            _patch({'compact': value});
          },
        ),
      ],
    );
  }
}
