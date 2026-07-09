import 'package:flutter/material.dart';
import 'package:core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:emma/settings/emma_memory_service.dart';
import 'package:emma/settings/emma_memory_provider.dart';

/// Ekran „Co Emma o mnie pamięta" — fakty trwałe, bieżący kontekst, preferencje.
class EmmaMemorySettingsMobile extends ConsumerStatefulWidget {
  const EmmaMemorySettingsMobile({super.key});

  @override
  ConsumerState<EmmaMemorySettingsMobile> createState() =>
      _EmmaMemorySettingsMobileState();
}

class _EmmaMemorySettingsMobileState
    extends ConsumerState<EmmaMemorySettingsMobile> {
  final Set<String> _busy = {};

  Future<void> _forget(
      {required String kind, String? key, int? id, required String tag}) async {
    setState(() => _busy.add(tag));
    final ok = await EmmaMemoryService.forget(
        ref: ref, kind: kind, key: key, id: id);
    if (!mounted) return;
    if (ok) {
      ref.invalidate(emmaMemoryProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się usunąć.'.tr)),
      );
    }
    if (mounted) setState(() => _busy.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final textTheme = Theme.of(context).textTheme;
    final memAsync = ref.watch(emmaMemoryProvider);

    return Scaffold(
      body: Column(
        children: [
          MobileSettingsAppbar(
            title: 'Co Emma o mnie pamięta'.tr,
            onPressed: () => ref.read(navigationService).beamPop(),
          ),
          Expanded(
            child: memAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Błąd ładowania pamięci.'.tr,
                    style: TextStyle(color: theme.textColor)),
              ),
              data: (mem) {
                if (mem == null) {
                  return Center(
                    child: Text('Nie udało się załadować pamięci.'.tr,
                        style: TextStyle(color: theme.textColor)),
                  );
                }
                if (mem.isEmpty) {
                  return _EmptyState(theme: theme);
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(emmaMemoryProvider),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'To, co Emma zapamiętała, żeby lepiej Ci pomagać. Możesz usunąć dowolny wpis.'
                            .tr,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: theme.textColor.withAlpha(170)),
                      ),
                      const SizedBox(height: 20),

                      if (mem.facts.isNotEmpty) ...[
                        _SectionHeader(
                            icon: Icons.person_outline,
                            title: 'Fakty o Tobie'.tr,
                            color: theme.textColor),
                        const SizedBox(height: 8),
                        ...mem.facts.map((f) => _MemoryTile(
                              theme: theme,
                              title: _prettyKey(f.key),
                              value: f.value,
                              badge: f.category,
                              busy: _busy.contains('fact:${f.id}'),
                              onDelete: () => _forget(
                                  kind: 'fact', id: f.id, tag: 'fact:${f.id}'),
                            )),
                        const SizedBox(height: 20),
                      ],

                      if (mem.preferences.isNotEmpty) ...[
                        _SectionHeader(
                            icon: Icons.tune,
                            title: 'Preferencje'.tr,
                            color: theme.textColor),
                        const SizedBox(height: 8),
                        ...mem.preferences.entries.map((e) => _MemoryTile(
                              theme: theme,
                              title: _prettyKey(e.key),
                              value: e.value,
                              busy: _busy.contains('pref:${e.key}'),
                              onDelete: () => _forget(
                                  kind: 'preference',
                                  key: e.key,
                                  tag: 'pref:${e.key}'),
                            )),
                        const SizedBox(height: 20),
                      ],

                      if (mem.context.isNotEmpty) ...[
                        _SectionHeader(
                            icon: Icons.schedule,
                            title: 'Na teraz (wygasa)'.tr,
                            color: theme.textColor),
                        const SizedBox(height: 8),
                        ...mem.context.map((c) => _MemoryTile(
                              theme: theme,
                              title: _prettyKey(c.key),
                              value: c.value,
                              badge: c.expiresAt != null
                                  ? 'do ${c.expiresAt!.substring(0, 16).replaceAll('T', ' ')}'
                                  : null,
                              busy: _busy.contains('ctx:${c.id}'),
                              onDelete: () => _forget(
                                  kind: 'context', id: c.id, tag: 'ctx:${c.id}'),
                            )),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _prettyKey(String key) =>
      key.replaceAll('_', ' ').trim().capitalizeFirst ?? key;
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: color.withAlpha(200)),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15, color: color)),
        ],
      );
}

class _MemoryTile extends StatelessWidget {
  final dynamic theme;
  final String title;
  final String value;
  final String? badge;
  final bool busy;
  final VoidCallback onDelete;

  const _MemoryTile({
    required this.theme,
    required this.title,
    required this.value,
    this.badge,
    required this.busy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.filterPageColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.bordercolor.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.textColor)),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.textColor.withAlpha(18),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(badge!,
                            style: TextStyle(
                                fontSize: 10,
                                color: theme.textColor.withAlpha(160))),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(value,
                    style: TextStyle(color: theme.textColor.withAlpha(200))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  visualDensity: VisualDensity.compact,
                  splashRadius: 20,
                  icon: Icon(Icons.close,
                      size: 18, color: theme.textColor.withAlpha(140)),
                  tooltip: 'Zapomnij'.tr,
                  onPressed: onDelete,
                ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final dynamic theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.psychology_outlined,
                  size: 48, color: theme.textColor.withAlpha(90)),
              const SizedBox(height: 14),
              Text(
                'Na razie nie pamiętam o Tobie nic trwałego.'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: theme.textColor),
              ),
              const SizedBox(height: 6),
              Text(
                'Powiedz mi coś o sobie albo swoich preferencjach, a zapamiętam.'
                    .tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textColor.withAlpha(150)),
              ),
            ],
          ),
        ),
      );
}
