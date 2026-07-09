import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/text_field.dart';

/// ==============================
/// API PATHS — adjust as needed
/// ==============================
class _ApiPaths {
  static const _base = 'https://www.superbee.cloud';
  static const list = '$_base/association/applications/';                     // GET (with filters)
  static String detail(String id) => '$_base/association/applications/$id/';  // GET
  static String review(String id) => '$_base/association/applications/$id/review/'; // POST
}

/// ==============================
/// MODELS
/// ==============================
class MembershipApplicationModel {
  final String id;
  final int associationId;
  final int applicant;                 // auth user id
  final String applicantUsername;
  final String applicantType;          // "person" | "company"
  final String info;
  final String status;                 // pending|review|accepted|rejected
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final int? reviewedBy;
  final String reviewNotes;
  final String companyName;            // label for member
  final int? representedCompany;       // company id (optional)
  final String representedPosition;    // optional
  final List<MemberDocumentModel> documents;

  MembershipApplicationModel({
    required this.id,
    required this.associationId,
    required this.applicant,
    required this.applicantUsername,
    required this.applicantType,
    required this.info,
    required this.status,
    required this.submittedAt,
    required this.reviewedAt,
    required this.reviewedBy,
    required this.reviewNotes,
    required this.companyName,
    required this.representedCompany,
    required this.representedPosition,
    required this.documents,
  });

  factory MembershipApplicationModel.fromJson(Map<String, dynamic> j) {
    DateTime? _dt(s) => s == null ? null : DateTime.tryParse('$s');
    final docs = (j['documents'] as List? ?? [])
        .map((e) => MemberDocumentModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return MembershipApplicationModel(
      id: '${j["id"]}',
      associationId: (j['association'] as num).toInt(),
      applicant: (j['applicant'] as num).toInt(),
      applicantUsername: j['applicant_username'] ?? '',
      applicantType: j['applicant_type'] ?? 'person',
      info: j['info'] ?? '',
      status: j['status'] ?? 'pending',
      submittedAt: DateTime.parse('${j["submitted_at"]}'),
      reviewedAt: _dt(j['reviewed_at']),
      reviewedBy: j['reviewed_by'] as int?,
      reviewNotes: j['review_notes'] ?? '',
      companyName: j['company_name'] ?? '',
      representedCompany: j['represented_company'] as int?,
      representedPosition: j['represented_position'] ?? '',
      documents: docs,
    );
  }
}

class MemberDocumentModel {
  final String id;
  final String fileUrl;
  final DateTime uploadedAt;
  final String description;
  MemberDocumentModel({
    required this.id,
    required this.fileUrl,
    required this.uploadedAt,
    required this.description,
  });
  factory MemberDocumentModel.fromJson(Map<String, dynamic> j) => MemberDocumentModel(
        id: '${j["id"]}',
        fileUrl: j['file_url'] ?? '',
        uploadedAt: DateTime.parse('${j["uploaded_at"]}'),
        description: j['description'] ?? '',
      );
}

/// ==============================
/// API LAYER (uses ApiServices)
/// ==============================
class MembershipApplicationsApi {
  const MembershipApplicationsApi(this.ref);
  final Ref ref;

  // List with filters & pagination
  Future<List<MembershipApplicationModel>> list({
    int? associationId,
    String? status,            // pending|review|accepted|rejected
    String? q,                 // free text in "info" or applicant_username (server can extend)
    String? applicantType,     // person|company
    int page = 1,
    int pageSize = 20,
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (associationId != null) qp['association_id'] = associationId;
    if (status != null && status.isNotEmpty) qp['status'] = status;
    if (q != null && q.isNotEmpty) qp['q'] = q;
    if (applicantType != null && applicantType.isNotEmpty) qp['applicant_type'] = applicantType;

    final res = await ApiServices.get(
      _ApiPaths.list,
      hasToken: true,
      queryParameters: qp,
      responseType: ResponseType.json,
      ref: ref,
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Failed to fetch applications (${res?.statusCode})');
    }

    // Accept both plain list or DRF paginated {results:[], count:..}
    final data = res.data;
    List list;
    if (data is Map && data['results'] is List) {
      list = data['results'];
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }
    return list
        .map((e) => MembershipApplicationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<MembershipApplicationModel> detail(String id) async {
    final res = await ApiServices.get(
      _ApiPaths.detail(id),
      hasToken: true,
      responseType: ResponseType.json,
      ref: ref,
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Failed to fetch detail (${res?.statusCode})');
    }
    return MembershipApplicationModel.fromJson(Map<String, dynamic>.from(res.data));
  }

  // Approve/Reject with notes
  Future<Map<String, dynamic>> review({
    required String id,
    required String decision, // "accepted" | "rejected"
    String notes = '',
  }) async {
    final res = await ApiServices.post(
      _ApiPaths.review(id),
      hasToken: true,
      data: {'decision': decision, 'notes': notes},
      ref: ref,
    );
    if (res == null || res.statusCode != 200) {
      throw Exception('Review failed (${res?.statusCode})');
    }
    return Map<String, dynamic>.from(res.data as Map);
  }
}

final membershipApplicationsApiProvider =
    Provider<MembershipApplicationsApi>((ref) => MembershipApplicationsApi(ref));

/// ==============================
/// STATE
/// ==============================
class ApplicationsFilter {
  final int? associationId;
  final String status;        // '', pending, review, accepted, rejected
  final String q;
  final String applicantType; // '', person, company
  final int page;
  final int pageSize;

  const ApplicationsFilter({
    this.associationId,
    this.status = '',
    this.q = '',
    this.applicantType = '',
    this.page = 1,
    this.pageSize = 20,
  });

  ApplicationsFilter copyWith({
    int? associationId,
    String? status,
    String? q,
    String? applicantType,
    int? page,
    int? pageSize,
  }) =>
      ApplicationsFilter(
        associationId: associationId ?? this.associationId,
        status: status ?? this.status,
        q: q ?? this.q,
        applicantType: applicantType ?? this.applicantType,
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
      );
}

final applicationsFilterProvider =
    StateProvider<ApplicationsFilter>((_) => const ApplicationsFilter());

final applicationsProvider =
    FutureProvider.autoDispose<List<MembershipApplicationModel>>((ref) async {
  final api = ref.read(membershipApplicationsApiProvider);
  final f = ref.watch(applicationsFilterProvider);
  return api.list(
    associationId: f.associationId,
    status: f.status.isEmpty ? null : f.status,
    q: f.q.isEmpty ? null : f.q,
    applicantType: f.applicantType.isEmpty ? null : f.applicantType,
    page: f.page,
    pageSize: f.pageSize,
  );
});

// Currently selected application id for the right-side detail
final selectedApplicationIdProvider = StateProvider<String?>((_) => null);

final applicationDetailProvider =
    FutureProvider.autoDispose.family<MembershipApplicationModel, String>((ref, id) async {
  final api = ref.read(membershipApplicationsApiProvider);
  return api.detail(id);
});

/// ==============================
/// PAGE (Master–Detail)
/// ==============================
class MembershipApplicationsPage extends ConsumerWidget {
  const MembershipApplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(applicationsProvider);
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {

        return BarManager(
          sideMenuKey: sideMenuKey,
          appModule: AppModule.association,
          layoutTypePc: LayoutTypePc.row,

          // ---------- DESKTOP / PC ----------
          childrenPc: [
            // Left: list with filters
            SizedBox(
              width: 520,
              child: Column(
                children: [
                  _FiltersBar(theme),
                  const Divider(height: 1),
                  Expanded(
                    child: async.when(
                      data: (items) => _ApplicationsList(items: items, theme: theme),
                      error: (e, st) => _CenteredMsg('Błąd: $e', theme),
                      loading: () => const _CenteredLoader(),
                    ),
                  ),
                  const _PaginationBar(),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            // Right: detail
             Expanded(child: _DetailPane(theme)),
          ],

          // ---------- MOBILE ----------
          childrenMobile: [
            const SizedBox(height: 8),
            // Filtry u góry
             _FiltersBar(theme),
            const Divider(height: 1),
            Expanded(
              child: Column(
                children: [
                  // Lista aplikacji
                  Expanded(
                    child: async.when(
                      data: (items) => _ApplicationsList(items: items, theme: theme),
                      error: (e, st) => _CenteredMsg('Błąd: $e', theme),
                      loading: () => const _CenteredLoader(),
                    ),
                  ),
                  const Divider(height: 1),
                  // Szczegóły w dolnym panelu
                  SizedBox(
                    height: 260, // możesz podbić / zmniejszyć wg uznania
                    child:  _DetailPane(theme),
                  ),
                ],
              ),
            ),
            const _PaginationBar(),
          ],
        );
      },
    );
  }
}


/// ==============================
/// FILTERS
/// ==============================
class _FiltersBar extends ConsumerStatefulWidget {
  const _FiltersBar(this.theme);
  final ThemeColors theme;

  @override
  ConsumerState<_FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends ConsumerState<_FiltersBar> {
  late final TextEditingController _q =
      TextEditingController(text: ref.read(applicationsFilterProvider).q);
  late final TextEditingController _assocC = TextEditingController(
      text: (ref.read(applicationsFilterProvider).associationId ?? '').toString());

  String _status = '';
  String _type = '';

  @override
  void initState() {
    super.initState();
    final f = ref.read(applicationsFilterProvider);
    _status = f.status;
    _type = f.applicantType;
  }

  void _apply() {
    final assocIdText = _assocC.text.trim();
    int? assocId = int.tryParse(assocIdText.isEmpty ? '' : assocIdText);
    ref.read(applicationsFilterProvider.notifier).state =
        ref.read(applicationsFilterProvider).copyWith(
              associationId: assocId,
              status: _status,
              q: _q.text.trim(),
              applicantType: _type,
              page: 1,
            );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        children: [
          SizedBox(
          width: 130,
          child: CoreTextField(
            label: 'Association ID',
            controller: _assocC,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _apply(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 200,
          child: CoreTextField(
            label: 'Szukaj (info / user)',
            controller: _q,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _apply(),
          ),
        ),
          DropdownButton<String>(
            value: _status.isEmpty ? null : _status,
            dropdownColor: theme.dashboardContainer,
            hint: Text('Status', style: TextStyle(color: theme.textColor)),
            items:  [
              DropdownMenuItem(value: 'pending', child: Text('Pending', style: TextStyle(color: theme.textColor))),
              DropdownMenuItem(value: 'review', child: Text('In review', style: TextStyle(color: theme.textColor))),
              DropdownMenuItem(value: 'accepted', child: Text('Accepted', style: TextStyle(color: theme.textColor))),
              DropdownMenuItem(value: 'rejected', child: Text('Rejected', style: TextStyle(color: theme.textColor))),
            ],
            onChanged: (v) {
              setState(() => _status = v ?? '');
              _apply();
            },
          ),
          DropdownButton<String>(
            value: _type.isEmpty ? null : _type,
            dropdownColor: theme.dashboardContainer,
            hint:  Text('Typ zgłoszenia', style: TextStyle(color: theme.textColor)),
            items:  [
              DropdownMenuItem(value: 'person', child: Text('Person', style: TextStyle(color: theme.textColor))),
              DropdownMenuItem(value: 'company', child: Text('Company', style: TextStyle(color: theme.textColor))),
            ],
            onChanged: (v) {
              setState(() => _type = v ?? '');
              _apply();
            },
          ),
          TextButton(
            onPressed: () {
              _assocC.clear();
              _q.clear();
              setState(() {
                _status = '';
                _type = '';
              });
              ref.read(applicationsFilterProvider.notifier).state =
                  const ApplicationsFilter();
            },
            child:  Text('Wyczyść', style: TextStyle(color: theme.textColor)),
          ),
          ElevatedButton.icon(
            onPressed: _apply,
            icon:  Icon(Icons.search, color: theme.textColor),
            label:  Text('Filtruj', style: TextStyle(color: theme.textColor)),
          ),
        ],
      ),
    );
  }
}

/// ==============================
/// LIST (Master)
/// ==============================
class _ApplicationsList extends ConsumerWidget {
  const _ApplicationsList({required this.items, required this.theme});
  final List<MembershipApplicationModel> items;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return  _CenteredMsg('Brak aplikacji', theme);
    }
    final df = DateFormat('yyyy-MM-dd HH:mm');
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final m = items[i];
        final selected = ref.watch(selectedApplicationIdProvider) == m.id;
        return ListTile(
          selected: selected,
          title: Text(
            '${m.applicantUsername} • ${m.applicantType == "company" ? "Company" : "Person"}',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.textColor)
          ),
          subtitle: Text(
            '${m.status.toUpperCase()} • ${df.format(m.submittedAt.toLocal())}'
            '${m.companyName.isNotEmpty ? ' • ${m.companyName}' : ''}',
            style: TextStyle(color: theme.textColor.withAlpha(100))
          ),
          trailing: _StatusDot(status: m.status),
          onTap: () => ref.read(selectedApplicationIdProvider.notifier).state = m.id,
        );
      },
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final String status;
  Color get color {
    switch (status) {
      case 'pending': return Colors.amber;
      case 'review': return Colors.blueGrey;
      case 'accepted': return Colors.green;
      case 'rejected': return Colors.redAccent;
      default: return Colors.grey;
    }
  }
  @override
  Widget build(BuildContext context) => CircleAvatar(radius: 6, backgroundColor: color);
}

/// ==============================
/// DETAIL (Detail)
/// ==============================
class _DetailPane extends ConsumerWidget {
  const _DetailPane(this.theme);
  final ThemeColors theme; 

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(selectedApplicationIdProvider);
    if (sel == null) {
      return  _CenteredMsg('Wybierz aplikację z listy po lewej.', theme);
    }
    final async = ref.watch(applicationDetailProvider(sel));
    return async.when(
      data: (m) => _DetailBody(m: m),
      error: (e, st) => _CenteredMsg('Błąd: $e', theme),
      loading: () => const _CenteredLoader(),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.m});
  final MembershipApplicationModel m;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    final isTerminal = m.status == 'accepted' || m.status == 'rejected';
    final theme = ref.read(themeColorsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                runSpacing: 8, spacing: 16, crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Aplikacja #${m.id}', style: TextStyle(color: theme.textColor)),
                  Chip(backgroundColor: theme.themeColor, label: Text(m.status.toUpperCase(), style: TextStyle(color: AppColors.white))),
                ],
              ),
              const SizedBox(height: 12),
              _KV('Wnioskodawca', m.applicantUsername, theme),
              _KV('Typ', m.applicantType == 'company' ? 'Company' : 'Person', theme),
              if (m.companyName.isNotEmpty) _KV('Firma (etykieta)', m.companyName, theme),
              if (m.representedCompany != null) _KV('Reprezentowana firma (ID)', '${m.representedCompany}', theme),
              if (m.representedPosition.isNotEmpty) _KV('Stanowisko', m.representedPosition, theme),
              _KV('Złożono', df.format(m.submittedAt.toLocal()), theme),
              if (m.reviewedAt != null) _KV('Zrecenzowano', df.format(m.reviewedAt!.toLocal()), theme),
              const SizedBox(height: 12),
              Text('Informacje od wnioskodawcy', style: TextStyle(color: theme.textColor)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.textColor.withAlpha(120)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(m.info, style: TextStyle(color: theme.textColor)),
              ),
              const SizedBox(height: 16),
              if (m.documents.isNotEmpty) ...[
                Text('Załączniki', style: TextStyle(color: theme.textColor)),
                const SizedBox(height: 6),
                _DocsList(docs: m.documents, theme: theme),
                const SizedBox(height: 16),
              ],
              Text('Notatka z recenzji', style: TextStyle(color: theme.textColor)),
              const SizedBox(height: 6),
              Text(m.reviewNotes.isEmpty ? '—' : m.reviewNotes, style: TextStyle(color: theme.textColor)),
              const SizedBox(height: 24),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: isTerminal ? null : () => _review(context, ref, m.id, 'accepted', theme),
                    icon: Icon(Icons.check, color: theme.textColor),
                    label:  Text('Zatwierdź', style: TextStyle(color: theme.textColor)),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: isTerminal ? null : () => _review(context, ref, m.id, 'rejected', theme),
                    icon: Icon(Icons.close, color: theme.textColor),
                    label: Text('Odrzuć', style: TextStyle(color: theme.textColor)),
                  ),
                  const SizedBox(width: 12),
                  if (!isTerminal)
                    TextButton.icon(
                      onPressed: () => ref.invalidate(applicationDetailProvider(m.id)),
                      icon: Icon(Icons.refresh, color: theme.textColor),
                      label: Text('Odśwież', style: TextStyle(color: theme.textColor)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _review(BuildContext context, WidgetRef ref, String id, String decision, ThemeColors theme) async {
    final notes = await _askForNotes(context, decision == 'accepted' ? 'Powód akceptacji (opcjonalnie)' : 'Powód odrzucenia (opcjonalnie)', theme);
    if (notes == null) return;
    try {
      await ref.read(membershipApplicationsApiProvider).review(id: id, decision: decision, notes: notes);
      // Optimistic refresh: detail + list
      ref.invalidate(applicationDetailProvider(id));
      ref.invalidate(applicationsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(decision == 'accepted' ? 'Aplikacja zaakceptowana' : 'Aplikacja odrzucona')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
    }
  }
}

class _DocsList extends StatelessWidget {
  const _DocsList({required this.docs, required this.theme});
  final List<MemberDocumentModel> docs;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    return Column(
      children: docs.map((d) {
        return ListTile(
          dense: true,
          leading: Icon(Icons.attach_file, color: theme.textColor),
          title: Text(d.description.isNotEmpty ? d.description : d.fileUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.textColor)),
          subtitle: Text(df.format(d.uploadedAt.toLocal())),
          trailing: IconButton(
            tooltip: 'Otwórz',
            onPressed: () {
              // keep it simple: open in new tab if running on web
              // (you can integrate url_launcher if używacie)
            },
            icon:  Icon(Icons.open_in_new, color: theme.textColor),
          ),
        );
      }).toList(),
    );
  }
}

Future<String?> _askForNotes(BuildContext context, String title, ThemeColors theme) async {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Consumer(
        builder: (context, ref, _) {
          return CoreTextField(
            label: 'Notatka (opcjonalna)',
            hintText: 'Dodaj krótką notatkę…',
            controller: c,
            maxLines: 4,
            minLines: 3,
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child:  Text('Anuluj', style: TextStyle(color: theme.textColor)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, c.text.trim()),
          child:  Text('Zapisz', style: TextStyle(color: theme.textColor)),
        ),
      ],
    ),
  );
}


/// ==============================
/// PAGINATION
/// ==============================
class _PaginationBar extends ConsumerWidget {
  const _PaginationBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(applicationsFilterProvider);
    final theme = ref.read(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Poprzednia',
            onPressed: f.page > 1
                ? () => ref.read(applicationsFilterProvider.notifier).state =
                    f.copyWith(page: f.page - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Strona ${f.page}', style: TextStyle(color: theme.textColor)),
          IconButton(
            tooltip: 'Następna',
            onPressed: () => ref.read(applicationsFilterProvider.notifier).state =
                f.copyWith(page: f.page + 1),
            icon: const Icon(Icons.chevron_right),
          ),
          const Spacer(),
          DropdownButton<int>(
            dropdownColor: theme.dashboardContainer,
            value: f.pageSize,
            items:  [
              DropdownMenuItem(value: 10, child: Text('10', style: TextStyle(color: theme.textColor))),
              DropdownMenuItem(value: 20, child: Text('20', style: TextStyle(color: theme.textColor))),
              DropdownMenuItem(value: 50, child: Text('50', style: TextStyle(color: theme.textColor))),
              DropdownMenuItem(value: 100, child: Text('100', style: TextStyle(color: theme.textColor))),
            ],
            onChanged: (v) => ref.read(applicationsFilterProvider.notifier).state =
                f.copyWith(pageSize: v ?? 20, page: 1),
          ),
        ],
      ),
    );
  }
}

/// ==============================
/// HELPERS
/// ==============================
class _KV extends StatelessWidget {
  const _KV(this.k, this.v, this.theme);
  final String k;
  final String v;
  final ThemeColors theme;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 200, child: Text(k, style:  TextStyle(fontWeight: FontWeight.w600, color: theme.textColor))),
          Expanded(child: Text(v, style: TextStyle(color: theme.textColor))),
        ],
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
}

class _CenteredMsg extends StatelessWidget {
  const _CenteredMsg(this.text, this.theme);
  final String text;
  final ThemeColors theme;
  @override
  Widget build(BuildContext context) =>
      Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(text, style: TextStyle(color: theme.textColor))));
}
