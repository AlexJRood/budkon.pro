
import 'package:crm/your_agent/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class YourAgentStatusTab extends ConsumerWidget {
  final int transactionId;

  const YourAgentStatusTab({
    super.key,
    required this.transactionId,
  });

String _eventLabel(String type, String? backendLabel) {
  if (backendLabel != null && backendLabel.trim().isNotEmpty) {
    return backendLabel;
  }

  switch (type) {
    case 'invite_click':
      return 'event_invite_click'.tr;
    case 'invite_status_open':
      return 'event_invite_status_open'.tr;
    case 'portal_bound':
      return 'event_portal_bound'.tr;
    case 'portal_visit':
      return 'event_portal_visit'.tr;
    case 'case_open':
      return 'event_case_open'.tr;
    case 'listing_view':
      return 'event_listing_view'.tr;
    case 'documents_view':
      return 'event_documents_view'.tr;
    case 'presentations_view':
      return 'event_presentations_view'.tr;
    case 'presentations_list_view':
      return 'event_presentations_list_view'.tr;
    case 'presentation_item_open':
      return 'event_presentation_item_open'.tr;
    case 'presentation_event_open':
      return 'event_presentation_event_open'.tr;
    case 'suggestion_created':
      return 'event_suggestion_created'.tr;
    default:
      return type;
  }
}

  String _yesNo(bool value) => value ? 'yes_label'.tr : 'no_label'.tr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final asyncStatus = ref.watch(agentPortalStatusProvider(transactionId));

    return asyncStatus.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'error_loading_status $e'.tr,
          style: TextStyle(color: theme.textColor),
        ),
      ),
      data: (status) {
        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            _StatusSectionCard(
              title: 'invitation_status_title'.tr,
              children: [
               _StatusRow(label: 'link_clicked_label'.tr, value: _yesNo(status.isInviteClicked)),
               _StatusRow(label: 'click_count_label'.tr, value: status.inviteClickCount.toString()),
               _StatusRow(label: 'last_click_label'.tr, value: status.inviteClickedAt ?? '-'),
               _StatusRow(label: 'linked_account_label'.tr, value: _yesNo(status.isBound)),
               _StatusRow(label: 'accepted_bound_at_label'.tr, value: status.boundAt ?? '-'),
               _StatusRow(label: 'portal_active_label'.tr, value: _yesNo(status.isEnabled)),
               _StatusRow(label: 'client_has_access_now_label'.tr, value: _yesNo(status.canClientAccessNow)),
               _StatusRow(label: 'visible_until_label'.tr, value: status.visibleUntil ?? '-'),
              ],
            ),
            const SizedBox(height: 12),
            _StatusSectionCard(
              title: 'client_activity_title'.tr,
              children: [
                _StatusRow(label: 'client_visited_portal_label'.tr, value: _yesNo(status.isSeenByClient)),
                _StatusRow(label: 'first_visit_label'.tr, value: status.firstSeenAt ?? '-'),
                _StatusRow(label: 'last_visit_label'.tr, value: status.lastSeenAt ?? '-'),
                _StatusRow(label: 'visit_count_label'.tr, value: status.visitCount.toString()),
                _StatusRow(label: 'last_activity_label'.tr, value: status.lastActivityAt ?? '-'),
              ],
            ),
            const SizedBox(height: 12),
            _StatusSectionCard(
              title:'what_client_checked_title'.tr,
              children: [
                _StatusRow(label: 'viewed_listing_label'.tr, value: _yesNo(status.hasSeenListing)),
                _StatusRow(label: 'viewed_documents_label'.tr, value: _yesNo(status.hasSeenDocuments)),
                _StatusRow(label: 'viewed_presentations_label'.tr, value: _yesNo(status.hasSeenPresentations)),
              ],
            ),
            const SizedBox(height: 12),
            _StatusSectionCard(
              title: 'events_timeline_title'.tr,
              children: status.recentEvents.isEmpty
                  ? [
                      Text(
                        'no_events_message'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ]
                  : status.recentEvents.map((event) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.dashboardContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dashboardBoarder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _eventLabel(event.eventType, event.eventTypeLabel),
                              style: TextStyle(
                                color: theme.textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event.createdAt ?? '-',
                              style: TextStyle(
                                color: theme.textColor.withAlpha(170),
                                fontSize: 12,
                              ),
                            ),
                            if (event.userName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${'user_label'.tr}: ${event.userName}',
                                style: TextStyle(color: theme.textColor),
                              ),
                            ],
                            if (event.metadata.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                event.metadata.toString(),
                                style: TextStyle(
                                  color: theme.textColor.withAlpha(170),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _StatusSectionCard extends ConsumerWidget {
  final String title;
  final List<Widget> children;

  const _StatusSectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.textColor.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _StatusRow extends ConsumerWidget {
  final String label;
  final String value;

  const _StatusRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                color: theme.textColor.withAlpha(180),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}