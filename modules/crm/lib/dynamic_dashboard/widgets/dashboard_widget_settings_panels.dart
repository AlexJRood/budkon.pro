import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SwitchTile extends ConsumerWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          color: theme.textColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: theme.textColor.withAlpha(150),
          fontSize: 12,
        ),
      ),
      value: value,
      activeThumbColor: theme.themeColor,
      activeTrackColor: theme.themeColor.withAlpha(180),
      onChanged: onChanged,
    );
  }
}

// ─── Welcome Header ───────────────────────────────────────────────────────────

class WelcomeHeaderSettingsPanel extends StatelessWidget {
  const WelcomeHeaderSettingsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final Map<String, dynamic> settings;
  final ValueChanged<Map<String, dynamic>> onSettingsChanged;

  bool get _showSubtitle {
    final raw = settings['showSubtitle'];
    if (raw is bool) return raw;
    return true;
  }

  void _patch(Map<String, dynamic> patch) =>
      onSettingsChanged({...settings, ...patch});

  @override
  Widget build(BuildContext context) {
    return _SwitchTile(
      title: 'Show subtitle'.tr,
      subtitle: 'Real Estate Property Management Dashboard',
      value: _showSubtitle,
      onChanged: (v) => _patch({'showSubtitle': v}),
    );
  }
}

// ─── Financial Widget ─────────────────────────────────────────────────────────

class FinancialWidgetSettingsPanel extends ConsumerWidget {
  const FinancialWidgetSettingsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final Map<String, dynamic> settings;
  final ValueChanged<Map<String, dynamic>> onSettingsChanged;

  bool _bool(String key) {
    final raw = settings[key];
    return raw is bool ? raw : false;
  }

  void _patch(Map<String, dynamic> patch) =>
      onSettingsChanged({...settings, ...patch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Column(
      children: [
        _SwitchTile(
          title: 'Scroll to latest'.tr,
          subtitle: 'Start scrolled to the right (most recent)'.tr,
          value: _bool('alignRight'),
          onChanged: (v) => _patch({'alignRight': v}),
        ),
        Divider(height: 1, color: theme.dashboardBoarder),
        _SwitchTile(
          title: 'Vertical layout'.tr,
          subtitle: 'Stack revenues and expenses vertically'.tr,
          value: _bool('vertical'),
          onChanged: (v) => _patch({'vertical': v}),
        ),
        Divider(height: 1, color: theme.dashboardBoarder),
        _SwitchTile(
          title: 'Expanded cards'.tr,
          subtitle: 'Larger chips with more vertical space'.tr,
          value: _bool('isExpanded'),
          onChanged: (v) => _patch({'isExpanded': v}),
        ),
      ],
    );
  }
}

// ─── Recent Leads ─────────────────────────────────────────────────────────────

class RecentLeadsSettingsPanel extends ConsumerWidget {
  const RecentLeadsSettingsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final Map<String, dynamic> settings;
  final ValueChanged<Map<String, dynamic>> onSettingsChanged;

  bool get _transparentBackground =>
      (settings['backgroundMode'] ?? 'card').toString() == 'transparent';

  bool get _minimalItems =>
      (settings['itemStyle'] ?? 'card').toString() == 'minimal';

  bool get _showHeader {
    final raw = settings['showHeader'];
    return raw is bool ? raw : true;
  }

  bool get _compact {
    final raw = settings['compact'];
    return raw is bool ? raw : false;
  }

  void _patch(Map<String, dynamic> patch) =>
      onSettingsChanged({...settings, ...patch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Column(
      children: [
        _SwitchTile(
          title: 'Transparent background'.tr,
          subtitle: 'Remove widget background and border'.tr,
          value: _transparentBackground,
          onChanged: (v) =>
              _patch({'backgroundMode': v ? 'transparent' : 'card'}),
        ),
        Divider(height: 1, color: theme.dashboardBoarder),
        _SwitchTile(
          title: 'Show header'.tr,
          subtitle: 'Show title and navigation button'.tr,
          value: _showHeader,
          onChanged: (v) => _patch({'showHeader': v}),
        ),
        Divider(height: 1, color: theme.dashboardBoarder),
        _SwitchTile(
          title: 'Minimal contact items'.tr,
          subtitle: 'Remove card background from each contact row'.tr,
          value: _minimalItems,
          onChanged: (v) => _patch({'itemStyle': v ? 'minimal' : 'card'}),
        ),
        Divider(height: 1, color: theme.dashboardBoarder),
        _SwitchTile(
          title: 'Compact mode'.tr,
          subtitle: 'Prefer compact list layout'.tr,
          value: _compact,
          onChanged: (v) => _patch({'compact': v}),
        ),
      ],
    );
  }
}

// ─── Association Membership Status ───────────────────────────────────────────

class AssociationMembershipStatusSettingsPanel extends ConsumerWidget {
  const AssociationMembershipStatusSettingsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final Map<String, dynamic> settings;
  final ValueChanged<Map<String, dynamic>> onSettingsChanged;

  bool _bool(String key, {bool defaultValue = true}) {
    final raw = settings[key];
    return raw is bool ? raw : defaultValue;
  }

  void _patch(Map<String, dynamic> patch) =>
      onSettingsChanged({...settings, ...patch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Column(
      children: [
        _SwitchTile(
          title: 'Show header'.tr,
          subtitle: 'Show title, add member button and filters'.tr,
          value: _bool('showHeader'),
          onChanged: (v) => _patch({'showHeader': v}),
        ),
        Divider(height: 1, color: theme.dashboardBoarder),
        _SwitchTile(
          title: 'Show payments banner'.tr,
          subtitle: 'Show subscription management reminder'.tr,
          value: _bool('showPaymentsBanner'),
          onChanged: (v) => _patch({'showPaymentsBanner': v}),
        ),
        Divider(height: 1, color: theme.dashboardBoarder),
        _SwitchTile(
          title: 'Show pagination'.tr,
          subtitle: 'Show previous / next page buttons'.tr,
          value: _bool('showPagination'),
          onChanged: (v) => _patch({'showPagination': v}),
        ),
      ],
    );
  }
}

// ─── Association Overview ─────────────────────────────────────────────────────

class AssociationOverviewSettingsPanel extends ConsumerWidget {
  const AssociationOverviewSettingsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final Map<String, dynamic> settings;
  final ValueChanged<Map<String, dynamic>> onSettingsChanged;

  static const _options = [7, 14, 30, 60, 90];

  int get _days {
    final raw = settings['days'];
    return raw is num ? raw.toInt() : 30;
  }

  void _patch(Map<String, dynamic> patch) =>
      onSettingsChanged({...settings, ...patch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final current = _days;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Time range'.tr,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _options
              .map(
                (d) => ChoiceChip(
                  label: Text(
                    '$d ${'days'.tr}',
                    style: TextStyle(
                      color: d == current ? theme.themeTextColor : theme.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: d == current,
                  selectedColor: theme.themeColor,
                  backgroundColor: theme.adPopBackground.withAlpha(80),
                  side: BorderSide(
                    color: d == current
                        ? theme.themeColor
                        : theme.dashboardBoarder,
                  ),
                  onSelected: (_) => _patch({'days': d}),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
