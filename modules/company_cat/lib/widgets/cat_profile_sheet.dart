import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/cat_profile_provider.dart';
import '../provider/company_cat_provider.dart';

/// Profil kota: staty, najlepszy przyjaciel, leaderboard, achievements.
class CatProfileSheet extends ConsumerWidget {
  const CatProfileSheet({super.key});

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(catProfileProvider);
    final cat = ref.watch(companyCatProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Nie udało się wczytać profilu.'),
          ),
          data: (p) {
            if (p == null) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Brak profilu kota.'),
              );
            }
            return ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading:
                      Text(cat.moodEmoji, style: const TextStyle(fontSize: 30)),
                  title: Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Humor ${p.happiness} · Energia ${p.energy} · '
                    'Głaskań ${p.totalPets} · Opiekunów ${p.distinctPetters}',
                  ),
                ),
                if (p.bestFriend != null)
                  ListTile(
                    leading: const Text('🏆', style: TextStyle(fontSize: 22)),
                    title: const Text('Najlepszy przyjaciel'),
                    subtitle: Text(
                      '${p.bestFriend!.name} · ${p.bestFriend!.count} interakcji',
                    ),
                  ),
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Leaderboard',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                ...p.leaderboard.asMap().entries.map((e) {
                  final i = e.key;
                  final entry = e.value;
                  return ListTile(
                    dense: true,
                    leading: Text(
                      i < 3 ? _medals[i] : '${i + 1}.',
                      style: const TextStyle(fontSize: 18),
                    ),
                    title: Text(entry.name),
                    trailing: Text(
                      '${entry.count}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                }),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: p.achievements
                        .map(
                          (a) => Chip(
                            avatar: Text(a.unlocked ? '⭐' : '🔒'),
                            label: Text(a.label),
                            backgroundColor:
                                a.unlocked ? null : Colors.grey.shade200,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
