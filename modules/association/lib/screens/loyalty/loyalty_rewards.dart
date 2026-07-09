// lib/loyalty/loyalty_rewards_screen.dart
import 'dart:convert';

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

T normalizeJson<T>(dynamic value) {
  if (value is T) return value;
  final decoded = jsonDecode(jsonEncode(value));
  return decoded as T;
}

/// ---------- Models ----------
class RewardItem {
  final int id;
  final int program;
  final String code;
  final String name;
  final int costPoints;
  final String rewardType; // voucher_percent | voucher_fixed | perk
  final Map<String, dynamic> payload;
  final bool isActive;

  RewardItem({
    required this.id,
    required this.program,
    required this.code,
    required this.name,
    required this.costPoints,
    required this.rewardType,
    required this.payload,
    required this.isActive,
  });

  factory RewardItem.fromJson(Map<String, dynamic> j) => RewardItem(
        id: j['id'] as int,
        program: (j['program'] is int)
            ? j['program'] as int
            : (j['program']?['id'] ?? 0),
        code: j['code'] as String? ?? '',
        name: j['name'] as String? ?? '',
        costPoints: (j['cost_points'] as num? ?? 0).toInt(),
        rewardType: j['reward_type'] as String? ?? 'voucher_percent',
        payload: j['payload'] is Map
            ? Map<String, dynamic>.from(j['payload'])
            : normalizeJson<Map<String, dynamic>>(j['payload'] ?? {}),
        isActive: j['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'program': program,
        'code': code,
        'name': name,
        'cost_points': costPoints,
        'reward_type': rewardType,
        'payload': payload,
        'is_active': isActive,
      };
}

class ScaleTier {
  final int id;
  final int program;
  final String name;
  final int threshold;
  final int order;
  final Map<String, dynamic> benefits;

  ScaleTier({
    required this.id,
    required this.program,
    required this.name,
    required this.threshold,
    required this.order,
    required this.benefits,
  });

  factory ScaleTier.fromJson(Map<String, dynamic> j) => ScaleTier(
        id: j['id'] as int,
        program: (j['program'] is int)
            ? j['program'] as int
            : (j['program']?['id'] ?? 0),
        name: j['name'] as String? ?? '',
        threshold: (j['threshold'] as num? ?? 0).toInt(),
        order: (j['order'] as num?)?.toInt() ?? 0,
        benefits: j['benefits'] is Map
            ? Map<String, dynamic>.from(j['benefits'])
            : normalizeJson<Map<String, dynamic>>(j['benefits'] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'program': program,
        'name': name,
        'threshold': threshold,
        'order': order,
        'benefits': benefits,
      };
}

class BalanceProgress {
  final int userId;
  final int points;
  final String tier;
  final String? nextTier;
  final int? nextThreshold;
  final double progressPercent;

  BalanceProgress({
    required this.userId,
    required this.points,
    required this.tier,
    this.nextTier,
    this.nextThreshold,
    required this.progressPercent,
  });

  factory BalanceProgress.fromJson(Map<String, dynamic> j) => BalanceProgress(
        userId: (j['user_id'] ?? 0) as int,
        points: (j['points'] ?? 0) as int,
        tier: (j['tier'] ?? 'basic') as String,
        nextTier: j['next_tier'] as String?,
        nextThreshold: j['next_threshold'] as int?,
        progressPercent: ((j['progress_percent'] ?? 0.0) as num).toDouble(),
      );
}

/// ---------- API ----------
class RewardsApi {
  RewardsApi(this.baseUrl, {required this.ref});
  final String baseUrl;
  final Ref ref;

  String _u(String p) => '$baseUrl$p';

  // Rewards
  Future<List<RewardItem>> listRewards({required int programId}) async {
    final res = await ApiServices.get(
      _u('/loyalty/rewards/'),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
      queryParameters: {'program': programId},
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Fetch rewards failed: ${res?.statusCode}');
    }
    final data = normalizeJson<dynamic>(res.data);
    final List list = data is List
        ? data
        : (data is Map && data['results'] is List ? data['results'] : const []);
    return list
        .map((e) => RewardItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<RewardItem> createReward(RewardItem item) async {
    final res = await ApiServices.post(
      _u('/loyalty/rewards/'),
      hasToken: true,
      ref: ref,
      data: item.toJson(),
    );
    if (res == null || (res.statusCode != 201 && res.statusCode != 200)) {
      throw Exception('Create reward failed: ${res?.statusCode} ${res?.data}');
    }
    return RewardItem.fromJson(normalizeJson<Map<String, dynamic>>(res.data));
  }

  Future<RewardItem> updateReward(int id, Map<String, dynamic> patch) async {
    final res = await ApiServices.patch(
      _u('/loyalty/rewards/$id/'),
      hasToken: true,
      ref: ref,
      data: patch,
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Update reward failed: ${res?.statusCode}');
    }
    return RewardItem.fromJson(normalizeJson<Map<String, dynamic>>(res.data));
  }

  Future<void> deleteReward(int id) async {
    final res = await ApiServices.delete(
      _u('/loyalty/rewards/$id/'),
      hasToken: true,
    );
    if (res == null || res.statusCode != 204) {
      throw Exception('Delete reward failed: ${res?.statusCode}');
    }
  }

  // Scale tiers
  Future<List<ScaleTier>> listTiers({required int programId}) async {
    final res = await ApiServices.get(
      _u('/loyalty/tiers/'),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
      queryParameters: {'program': programId},
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Fetch tiers failed: ${res?.statusCode}');
    }
    final data = normalizeJson<dynamic>(res.data);
    final List list = data is List
        ? data
        : (data is Map && data['results'] is List ? data['results'] : const []);
    return list
        .map((e) => ScaleTier.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ScaleTier> createTier(ScaleTier t) async {
    final res = await ApiServices.post(
      _u('/loyalty/tiers/'),
      hasToken: true,
      ref: ref,
      data: t.toJson(),
    );
    if (res == null || (res.statusCode != 201 && res.statusCode != 200)) {
      throw Exception('Create tier failed: ${res?.statusCode} ${res?.data}');
    }
    return ScaleTier.fromJson(normalizeJson<Map<String, dynamic>>(res.data));
  }

  Future<ScaleTier> updateTier(int id, Map<String, dynamic> patch) async {
    final res = await ApiServices.patch(
      _u('/loyalty/tiers/$id/'),
      hasToken: true,
      ref: ref,
      data: patch,
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Update tier failed: ${res?.statusCode}');
    }
    return ScaleTier.fromJson(normalizeJson<Map<String, dynamic>>(res.data));
  }

  Future<void> deleteTier(int id) async {
    final res = await ApiServices.delete(
      _u('/loyalty/tiers/$id/'),
      hasToken: true,
    );
    if (res == null || res.statusCode != 204) {
      throw Exception('Delete tier failed: ${res?.statusCode}');
    }
  }

  // Balance for quick header
  Future<BalanceProgress> getBalance({required int programId}) async {
    final res = await ApiServices.get(
      _u('/loyalty/balance/'),
      hasToken: true,
      ref: ref,
      queryParameters: {'program': programId},
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Balance fetch failed: ${res?.statusCode}');
    }
    final obj = normalizeJson<Map<String, dynamic>>(res.data);
    return BalanceProgress.fromJson(obj);
  }
}

/// ---------- Providers ----------
final rewardsApiProvider = Provider.family<RewardsApi, String>((ref, baseUrl) {
  return RewardsApi(baseUrl, ref: ref);
});

final rewardItemsProvider =
    FutureProvider.family<List<RewardItem>, ({String baseUrl, int programId})>(
        (ref, args) async {
  final api = ref.read(rewardsApiProvider(args.baseUrl));
  return api.listRewards(programId: args.programId);
});

final scaleTiersProvider =
    FutureProvider.family<List<ScaleTier>, ({String baseUrl, int programId})>(
        (ref, args) async {
  final api = ref.read(rewardsApiProvider(args.baseUrl));
  return api.listTiers(programId: args.programId);
});

final balanceProvider =
    FutureProvider.family<BalanceProgress, ({String baseUrl, int programId})>(
        (ref, args) async {
  final api = ref.read(rewardsApiProvider(args.baseUrl));
  return api.getBalance(programId: args.programId);
});

/// ---------- Screen ----------
class LoyaltyRewardsScreen extends ConsumerWidget {
  const LoyaltyRewardsScreen({
    super.key,
    this.baseUrl = 'https://www.superbee.cloud',
    required this.programId,
  });

  final String baseUrl;
  final int programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final balanceAsync =
        ref.watch(balanceProvider((baseUrl: baseUrl, programId: programId)));

    final sideMenuKey = GlobalKey<SideMenuState>();

    return LayoutBuilder(
      builder: (context, constraints) {
        // --- header z balansem (wspólny dla obu layoutów) ---
        Widget buildBalanceHeader() {
          return balanceAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (b) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dashboardBoarder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars, size: 20, color: theme.textColor),
                    const SizedBox(width: 8),
                    Text(
                      'Twój poziom: ${b.tier} • Punkty: ${b.points}',
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (b.nextThreshold != null && b.nextTier != null)
                      Text(
                        'Do poziomu ${b.nextTier}: '
                        '${(b.nextThreshold! - b.points).clamp(0, 1 << 31)} pkt',
                        style: TextStyle(
                          color: theme.textColor.withAlpha(170),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        }
// --- wnętrze z TabBar + TabBarView (wspólne) ---
Widget buildTabs() {
  return DefaultTabController(
    length: 2,
    child: Column(
      children: [
        // TabBar
        Container(
          height: 48,
          padding: const EdgeInsets.all(4), // ✅ odstęp pod "pill"
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            border: Border.all(color: theme.dashboardBoarder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            // ✅ mniej „klejące” się do krawędzi
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: theme.themeColor, // ✅ zaznaczenie
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: theme.themeColor.withAlpha(50),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),

            // ✅ kolory tekstu
            labelColor: AppColors.white, // jeśli masz; jak nie -> theme.textColor
            unselectedLabelColor: theme.textColor.withAlpha(170),

            // ✅ typografia
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),

            // ✅ usuń linię/tabbar divider
            dividerColor: Colors.transparent,

            // ✅ trochę oddechu dla labeli
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),

            tabs: const [
              Tab(text: 'Nagrody katalogu'),
              Tab(text: 'Progi (skala)'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Treść zakładek
        Expanded(
          child: TabBarView(
            children: [
              _RewardsTab(baseUrl: baseUrl, programId: programId),
              _TiersTab(baseUrl: baseUrl, programId: programId),
            ],
          ),
        ),
      ],
    ),
  );
}


        return BarManager(
          sideMenuKey: sideMenuKey,
          appModule: AppModule.association,
          paddingPc: 10,
          paddingMobile: 4,
          childrenPc: [
            const SizedBox(height: 8),
            buildBalanceHeader(),
            Expanded(child: buildTabs()),
          ],
          childrenMobile: [
            buildBalanceHeader(),
            Expanded(child: buildTabs()),
          ],
        );
      },
    );
  }
}

/// ---------- Tab: Rewards ----------
class _RewardsTab extends ConsumerWidget {
  const _RewardsTab({required this.baseUrl, required this.programId});
  final String baseUrl;
  final int programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final itemsAsync =
        ref.watch(rewardItemsProvider((baseUrl: baseUrl, programId: programId)));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: itemsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: theme.textColor),
        ),
        error: (e, _) => Text(
          'Błąd pobierania nagród: $e',
          style: TextStyle(color: theme.textColor),
        ),
        data: (items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                border: Border.all(color: theme.dashboardBoarder),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.dashboardContainer,
                      side: BorderSide(color: theme.dashboardBoarder),
                    ),
                    onPressed: () async {
                      final updated = await showDialog<RewardItem?>(
                        context: context,
                        builder: (_) => _EditRewardDialog(
                          baseUrl: baseUrl,
                          initial: RewardItem(
                            id: 0,
                            program: programId,
                            code: '',
                            name: '',
                            costPoints: 0,
                            rewardType: 'voucher_percent',
                            payload: {},
                            isActive: true,
                          ),
                        ),
                      );
                      if (updated != null) {
                        ref.invalidate(
                          rewardItemsProvider((baseUrl: baseUrl, programId: programId)),
                        );
                      }
                    },
                    icon: Icon(Icons.add, color: theme.textColor),
                    label: Text('Dodaj nagrodę', style: TextStyle(color: theme.textColor)),
                  ),
                  const SizedBox(width: 12),
                  Text('Łącznie: ${items.length}', style: TextStyle(color: theme.textColor)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  border: Border.all(color: theme.dashboardBoarder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: theme.dashboardBoarder),
                  itemBuilder: (_, i) {
                    final r = items[i];
                    return ListTile(
                      iconColor: theme.textColor,
                      textColor: theme.textColor,
                      title: Text(
                        '${r.name}  ·  ${r.costPoints} pkt',
                        style: TextStyle(color: theme.textColor),
                      ),
                      subtitle: Text(
                        '${r.code}  •  ${r.rewardType}  •  ${r.isActive ? "aktywna" : "wyłączona"}',
                        style: TextStyle(color: theme.textColor.withAlpha(170)),
                      ),
                      onTap: () async {
                        final updated = await showDialog<RewardItem?>(
                          context: context,
                          builder: (_) =>
                              _EditRewardDialog(baseUrl: baseUrl, initial: r),
                        );
                        if (updated != null) {
                          ref.invalidate(
                            rewardItemsProvider((baseUrl: baseUrl, programId: programId)),
                          );
                        }
                      },
                      trailing: Icon(Icons.chevron_right, color: theme.textColor),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditRewardDialog extends ConsumerStatefulWidget {
  const _EditRewardDialog({required this.baseUrl, required this.initial});
  final String baseUrl;
  final RewardItem initial;

  @override
  ConsumerState<_EditRewardDialog> createState() => _EditRewardDialogState();
}

class _EditRewardDialogState extends ConsumerState<_EditRewardDialog> {
  late TextEditingController _code;
  late TextEditingController _name;
  late TextEditingController _cost;
  late TextEditingController _payload;
  String _type = 'voucher_percent';
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.initial.code);
    _name = TextEditingController(text: widget.initial.name);
    _cost = TextEditingController(text: widget.initial.costPoints.toString());
    _payload = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(widget.initial.payload),
    );
    _type = widget.initial.rewardType;
    _active = widget.initial.isActive;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _cost.dispose();
    _payload.dispose();
    super.dispose();
  }

  InputDecoration _dec(ThemeColors theme, String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textColor),
        floatingLabelStyle: TextStyle(color: theme.textColor),
        filled: true,
        fillColor: theme.dashboardContainer,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.dashboardBoarder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.dashboardBoarder, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final api = ref.read(rewardsApiProvider(widget.baseUrl));

    return AlertDialog(
      backgroundColor: theme.dashboardContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.dashboardBoarder),
      ),
      title: Text(
        widget.initial.id == 0
            ? 'Nowa nagroda'
            : 'Edytuj nagrodę #${widget.initial.id}',
        style: TextStyle(color: theme.textColor),
      ),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _code,
                      decoration: _dec(theme, 'Kod'),
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _name,
                      decoration: _dec(theme, 'Nazwa'),
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cost,
                      keyboardType: TextInputType.number,
                      decoration: _dec(theme, 'Koszt (pkt)'),
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      dropdownColor: theme.dashboardContainer,
                      style: TextStyle(color: theme.textColor),
                      items: [
                        DropdownMenuItem(
                          value: 'voucher_percent',
                          child: Text('Voucher %',
                              style: TextStyle(color: theme.textColor)),
                        ),
                        DropdownMenuItem(
                          value: 'voucher_fixed',
                          child: Text('Voucher kwotowy',
                              style: TextStyle(color: theme.textColor)),
                        ),
                        DropdownMenuItem(
                          value: 'perk',
                          child:
                              Text('Perk', style: TextStyle(color: theme.textColor)),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _type = v ?? 'voucher_percent'),
                      decoration: _dec(theme, 'Typ nagrody'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  border: Border.all(color: theme.dashboardBoarder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SwitchListTile(
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  title: Text('Aktywna', style: TextStyle(color: theme.textColor)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  activeColor: theme.textColor,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Payload (JSON)',
                  style: TextStyle(color: theme.textColor),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _payload,
                minLines: 6,
                maxLines: 10,
                decoration: _dec(theme, ''),
                style: TextStyle(color: theme.textColor, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.initial.id != 0)
          TextButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      await api.deleteReward(widget.initial.id);
                      if (!mounted) return;
                      Navigator.of(context).pop(widget.initial); // trigger refresh
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Usunięto nagrodę',
                              style: TextStyle(color: theme.textColor)),
                          backgroundColor: theme.dashboardContainer,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Błąd: $e',
                              style: TextStyle(color: theme.textColor)),
                          backgroundColor: theme.dashboardContainer,
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Usuń'),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: theme.textColor),
          child: const Text('Anuluj'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: theme.dashboardContainer,
            side: BorderSide(color: theme.dashboardBoarder),
          ),
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    Map<String, dynamic> p;
                    try {
                      p = _payload.text.trim().isEmpty
                          ? {}
                          : jsonDecode(_payload.text) as Map<String, dynamic>;
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Payload nie jest poprawnym JSON-em: $e',
                            style: TextStyle(color: theme.textColor),
                          ),
                          backgroundColor: theme.dashboardContainer,
                        ),
                      );
                      setState(() => _saving = false);
                      return;
                    }

                    final item = RewardItem(
                      id: widget.initial.id,
                      program: widget.initial.program,
                      code: _code.text.trim(),
                      name: _name.text.trim(),
                      costPoints: int.tryParse(_cost.text.trim()) ?? 0,
                      rewardType: _type,
                      payload: p,
                      isActive: _active,
                    );

                    RewardItem saved;
                    if (item.id == 0) {
                      saved = await api.createReward(item);
                    } else {
                      saved = await api.updateReward(item.id, item.toJson());
                    }

                    if (!mounted) return;
                    Navigator.of(context).pop(saved);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Zapisano nagrodę',
                            style: TextStyle(color: theme.textColor)),
                        backgroundColor: theme.dashboardContainer,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Błąd: $e',
                            style: TextStyle(color: theme.textColor)),
                        backgroundColor: theme.dashboardContainer,
                      ),
                    );
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          icon: _saving
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.textColor,
                  ),
                )
              : Icon(Icons.save, color: theme.textColor),
          label: Text('Zapisz', style: TextStyle(color: theme.textColor)),
        ),
      ],
    );
  }
}

/// ---------- Tab: Scale Tiers ----------
class _TiersTab extends ConsumerWidget {
  const _TiersTab({required this.baseUrl, required this.programId});
  final String baseUrl;
  final int programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final tiersAsync =
        ref.watch(scaleTiersProvider((baseUrl: baseUrl, programId: programId)));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical:16),
      child: tiersAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: theme.textColor),
        ),
        error: (e, _) => Text(
          'Błąd pobierania progów: $e',
          style: TextStyle(color: theme.textColor),
        ),
        data: (tiers) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.dashboardContainer,
                side: BorderSide(color: theme.dashboardBoarder),
              ),
              onPressed: () async {
                final saved = await showDialog<ScaleTier?>(
                  context: context,
                  builder: (_) => _EditTierDialog(
                    baseUrl: baseUrl,
                    initial: ScaleTier(
                      id: 0,
                      program: programId,
                      name: '',
                      threshold: 0,
                      order: (tiers.isNotEmpty ? tiers.last.order + 1 : 0),
                      benefits: {},
                    ),
                  ),
                );
                if (saved != null) {
                  ref.invalidate(
                    scaleTiersProvider((baseUrl: baseUrl, programId: programId)),
                  );
                }
              },
              icon: Icon(Icons.add, color: theme.textColor),
              label: Text('Dodaj próg', style: TextStyle(color: theme.textColor)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  border: Border.all(color: theme.dashboardBoarder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: true,
                  itemCount: tiers.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final moved = List<ScaleTier>.from(tiers);
                    final item = moved.removeAt(oldIndex);
                    moved.insert(newIndex, item);

                    // reassign "order" locally
                    for (var i = 0; i < moved.length; i++) {
                      if (moved[i].order != i) {
                        // PATCH each changed order
                        await ref
                            .read(rewardsApiProvider(baseUrl))
                            .updateTier(moved[i].id, {'order': i});
                      }
                    }
                    ref.invalidate(
                      scaleTiersProvider((baseUrl: baseUrl, programId: programId)),
                    );
                  },
                  itemBuilder: (_, i) {
                    final t = tiers[i];
                    return ListTile(
                      key: ValueKey('tier_${t.id}'),
                      textColor: theme.textColor,
                      iconColor: theme.textColor,
                      title: Text(
                        '${t.name}  ·  od ${t.threshold} pkt',
                        style: TextStyle(color: theme.textColor),
                      ),
                      subtitle: Text(
                        'order: ${t.order} • benefits: ${t.benefits.isEmpty ? "-" : t.benefits.keys.join(", ")}',
                        style: TextStyle(color: theme.textColor.withAlpha(170)),
                      ),
                      trailing: Icon(Icons.drag_handle, color: theme.textColor),
                      onTap: () async {
                        final saved = await showDialog<ScaleTier?>(
                          context: context,
                          builder: (_) =>
                              _EditTierDialog(baseUrl: baseUrl, initial: t),
                        );
                        if (saved != null) {
                          ref.invalidate(
                            scaleTiersProvider((baseUrl: baseUrl, programId: programId)),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditTierDialog extends ConsumerStatefulWidget {
  const _EditTierDialog({required this.baseUrl, required this.initial});
  final String baseUrl;
  final ScaleTier initial;

  @override
  ConsumerState<_EditTierDialog> createState() => _EditTierDialogState();
}

class _EditTierDialogState extends ConsumerState<_EditTierDialog> {
  late TextEditingController _name;
  late TextEditingController _threshold;
  late TextEditingController _order;
  late TextEditingController _benefits;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial.name);
    _threshold =
        TextEditingController(text: widget.initial.threshold.toString());
    _order = TextEditingController(text: widget.initial.order.toString());
    _benefits = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(widget.initial.benefits),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _threshold.dispose();
    _order.dispose();
    _benefits.dispose();
    super.dispose();
  }

  InputDecoration _dec(ThemeColors theme, String label) => InputDecoration(
        labelText: label.isEmpty ? null : label,
        labelStyle: TextStyle(color: theme.textColor),
        floatingLabelStyle: TextStyle(color: theme.textColor),
        filled: true,
        fillColor: theme.dashboardContainer,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.dashboardBoarder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.dashboardBoarder, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final api = ref.read(rewardsApiProvider(widget.baseUrl));
    final isNew = widget.initial.id == 0;

    return AlertDialog(
      backgroundColor: theme.dashboardContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.dashboardBoarder),
      ),
      title: Text(
        isNew ? 'Nowy próg' : 'Edytuj próg #${widget.initial.id}',
        style: TextStyle(color: theme.textColor),
      ),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _name,
                      decoration: _dec(theme, 'Nazwa progu'),
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _threshold,
                      keyboardType: TextInputType.number,
                      decoration: _dec(theme, 'Próg (pkt)'),
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _order,
                      keyboardType: TextInputType.number,
                      decoration: _dec(theme, 'Kolejność'),
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Benefits (JSON)',
                            style: TextStyle(color: theme.textColor)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _benefits,
                          minLines: 6,
                          maxLines: 10,
                          decoration: _dec(theme, ''),
                          style: TextStyle(
                            color: theme.textColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (!isNew)
          TextButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      await api.deleteTier(widget.initial.id);
                      if (!mounted) return;
                      Navigator.of(context).pop(widget.initial);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Usunięto próg',
                              style: TextStyle(color: theme.textColor)),
                          backgroundColor: theme.dashboardContainer,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Błąd: $e',
                              style: TextStyle(color: theme.textColor)),
                          backgroundColor: theme.dashboardContainer,
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Usuń'),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: theme.textColor),
          child: const Text('Anuluj'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: theme.dashboardContainer,
            side: BorderSide(color: theme.dashboardBoarder),
          ),
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    Map<String, dynamic> ben;
                    try {
                      ben = _benefits.text.trim().isEmpty
                          ? {}
                          : jsonDecode(_benefits.text) as Map<String, dynamic>;
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Benefits nie jest poprawnym JSON-em: $e',
                            style: TextStyle(color: theme.textColor),
                          ),
                          backgroundColor: theme.dashboardContainer,
                        ),
                      );
                      setState(() => _saving = false);
                      return;
                    }

                    final patch = {
                      'name': _name.text.trim(),
                      'threshold': int.tryParse(_threshold.text.trim()) ?? 0,
                      'order': int.tryParse(_order.text.trim()) ?? 0,
                      'benefits': ben,
                      'program': widget.initial.program,
                    };

                    final saved = widget.initial.id == 0
                        ? await api.createTier(
                            ScaleTier(
                              id: 0,
                              program: widget.initial.program,
                              name: patch['name'] as String,
                              threshold: patch['threshold'] as int,
                              order: patch['order'] as int,
                              benefits: ben,
                            ),
                          )
                        : await api.updateTier(widget.initial.id, patch);

                    if (!mounted) return;
                    Navigator.of(context).pop(saved);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Zapisano próg',
                            style: TextStyle(color: theme.textColor)),
                        backgroundColor: theme.dashboardContainer,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Błąd: $e',
                            style: TextStyle(color: theme.textColor)),
                        backgroundColor: theme.dashboardContainer,
                      ),
                    );
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          icon: _saving
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.textColor,
                  ),
                )
              : Icon(Icons.save, color: theme.textColor),
          label: Text('Zapisz', style: TextStyle(color: theme.textColor)),
        ),
      ],
    );
  }
}
