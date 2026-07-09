import 'package:crm/contact_panel/tabs/employee_settlements/models/compensation_notification_preferences_model.dart';
import 'package:crm/contact_panel/tabs/employee_settlements/provider/compensation_notification_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

class CompensationNotificationPreferencesCard extends ConsumerStatefulWidget {
  final bool isMobile;

  const CompensationNotificationPreferencesCard({
    super.key,
    this.isMobile = false,
  });

  @override
  ConsumerState<CompensationNotificationPreferencesCard> createState() =>
      _CompensationNotificationPreferencesCardState();
}

class _CompensationNotificationPreferencesCardState
    extends ConsumerState<CompensationNotificationPreferencesCard> {
  final TextEditingController _eventTypeController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _eventTypeController.dispose();
    super.dispose();
  }

  Future<void> _save(CompensationNotificationPreferencesModel model) async {
    if (_saving) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(compensationNotificationPreferencesProvider.notifier)
          .save(model);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('compensation_notifications_saved'.tr)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'Error'.tr}: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addEventType(CompensationNotificationPreferencesModel model) {
    final value = _eventTypeController.text.trim();
    if (value.isEmpty) return;

    _eventTypeController.clear();
    _save(model.addEventType(value));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(compensationNotificationPreferencesProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: state.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => _ErrorState(
          error: error,
          onRetry: () => ref
              .read(compensationNotificationPreferencesProvider.notifier)
              .fetch(),
        ),
        data: (model) => _NotificationPreferencesContent(
          theme: theme,
          model: model,
          saving: _saving,
          eventTypeController: _eventTypeController,
          onSave: _save,
          onAddEventType: () => _addEventType(model),
        ),
      ),
    );
  }
}

class _NotificationPreferencesContent extends StatelessWidget {
  final ThemeColors theme;
  final CompensationNotificationPreferencesModel model;
  final bool saving;
  final TextEditingController eventTypeController;
  final ValueChanged<CompensationNotificationPreferencesModel> onSave;
  final VoidCallback onAddEventType;

  const _NotificationPreferencesContent({
    required this.theme,
    required this.model,
    required this.saving,
    required this.eventTypeController,
    required this.onSave,
    required this.onAddEventType,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = saving || !model.enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final title = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'compensation_notifications_title'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.textColor,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  'compensation_notifications_subtitle'.tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(165),
                    height: 1.35,
                  ),
                ),
              ],
            );

            final pill = _StatusPill(
              enabled: model.enabled,
              pushEnabled: model.pushEnabled,
            );

            if (constraints.maxWidth < 720) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, const SizedBox(height: 10), pill],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: title), pill],
            );
          },
        ),
        const SizedBox(height: 16),
        _SwitchTile(
          title: 'compensation_notifications_enabled'.tr,
          subtitle: 'compensation_notifications_enabled_hint'.tr,
          icon: Icons.notifications_active_outlined,
          value: model.enabled,
          enabled: !saving,
          onChanged: (value) => onSave(model.copyWith(enabled: value)),
        ),
        _SwitchTile(
          title: 'compensation_push_enabled'.tr,
          subtitle: 'compensation_push_enabled_hint'.tr,
          icon: Icons.mobile_friendly_outlined,
          value: model.pushEnabled,
          enabled: !disabled,
          onChanged: (value) => onSave(model.copyWith(pushEnabled: value)),
        ),
        _SwitchTile(
          title: 'compensation_show_amounts'.tr,
          subtitle: 'compensation_show_amounts_hint'.tr,
          icon: Icons.payments_outlined,
          value: model.showAmounts,
          enabled: !disabled,
          onChanged: (value) => onSave(model.copyWith(showAmounts: value)),
        ),
        const SizedBox(height: 14),
        Text(
          'compensation_notification_events'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        for (final option in model.availableEvents)
          _SwitchTile(
            title: _eventTitle(option),
            subtitle: _eventSubtitle(option.key),
            icon: _eventIcon(option.key),
            value: model.eventEnabled(option.key),
            enabled: !disabled,
            compact: true,
            onChanged: (value) => onSave(model.toggleEvent(option.key, value)),
          ),
        const SizedBox(height: 14),
        Text(
          'compensation_event_type_filter'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'compensation_event_type_filter_hint'.tr,
          style: TextStyle(color: theme.textColor.withAlpha(155)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (model.eventTypes.isEmpty)
              Chip(
                avatar: const Icon(Icons.all_inclusive, size: 16),
                label: Text('all_events'.tr),
              )
            else
              for (final eventType in model.eventTypes)
                InputChip(
                  label: Text(eventType),
                  onDeleted: disabled
                      ? null
                      : () => onSave(model.removeEventType(eventType)),
                ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final field = CoreTextField(
              controller: eventTypeController,
              label: 'compensation_event_type'.tr,
              enabled: !disabled,
              prefixIcon: const Icon(Icons.filter_alt_outlined, size: 18),
              onSubmitted: (_) {
                if (!disabled) onAddEventType();
              },
            );

            final button = CoreOutlinedButton(
              onPressed: disabled ? null : onAddEventType,
              child: Text('add'.tr),
            );

            if (constraints.maxWidth < 620) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [field, const SizedBox(height: 8), button],
              );
            }

            return Row(
              children: [
                Expanded(child: field),
                const SizedBox(width: 10),
                button,
              ],
            );
          },
        ),
      ],
    );
  }

  String _eventTitle(CompensationNotificationEventOption option) {
    switch (option.key) {
      case 'agreement_available':
        return 'notification_event_agreement_available'.tr;
      case 'agreement_status_changed':
        return 'notification_event_agreement_status_changed'.tr;
      case 'compensation_event_created':
        return 'notification_event_compensation_event_created'.tr;
      case 'settlement_published':
        return 'notification_event_settlement_published'.tr;
      case 'payment_received':
        return 'notification_event_payment_received'.tr;
      default:
        return option.label;
    }
  }

  String _eventSubtitle(String key) {
    switch (key) {
      case 'agreement_available':
        return 'notification_event_agreement_available_hint'.tr;
      case 'agreement_status_changed':
        return 'notification_event_agreement_status_changed_hint'.tr;
      case 'compensation_event_created':
        return 'notification_event_compensation_event_created_hint'.tr;
      case 'settlement_published':
        return 'notification_event_settlement_published_hint'.tr;
      case 'payment_received':
        return 'notification_event_payment_received_hint'.tr;
      default:
        return '';
    }
  }

  IconData _eventIcon(String key) {
    switch (key) {
      case 'agreement_available':
        return Icons.assignment_turned_in_outlined;
      case 'agreement_status_changed':
        return Icons.sync_alt_outlined;
      case 'compensation_event_created':
        return Icons.add_chart_outlined;
      case 'settlement_published':
        return Icons.receipt_long_outlined;
      case 'payment_received':
        return Icons.payments_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}

class _SwitchTile extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final bool enabled;
  final bool compact;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.themeColor.withAlpha(value ? 14 : 5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: SwitchListTile.adaptive(
          value: value,
          onChanged: enabled ? onChanged : null,
          secondary: Icon(icon, color: theme.textColor),
          title: Text(
            title,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: subtitle.isEmpty
              ? null
              : Text(
                  subtitle,
                  style: TextStyle(color: theme.textColor.withAlpha(150)),
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends ConsumerWidget {
  final bool enabled;
  final bool pushEnabled;

  const _StatusPill({
    required this.enabled,
    required this.pushEnabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final label = !enabled
        ? 'notifications_disabled'.tr
        : pushEnabled
            ? 'push_notifications_enabled'.tr
            : 'in_app_notifications_only'.tr;

    final icon = !enabled
        ? Icons.notifications_off_outlined
        : pushEnabled
            ? Icons.notifications_active_outlined
            : Icons.notifications_none_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.textColor),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.error_outline, size: 34),
        const SizedBox(height: 10),
        Text('unable_to_load_notification_settings'.tr),
        const SizedBox(height: 5),
        Text(error.toString(), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        CoreOutlinedButton(onPressed: onRetry, child: Text('retry'.tr)),
      ],
    );
  }
}
