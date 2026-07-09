import 'package:association/screens/events/models/event_models.dart';
import 'package:association/screens/events/screen/social_events.dart';
import 'package:association/screens/events/widgets/event_helper_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';

class EventsGrid extends StatelessWidget {
  const EventsGrid({required this.items, required this.theme});
  final List<EventPublicCardModel> items;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return CenteredMsg('no_events_found'.tr, theme);
    final w = MediaQuery.of(context).size.width;
    final cross = w >= 1400
        ? 4
        : w >= 1100
        ? 3
        : w >= 700
        ? 2
        : 1;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 0.85, // Slightly taller for premium info layout
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _EventCard(item: items[i]),
    );
  }
}

class _EventCard extends ConsumerWidget {
  const _EventCard({required this.item});
  final EventPublicCardModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final date = item.startTime != null
        ? DateFormat(
            'EEE, d MMM • HH:mm',
            'pl_PL',
          ).format(item.startTime!.toLocal())
        : '';

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicEventDetailsPage(slug: item.slug),
        ),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: CustomColors.secondaryWidgetColor(context, ref),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.textColor.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.coverImageUrl != null &&
                      item.coverImageUrl!.isNotEmpty)
                    Image.network(item.coverImageUrl!, fit: BoxFit.cover)
                  else
                    Container(
                      color: theme.textColor.withOpacity(0.1),
                      child: Icon(
                        Icons.event,
                        size: 48,
                        color: theme.textColor.withOpacity(0.3),
                      ),
                    ),

                  // Top Overlay Chips
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.isFree
                                ? Icons.celebration
                                : Icons.confirmation_number,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.isFree ? 'FREE' : 'TICKETS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info Section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        AppIcons.calendar(
                          color: theme.textColor.withOpacity(0.6),
                          width: 14,
                          height: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            date,
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        AppIcons.location(
                          color: theme.textColor.withOpacity(0.6),
                          width: 14,
                          height: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.city?.isNotEmpty == true
                                ? item.city!
                                : (item.location ?? 'TBA'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.textColor.withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Divider(height: 1, thickness: 0.5),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LEARN MORE',
                          style: TextStyle(
                            color: theme.textColor.withValues(alpha: 0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: theme.textColor.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
