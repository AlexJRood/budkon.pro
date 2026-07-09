// lib/article/list_association_articles_page.dart
import 'package:association/providers/articles.dart';
import 'package:association/screens/articles/create_articles.dart';
import 'package:association/screens/articles/edit_article.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';

/// Simple local state providers for list controls
final _pageProvider = StateProvider.autoDispose<int>((ref) => 1);
final _pageSizeProvider = StateProvider.autoDispose<int>((ref) => 10);
final _searchProvider = StateProvider.autoDispose<String?>((ref) => null);
final _orderingProvider = StateProvider.autoDispose<String?>((ref) => '-published_date');

class ListAssociationArticlesPage extends ConsumerWidget {
  final int associationId;
  const ListAssociationArticlesPage({super.key, required this.associationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // read current controls
    final page = ref.watch(_pageProvider);
    final pageSize = ref.watch(_pageSizeProvider);
    final search = ref.watch(_searchProvider);
    final ordering = ref.watch(_orderingProvider);
    final theme = ref.read(themeColorsProvider);

    final args = ArticleListArgs(
      associationId: associationId,
      page: page,
      pageSize: pageSize,
      search: (search?.isEmpty ?? true) ? null : search,
      ordering: (ordering?.isEmpty ?? true) ? null : ordering,
    );

    final asyncList = ref.watch(associationArticlesProvider(args));

    // helper to refresh list
    Future<void> refresh() async {
      ref.invalidate(associationArticlesProvider(args));
      await ref.read(associationArticlesProvider(args).future);
    }

    final sideMenuKey = GlobalKey<SideMenuState>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        Future<void> _openCreateArticle() async {
          final created = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  CreateAssociationArticlePage(associationId: associationId),
            ),
          );
          if (created != null) {
            await refresh();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dodano artykuł')),
              );
            }
          }
        }

        // wspólny content listy artykułów – użyjemy go na PC i mobile
        final Widget content = asyncList.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            error: e,
            onRetry: refresh,
          ),
          data: (data) {
            final results = (data['results'] as List?) ?? const [];
            final count = (data['count'] as int?) ?? results.length;
            final totalPages = (count / pageSize).ceil().clamp(1, 999999);

            if (results.isEmpty) {
              return _EmptyView(
                theme: theme,
                onCreate: _openCreateArticle,
              );
            }

            return Column(
              children: [
                // HEADER
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    isMobile ? 8 : 16,
                    12,
                    isMobile ? 4 : 10,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Artykuły stowarzyszenia',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                      const Spacer(),
                      if (!isMobile) ...[
                        IconButton(
                          tooltip: 'Odśwież',
                          onPressed: () => refresh(),
                          icon: const Icon(Icons.refresh),
                        ),
                        _OrderingMenu(
                          current: ordering,
                          onChanged: (o) {
                            ref.read(_orderingProvider.notifier).state = o;
                            ref.read(_pageProvider.notifier).state = 1;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
                          child: SizedBox(
                            width: 260,
                            child: _SearchField(
                              initial: search,
                              onSubmitted: (q) {
                                ref.read(_searchProvider.notifier).state =
                                    q?.trim().isEmpty == true ? null : q?.trim();
                                ref.read(_pageProvider.notifier).state = 1;
                              },
                              onCleared: () {
                                ref.read(_searchProvider.notifier).state = null;
                                ref.read(_pageProvider.notifier).state = 1;
                              },
                            ),
                          ),
                        ),
                      ] else ...[
                        // MOBILE: tylko przycisk refresh + ikona filtra,
                        // a search/sort możemy wrzucić do bottomSheet w kolejnym kroku
                        IconButton(
                          tooltip: 'Odśwież',
                          onPressed: () => refresh(),
                          icon: const Icon(Icons.refresh),
                          color: theme.textColor,
                        ),
                      ],
                    ],
                  ),
                ),

                // MOBILE: search pod tytułem, na pełną szerokość
                if (isMobile)
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    child: _SearchField(
                      initial: search,
                      onSubmitted: (q) {
                        ref.read(_searchProvider.notifier).state =
                            q?.trim().isEmpty == true ? null : q?.trim();
                        ref.read(_pageProvider.notifier).state = 1;
                      },
                      onCleared: () {
                        ref.read(_searchProvider.notifier).state = null;
                        ref.read(_pageProvider.notifier).state = 1;
                      },
                    ),
                  ),

                // Header with count & page size selector
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  child: Row(
                    children: [
                      Text(
                        'Liczba: $count',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      DropdownButton<int>(
                        value: pageSize,
                        onChanged: (v) {
                          if (v == null) return;
                          ref.read(_pageSizeProvider.notifier).state = v;
                          ref.read(_pageProvider.notifier).state = 1;
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 10,
                            child: Text('10 / str.'),
                          ),
                          DropdownMenuItem(
                            value: 20,
                            child: Text('20 / str.'),
                          ),
                          DropdownMenuItem(
                            value: 50,
                            child: Text('50 / str.'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final item = results[i] as Map<String, dynamic>;
                        return _ArticleCard(
                          article: item,
                          onEdit: () async {
                            final updated = await Navigator.of(ctx).push(
                              MaterialPageRoute(
                                builder: (_) => EditAssociationArticlePage(
                                  associationId: associationId,
                                  articleId: item['id'] as int,
                                ),
                              ),
                            );
                            if (updated != null) {
                              await refresh();
                            }
                          },
                          onDelete: () async {
                            final ok = await _confirmDelete(ctx);
                            if (ok != true) return;
                            try {
                              await ref
                                  .read(deleteArticleProvider(item['id'] as int).future);
                              await refresh();
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                      content: Text('Usunięto artykuł')),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Błąd usuwania: $e'),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),

                _Pager(
                  page: page,
                  totalPages: totalPages,
                  onPrev: page > 1
                      ? () =>
                          ref.read(_pageProvider.notifier).state = page - 1
                      : null,
                  onNext: page < totalPages
                      ? () =>
                          ref.read(_pageProvider.notifier).state = page + 1
                      : null,
                ),
              ],
            );
          },
        );

        return BarManager(
          sideMenuKey: sideMenuKey,
          appModule: AppModule.association,
          paddingMobile: 8,

          // PC – duży FAB
          verticalButtonsPc: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Nowy artykuł'),
            onPressed: _openCreateArticle,
          ),

          // Mobile – mały plusik przy krawędzi
          verticalButtons:
              isMobile ? _MobileAddArticleButton(onPressed: _openCreateArticle) : null,

          // ważne: osobne layouty platformowe
          childrenPc: [
            content,
          ],
          childrenMobile: [
            const SizedBox(height: 60),
            content,
          ],
        );
      },
    );
  }
}


// --- Widgets ---

class _SearchField extends StatefulWidget {
  final String? initial;
  final ValueChanged<String?> onSubmitted;
  final VoidCallback onCleared;
  const _SearchField({
    required this.initial,
    required this.onSubmitted,
    required this.onCleared,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) {
      _ctrl.text = widget.initial ?? '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      decoration: InputDecoration(
        hintText: 'Szukaj po tytule/treści/autorze…',
        filled: true,
        isDense: true,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _ctrl.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _ctrl.clear();
                  widget.onCleared();
                },
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onSubmitted: (v) => widget.onSubmitted(v),
    );
  }
}

class _OrderingMenu extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onChanged;
  const _OrderingMenu({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      tooltip: 'Sortowanie',
      initialValue: current,
      onSelected: onChanged,
      itemBuilder: (ctx) => const [
        PopupMenuItem(value: '-published_date', child: Text('Najnowsze')),
        PopupMenuItem(value: 'published_date', child: Text('Najstarsze')),
        PopupMenuItem(value: 'title', child: Text('Tytuł A→Z')),
        PopupMenuItem(value: '-title', child: Text('Tytuł Z→A')),
      ],
      icon: const Icon(Icons.sort),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Map<String, dynamic> article;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ArticleCard({
    required this.article,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = (article['title'] ?? '') as String;
    final status = (article['status'] ?? 'draft') as String;
    final publisherName = (article['publisher_public']?['company_name'] ?? '') as String? ?? '';
    final authorName = () {
      final ap = article['author_public'];
      if (ap is Map && ap['first_name'] != null) {
        final fn = (ap['first_name'] ?? '') as String;
        final ln = (ap['last_name'] ?? '') as String;
        final u = (ap['username'] ?? '') as String;
        final full = ('$fn $ln').trim();
        return full.isNotEmpty ? full : u;
      }
      return (article['author']?.toString()) ?? '';
    }();

    final publishedDate = (article['published_date'] ?? '') as String? ?? '';
    final tags = (article['tags'] as List?)?.length ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail preview (if you keep URL or path)
            if (article['thumbnail'] != null && (article['thumbnail'] as String).isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  article['thumbnail'],
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 84,
                    height: 84,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              )
            else
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.article),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title + status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(status == 'published' ? 'Opublikowany' : 'Szkic'),
                        backgroundColor: status == 'published'
                            ? Colors.green.withAlpha(31)
                            : Colors.orange.withAlpha(31),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (publisherName.isNotEmpty)
                        Chip(
                          label: Text(publisherName, overflow: TextOverflow.ellipsis),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (authorName.isNotEmpty)
                        Chip(
                          label: Text('Autor: $authorName', overflow: TextOverflow.ellipsis),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (publishedDate.isNotEmpty)
                        Chip(
                          label: Text('Data: $publishedDate'),
                          visualDensity: VisualDensity.compact,
                        ),
                      Chip(
                        label: Text('Tagi: $tags'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edytuj'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Usuń'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  final int page;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _Pager({
    required this.page,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Text('Strona $page z $totalPages'),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Poprzednia'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Następna'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onCreate;
  final ThemeColors theme;
  const _EmptyView({required this.onCreate, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feed, size: 48, color: theme.textColor.withAlpha(160)),
            const SizedBox(height: 8),
            Text('Brak artykułów', style: TextStyle(color: theme.textColor.withAlpha(160))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: Icon(Icons.add, color: theme.textColor),
              label: Text('Utwórz pierwszy', style: TextStyle(color: theme.textColor)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
            const SizedBox(height: 8),
            Text(
              'Błąd: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      ),
    );
  }
}






// umieść np. na dole pliku list_association_articles_page.dart (po widgetach)
// top-level helper
Future<bool> _confirmDelete(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Usunąć artykuł?'),
      content: const Text('Tej operacji nie można cofnąć.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Usuń'),
        ),
      ],
    ),
  );
  return result ?? false;
}





class _MobileAddArticleButton extends StatelessWidget {
  const _MobileAddArticleButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 45,
      height: 45,
      child: ElevatedButton(
        style: buttonStyleRounded10ThemeRed,
        onPressed: onPressed,
        child: const Icon(Icons.add, color: Colors.white, size: 22),
      ),
    );
  }
}
