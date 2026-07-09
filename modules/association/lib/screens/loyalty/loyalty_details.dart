// lib/loyalty/loyalty_admin_screen.dart
// Flutter Web/Desktop + Riverpod
// Dynamic templates list -> dynamic form from config_schema -> dry-run -> create rule
// Uses CoreTextField for all text inputs.

import 'dart:convert';
import 'dart:typed_data';

import 'package:association/models/loyalyty/rewards.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/text_field.dart';

Map<String, dynamic> _ensureObject(dynamic data) {
  // 1) Already a map
  if (data is Map) return Map<String, dynamic>.from(data);

  // 2) Raw bytes -> string -> json
  if (data is Uint8List) {
    final s = utf8.decode(data);
    final v = jsonDecode(s);
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is List && v.isNotEmpty && v.first is Map) {
      return Map<String, dynamic>.from(v.first as Map);
    }
    throw Exception('Unexpected bytes JSON shape: ${v.runtimeType}');
  }

  // 3) JSON string
  if (data is String) {
    final v = jsonDecode(data);
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is List && v.isNotEmpty && v.first is Map) {
      return Map<String, dynamic>.from(v.first as Map);
    }
    throw Exception('Unexpected string JSON shape: ${v.runtimeType}');
  }

  // 4) Last attempt: normalize to Map
  final normalized = normalizeJson<dynamic>(data);
  if (normalized is Map) return Map<String, dynamic>.from(normalized);
  if (normalized is List && normalized.isNotEmpty && normalized.first is Map) {
    return Map<String, dynamic>.from(normalized.first as Map);
  }

  throw Exception('Unexpected balance payload shape: ${data.runtimeType} => $data');
}

/// -----------------------------
/// JSON normalizer (fix ImmutableMap/ImmutableList on Web)
/// -----------------------------
T normalizeJson<T>(dynamic value) {
  if (value is T) return value;
  // Convert anything (ImmutableMap/ImmutableList) to plain Dart structures
  final decoded = jsonDecode(jsonEncode(value));
  return decoded as T;
}

/// -----------------------------
/// Models
/// -----------------------------

class RuleTemplateModel {
  final String code;
  final String name;
  final String? description;
  final String eventType;
  final String rewardType;
  final String? icon;
  final Map<String, dynamic> configSchema;
  final Map<String, dynamic> limitsSchema;
  final List<dynamic> availableActions;

  RuleTemplateModel({
    required this.code,
    required this.name,
    required this.eventType,
    required this.rewardType,
    required this.configSchema,
    required this.limitsSchema,
    required this.availableActions,
    this.description,
    this.icon,
  });

  factory RuleTemplateModel.fromJson(Map<String, dynamic> j) => RuleTemplateModel(
        code: j['code'] as String,
        name: j['name'] as String,
        description: (j['description'] ?? '') as String?,
        eventType: j['event_type'] as String,
        rewardType: j['reward_type'] as String,
        icon: (j['icon'] ?? '') as String?,
        // Safe conversion for Web (ImmutableMap -> Map)
        configSchema: j['config_schema'] is Map
            ? Map<String, dynamic>.from(j['config_schema'] as Map)
            : normalizeJson<Map<String, dynamic>>(j['config_schema'] ?? {}),
        limitsSchema: j['limits_schema'] is Map
            ? Map<String, dynamic>.from(j['limits_schema'] as Map)
            : normalizeJson<Map<String, dynamic>>(j['limits_schema'] ?? {}),
        availableActions: j['available_actions'] is List
            ? List<dynamic>.from(j['available_actions'] as List)
            : normalizeJson<List<dynamic>>(j['available_actions'] ?? []),
      );
}

class RuleModel {
  final int id;
  final int program;
  final String name;
  final String eventType;
  final Map<String, dynamic> condition;
  final Map<String, dynamic> reward;
  final Map<String, dynamic> limits;
  final bool active;
  final int order;

  // NEW:
  final int? templateId;
  final Map<String, dynamic>? template;

  RuleModel({
    required this.id,
    required this.program,
    required this.name,
    required this.eventType,
    required this.condition,
    required this.reward,
    required this.limits,
    required this.active,
    required this.order,
    this.templateId,
    this.template,
  });

  factory RuleModel.fromJson(Map<String, dynamic> j) {
    final t = j['template'];
    int? tId;
    Map<String, dynamic>? tObj;
    if (t is int) {
      tId = t;
    } else if (t is Map) {
      tObj = Map<String, dynamic>.from(t);
      tId = (tObj['id'] is int) ? tObj['id'] as int : null;
    }

    return RuleModel(
      id: j['id'] as int,
      program: (j['program'] is int)
          ? j['program'] as int
          : (j['program']?['id'] ?? 0) as int,
      name: j['name'] as String,
      eventType: j['event_type'] as String,
      condition: j['condition'] is Map
          ? Map<String, dynamic>.from(j['condition'])
          : normalizeJson<Map<String, dynamic>>(j['condition'] ?? {}),
      reward: j['reward'] is Map
          ? Map<String, dynamic>.from(j['reward'])
          : normalizeJson<Map<String, dynamic>>(j['reward'] ?? {}),
      limits: j['limits'] is Map
          ? Map<String, dynamic>.from(j['limits'])
          : normalizeJson<Map<String, dynamic>>(j['limits'] ?? {}),
      active: j['active'] as bool? ?? true,
      order: j['order'] as int? ?? 0,
      templateId: tId,
      template: tObj,
    );
  }
}

/// -----------------------------
/// API
/// -----------------------------

class LoyaltyApi {
  LoyaltyApi(this.baseUrl, {required this.ref});
  final String baseUrl;
  final Ref ref;

  String _u(String p) => '$baseUrl$p';

  Future<List<RuleTemplateModel>> listTemplates() async {
    final res = await ApiServices.get(
      _u('/loyalty/templates/'),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Nie udało się pobrać szablonów: ${res?.statusCode}');
    }

    final root = normalizeJson<dynamic>(res.data);
    final List list = root is List
        ? root
        : (root is Map && root['results'] is List)
            ? root['results']
            : const [];

    return list.map((e) {
      final map =
          e is Map ? Map<String, dynamic>.from(e) : normalizeJson<Map<String, dynamic>>(e);
      return RuleTemplateModel.fromJson(map);
    }).toList();
  }

  Future<Map<String, dynamic>> dryRun({
    required String templateCode,
    required Map<String, dynamic> config,
    required Map<String, dynamic> payload,
  }) async {
    final res = await ApiServices.post(
      _u('/loyalty/dry-run/'),
      hasToken: true,
      ref: ref,
      data: {
        'template_code': templateCode,
        'config': config,
        'payload': payload,
      },
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Dry-run nie powiódł się: ${res?.statusCode} ${res?.data}');
    }
    return normalizeJson<Map<String, dynamic>>(res.data);
  }

  Future<RuleModel> createRuleFromTemplate({
    required String templateCode,
    required int programId,
    String? name,
    Map<String, dynamic>? config,
    Map<String, dynamic>? limits,
  }) async {
    final res = await ApiServices.post(
      _u('/loyalty/create-rule/'),
      hasToken: true,
      ref: ref,
      data: {
        'template_code': templateCode,
        'program_id': programId,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        'config': config ?? <String, dynamic>{},
        'limits': limits ?? <String, dynamic>{},
      },
    );
    if (res == null || res.statusCode != 201) {
      throw Exception(
          'Utworzenie reguły nie powiodło się: ${res?.statusCode} ${res?.data}');
    }
    final map = normalizeJson<Map<String, dynamic>>(res.data);
    return RuleModel.fromJson(map);
  }

  Future<List<RuleModel>> listRules({required int programId}) async {
    final res = await ApiServices.get(
      _u('/loyalty/rules/'),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
      queryParameters: {'program_id': programId},
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Nie udało się pobrać reguł: ${res?.statusCode}');
    }

    final data = res.data;
    List items;
    if (data is List) {
      items = data;
    } else if (data is Map && data['results'] is List) {
      items = data['results'] as List;
    } else if (data is Map) {
      items = [data];
    } else {
      throw Exception(
          'Nieoczekiwany format odpowiedzi: ${data.runtimeType} => $data');
    }

    return items.where((e) => e is Map).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return RuleModel.fromJson(m);
    }).toList();
  }

  Future<RuleModel> getRule(int id) async {
    final res = await ApiServices.get(
      _u('/loyalty/rules/$id/'),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Nie udało się pobrać reguły #$id: ${res?.statusCode}');
    }
    final map = normalizeJson<Map<String, dynamic>>(res.data);
    return RuleModel.fromJson(map);
  }

  Future<RuleModel> updateRule(
    int id, {
    String? name,
    bool? active,
    int? order,
    Map<String, dynamic>? condition,
    Map<String, dynamic>? reward,
    Map<String, dynamic>? limits,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (active != null) 'active': active,
      if (order != null) 'order': order,
      if (condition != null) 'condition': condition,
      if (reward != null) 'reward': reward,
      if (limits != null) 'limits': limits,
    };

    final res = await ApiServices.patch(
      _u('/loyalty/rules/$id/'),
      hasToken: true,
      ref: ref,
      data: body,
    );

    if (res == null || (res.statusCode != 200 && res.statusCode != 202)) {
      throw Exception('Nie udało się zaktualizować reguły: ${res?.statusCode} ${res?.data}');
    }

    final map = normalizeJson<Map<String, dynamic>>(res.data);
    return RuleModel.fromJson(map);
  }

  Future<void> deleteRule(int id) async {
    final res = await ApiServices.delete(
      _u('/loyalty/rules/$id/'),
      hasToken: true,
    );
    if (res == null || res.statusCode != 204) {
      throw Exception('Nie udało się usunąć reguły: ${res?.statusCode} ${res?.data}');
    }
  }

  // list rewards
  Future<List<RewardItem>> listRewards({
    required int programId,
    bool includeInactive = false,
  }) async {
    final res = await ApiServices.get(
      _u('/loyalty/rewards/'),
      hasToken: true,
      ref: ref,
      queryParameters: {'program': programId},
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Rewards fetch failed');
    }
    final data = res.data;
    final List arr = data is List
        ? data
        : (data is Map && data['results'] is List)
            ? data['results']
            : [];
    return arr
        .whereType<Map>()
        .map((e) => RewardItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // create/update/delete rewards (admin)
  Future<RewardItem> createReward(Map<String, dynamic> payload) async {
    final res = await ApiServices.post(
      _u('/loyalty/rewards/'),
      hasToken: true,
      ref: ref,
      data: payload,
    );
    if (res == null || res.statusCode != 201) {
      throw Exception('Create reward failed');
    }
    return RewardItem.fromJson(normalizeJson<Map<String, dynamic>>(res.data));
  }

  Future<RewardItem> updateReward(
      int id, Map<String, dynamic> patch) async {
    final res = await ApiServices.patch(
      _u('/loyalty/rewards/$id/'),
      hasToken: true,
      ref: ref,
      data: patch,
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Update reward failed');
    }
    return RewardItem.fromJson(normalizeJson<Map<String, dynamic>>(res.data));
  }

  Future<void> deleteReward(int id) async {
    final res = await ApiServices.delete(
      _u('/loyalty/rewards/$id/'),
      hasToken: true,
    );
    if (res == null || res.statusCode != 204) {
      throw Exception('Delete reward failed');
    }
  }

  // tiers
  Future<List<Tier>> listTiers({required int programId}) async {
    final res = await ApiServices.get(
      _u('/loyalty/tiers/'),
      hasToken: true,
      ref: ref,
      queryParameters: {'program': programId},
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Tiers fetch failed');
    }
    final data = res.data;
    final List arr = data is List
        ? data
        : (data is Map && data['results'] is List)
            ? data['results']
            : [];
    return arr
        .whereType<Map>()
        .map((e) => Tier.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // balance + progress
  Future<BalanceProgress> getBalance({required int programId}) async {
    final res = await ApiServices.get(
      _u('/loyalty/balance/'),
      hasToken: true,
      ref: ref,
      queryParameters: {'program': programId},
      responseType: ResponseType.json,
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Balance fetch failed: ${res?.statusCode}');
    }
    final obj = _ensureObject(res.data);
    return BalanceProgress.fromJson(obj);
  }

  // redeem
  Future<Map<String, dynamic>> redeem({
    required int programId,
    required String itemCode,
    int? userId,
  }) async {
    final res = await ApiServices.post(
      _u('/loyalty/redeem/'),
      hasToken: true,
      ref: ref,
      data: {
        'program_id': programId,
        'item_code': itemCode,
        if (userId != null) 'user_id': userId,
      },
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Redeem failed: ${res?.statusCode} ${res?.data}');
    }
    return normalizeJson<Map<String, dynamic>>(res.data);
  }
}

/// -----------------------------
/// Providers
/// -----------------------------

final loyaltyApiProvider =
    Provider.family<LoyaltyApi, String>((ref, baseUrl) {
  return LoyaltyApi(baseUrl, ref: ref);
});

final loyaltyTemplatesProvider =
    FutureProvider.family<List<RuleTemplateModel>, String>(
        (ref, baseUrl) async {
  final api = ref.read(loyaltyApiProvider(baseUrl));
  return api.listTemplates();
});

final loyaltyRulesProvider = FutureProvider.family<
    List<RuleModel>, ({String baseUrl, int programId})>((ref, args) async {
  final api = ref.read(loyaltyApiProvider(args.baseUrl));
  return api.listRules(programId: args.programId);
});

class DryRunState {
  final bool loading;
  final String? error;
  final Map<String, dynamic>? result;
  const DryRunState({this.loading = false, this.error, this.result});

  DryRunState copyWith({
    bool? loading,
    String? error,
    Map<String, dynamic>? result,
  }) =>
      DryRunState(
        loading: loading ?? this.loading,
        error: error,
        result: result ?? this.result,
      );
}

class DryRunNotifier extends StateNotifier<DryRunState> {
  DryRunNotifier(this._api) : super(const DryRunState());
  final LoyaltyApi _api;

  Future<void> run({
    required String templateCode,
    required Map<String, dynamic> config,
    required Map<String, dynamic> payload,
  }) async {
    state = state.copyWith(loading: true, error: null, result: null);
    try {
      final r =
          await _api.dryRun(templateCode: templateCode, config: config, payload: payload);
      state = state.copyWith(loading: false, result: r);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void clear() => state = const DryRunState();
}

final dryRunProvider = StateNotifierProvider.family<DryRunNotifier,
    DryRunState, String>((ref, baseUrl) {
  final api = ref.read(loyaltyApiProvider(baseUrl));
  return DryRunNotifier(api);
});

class CreateRuleState {
  final bool loading;
  final String? error;
  final RuleModel? created;
  const CreateRuleState({this.loading = false, this.error, this.created});

  CreateRuleState copyWith({
    bool? loading,
    String? error,
    RuleModel? created,
  }) =>
      CreateRuleState(
        loading: loading ?? this.loading,
        error: error,
        created: created ?? this.created,
      );
}

class CreateRuleNotifier extends StateNotifier<CreateRuleState> {
  CreateRuleNotifier(this._api) : super(const CreateRuleState());
  final LoyaltyApi _api;

  Future<RuleModel> create({
    required String templateCode,
    required int programId,
    String? name,
    Map<String, dynamic>? config,
    Map<String, dynamic>? limits,
  }) async {
    state = state.copyWith(loading: true, error: null, created: null);
    try {
      final r = await _api.createRuleFromTemplate(
        templateCode: templateCode,
        programId: programId,
        name: name,
        config: config,
        limits: limits,
      );
      state = state.copyWith(loading: false, created: r);
      return r;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      rethrow;
    }
  }
}

final createRuleProvider =
    StateNotifierProvider.family<CreateRuleNotifier, CreateRuleState, String>(
        (ref, baseUrl) {
  final api = ref.read(loyaltyApiProvider(baseUrl));
  return CreateRuleNotifier(api);
});

/// -----------------------------
/// UI
/// -----------------------------

class LoyaltyAdminScreen extends ConsumerStatefulWidget {
  const LoyaltyAdminScreen({
    super.key,
    this.baseUrl = 'https://www.superbee.cloud',
    required this.programId,
  });

  final String baseUrl;
  final int programId;

  @override
  ConsumerState<LoyaltyAdminScreen> createState() =>
      _LoyaltyAdminScreenState();
}

class _LoyaltyAdminScreenState extends ConsumerState<LoyaltyAdminScreen> {
  RuleTemplateModel? selected;
  final _nameCtrl = TextEditingController();
  final Map<String, TextEditingController> _configCtrls = {};
  final Map<String, dynamic> _configValues = {};
  final Map<String, dynamic> _limitsValues = {};
  final _payloadCtrl = TextEditingController(
    text: const JsonEncoder.withIndent('  ').convert({
      "user_id": 1,
      "amount": 100,
      "currency": "PLN",
      "paid_at": "2025-11-07T12:00:00Z",
      "due_date": "2025-11-08T12:00:00Z",
    }),
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final c in _configCtrls.values) {
      c.dispose();
    }
    _payloadCtrl.dispose();
    super.dispose();
  }

  void _openEditRuleDialog(RuleModel rule) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditRuleDialog(
        baseUrl: widget.baseUrl,
        rule: rule,
        onSaved: (updated) {
          ref.invalidate(
            loyaltyRulesProvider(
              (baseUrl: widget.baseUrl, programId: widget.programId),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(loyaltyTemplatesProvider(widget.baseUrl));
    final rulesAsync = ref.watch(
      loyaltyRulesProvider(
        (baseUrl: widget.baseUrl, programId: widget.programId),
      ),
    );
    final dry = ref.watch(dryRunProvider(widget.baseUrl));
    final creator = ref.watch(createRuleProvider(widget.baseUrl));
    final theme = ref.read(themeColorsProvider);

    final sideMenuKey = GlobalKey<SideMenuState>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        Widget buildTemplatesPanel() {
          return Container(
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              border: Border.all(color: theme.dashboardBoarder),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: templatesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    _ErrorBox(msg: 'Błąd pobierania szablonów: $e'),
                data: (tpls) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Szablony',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: tpls.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final t = tpls[i];
                          final sel = selected?.code == t.code;
                          return ListTile(
                            title: Text(
                              t.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: theme.textColor)
                            ),
                            subtitle: Text(
                              t.description ?? t.eventType,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: theme.textColor.withAlpha(120))
                            ),
                            trailing: sel
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : null,
                            onTap: () {
                              setState(() {
                                selected = t;
                                _nameCtrl.text = t.name;
                                _initConfigControllers(t);
                                _initLimitsDefaults(t);
                              });
                              ref
                                  .read(dryRunProvider(widget.baseUrl).notifier)
                                  .clear();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        Widget buildConfigPanel() {
          return Container(
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              border: Border.all(color: theme.dashboardBoarder),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: selected == null
                  ?  Center(
                      child: Text(
                        'Wybierz szablon po lewej, aby skonfigurować regułę.',
                              style: TextStyle(color: theme.textColor)
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konfiguracja',
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CoreTextField(
                          label: 'Nazwa reguły (opcjonalnie)',
                          hintText: 'Domyślnie: nazwa szablonu',
                          controller: _nameCtrl,
                        ),
                        const SizedBox(height: 12),
                        _DynamicConfigForm(
                          schema: selected!.configSchema,
                          ctrls: _configCtrls,
                          onChanged: (key, value) =>
                              _configValues[key] = value,
                        ),
                        const SizedBox(height: 12),
                        ExpansionTile(
                          title: Text('Limity (opcjonalne)', 
                              style: TextStyle(color: theme.textColor)),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          children: [
                            _DynamicLimitsForm(
                              limitsSchema: selected!.limitsSchema,
                              values: _limitsValues,
                              onChanged: (k, v) => _limitsValues[k] = v,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Payload do Dry-run (JSON)',
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _JsonField(controller: _payloadCtrl),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: dry.loading
                                  ? null
                                  : () {
                                      Map<String, dynamic> payload;
                                      try {
                                        payload =
                                            jsonDecode(_payloadCtrl.text
                                                        .trim()
                                                        .isEmpty
                                                    ? '{}'
                                                    : _payloadCtrl.text)
                                                as Map<String, dynamic>;
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Niepoprawny JSON payload: $e', 
                              style: TextStyle(color: theme.textColor)),
                                          ),
                                        );
                                        return;
                                      }
                                      ref
                                          .read(
                                            dryRunProvider(widget.baseUrl)
                                                .notifier,
                                          )
                                          .run(
                                            templateCode: selected!.code,
                                            config: _configValues,
                                            payload: payload,
                                          );
                                    },
                              icon: dry.loading
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(Icons.play_arrow,
                                      color: theme.textColor),
                              label: Text(
                                'Dry-run',
                                style:
                                    TextStyle(color: theme.textColor),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (dry.error != null)
                              Expanded(
                                child: Text(
                                  'Błąd: ${dry.error}',
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: creator.loading
                                  ? null
                                  : () async {
                                      try {
                                        final rule = await ref
                                            .read(
                                              createRuleProvider(
                                                      widget.baseUrl)
                                                  .notifier,
                                            )
                                            .create(
                                              templateCode: selected!.code,
                                              programId: widget.programId,
                                              name: _nameCtrl.text
                                                      .trim()
                                                      .isEmpty
                                                  ? null
                                                  : _nameCtrl.text.trim(),
                                              config: _configValues,
                                              limits: _limitsValues,
                                            );
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Utworzono regułę #${rule.id}'),
                                          ),
                                        );
                                        ref.invalidate(
                                          loyaltyRulesProvider(
                                            (
                                              baseUrl: widget.baseUrl,
                                              programId:
                                                  widget.programId,
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Błąd tworzenia reguły: $e'),
                                          ),
                                        );
                                      }
                                    },
                              icon: creator.loading
                                  ? SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: theme.textColor,
                                      ),
                                    )
                                  :  Icon(Icons.check, color: theme.textColor),
                              label:  Text('Zapisz regułę', 
                              style: TextStyle(color: theme.textColor)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _DryRunResultBox(result: dry.result, theme: theme),
                      ],
                    ),
            ),
          );
        }

        Widget buildRulesPanel() {
          return Container(
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              border: Border.all(color: theme.dashboardBoarder),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: rulesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    _ErrorBox(msg: 'Błąd pobierania reguł: $e',),
                data: (rules) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reguły w programie',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: rules.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final r = rules[i];
                          return ListTile(
                            onTap: () => _openEditRuleDialog(r),
                            title: Text(
                              r.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: theme.textColor)
                            ),
                            subtitle: Text(r.eventType, 
                              style: TextStyle(color: theme.textColor.withAlpha(120))),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(r.active ? 'Aktywna' : 'Wyłączona'),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: r.active
                                      ? Colors.green
                                          .withAlpha(26)
                                      : theme.dashboardContainer,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '#${r.order}',
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }


        return BarManager(
          sideMenuKey: sideMenuKey,
          appModule: AppModule.association,
          paddingPc: 10,
          paddingMobile: 4,
          spacing: 5,
          childrenPc: [
            const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 5),
                  Text(
                    'Program lojalnościowy — Reguły',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 360, child: buildTemplatesPanel()),
                    const SizedBox(width: 16),
                    Expanded(child: buildConfigPanel()),
                    const SizedBox(width: 16),
                    SizedBox(width: 420, child: buildRulesPanel()),
                  ],
                ),
              ),
          ],
          childrenMobile: [
            const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Program lojalnościowy — Reguły',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(4),
                  children: [
                    SizedBox(
                      height: 260,
                      child: buildTemplatesPanel(),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 420,
                      child: buildConfigPanel(),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 280,
                      child: buildRulesPanel(),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  void _initConfigControllers(RuleTemplateModel t) {
    _configCtrls.clear();
    _configValues.clear();

    final props = t.configSchema['properties'] is Map
        ? Map<String, dynamic>.from(t.configSchema['properties'])
        : const <String, dynamic>{};

    final defs = t.configSchema['defaults'] is Map
        ? Map<String, dynamic>.from(t.configSchema['defaults'])
        : const <String, dynamic>{};

    props.forEach((key, defRaw) {
      final def = defRaw is Map ? Map<String, dynamic>.from(defRaw) : <String, dynamic>{};
      final type = (def['type'] ?? 'string') as String;
      final init = defs.containsKey(key) ? defs[key] : def['default'];
      _configValues[key] = init;
      if (type == 'string' || type == 'integer' || type == 'number') {
        _configCtrls[key] =
            TextEditingController(text: init?.toString() ?? '');
      }
    });
  }

  void _initLimitsDefaults(RuleTemplateModel t) {
    _limitsValues.clear();
    final defaults = t.limitsSchema['defaults'] is Map
        ? Map<String, dynamic>.from(t.limitsSchema['defaults'])
        : const <String, dynamic>{};
    _limitsValues.addAll(defaults);
  }
}

/// Dynamic form for config_schema
class _DynamicConfigForm extends StatefulWidget {
  const _DynamicConfigForm({
    required this.schema,
    required this.ctrls,
    required this.onChanged,
  });

  final Map<String, dynamic> schema;
  final Map<String, TextEditingController> ctrls;
  final void Function(String key, dynamic value) onChanged;

  @override
  State<_DynamicConfigForm> createState() => _DynamicConfigFormState();
}

class _DynamicConfigFormState extends State<_DynamicConfigForm> {
  @override
  Widget build(BuildContext context) {
    final props = widget.schema['properties'] is Map
        ? Map<String, dynamic>.from(widget.schema['properties'])
        : const <String, dynamic>{};

    if (props.isEmpty) {
      return const Text('Brak dodatkowych pól konfiguracyjnych.');
    }

    return Column(
      children: props.entries.map((e) {
        final key = e.key;
        final spec =
            e.value is Map ? Map<String, dynamic>.from(e.value) : <String, dynamic>{};
        final type = (spec['type'] ?? 'string') as String;
        final title = (spec['title'] ?? key) as String;
        final hint = (spec['description'] ?? '') as String;

        switch (type) {
          case 'boolean':
            final def = spec['default'] as bool? ?? false;
            return _BoolField(
              label: title,
              value: (widget.ctrls[key]?.text ?? '').isEmpty
                  ? def
                  : (widget.ctrls[key]!.text == 'true'),
              onChanged: (v) {
                widget.ctrls[key] ??= TextEditingController();
                widget.ctrls[key]!.text = v.toString();
                widget.onChanged(key, v);
                setState(() {});
              },
            );

        case 'integer':
        case 'number':
          return _TextFieldRow(
            controller: widget.ctrls[key] ??= TextEditingController(
              text: spec['default']?.toString() ?? '',
            ),
            label: title,
            hint: hint,
            keyboardTypeNumber: true,
            onChanged: (v) {
              final parsed = num.tryParse(v);
              widget.onChanged(key, parsed ?? v);
            },
          );


          case 'enum':
          case 'select':
            final items = (spec['enum'] ?? const []) as List;
            final labels = (spec['enumNames'] ?? const []) as List;
            final def = (spec['default'] ??
                    (items.isNotEmpty ? items.first : null))
                ?.toString();
            final current =
                (widget.ctrls[key]?.text ?? def ?? '').toString();
            return _DropdownRow(
              label: title,
              value: current.isEmpty ? null : current,
              items:
                  List<String>.from(items.map((e) => e.toString())),
              itemLabels: labels.isNotEmpty
                  ? List<String>.from(
                      labels.map((e) => e.toString()),
                    )
                  : null,
              onChanged: (val) {
                widget.ctrls[key] ??= TextEditingController();
                widget.ctrls[key]!.text = val ?? '';
                widget.onChanged(key, val);
                setState(() {});
              },
            );

case 'string':
default:
  return _TextFieldRow(
    controller: widget.ctrls[key] ??= TextEditingController(
      text: spec['default']?.toString() ?? '',
    ),
    label: title,
    hint: hint,
    onChanged: (v) => widget.onChanged(key, v),
  );

        }
      }).toList(),
    );
  }
}

/// Limits lightweight editor
class _DynamicLimitsForm extends StatefulWidget {
  const _DynamicLimitsForm({
    required this.limitsSchema,
    required this.values,
    required this.onChanged,
  });

  final Map<String, dynamic> limitsSchema;
  final Map<String, dynamic> values;
  final void Function(String key, dynamic value) onChanged;

  @override
  State<_DynamicLimitsForm> createState() => _DynamicLimitsFormState();
}

class _DynamicLimitsFormState extends State<_DynamicLimitsForm> {
  final Map<String, TextEditingController> _lCtrls = {};

  @override
  void initState() {
    super.initState();
    for (final e in widget.values.entries) {
      _lCtrls[e.key] =
          TextEditingController(text: e.value?.toString() ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final props = widget.limitsSchema['properties'] is Map
        ? Map<String, dynamic>.from(widget.limitsSchema['properties'])
        : const <String, dynamic>{};
    final keys =
        props.isEmpty ? widget.values.keys.toList() : props.keys.toList();

    if (keys.isEmpty) {
      return const Text(
          'Brak domyślnych limitów. Możesz dodać własne klucze w backendzie.');
    }

    return Column(
      children: keys.map((k) {
        final spec =
            props[k] is Map ? Map<String, dynamic>.from(props[k]) : <String, dynamic>{};
        final title = (spec['title'] ?? k) as String;
        final desc = (spec['description'] ?? '') as String;
        final isBool = (spec['type'] == 'boolean');

        if (isBool) {
          final v = (widget.values[k] is bool)
              ? widget.values[k] as bool
              : (spec['default'] as bool? ?? false);
          return _BoolField(
            label: title,
            value: v,
            helper: desc.isEmpty ? null : desc,
            onChanged: (nv) {
              widget.onChanged(k, nv);
              setState(() => widget.values[k] = nv);
            },
          );
        }

        _lCtrls[k] ??= TextEditingController(
          text: widget.values[k]?.toString() ??
              (spec['default']?.toString() ?? ''),
        );
        return _TextFieldRow(
          controller: _lCtrls[k]!,
          label: title,
          hint: desc,
          onChanged: (v) {
            final n = num.tryParse(v);
            widget.onChanged(k, n ?? v);
            widget.values[k] = n ?? v;
          },
        );
      }).toList(),
    );
  }
}

/// Simple JSON multiline input
class _JsonField extends StatelessWidget {
  const _JsonField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return CoreTextField(
      label: 'JSON',
      hintText: '{ "user_id": 1, "amount": 100, ... }',
      controller: controller,
      minLines: 6,
      maxLines: 12,
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.msg});
  final String msg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(15),
        border: Border.all(color: Colors.red.withAlpha(51)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ],
      ),
    );
  }
}

class _DryRunResultBox extends StatelessWidget {
  const _DryRunResultBox({this.result, required this.theme});
  final Map<String, dynamic>? result;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    if (result == null) return const SizedBox.shrink();
    final pretty = const JsonEncoder.withIndent('  ').convert(result);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: SelectableText(
        pretty,
        style: TextStyle(fontFamily: 'monospace', color: theme.textColor),
      ),
    );
  }
}

/// Reusable field rows

class _TextFieldRow extends StatelessWidget {
  const _TextFieldRow({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardTypeNumber = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool keyboardTypeNumber;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CoreTextField(
        label: label,
        hintText: hint,
        controller: controller,
        keyboardType:
            keyboardTypeNumber ? TextInputType.number : TextInputType.text,
        onChanged: onChanged,
      ),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.itemLabels,
  });

  final String label;
  final List<String> items;
  final List<String>? itemLabels;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = itemLabels ?? items;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        items: [
          for (var i = 0; i < items.length; i++)
            DropdownMenuItem(value: items[i], child: Text(labels[i])),
        ],
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _BoolField extends StatelessWidget {
  const _BoolField({
    required this.label,
    required this.value,
    this.onChanged,
    this.helper,
  });
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label),
      subtitle: helper == null
          ? null
          : Text(helper!, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _EditRuleDialog extends ConsumerStatefulWidget {
  const _EditRuleDialog({
    required this.baseUrl,
    required this.rule,
    required this.onSaved,
  });

  final String baseUrl;
  final RuleModel rule;
  final void Function(RuleModel? updated) onSaved; // null => deleted

  @override
  ConsumerState<_EditRuleDialog> createState() => _EditRuleDialogState();
}

class _EditRuleDialogState extends ConsumerState<_EditRuleDialog> {
  late TextEditingController _name;
  late TextEditingController _order;
  late TextEditingController _condition;
  late TextEditingController _reward;
  late TextEditingController _limits;
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.rule.name);
    _order = TextEditingController(text: widget.rule.order.toString());
    _condition = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(widget.rule.condition),
    );
    _reward = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(widget.rule.reward),
    );
    _limits = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(widget.rule.limits),
    );
    _active = widget.rule.active;
  }

  @override
  void dispose() {
    _name.dispose();
    _order.dispose();
    _condition.dispose();
    _reward.dispose();
    _limits.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      Map<String, dynamic> cond, rew, lim;
      try {
        cond = (_condition.text.trim().isEmpty)
            ? {}
            : (jsonDecode(_condition.text)
                as Map<String, dynamic>);
        rew = (_reward.text.trim().isEmpty)
            ? {}
            : (jsonDecode(_reward.text)
                as Map<String, dynamic>);
        lim = (_limits.text.trim().isEmpty)
            ? {}
            : (jsonDecode(_limits.text)
                as Map<String, dynamic>);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Niepoprawny JSON: $e')),
        );
        setState(() => _saving = false);
        return;
      }

      final orderNum = int.tryParse(_order.text.trim());
      final api = ref.read(loyaltyApiProvider(widget.baseUrl));

      final updated = await api.updateRule(
        widget.rule.id,
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        active: _active,
        order: orderNum,
        condition: cond,
        reward: rew,
        limits: lim,
      );

      if (!mounted) return;
      widget.onSaved(updated);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zapisano regułę')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd zapisu: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _saving = true);
    try {
      final api = ref.read(loyaltyApiProvider(widget.baseUrl));
      await api.deleteRule(widget.rule.id);
      if (!mounted) return;
      widget.onSaved(null);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usunięto regułę')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd usuwania: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    return AlertDialog(
      backgroundColor: theme.dashboardContainer,
      title: Text('Edytuj regułę #${widget.rule.id}', 
                              style: TextStyle(color: theme.textColor)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
        child: SizedBox(
          width: 820,
          height: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                CoreTextField(
                  label: 'Nazwa',
                  controller: _name,
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CoreTextField(
                        label: 'Kolejność',
                        controller: _order,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SwitchListTile(
                        value: _active,
                        onChanged: (v) => setState(() => _active = v),
                        title:  Text('Aktywna', 
                              style: TextStyle(color: theme.textColor)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Condition (JSON)',
                    style: TextStyle(color: theme.textColor)
                  ),
                ),
                _JsonField(controller: _condition),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Reward (JSON)',
                    style: TextStyle(color: theme.textColor)
                  ),
                ),
                _JsonField(controller: _reward),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Limits (JSON)',
                    style: TextStyle(color: theme.textColor)
                  ),
                ),
                _JsonField(controller: _limits),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child:  Text('Anuluj',style: TextStyle(color: theme.textColor)),
        ),
        TextButton(
          onPressed: _saving ? null : _delete,
          style: elevatedButtonStyleRounded10,
          child: Text('Usuń', style: TextStyle(color: theme.textColor)),
        ),
        FilledButton.icon(
          style: buttonStyleRounded10ThemeRedWithPadding15,
          onPressed: _saving ? null : _save,
          icon: _saving
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: theme.textColor),
                )
              :  Icon(Icons.save, color: theme.textColor),
          label:  Text('Zapisz', style: TextStyle(color: theme.textColor)),
        ),
      ],
    );
  }
}
