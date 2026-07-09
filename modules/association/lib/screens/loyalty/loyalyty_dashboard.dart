// lib/loyalty/loyalty_program_dashboard_screen.dart
import 'dart:convert';
import 'package:association/screens/loyalty/loyalty_details.dart';
import 'package:association/screens/loyalty/loyalty_rewards.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';

T normalizeJson<T>(dynamic v) {
  if (v is T) return v;
  final d = jsonDecode(jsonEncode(v));
  return d as T;
}

class ProgramDashboardData {
  final Map<String, dynamic> metrics;
  final List<dynamic> topMembers;
  final List<dynamic> topRewards;
  final List<dynamic> recentTransactions;
  final List<dynamic> recentRedemptions;

  ProgramDashboardData({
    required this.metrics,
    required this.topMembers,
    required this.topRewards,
    required this.recentTransactions,
    required this.recentRedemptions,
  });

  factory ProgramDashboardData.fromJson(Map<String, dynamic> j) => ProgramDashboardData(
    metrics: Map<String,dynamic>.from(j['metrics'] ?? {}),
    topMembers: List<dynamic>.from(j['top_members'] ?? []),
    topRewards: List<dynamic>.from(j['top_rewards'] ?? []),
    recentTransactions: List<dynamic>.from(j['recent_transactions'] ?? []),
    recentRedemptions: List<dynamic>.from(j['recent_redemptions'] ?? []),
  );
}

class DashboardApi {
  DashboardApi(this.baseUrl, {required this.ref});
  final String baseUrl;
  final Ref ref;

  String _u(String p) => '$baseUrl$p';

  Future<ProgramDashboardData> getDashboard({required int programId, int days = 30}) async {
    final res = await ApiServices.get(
      _u('/loyalty/dashboard/'),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
      queryParameters: {'program': programId, 'days': days},
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Dashboard fetch failed: ${res?.statusCode} ${res?.data}');
    }
    final obj = normalizeJson<Map<String, dynamic>>(res.data);
    return ProgramDashboardData.fromJson(obj);
  }
}

final dashboardApiProvider = Provider.family<DashboardApi, String>((ref, baseUrl) {
  return DashboardApi(baseUrl, ref: ref);
});

final programDashboardProvider = FutureProvider.family<ProgramDashboardData, ({String baseUrl, int programId, int days})>((ref, args) async {
  final api = ref.read(dashboardApiProvider(args.baseUrl));
  return api.getDashboard(programId: args.programId, days: args.days);
});

class LoyaltyProgramDashboardScreen extends ConsumerStatefulWidget {
  const LoyaltyProgramDashboardScreen({
    super.key,
    this.baseUrl = 'https://www.superbee.cloud',
    required this.programId,
  });
  final String baseUrl;
  final int programId;

  @override
  ConsumerState<LoyaltyProgramDashboardScreen> createState() => _LoyaltyProgramDashboardScreenState();
}


class _LoyaltyProgramDashboardScreenState extends ConsumerState<LoyaltyProgramDashboardScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final sideMenuKey = GlobalKey<SideMenuState>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        final dataAsync = ref.watch(
          programDashboardProvider((
            baseUrl: widget.baseUrl,
            programId: widget.programId,
            days: _days,
          )),
        );

        // ====== HEADER WSPÓLNY (lekko inny na mobile) ======
        Widget buildHeader() {
          if (isMobile) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Program lojalnościowy — Podsumowanie',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // wybór zakresu dni
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: theme.dashboardContainer,
                          border: Border.all(color: theme.dashboardBoarder),
                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _days,
                            items: [
                              DropdownMenuItem(
                                value: 7,
                                child: Text('7 dni', style: TextStyle(color: theme.textColor)),
                              ),
                              DropdownMenuItem(
                                value: 30,
                                child: Text('30 dni', style: TextStyle(color: theme.textColor)),
                              ),
                              DropdownMenuItem(
                                value: 90,
                                child: Text('90 dni', style: TextStyle(color: theme.textColor)),
                              ),
                            ],
                            onChanged: (v) => setState(() => _days = v ?? 30),
                          ),
                        ),
                      ),

                      // Edycja reguł
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.dashboardContainer,
                            foregroundColor: theme.textColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: theme.dashboardBoarder),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LoyaltyAdminScreen(
                                  programId: widget.programId,
                                  baseUrl: widget.baseUrl,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.rule, color: theme.textColor),
                              const SizedBox(width: 5),
                              Text('Edytuj reguły', style: TextStyle(color: theme.textColor)),
                            ],
                          ),
                        ),
                      ),

                      // Edycja nagród
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.dashboardContainer,
                            foregroundColor: theme.textColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: theme.dashboardBoarder),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LoyaltyRewardsScreen(
                                  programId: widget.programId,
                                  baseUrl: widget.baseUrl,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.card_giftcard, color: theme.textColor),
                              const SizedBox(width: 5),
                              Text('Edytuj nagrody', style: TextStyle(color: theme.textColor)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          // DESKTOP HEADER
          return Row(
            children: [
              Text(
                'Program lojalnościowy — Podsumowanie',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // zakres dni
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  border: Border.all(color: theme.dashboardBoarder),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _days,
                      items: [
                        DropdownMenuItem(
                          value: 7,
                          child: Text('7 dni', style: TextStyle(color: theme.textColor)),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Text('30 dni', style: TextStyle(color: theme.textColor)),
                        ),
                        DropdownMenuItem(
                          value: 90,
                          child: Text('90 dni', style: TextStyle(color: theme.textColor)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _days = v ?? 30),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // przycisk: reguły
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  border: Border.all(color: theme.dashboardBoarder),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LoyaltyAdminScreen(
                          programId: widget.programId,
                          baseUrl: widget.baseUrl,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    spacing: 5,
                    children: [
                      Icon(Icons.rule, color: theme.textColor),
                      Text('Edytuj reguły', style: TextStyle(color: theme.textColor)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // przycisk: nagrody
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  border: Border.all(color: theme.dashboardBoarder),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LoyaltyRewardsScreen(
                          programId: widget.programId,
                          baseUrl: widget.baseUrl,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    spacing: 5,
                    children: [
                      Icon(Icons.card_giftcard, color: theme.textColor),
                      Text('Edytuj nagrody', style: TextStyle(color: theme.textColor)),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return BarManager(
          sideMenuKey: sideMenuKey,
          appModule: AppModule.association,
          
          childrenPc: [
             buildHeader(),
              const SizedBox(height: 8),
              Expanded(
                child: dataAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Błąd: $e')),
                  data: (d) {
                    final m = d.metrics;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _MetricCard(
                              theme: theme,
                              title: 'Członkowie',
                              value: '${m['total_members'] ?? 0}',
                              subtitle: 'aktywni: ${m['active_members'] ?? 0}',
                            ),
                            _MetricCard(
                              theme: theme,
                              title: 'Suma punktów',
                              value: '${m['total_points'] ?? 0}',
                            ),
                            _MetricCard(
                              theme: theme,
                              title: 'Zdobyte (okres)',
                              value: '${m['earned_30d'] ?? 0}',
                            ),
                            _MetricCard(
                              theme: theme,
                              title: 'Wydane (okres)',
                              value: '${m['redeemed_30d'] ?? 0}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _Box(
                                  theme: theme,
                                  title: 'Top użytkownicy (punkty)',
                                  child: _SimpleTable(
                                    theme: theme,
                                    columns: const ['User ID', 'Punkty', 'Tier'],
                                    rows: d.topMembers
                                        .map((x) => [
                                              '${x['user_id']}',
                                              '${x['points']}',
                                              '${x['tier']}'
                                            ])
                                        .toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _Box(
                                  theme: theme,
                                  title: 'Najczęściej wykorzystywane nagrody',
                                  child: _SimpleTable(
                                    theme: theme,
                                    columns: const ['Kod', 'Nazwa', 'Użycia'],
                                    rows: d.topRewards
                                        .map((x) => [
                                              '${x['code'] ?? '-'}',
                                              '${x['name'] ?? '-'}',
                                              '${x['uses'] ?? 0}'
                                            ])
                                        .toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _Box(
                                  theme: theme,
                                  title: 'Ostatnie transakcje (punkty)',
                                  child: _SimpleTable(
                                    theme: theme,
                                    columns: const ['User ID', 'Δ', 'Powód', 'Data'],
                                    rows: d.recentTransactions
                                        .map((t) => [
                                              '${t['user_id']}',
                                              '${t['delta']}',
                                              '${t['reason']}',
                                              '${t['created_at']}'
                                            ])
                                        .toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _Box(
                                  theme: theme,
                                  title: 'Ostatnie vouchery',
                                  child: _SimpleTable(
                                    theme: theme,
                                    columns: const ['Kod', 'User ID', 'Payload', 'Zrealizowany', 'Data'],
                                    rows: d.recentRedemptions
                                        .map((v) => [
                                              '${v['code']}',
                                              '${v['user_id'] ?? '-'}',
                                              jsonEncode(v['payload'] ?? {}),
                                              '${v['is_redeemed'] == true ? "tak" : "nie"}',
                                              '${v['created_at']}',
                                            ])
                                        .toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
          childrenMobile: [
             buildHeader(),
              Expanded(
                child: dataAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Błąd: $e')),
                  data: (d) {
                    final m = d.metrics;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      children: [
                        // metryki
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _MetricCard(
                              theme: theme,
                              title: 'Członkowie',
                              value: '${m['total_members'] ?? 0}',
                              subtitle: 'aktywni: ${m['active_members'] ?? 0}',
                            ),
                            _MetricCard(
                              theme: theme,
                              title: 'Suma punktów',
                              value: '${m['total_points'] ?? 0}',
                            ),
                            _MetricCard(
                              theme: theme,
                              title: 'Zdobyte (okres)',
                              value: '${m['earned_30d'] ?? 0}',
                            ),
                            _MetricCard(
                              theme: theme,
                              title: 'Wydane (okres)',
                              value: '${m['redeemed_30d'] ?? 0}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Top members
                        SizedBox(
                          height: 260,
                          child: _Box(
                            theme: theme,
                            title: 'Top użytkownicy (punkty)',
                            child: _SimpleTable(
                              theme: theme,
                              columns: const ['User ID', 'Punkty', 'Tier'],
                              rows: d.topMembers
                                  .map((x) => [
                                        '${x['user_id']}',
                                        '${x['points']}',
                                        '${x['tier']}'
                                      ])
                                  .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Top rewards
                        SizedBox(
                          height: 260,
                          child: _Box(
                            theme: theme,
                            title: 'Najczęściej wykorzystywane nagrody',
                            child: _SimpleTable(
                              theme: theme,
                              columns: const ['Kod', 'Nazwa', 'Użycia'],
                              rows: d.topRewards
                                  .map((x) => [
                                        '${x['code'] ?? '-'}',
                                        '${x['name'] ?? '-'}',
                                        '${x['uses'] ?? 0}'
                                      ])
                                  .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Recent transactions
                        SizedBox(
                          height: 260,
                          child: _Box(
                            theme: theme,
                            title: 'Ostatnie transakcje (punkty)',
                            child: _SimpleTable(
                              theme: theme,
                              columns: const ['User ID', 'Δ', 'Powód', 'Data'],
                              rows: d.recentTransactions
                                  .map((t) => [
                                        '${t['user_id']}',
                                        '${t['delta']}',
                                        '${t['reason']}',
                                        '${t['created_at']}'
                                      ])
                                  .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Recent vouchers
                        SizedBox(
                          height: 260,
                          child: _Box(
                            theme: theme,
                            title: 'Ostatnie vouchery',
                            child: _SimpleTable(
                              theme: theme,
                              columns: const ['Kod', 'User ID', 'Payload', 'Zrealizowany', 'Data'],
                              rows: d.recentRedemptions
                                  .map((v) => [
                                        '${v['code']}',
                                        '${v['user_id'] ?? '-'}',
                                        jsonEncode(v['payload'] ?? {}),
                                        '${v['is_redeemed'] == true ? "tak" : "nie"}',
                                        '${v['created_at']}',
                                      ])
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}


class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, this.subtitle, required this.theme});
  final String title;
  final String value;
  final String? subtitle;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {

    return Container(      
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              border: Border.all(
                color: theme.dashboardBoarder
              ),
              borderRadius: BorderRadius.all(Radius.circular(10))
            ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 220,
          height: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: theme.textColor, fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(color: theme.textColor, fontSize: 26, fontWeight: FontWeight.w700)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: TextStyle(color: theme.textColor, fontSize: 10)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.title, required this.child, required this.theme,});
  final String title;
  final Widget child;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    
    return Container(      
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              border: Border.all(
                color: theme.dashboardBoarder
              ),
              borderRadius: BorderRadius.all(Radius.circular(10))
            ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _SimpleTable extends StatelessWidget {
  const _SimpleTable({required this.columns, required this.theme, required this.rows});
  final List<String> columns;
  final ThemeColors theme;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: DataTable(
        columns: [for (final c in columns) DataColumn(label: Text(c, style: TextStyle(color: theme.textColor.withAlpha(120))))],
        rows: [
          for (final r in rows)
            DataRow(cells: [for (final cell in r) DataCell(SelectableText(cell, style: TextStyle(color: theme.textColor)))]),
        ],
      ),
    );
  }
}
