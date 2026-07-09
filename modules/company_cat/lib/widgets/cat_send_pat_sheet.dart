import 'dart:convert';
import 'package:company_cat/company_cat_urls.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

import '../provider/company_cat_provider.dart';

class CatMember {
  final int userId;
  final String name;
  const CatMember(this.userId, this.name);
}

final _catMembersProvider =
    FutureProvider.autoDispose<List<CatMember>>((ref) async {
  final resp = await ApiServices.get(
    CompanyCatUrls.companyCatMembers,
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

  final list = map['members'];
  if (list is! List) return const [];
  return list.whereType<Map>().map((e) {
    final id = e['user_id'];
    final uid = id is int ? id : int.tryParse('$id') ?? 0;
    return CatMember(uid, (e['name'] ?? '').toString());
  }).where((m) => m.userId != 0).toList();
});

/// Picker: wyślij głaska koledze (kot dostarczy).
class CatSendPatSheet extends ConsumerWidget {
  const CatSendPatSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_catMembersProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Wyślij głaska 🐾',
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
                  child: Text('Nie udało się wczytać listy.'),
                ),
                data: (members) {
                  if (members.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Brak kolegów w firmie.'),
                    );
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: members
                        .map(
                          (m) => ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person_outline),
                            ),
                            title: Text(m.name),
                            trailing: const Text('🐾'),
                            onTap: () {
                              final messenger = ScaffoldMessenger.maybeOf(context);
                              ref
                                  .read(companyCatProvider.notifier)
                                  .sendPat(m.userId);
                              Navigator.pop(context);
                              messenger?.showSnackBar(
                                SnackBar(
                                  content: Text('Wysłano głaska do ${m.name}'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
