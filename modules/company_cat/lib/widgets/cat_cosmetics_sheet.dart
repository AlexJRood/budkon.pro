import 'dart:convert';
import 'package:company_cat/company_cat_urls.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

import '../provider/company_cat_provider.dart';

class CosmeticItem {
  final String key;
  final String label;
  final int unlockPets;
  final bool unlocked;
  final bool equipped;
  const CosmeticItem({
    required this.key,
    required this.label,
    required this.unlockPets,
    required this.unlocked,
    required this.equipped,
  });

  factory CosmeticItem.fromJson(Map<String, dynamic> j) => CosmeticItem(
        key: (j['key'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        unlockPets:
            j['unlock_pets'] is num ? (j['unlock_pets'] as num).toInt() : 0,
        unlocked: j['unlocked'] == true,
        equipped: j['equipped'] == true,
      );
}

final _cosmeticsProvider =
    FutureProvider.autoDispose<List<CosmeticItem>>((ref) async {
  final resp = await ApiServices.get(
    CompanyCatUrls.companyCatCosmetics,
    hasToken: true,
    ref: null,
  );
  if (resp == null || resp.statusCode != 200) return const [];
  final data = resp.data;
  Map<String, dynamic> map;
  if (data is Map) {
    map = Map<String, dynamic>.from(data);
  } else if (data is List<int>) {
    map = Map<String, dynamic>.from(jsonDecode(utf8.decode(data)));
  } else if (data is String) {
    map = Map<String, dynamic>.from(jsonDecode(data));
  } else {
    return const [];
  }
  final list = map['items'];
  if (list is! List) return const [];
  return list
      .whereType<Map>()
      .map((e) => CosmeticItem.fromJson(Map<String, dynamic>.from(e)))
      .toList();
});

/// Ubranka kota — odblokowywane wspólnie (po głaskaniach), zero straty.
class CatCosmeticsSheet extends ConsumerWidget {
  const CatCosmeticsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_cosmeticsProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Ubranka 🎩',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            Flexible(
              child: async.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Nie udało się wczytać.'),
                ),
                data: (items) => GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  padding: const EdgeInsets.all(12),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children:
                      items.map((it) => _tile(context, ref, it)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, CosmeticItem it) {
    final display = it.key.isEmpty ? '🚫' : it.key;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: it.unlocked
          ? () async {
              await ref.read(companyCatProvider.notifier).equip(it.key);
              ref.invalidate(_cosmeticsProvider);
            }
          : null,
      child: Opacity(
        opacity: it.unlocked ? 1 : 0.4,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: it.equipped ? Colors.blue : Colors.grey.shade300,
              width: it.equipped ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(display, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
              Text(
                it.label,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
              if (!it.unlocked)
                Text(
                  '🔒 ${it.unlockPets}',
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
