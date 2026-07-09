// lib/loyalty/loyalty_programs_screen.dart
// Flutter Web/Desktop + Riverpod
// Lists Loyalty Programs + create & edit dialogs
// UI in Polish, comments in English.

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/text_field.dart';

/// -----------------------------
/// Model
/// -----------------------------
class LoyaltyProgramModel {
  final int id;
  final int association; // required by backend
  final String name;
  final bool isActive;
  final String currency;

  LoyaltyProgramModel({
    required this.id,
    required this.association,
    required this.name,
    required this.isActive,
    required this.currency,
  });

  factory LoyaltyProgramModel.fromJson(Map<String, dynamic> j) =>
      LoyaltyProgramModel(
        id: j['id'] as int,
        association: (j['association'] is int)
            ? j['association'] as int
            : (j['association']?['id'] ?? 0) as int,
        name: j['name'] as String? ?? '',
        isActive: j['is_active'] as bool? ?? true,
        currency: j['currency'] as String? ?? 'POINTS',
      );

  Map<String, dynamic> toPatchBody() => {
        'association': association,
        'name': name,
        'is_active': isActive,
        'currency': currency,
      };
}

/// -----------------------------
/// API
/// -----------------------------
class LoyaltyProgramsApi {
  LoyaltyProgramsApi(this.baseUrl, {required this.ref});
  final String baseUrl;
  final Ref ref;

  String _u(String p) => '$baseUrl$p';

  Future<List<LoyaltyProgramModel>> list({int? associationId}) async {
    final res = await ApiServices.get(
      _u('/loyalty/programs/'),
      hasToken: true,
      ref: ref,
      responseType: ResponseType.json,
      queryParameters:
          associationId != null ? {'association': associationId} : null,
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Nie udało się pobrać programów: ${res?.statusCode}');
    }
    final data = res.data;
    final List raw = data is List
        ? data
        : (data is Map && data['results'] is List)
            ? data['results']
            : [];
    return raw
        .map((e) =>
            LoyaltyProgramModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<LoyaltyProgramModel> create({
    required int associationId,
    required String name,
    required String currency,
    bool isActive = true,
  }) async {
    final res = await ApiServices.post(
      _u('/loyalty/programs/'),
      hasToken: true,
      ref: ref,
      data: {
        'association': associationId,
        'name': name,
        'currency': currency,
        'is_active': isActive,
      },
    );
    if (res == null || res.statusCode != 201) {
      throw Exception(
        'Utworzenie programu nie powiodło się: ${res?.statusCode} ${res?.data}',
      );
    }
    return LoyaltyProgramModel.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<LoyaltyProgramModel> update({
    required int id,
    required Map<String, dynamic> patchBody,
  }) async {
    final res = await ApiServices.patch(
      _u('/loyalty/programs/$id/'),
      hasToken: true,
      ref: ref,
      data: patchBody,
    );
    if (res == null || res.statusCode != 200) {
      throw Exception(
        'Aktualizacja programu nie powiodła się: ${res?.statusCode} ${res?.data}',
      );
    }
    return LoyaltyProgramModel.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<void> delete(int id) async {
    final res = await ApiServices.delete(
      _u('/loyalty/programs/$id/'),
      hasToken: true,
    );
    if (res == null || (res.statusCode != 204 && res.statusCode != 200)) {
      throw Exception('Usunięcie nie powiodło się: ${res?.statusCode} ${res?.data}');
    }
  }
}

/// -----------------------------
/// Providers
/// -----------------------------
final loyaltyProgramsApiProvider =
    Provider.family<LoyaltyProgramsApi, String>((ref, baseUrl) {
  return LoyaltyProgramsApi(baseUrl, ref: ref);
});

final loyaltyProgramsProvider = FutureProvider.family<
    List<LoyaltyProgramModel>,
    ({String baseUrl, int? associationId})>((ref, args) async {
  final api = ref.read(loyaltyProgramsApiProvider(args.baseUrl));
  return api.list(associationId: args.associationId);
});

class CreateProgramState {
  final bool loading;
  final String? error;
  final LoyaltyProgramModel? created;
  const CreateProgramState({this.loading = false, this.error, this.created});
  CreateProgramState copyWith({
    bool? loading,
    String? error,
    LoyaltyProgramModel? created,
  }) =>
      CreateProgramState(
        loading: loading ?? this.loading,
        error: error,
        created: created ?? this.created,
      );
}

class CreateProgramNotifier extends StateNotifier<CreateProgramState> {
  CreateProgramNotifier(this._api) : super(const CreateProgramState());
  final LoyaltyProgramsApi _api;

  Future<LoyaltyProgramModel> create({
    required int associationId,
    required String name,
    required String currency,
    required bool isActive,
  }) async {
    state = state.copyWith(loading: true, error: null, created: null);
    try {
      final r = await _api.create(
        associationId: associationId,
        name: name,
        currency: currency,
        isActive: isActive,
      );
      state = state.copyWith(loading: false, created: r);
      return r;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      rethrow;
    }
  }
}

final createProgramProvider = StateNotifierProvider.family<
    CreateProgramNotifier, CreateProgramState, String>((ref, baseUrl) {
  final api = ref.read(loyaltyProgramsApiProvider(baseUrl));
  return CreateProgramNotifier(api);
});

class UpdateProgramState {
  final bool loading;
  final String? error;
  final LoyaltyProgramModel? updated;
  const UpdateProgramState({this.loading = false, this.error, this.updated});
  UpdateProgramState copyWith({
    bool? loading,
    String? error,
    LoyaltyProgramModel? updated,
  }) =>
      UpdateProgramState(
        loading: loading ?? this.loading,
        error: error,
        updated: updated ?? this.updated,
      );
}

class UpdateProgramNotifier extends StateNotifier<UpdateProgramState> {
  UpdateProgramNotifier(this._api) : super(const UpdateProgramState());
  final LoyaltyProgramsApi _api;

  Future<LoyaltyProgramModel> update({
    required int id,
    required Map<String, dynamic> patchBody,
  }) async {
    state = state.copyWith(loading: true, error: null, updated: null);
    try {
      final r = await _api.update(id: id, patchBody: patchBody);
      state = state.copyWith(loading: false, updated: r);
      return r;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      rethrow;
    }
  }
}

final updateProgramProvider = StateNotifierProvider.family<
    UpdateProgramNotifier, UpdateProgramState, String>((ref, baseUrl) {
  final api = ref.read(loyaltyProgramsApiProvider(baseUrl));
  return UpdateProgramNotifier(api);
});

final deleteProgramProvider =
    FutureProvider.family<void, ({String baseUrl, int id})>((ref, args) async {
  final api = ref.read(loyaltyProgramsApiProvider(args.baseUrl));
  await api.delete(args.id);
});

/// -----------------------------
/// UI Screen
/// -----------------------------
class LoyaltyProgramsScreen extends ConsumerWidget {
  const LoyaltyProgramsScreen({
    super.key,
    this.baseUrl = 'https://www.superbee.cloud',
    this.associationId,
  });

  final String baseUrl;
  final int? associationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final nav = ref.read(navigationService);
    final currentPath = nav.currentPath;

    final sideMenuKey = GlobalKey<SideMenuState>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        final async = ref.watch(
          loyaltyProgramsProvider((baseUrl: baseUrl, associationId: associationId)),
        );

        Future<void> _openCreateDialog() async {
          final created = await showDialog<LoyaltyProgramModel>(
            context: context,
            builder: (_) => _ProgramDialog(
              baseUrl: baseUrl,
              associationId: associationId,
            ),
          );
          if (created != null) {
            ref.invalidate(
              loyaltyProgramsProvider((baseUrl: baseUrl, associationId: associationId)),
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Utworzono program „${created.name}”',
                    style: TextStyle(color: theme.textColor),
                  ),
                  backgroundColor: theme.dashboardContainer,
                ),
              );
            }
          }
        }

        // ---------- HEADER ----------
        Widget buildHeader() {
          if (isMobile) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Programy lojalnościowe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: elevatedButtonStyleRounded10,
                      onPressed: _openCreateDialog,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: theme.textColor),
                          const SizedBox(width: 6),
                          Text(
                            'Nowy program',
                            style: TextStyle(color: theme.textColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // DESKTOP
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  border: Border.all(color: theme.dashboardBoarder),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: ElevatedButton(
                  style: elevatedButtonStyleRounded10,
                  onPressed: _openCreateDialog,
                  child: Row(
                    children: [
                      Icon(Icons.add, color: theme.textColor),
                      const SizedBox(width: 6),
                      Text(
                        'Nowy program',
                        style: TextStyle(color: theme.textColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // ---------- LIST CONTENT ----------
        Widget buildListContent() {
          return async.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: theme.textColor),
            ),
            error: (e, _) => Center(
              child: Text(
                'Błąd pobierania: $e',
                style: TextStyle(color: theme.textColor),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return _EmptyState(onCreate: _openCreateDialog);
              }

              return ListView.separated(
                padding: isMobile
                    ? const EdgeInsets.fromLTRB(12, 4, 12, 12)
                    : EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = items[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: theme.dashboardContainer,
                      border: Border.all(color: theme.dashboardBoarder),
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    child: ElevatedButton(
                      style: elevatedButtonStyleRounded10withoutPadding,
                      onPressed: () {},
                      child: ListTile(
                        onTap: () => nav.pushNamedScreen('$currentPath/${p.id}/dashboard'),
                        leading: CircleAvatar(
                          backgroundColor: theme.dashboardContainer,
                          child: Text(
                            p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                        title: Text(
                          p.name,
                          style: TextStyle(color: theme.textColor),
                        ),
                        subtitle: Text(
                          'Stowarzyszenie: ${p.association} • Waluta: ${p.currency}',
                          style: TextStyle(color: theme.textColor.withAlpha(170)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: theme.dashboardContainer,
                                border: Border.all(color: theme.dashboardBoarder),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Text(
                                p.isActive ? 'Aktywny' : 'Wyłączony',
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Edytuj',
                              icon: Icon(Icons.edit_outlined, color: theme.textColor),
                              onPressed: () async {
                                final updated = await showDialog<LoyaltyProgramModel>(
                                  context: context,
                                  builder: (_) => _ProgramDialog(
                                    baseUrl: baseUrl,
                                    existing: p,
                                    associationId: p.association,
                                  ),
                                );
                                if (updated != null) {
                                  ref.invalidate(
                                    loyaltyProgramsProvider(
                                      (baseUrl: baseUrl, associationId: associationId),
                                    ),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Zaktualizowano program „${updated.name}”',
                                          style: TextStyle(color: theme.textColor),
                                        ),
                                        backgroundColor: theme.dashboardContainer,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Otwórz',
                              icon: Icon(Icons.open_in_new, color: theme.textColor),
                              onPressed: () => nav.pushNamedScreen('$currentPath/${p.id}'),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Rewards',
                              icon: Icon(Icons.card_giftcard, color: theme.textColor),
                              onPressed: () => nav.pushNamedScreen('$currentPath/${p.id}/rewards'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        }

        return BarManager(
          sideMenuKey: sideMenuKey,
          appModule: AppModule.association,
          childrenPc: [
            const SizedBox(height: 10),
            buildHeader(),
            const SizedBox(height: 10),
            Expanded(child: buildListContent()),
          ],
          childrenMobile: [
            buildHeader(),
            Expanded(child: buildListContent()),
          ],
        );
      },
    );
  }
}

/// -----------------------------
/// Dialog: Create/Edit Program
/// -----------------------------
class _ProgramDialog extends ConsumerStatefulWidget {
  const _ProgramDialog({
    required this.baseUrl,
    this.existing,
    this.associationId,
  });

  final String baseUrl;
  final LoyaltyProgramModel? existing;
  final int? associationId;

  @override
  ConsumerState<_ProgramDialog> createState() => _ProgramDialogState();
}

class _ProgramDialogState extends ConsumerState<_ProgramDialog> {
  late final TextEditingController _name;
  late final TextEditingController _association;
  String _currency = 'POINTS';
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _association = TextEditingController(
      text: (widget.existing?.association ?? widget.associationId ?? '').toString(),
    );
    _currency = widget.existing?.currency ?? 'POINTS';
    _active = widget.existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _association.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final theme = ref.read(themeColorsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dashboardBoarder),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(isEdit ? Icons.edit_outlined : Icons.add, color: theme.textColor),
                  const SizedBox(width: 8),
                  Text(
                    isEdit ? 'Edytuj program' : 'Nowy program',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // CoreTextField from your theme lib:
              // We still wrap with container theme, but CoreTextField has its own styling.
              CoreTextField(
                label: 'Nazwa programu',
                controller: _name,
              ),
              const SizedBox(height: 10),

              CoreTextField(
                label: 'ID stowarzyszenia',
                controller: _association,
                keyboardType: TextInputType.number,
                hintText: 'np. 8',
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _currency,
                dropdownColor: theme.dashboardContainer,
                decoration: InputDecoration(
                  labelText: 'Waluta punktowa',
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                style: TextStyle(color: theme.textColor),
                items: [
                  DropdownMenuItem(
                    value: 'POINTS',
                    child: Text('POINTS (punkty)', style: TextStyle(color: theme.textColor)),
                  ),
                  DropdownMenuItem(
                    value: 'MILES',
                    child: Text('MILES', style: TextStyle(color: theme.textColor)),
                  ),
                  DropdownMenuItem(
                    value: 'TOKENS',
                    child: Text('TOKENS', style: TextStyle(color: theme.textColor)),
                  ),
                ],
                onChanged: (v) => setState(() => _currency = v ?? 'POINTS'),
              ),
              const SizedBox(height: 6),

              Container(
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  border: Border.all(color: theme.dashboardBoarder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SwitchListTile(
                  title: Text('Aktywny', style: TextStyle(color: theme.textColor)),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  activeColor: theme.textColor,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.dashboardBoarder),
                      foregroundColor: theme.textColor,
                    ),
                    child: Text('Anuluj', style: TextStyle(color: theme.textColor)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: Icon(Icons.check, color: theme.textColor),
                    label: Text(isEdit ? 'Zapisz' : 'Utwórz', style: TextStyle(color: theme.textColor)),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.dashboardContainer,
                      side: BorderSide(color: theme.dashboardBoarder),
                    ),
                    onPressed: () async {
                      final assocId = int.tryParse(_association.text.trim());
                      if (assocId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Podaj poprawne ID stowarzyszenia',
                              style: TextStyle(color: theme.textColor),
                            ),
                            backgroundColor: theme.dashboardContainer,
                          ),
                        );
                        return;
                      }
                      final name = _name.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Nazwa nie może być pusta',
                              style: TextStyle(color: theme.textColor),
                            ),
                            backgroundColor: theme.dashboardContainer,
                          ),
                        );
                        return;
                      }

                      try {
                        if (isEdit) {
                          final body = {
                            'association': assocId,
                            'name': name,
                            'currency': _currency,
                            'is_active': _active,
                          };
                          final updated = await ref
                              .read(updateProgramProvider(widget.baseUrl).notifier)
                              .update(
                                id: widget.existing!.id,
                                patchBody: body,
                              );
                          if (context.mounted) Navigator.pop(context, updated);
                        } else {
                          final created = await ref
                              .read(createProgramProvider(widget.baseUrl).notifier)
                              .create(
                                associationId: assocId,
                                name: name,
                                currency: _currency,
                                isActive: _active,
                              );
                          if (context.mounted) Navigator.pop(context, created);
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Błąd: $e', style: TextStyle(color: theme.textColor)),
                            backgroundColor: theme.dashboardContainer,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// -----------------------------
/// Empty state
/// -----------------------------
class _EmptyState extends ConsumerWidget {
  const _EmptyState({this.onCreate});
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          border: Border.all(color: theme.dashboardBoarder),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard, size: 64, color: theme.textColor),
            const SizedBox(height: 8),
            Text(
              'Nie masz jeszcze żadnych programów lojalnościowych.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Utwórz pierwszy program, aby skonfigurować reguły i nagrody.',
              style: TextStyle(color: theme.textColor.withAlpha(170)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCreate,
              icon: Icon(Icons.add, color: theme.textColor),
              label: Text('Utwórz program', style: TextStyle(color: theme.textColor)),
              style: FilledButton.styleFrom(
                backgroundColor: theme.dashboardContainer,
                side: BorderSide(color: theme.dashboardBoarder),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
