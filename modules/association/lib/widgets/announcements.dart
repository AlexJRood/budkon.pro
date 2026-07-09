// lib/dashboard/widgets/news_and_announcements_widget.dart
import 'package:association/providers/articles.dart';
import 'package:association/providers/notifications.dart';
import 'package:association/screens/notifications/detail_pane.dart';
import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:association/screens/articles/edit_article.dart';
import 'package:association/screens/articles/create_articles.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';


class DashboardNewsAndAnnouncements extends ConsumerStatefulWidget {
  final int associationId;
  final String baseUrl; // e.g. https://www.superbee.cloud (dla campaignListProvider args)
  final double height;
  final ThemeColors theme;
  final bool isMobile;
  const DashboardNewsAndAnnouncements({
    super.key,
    this.height = 520,
    required this.associationId,
    required this.baseUrl,
    required this.theme,
    this.isMobile = false,
  });

  @override
  ConsumerState<DashboardNewsAndAnnouncements> createState() => _DashboardNewsAndAnnouncementsState();
}

class _DashboardNewsAndAnnouncementsState extends ConsumerState<DashboardNewsAndAnnouncements>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    // call .load() once, not in build (prevents loops)
    Future.microtask(() {
      ref.read(campaignListProvider((baseUrl: widget.baseUrl, associationId: widget.associationId)).notifier).load();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
            height: widget.height,
      
            
            decoration: BoxDecoration(
              color: widget.theme.dashboardContainer,
              border: Border.all(
                color: widget.theme.dashboardBoarder
              ),
              borderRadius: BorderRadius.all(Radius.circular(10))
            ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(            
            
            decoration: BoxDecoration(
              color: widget.theme.dashboardContainer,
              borderRadius: BorderRadius.all(Radius.circular(10))
            ),


            child: TabBar(
              controller: _tab,
              indicatorColor: widget.theme.themeColor,
              labelColor: widget.theme.textColor,
              unselectedLabelColor: widget.theme.textColor.withAlpha(160),
              labelStyle: TextStyle(color: widget.theme.textColor,),

              tabs:[
                Tab(text: 'recent_announcements'.tr),
                Tab(text: 'association_articles'.tr),
                Tab(text: 'system_news'.tr),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _CampaignsTab(
                  baseUrl: widget.baseUrl,
                  associationId: widget.associationId,
                  isMobile: widget.isMobile,
                ),
                _ArticlesTab(associationId: widget.associationId),
                _SystemNewsEmpty(theme: widget.theme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ====== Tab: Kampanie (używa Twojego campaignListProvider) ======
class _CampaignsTab extends ConsumerWidget {
  final String baseUrl;
  final int associationId;
  final bool isMobile;
  const _CampaignsTab({required this.baseUrl, required this.isMobile, required this.associationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(campaignListProvider((baseUrl: baseUrl, associationId: associationId)));
    final theme = ref.read(themeColorsProvider);
    
    if (state.loading) return const Center(child: CircularProgressIndicator());
    if (state.error != null) {
      return _ListError(
        theme:theme,
        message: 'failed_to_load_campaigns'.tr + state.error.toString(),
        onRetry: () => ref
            .read(campaignListProvider((baseUrl: baseUrl, associationId: associationId)).notifier)
            .load(),
      );
    }
    final items = state.items;
    if (items.isEmpty) return  _EmptyList(message: 'no_campaigns'.tr, theme: theme);

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final c = items[i];
        final title = c.title;
        final created = c.createdAt.toIso8601String();
        final thumb = c.image ?? '';
        final id = c.id;

        return _Tile(
          theme: theme,
          thumbnailUrl: thumb,
          title: title,
          subtitle: _friendlyDate(created,context),
          onTap: () => _openCampaign(context, ref, theme, id),
          // TODO: finish flow
          // trailing: IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        );
      },
    );
  }


  void _openCampaign(
  BuildContext context,
  WidgetRef ref,
  ThemeColors theme,
  String id,
) {
  Future<void> onActionDone() async {
    // Reload list so counters/status refresh
    await ref
        .read(
          campaignListProvider((baseUrl: baseUrl, associationId: associationId))
              .notifier,
        )
        .load();

    // Refresh detail provider
    ref.invalidate(campaignDetailProvider((baseUrl: baseUrl, id: id)));
  }

  PopPageManager.show(
    context,
    tag: 'assoc_campaign_$id',
    shouldBeADrawer: true,
    isBig: true,
    hasBackButton: true,
    hasPaddingMobile: false,
    child: const SizedBox.shrink(),

    // ✅ THIS passes scrollController into your detail pane
    childBuilder: (ctx, sc) {
      return AssociationCampaignDetailPane(
        baseUrl: baseUrl,
        selectedId: id,
        onActionDone: onActionDone,
        theme: theme,
        scrollController: sc,
      );
    },
  );
}


}


// ====== Tab: Artykuły (kompozycja z associationArticlesProvider) ======
class _ArticlesTab extends ConsumerWidget {
  final int associationId;
  const _ArticlesTab({required this.associationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentAssocArticlesProvider(associationId));
    final theme = ref.read(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ListError(
          theme: theme,
          message: 'failed_to_load_articles'.tr + e.toString(),
          onRetry: () => ref.refresh(recentAssocArticlesProvider(associationId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyList(
              theme: theme,
              message: 'no_articles'.tr,
              action: ElevatedButton.icon(
                icon: Icon(Icons.add, color: theme.textColor),
                label: Text('create_article'.tr, style: TextStyle(color: theme.textColor)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateAssociationArticlePage(associationId: associationId),
                    ),
                  );
                },
              ),
            );
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final a = items[i];
              final title = (a['title'] ?? '') as String;
              final thumb = (a['thumbnail'] ?? '') as String;
              final date = (a['published_date'] ?? '') as String;
              final author = () {
                final ap = a['author_public'];
                if (ap is Map) {
                  final fn = (ap['first_name'] ?? '') as String;
                  final ln = (ap['last_name'] ?? '') as String;
                  final u = (ap['username'] ?? '') as String;
                  final full = ('$fn $ln').trim();
                  return full.isNotEmpty ? full : u;
                }
                return '';
              }();

              return _Tile(
                theme: theme,
                thumbnailUrl: thumb,
                title: title,
                subtitle: [
                  if (author.isNotEmpty) 'by_author'.tr + author,
                  if (date.isNotEmpty) _friendlyDate(date, context),
                ].where((e) => e.isNotEmpty).join(' · '),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') {
                      Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (_) => EditAssociationArticlePage(
                            associationId: associationId,
                            articleId: (a['id'] as num).toInt(),
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) =>  [PopupMenuItem(value: 'edit', child: Text('Edit'.tr,
                        style: TextStyle(color: theme.textColor)))],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ====== Tab: System news (pusty) ======
class _SystemNewsEmpty extends StatelessWidget {
  final ThemeColors theme;
  const _SystemNewsEmpty({required this.theme});

  @override
  Widget build(BuildContext context) {
    return  Center(child: Text('System news – coming soon 🔧'.tr,
                        style: TextStyle(color: theme.textColor)));
  }
}

// ====== Wspólne mini-widżety ======
// (Comments in English)
class _Tile extends StatelessWidget {
  final String thumbnailUrl;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final ThemeColors theme;

  const _Tile({
    required this.thumbnailUrl,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(10);
    
    return ElevatedButton(
      style: elevatedButtonStyleRounded10,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: r,
              child: thumbnailUrl.isNotEmpty
                  ? Image.network(
                      thumbnailUrl,
                      width: 88,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbFallback(),
                    )
                  : _thumbFallback(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.textColor)
                      ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.textColor.withAlpha(180))
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback() => Container(
        width: 88,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_not_supported_outlined),
      );
}

class _EmptyList extends StatelessWidget {
  final String message;
  final Widget? action;
  final ThemeColors theme;
  const _EmptyList({required this.message, this.action, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(Icons.inbox_outlined, size: 42, color: theme.textColor),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: theme.textColor)),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}

class _ListError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final ThemeColors theme;
  const _ListError({required this.message, required this.onRetry, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: theme.textColor)),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: onRetry, icon: Icon(Icons.refresh, color: theme.textColor), label:  Text('try_again'.tr,
                        style: TextStyle(color: theme.textColor) )),
        ],
      ),
    );
  }
}

String _friendlyDate(String raw, BuildContext context) {
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  final now = DateTime.now();
  final d = now.difference(dt).inDays;
  if (d == 0) return 'today'.tr;
  if (d == 1) return 'one_day_ago'.tr;
  return 'days_ago'.trParams({'days': d.toString()});
}