// lib/admin/feedback/feedback_api.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

const kApiBase = 'https://www.superbee.cloud';
const kFeedbackBase = '$kApiBase/feedback';
const kFeedbackProblems = '$kApiBase/feedback/problems/';

String _join(String a, String b) => a.endsWith('/') ? a + b : '$a/$b';

dynamic _decodeResponseData(dynamic raw) {
  if (raw is List<int>) return json.decode(utf8.decode(raw));
  if (raw is String) return json.decode(raw);
  return raw;
}

String absoluteUrl(String? url) {
  if (url == null) return '';
  url = url.trim();
  if (url.isEmpty) return '';

  final parsed = Uri.tryParse(url);
  if (parsed != null && parsed.hasScheme) {
    if (parsed.scheme == 'http' || parsed.scheme == 'https') {
      return parsed.replace(scheme: 'https').toString();
    }
    return url;
  }

  if (url.startsWith('//')) {
    return 'https:$url';
  }

  final base = Uri.parse(kApiBase);
  final baseHttps = Uri(
    scheme: 'https',
    host: base.host,
    port: (base.hasPort && base.port != 80 && base.port != 443) ? base.port : null,
    path: base.path,
  );

  return baseHttps.resolve(url).toString();
}

List<dynamic> _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    if (data['results'] is List) return (data['results'] as List);
    if (data['items'] is List) return (data['items'] as List);
    return [data];
  }
  return const [];
}

String? _iso(DateTime? dt) => dt?.toUtc().toIso8601String();

class FeedbackApi {
  static Future<List<FeedbackModel>> listFeedbacks({
    required dynamic ref,
    String? search,
    bool? isSolved,
    int? problemId,
    List<int>? responsibleIds,
    bool? responsibleIsNull,
    int? userId,
    List<String>? features,
    List<String>? teams,
    List<String>? apps,
    List<String>? priority,
    String? pathIcontains,
    bool? hasImage,
    bool? hasNote,
    bool? unassigned,
    DateTime? createdAfter,
    DateTime? createdBefore,
    String? ordering,
  }) async {
    final qp = <String, String>{};

    if (search != null && search.trim().isNotEmpty) qp['search'] = search.trim();
    if (isSolved != null) qp['is_solved'] = isSolved ? 'true' : 'false';
    if (problemId != null) qp['problem'] = '$problemId';

    if (responsibleIsNull == true) {
      qp['responsible_person__isnull'] = 'true';
      qp['responsible_person'] = 'null';
    } else if (responsibleIds != null && responsibleIds.isNotEmpty) {
      if (responsibleIds.length == 1) {
        qp['responsible_person'] = '${responsibleIds.first}';
      } else {
        qp['responsible_person__in'] = responsibleIds.join(',');
      }
    }

    if (userId != null) qp['user'] = '$userId';

    void addList1OrIn(String baseKey, List<String>? values) {
      if (values == null || values.isEmpty) return;
      if (values.length == 1) {
        qp[baseKey] = values.first;
      } else {
        qp['${baseKey}__in'] = values.join(',');
      }
    }

    addList1OrIn('feature', features);
    addList1OrIn('team', teams);
    addList1OrIn('app', apps);

    if (priority != null && priority.isNotEmpty) {
      qp['priority__in'] = priority.join(',');
    }

    if (hasImage != null) qp['has_image'] = hasImage ? 'true' : 'false';
    if (hasNote != null) qp['has_note'] = hasNote ? 'true' : 'false';
    if (unassigned != null) qp['unassigned'] = unassigned ? 'true' : 'false';

    if (pathIcontains != null && pathIcontains.trim().isNotEmpty) {
      qp['path_icontains'] = pathIcontains.trim();
    }

    final after = _iso(createdAfter);
    final before = _iso(createdBefore);

    if (after != null) qp['created_at_after'] = after;
    if (before != null) qp['created_at_before'] = before;

    if (ordering != null && ordering.trim().isNotEmpty) {
      qp['ordering'] = ordering.trim();
    }
    final res = await ApiServices.get(
      _join(kFeedbackBase, ''),
      queryParameters: qp.isEmpty ? null : qp,
      hasToken: true,
      ref: ref,
    );
    debugPrint('=== listFeedbacks RESPONSE ===');
    debugPrint('statusCode: ${res?.statusCode}');
    debugPrint('raw data: ${res?.data}');
    if (res == null) return [];

    final data = _decodeResponseData(res.data);
    final list = _extractList(data);
    debugPrint('decoded list count: ${list.length}');
    return list.map((e) => FeedbackModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<bool> deleteFeedback({required int id}) async {
    final res = await ApiServices.delete(_join(kFeedbackBase, '$id/'), hasToken: true);
    final code = res?.statusCode ?? 0;
    return code >= 200 && code < 300;
  }

  static Future<FeedbackModel?> fetchDetail({
    required dynamic ref,
    required int id,
  }) async {
    final res = await ApiServices.get(
      _join(kFeedbackBase, '$id/'),
      hasToken: true,
      ref: ref,
    );
    if (res == null) return null;

    final data = _decodeResponseData(res.data);
    if (data is Map<String, dynamic>) return FeedbackModel.fromJson(data);

    final list = _extractList(data);
    if (list.isEmpty) return null;

    return FeedbackModel.fromJson(list.first as Map<String, dynamic>);
  }

  String? cleanString(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static Future<bool> patchFeedback({
    required int id,
    bool? isSolved,
    String? note,
    int? responsiblePerson,
    String? path,
    String? feature,
    String? team,
    String? app,
    String? priority,
    int? problemId,
    String? title,
    String? description,
  }) async {
    final payload = <String, dynamic>{};

    if (isSolved != null) payload['is_solved'] = isSolved;
    if (note != null) payload['note'] = note;
    if (responsiblePerson != null) payload['responsible_person'] = responsiblePerson;
    if (path != null) payload['path'] = path;
    if (feature != null) payload['feature'] = feature;
    if (team != null) payload['team'] = team;
    if (app != null) payload['app'] = app;
    if (priority != null) payload['priority'] = priority;
    if (problemId != null) payload['problem'] = problemId;
    if (title != null) payload['title'] = title;
    if (description != null) payload['description'] = description;

    debugPrint('=== PATCH FEEDBACK REQUEST ===');
    debugPrint('id: $id');
    debugPrint('payload: $payload');

    final res = await ApiServices.patch(
      _join(kFeedbackBase, '$id/'),
      data: payload,
      hasToken: true,
    );

    debugPrint('=== PATCH FEEDBACK RESPONSE ===');
    debugPrint('statusCode: ${res?.statusCode}');
    debugPrint('data: ${res?.data}');

    final code = res?.statusCode ?? 0;
    return code >= 200 && code < 300;
  }

  static Future<List<FeedbackProblemModel>> listProblems({required dynamic ref}) async {
    final res = await ApiServices.get(kFeedbackProblems, hasToken: true, ref: ref);
    if (res == null) return [];
    final data = _decodeResponseData(res.data);
    final list = _extractList(data);
    return list.map((e) => FeedbackProblemModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

// -----------------------------------------------------------------------------
// Filters / Providers
// -----------------------------------------------------------------------------

class FeedbackFilters {
  final String search;
  final bool? isSolved;
  final int? problemId;
  final List<int> responsibleIds;
  final bool? responsibleIsNull;
  final int? userId;
  final List<String> features;
  final List<String> teams;
  final List<String> apps;
  final List<String> priority;
  final String? pathIcontains;
  final bool? hasImage;
  final bool? hasNote;
  final bool? unassigned;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final String? ordering;

  const FeedbackFilters({
    this.search = '',
    this.isSolved,
    this.problemId,
    this.responsibleIds = const [],
    this.responsibleIsNull,
    this.userId,
    this.features = const [],
    this.teams = const [],
    this.apps = const [],
    this.priority = const [],
    this.pathIcontains,
    this.hasImage,
    this.hasNote,
    this.unassigned,
    this.createdAfter,
    this.createdBefore,
    this.ordering,
  });

  FeedbackFilters copyWith({
    String? search,
    bool? isSolved,
    int? problemId,
    List<int>? responsibleIds,
    bool? responsibleIsNull,
    int? userId,
    List<String>? features,
    List<String>? teams,
    List<String>? apps,
    List<String>? priority,
    String? pathIcontains,
    bool? hasImage,
    bool? hasNote,
    bool? unassigned,
    DateTime? createdAfter,
    DateTime? createdBefore,
    String? ordering,
    bool resetIsSolved = false,
    bool resetProblemId = false,
    bool resetResponsibleIsNull = false,
    bool resetUserId = false,
    bool resetPathIcontains = false,
    bool resetHasImage = false,
    bool resetHasNote = false,
    bool resetUnassigned = false,
    bool resetCreatedAfter = false,
    bool resetCreatedBefore = false,
    bool resetOrdering = false,
  }) {
    return FeedbackFilters(
      search: search ?? this.search,
      isSolved: resetIsSolved ? null : (isSolved ?? this.isSolved),
      problemId: resetProblemId ? null : (problemId ?? this.problemId),
      responsibleIds: responsibleIds ?? this.responsibleIds,
      responsibleIsNull: resetResponsibleIsNull
          ? null
          : (responsibleIsNull ?? this.responsibleIsNull),
      userId: resetUserId ? null : (userId ?? this.userId),
      features: features ?? this.features,
      teams: teams ?? this.teams,
      apps: apps ?? this.apps,
      priority: priority ?? this.priority,
      pathIcontains: resetPathIcontains ? null : (pathIcontains ?? this.pathIcontains),
      hasImage: resetHasImage ? null : (hasImage ?? this.hasImage),
      hasNote: resetHasNote ? null : (hasNote ?? this.hasNote),
      unassigned: resetUnassigned ? null : (unassigned ?? this.unassigned),
      createdAfter: resetCreatedAfter ? null : (createdAfter ?? this.createdAfter),
      createdBefore: resetCreatedBefore ? null : (createdBefore ?? this.createdBefore),
      ordering: resetOrdering ? null : (ordering ?? this.ordering),
    );
  }
}

final feedbackFiltersProvider =
StateProvider<FeedbackFilters>((ref) => const FeedbackFilters());

final feedbackListProvider =
FutureProvider.autoDispose<List<FeedbackModel>>((ref) async {
  final f = ref.watch(feedbackFiltersProvider);
  return FeedbackApi.listFeedbacks(
    ref: ref,
    search: f.search.isEmpty ? null : f.search,
    isSolved: f.isSolved,
    problemId: f.problemId,
    responsibleIds: f.responsibleIds,
    responsibleIsNull: f.responsibleIsNull,
    userId: f.userId,
    features: f.features.isEmpty ? null : f.features,
    teams: f.teams.isEmpty ? null : f.teams,
    apps: f.apps.isEmpty ? null : f.apps,
    priority: f.priority.isEmpty ? null : f.priority,
    pathIcontains: f.pathIcontains,
    hasImage: f.hasImage,
    hasNote: f.hasNote,
    unassigned: f.unassigned,
    createdAfter: f.createdAfter,
    createdBefore: f.createdBefore,
    ordering: f.ordering,
  );
});

class FeedbackDetailState {
  final FeedbackModel? data;
  final bool loading;
  final String? error;

  const FeedbackDetailState({
    this.data,
    this.loading = false,
    this.error,
  });

  FeedbackDetailState copyWith({
    FeedbackModel? data,
    bool? loading,
    String? error,
  }) =>
      FeedbackDetailState(
        data: data ?? this.data,
        loading: loading ?? this.loading,
        error: error,
      );
}

final feedbackDetailProvider = StateNotifierProvider.autoDispose
    .family<FeedbackDetailNotifier, FeedbackDetailState, int>((ref, id) {
  return FeedbackDetailNotifier(ref: ref, id: id);
});

final feedbackProblemsProvider =
FutureProvider.autoDispose<List<FeedbackProblemModel>>((ref) async {
  return FeedbackApi.listProblems(ref: ref);
});

// -----------------------------------------------------------------------------
// Detail form + notifier
// -----------------------------------------------------------------------------

class FeedbackDetailForm {
  final bool? isSolved;
  final String? note;
  final int? responsiblePerson;
  final String? title;
  final String? description;
  final String? path;
  final String? feature;
  final String? team;
  final String? app;
  final String? priority;
  final int? problemId;

  const FeedbackDetailForm({
    this.isSolved,
    this.note,
    this.responsiblePerson,
    this.title,
    this.description,
    this.path,
    this.feature,
    this.team,
    this.app,
    this.priority,
    this.problemId,
  });

  factory FeedbackDetailForm.fromModel(FeedbackModel m) => FeedbackDetailForm(
    isSolved: m.isSolved,
    note: m.note,
    responsiblePerson: m.responsiblePerson,
    title: m.title,
    description: m.description,
    path: m.path,
    feature: m.feature,
    team: m.team,
    app: m.app,
    priority: m.priority,
    problemId: m.problem,
  );

  FeedbackDetailForm copyWith({
    bool? isSolved,
    String? note,
    int? responsiblePerson,
    String? title,
    String? description,
    String? path,
    String? feature,
    String? team,
    String? app,
    String? priority,
    int? problemId,
    bool resetIsSolved = false,
    bool resetNote = false,
    bool resetResponsible = false,
    bool resetTitle = false,
    bool resetDescription = false,
    bool resetPath = false,
    bool resetFeature = false,
    bool resetTeam = false,
    bool resetApp = false,
    bool resetPriority = false,
    bool resetProblem = false,
  }) {
    return FeedbackDetailForm(
      isSolved: resetIsSolved ? null : (isSolved ?? this.isSolved),
      note: resetNote ? null : (note ?? this.note),
      responsiblePerson: resetResponsible ? null : (responsiblePerson ?? this.responsiblePerson),
      title: resetTitle ? null : (title ?? this.title),
      description: resetDescription ? null : (description ?? this.description),
      path: resetPath ? null : (path ?? this.path),
      feature: resetFeature ? null : (feature ?? this.feature),
      team: resetTeam ? null : (team ?? this.team),
      app: resetApp ? null : (app ?? this.app),
      priority: resetPriority ? null : (priority ?? this.priority),
      problemId: resetProblem ? null : (problemId ?? this.problemId),
    );
  }
}

class FeedbackDetailFormNotifier extends StateNotifier<FeedbackDetailForm?> {
  FeedbackDetailFormNotifier() : super(null);

  void seedFrom(FeedbackModel m) {
    state = FeedbackDetailForm.fromModel(m);
  }

  void setIsSolved(bool v) => state = state?.copyWith(isSolved: v);
  void setNote(String v) => state = state?.copyWith(note: v);
  void setResponsible(int? v) => state = state?.copyWith(responsiblePerson: v);
  void clearResponsible() => state = state?.copyWith(responsiblePerson: null);
  void setTitle(String? v) => state = state?.copyWith(title: v ?? '');
  void setDescription(String? v) => state = state?.copyWith(description: v ?? '');
  void setPath(String? v) => state = state?.copyWith(path: v ?? '');
  void setFeature(String? v) => state = state?.copyWith(feature: v);
  void setTeam(String? v) => state = state?.copyWith(team: v);
  void setApp(String? v) => state = state?.copyWith(app: v);
  void setPriority(String? v) => state = state?.copyWith(priority: v);
  void setProblem(int? v) => state = state?.copyWith(problemId: v);
}

final feedbackDetailFormProvider = StateNotifierProvider.autoDispose
    .family<FeedbackDetailFormNotifier, FeedbackDetailForm?, int>((ref, id) {
  return FeedbackDetailFormNotifier();
});

class FeedbackDetailNotifier extends StateNotifier<FeedbackDetailState> {
  final Ref ref;
  final int id;

  FeedbackDetailNotifier({
    required this.ref,
    required this.id,
  }) : super(const FeedbackDetailState(loading: true)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final m = await FeedbackApi.fetchDetail(ref: ref, id: id);
      state = state.copyWith(data: m, loading: false);
      if (m != null) {
        ref.read(feedbackDetailFormProvider(id).notifier).seedFrom(m);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), loading: false);
    }
  }

  Future<bool> delete() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final ok = await FeedbackApi.deleteFeedback(id: id);
      if (ok) {
        state = const FeedbackDetailState(data: null, loading: false, error: null);
        ref.invalidate(feedbackListProvider);
        ref.invalidate(feedbackDetailFormProvider(id));
        return true;
      } else {
        state = state.copyWith(loading: false, error: 'Delete failed');
        return false;
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> update({
    bool? isSolved,
    String? note,
    int? responsiblePerson,
    String? path,
    String? feature,
    String? team,
    String? app,
    String? priority,
    int? problemId,
    String? title,
    String? description,
  }) async {
    final ok = await FeedbackApi.patchFeedback(
      id: id,
      isSolved: isSolved,
      note: note,
      responsiblePerson: responsiblePerson,
      path: path,
      feature: feature,
      team: team,
      app: app,
      priority: priority,
      problemId: problemId,
      title: title,
      description: description,
    );
    if (ok) await load();
    return ok;
  }
}

class FeedbackProblemModel {
  final int id;
  final String title;
  final String? description;

  FeedbackProblemModel({
    required this.id,
    required this.title,
    this.description,
  });

  factory FeedbackProblemModel.fromJson(Map<String, dynamic> j) =>
      FeedbackProblemModel(
        id: j['id'] as int,
        title: j['title'] as String,
        description: j['description'] as String?,
      );
}

int? _asId(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is Map && v['id'] is int) return v['id'] as int;
  if (v is String) return int.tryParse(v);
  return null;
}

String? _asString(dynamic v) => v == null ? null : v.toString();

DateTime _parseDate(dynamic v) {
  if (v is String && v.isNotEmpty) {
    final dt = DateTime.tryParse(v);
    if (dt != null) return dt;
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

class FeedbackModel {
  final int id;
  final int? problem;
  final String? problemString;
  final String? title;
  final String? description;
  final String? image;
  final int? user;
  final DateTime createdAt;
  final bool isSolved;
  final String? note;
  final int? responsiblePerson;
  final String? feature;
  final String? featureDisplay;
  final String? team;
  final String? teamDisplay;
  final String? app;
  final String? priority;
  final String? appDisplay;
  final String? priorityDisplay;
  final String? path;

  FeedbackModel({
    required this.id,
    required this.problem,
    required this.problemString,
    required this.title,
    required this.description,
    required this.image,
    required this.user,
    required this.createdAt,
    required this.isSolved,
    required this.note,
    required this.responsiblePerson,
    this.feature,
    this.featureDisplay,
    this.team,
    this.teamDisplay,
    this.app,
    this.priority,
    this.appDisplay,
    this.priorityDisplay,
    this.path,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> j) => FeedbackModel(
    id: _asId(j['id']) ?? 0,
    problem: _asId(j['problem']),
    problemString: _asString(j['problem_string']),
    title: _asString(j['title']),
    description: _asString(j['description']),
    image: _asString(j['image']),
    user: _asId(j['user']),
    createdAt: _parseDate(j['created_at']),
    isSolved: (j['is_solved'] as bool?) ?? false,
    note: _asString(j['note']),
    responsiblePerson: _asId(j['responsible_person']),
    feature: _asString(j['feature']),
    featureDisplay: _asString(j['feature_display']),
    team: _asString(j['team']),
    teamDisplay: _asString(j['team_display']),
    app: _asString(j['app']),
    priority: _asString(j['priority']),
    appDisplay: _asString(j['app_display']),
    priorityDisplay: _asString(j['priority_display']),
    path: _asString(j['path']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'problem': problem,
    'problem_string': problemString,
    'title': title,
    'description': description,
    'image': image,
    'user': user,
    'created_at': createdAt.toIso8601String(),
    'is_solved': isSolved,
    'note': note,
    'responsible_person': responsiblePerson,
    'feature': feature,
    'feature_display': featureDisplay,
    'team': team,
    'team_display': teamDisplay,
    'app': app,
    'priority': priority,
    'app_display': appDisplay,
    'priority_display': priorityDisplay,
    'path': path,
  };

  FeedbackModel copyWith({
    int? id,
    int? problem,
    String? problemString,
    String? title,
    String? description,
    String? image,
    int? user,
    DateTime? createdAt,
    bool? isSolved,
    String? note,
    int? responsiblePerson,
    String? feature,
    String? featureDisplay,
    String? team,
    String? teamDisplay,
    String? app,
    String? priority,
    String? appDisplay,
    String? priorityDisplay,
    String? path,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      problem: problem ?? this.problem,
      problemString: problemString ?? this.problemString,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
      isSolved: isSolved ?? this.isSolved,
      note: note ?? this.note,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      feature: feature ?? this.feature,
      featureDisplay: featureDisplay ?? this.featureDisplay,
      team: team ?? this.team,
      teamDisplay: teamDisplay ?? this.teamDisplay,
      app: app ?? this.app,
      priority: priority ?? this.priority,
      appDisplay: appDisplay ?? this.appDisplay,
      priorityDisplay: priorityDisplay ?? this.priorityDisplay,
      path: path ?? this.path,
    );
  }
}

final feedbackIssuesByPathProvider =
FutureProvider.autoDispose.family<List<FeedbackModel>, String>((ref, path) async {
  final f = ref.watch(feedbackFiltersProvider);

  return FeedbackApi.listFeedbacks(
    ref: ref,
    search: f.search.isEmpty ? null : f.search,
    isSolved: f.isSolved,
    problemId: f.problemId,
    responsibleIds: f.responsibleIds,
    responsibleIsNull: f.responsibleIsNull,
    userId: f.userId,
    features: f.features.isEmpty ? null : f.features,
    teams: f.teams.isEmpty ? null : f.teams,
    apps: f.apps.isEmpty ? null : f.apps,
    priority: f.priority.isEmpty ? null : f.priority,
    pathIcontains: (f.pathIcontains != null && f.pathIcontains!.trim().isNotEmpty)
        ? f.pathIcontains
        : path,
    hasImage: f.hasImage,
    hasNote: f.hasNote,
    unassigned: f.unassigned,
    createdAfter: f.createdAfter,
    createdBefore: f.createdBefore,
    ordering: f.ordering ?? '-created_at',
  );
});