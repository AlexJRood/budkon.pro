// lib/screens/association_notifications/widgets/detail_pane.dart
// Comments are in English as requested.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:association/models/notifications_model.dart';
import 'package:association/providers/notifications.dart';
import 'package:core/theme/apptheme.dart';

import 'action_buttons.dart';
import 'info_tile.dart';
import 'preview_recipients.dart';
import 'json_card.dart';

class AssociationCampaignDetailPane extends ConsumerWidget {
  const AssociationCampaignDetailPane({
    super.key,
    required this.baseUrl,
    required this.selectedId,
    required this.onActionDone,
    required this.theme,
    this.scrollController,
  });

  final String baseUrl;
  final String? selectedId;
  final Future<void> Function() onActionDone;
  final ThemeColors theme;

  /// When provided (mobile drawer), this should be used by the internal scrollable.
  final ScrollController? scrollController;

  bool _isMobileLayout(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return scrollController != null || w < 600;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedId == null) {
      return Center(
        child: Text(
          'Wybierz kampanię z listy lub utwórz nową.',
          style: TextStyle(color: theme.textColor),
        ),
      );
    }

    final detail = ref.watch(
      campaignDetailProvider((baseUrl: baseUrl, id: selectedId!)),
    );

    return detail.when(
      data: (AssociationNotificationCampaign? c) {
        if (c == null) {
          return Center(
            child: Text(
              'Nie znaleziono kampanii.',
              style: TextStyle(color: theme.textColor),
            ),
          );
        }

        final mobile = _isMobileLayout(context);

        // Shared header block
        Widget header = Row(
          children: [
            Expanded(
              child: Text(
                c.title,
                style: TextStyle(color: theme.textColor, fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            AssociationCampaignActionButtons(
              baseUrl: baseUrl,
              campaign: c,
              onDone: onActionDone,
              theme: theme,
            ),
          ],
        );

        Widget statusWrap = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            InfoTile('Status', theme, c.status),
            InfoTile(
              'Plan',
              theme,
              c.scheduledAt?.toLocal().toString().substring(0, 16) ?? '—',
            ),
            InfoTile(
              'Wysłano',
              theme,
              '${c.sentSuccess}/${c.totalRecipients} (failed: ${c.sentFailed})',
            ),
          ],
        );

        Widget imageBlock = (c.image != null && c.image!.isNotEmpty)
            ? SizedBox(
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(c.image!, fit: BoxFit.cover),
                ),
              )
            : const SizedBox.shrink();

        // ✅ MOBILE: scrollable column, no Expanded inside
        if (mobile) {
          final h = MediaQuery.of(context).size.height;
          final cardHeight = (h * 0.32).clamp(220.0, 360.0);

          return ListView(
            controller: scrollController, // ✅ critical: wired to DraggableScrollableSheet
            padding: const EdgeInsets.all(16),
            children: [
              header,
              const SizedBox(height: 12),

              SelectableText(c.text, style: TextStyle(color: theme.textColor)),
              const SizedBox(height: 8),

              statusWrap,
              const SizedBox(height: 12),

              if (c.image != null && c.image!.isNotEmpty) ...[
                imageBlock,
                const SizedBox(height: 16),
              ],

              // On mobile stack cards vertically and give them a bounded height
              SizedBox(
                height: cardHeight,
                child: PreviewRecipientsCard(items: c.preview, theme: theme),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: cardHeight,
                child: JsonCard(title: 'Akcje (JSON)', theme: theme, value: c.actions),
              ),

              const SizedBox(height: 24),
            ],
          );
        }

        // ✅ DESKTOP: your original layout (bounded height from dialog)
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 12),
              SelectableText(c.text, style: TextStyle(color: theme.textColor)),
              const SizedBox(height: 8),
              statusWrap,
              const SizedBox(height: 12),
              if (c.image != null && c.image!.isNotEmpty) ...[
                imageBlock,
                const SizedBox(height: 16),
              ],
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: PreviewRecipientsCard(items: c.preview, theme: theme),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: JsonCard(title: 'Akcje (JSON)', theme: theme, value: c.actions),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Błąd: $e')),
    );
  }
}
