import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

import 'package:emma/provider/urls.dart';

/// Rezultat tworzenia / aktualizacji workflow przez Emmę.
class EmmaAutomationWorkflowResult {
  final Map<String, dynamic> workflow;

  /// Pytania do użytkownika (wizard) — puste gdy workflow jest kompletny.
  final List<Map<String, dynamic>> questions;

  const EmmaAutomationWorkflowResult({
    required this.workflow,
    required this.questions,
  });

  factory EmmaAutomationWorkflowResult.fromJson(Map<String, dynamic> j) {
    final rawQuestions = j['questions'];
    return EmmaAutomationWorkflowResult(
      workflow: j['workflow'] is Map
          ? Map<String, dynamic>.from(j['workflow'] as Map)
          : {},
      questions: rawQuestions is List
          ? rawQuestions
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : [],
    );
  }

  bool get needsMoreInfo => questions.isNotEmpty;
}

/// Rezultat dry-runu.
class EmmaAutomationDryRunResult {
  final String status;
  final List<Map<String, dynamic>> steps;
  final String? errorMessage;
  final int durationMs;

  const EmmaAutomationDryRunResult({
    required this.status,
    required this.steps,
    this.errorMessage,
    required this.durationMs,
  });

  factory EmmaAutomationDryRunResult.fromJson(Map<String, dynamic> j) {
    final dr = j['dry_run'] is Map
        ? Map<String, dynamic>.from(j['dry_run'] as Map)
        : j;
    final rawSteps = dr['steps'];
    return EmmaAutomationDryRunResult(
      status: (dr['status'] ?? 'ok').toString(),
      steps: rawSteps is List
          ? rawSteps
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : [],
      errorMessage: dr['error']?.toString(),
      durationMs: (dr['duration_ms'] as int?) ?? 0,
    );
  }

  bool get isSuccess => status == 'ok' || status == 'success';
}

/// Rezultat testu zewnętrznego konnektora.
class EmmaConnectorTestResult {
  final bool ok;
  final int latencyMs;
  final Map<String, dynamic> sampleResponse;
  final String? errorMessage;

  const EmmaConnectorTestResult({
    required this.ok,
    required this.latencyMs,
    required this.sampleResponse,
    this.errorMessage,
  });

  factory EmmaConnectorTestResult.fromJson(Map<String, dynamic> j) {
    return EmmaConnectorTestResult(
      ok: j['ok'] == true,
      latencyMs: (j['latency_ms'] as int?) ?? 0,
      sampleResponse: j['sample_response'] is Map
          ? Map<String, dynamic>.from(j['sample_response'] as Map)
          : {},
      errorMessage: j['error']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------

class EmmaAutomationService {
  final Ref _ref;

  const EmmaAutomationService(this._ref);

  /// Tworzy workflow z opisu naturalnego języka.
  /// Zwraca workflow + ewentualne pytania doprecyzowujące.
  Future<EmmaAutomationWorkflowResult> createFromDescription({
    required String description,
    String scopeType = 'user',
    Map<String, dynamic>? context,
  }) async {
    final body = {
      'description': description,
      'scope_type': scopeType,
      if (context != null) 'context': context,
    };
    final res = await ApiServices.post(
      URLsEmma.emmaAutomationCreate,
      data: body,
      hasToken: true,
      ref: _ref,
    );
    return EmmaAutomationWorkflowResult.fromJson(
      Map<String, dynamic>.from(res?.data as Map),
    );
  }

  /// Dosyła odpowiedzi na pytania wizarda i pobiera zaktualizowany workflow.
  Future<EmmaAutomationWorkflowResult> refineWorkflow({
    required String workflowId,
    required Map<String, dynamic> answers,
  }) async {
    final res = await ApiServices.post(
      URLsEmma.emmaAutomationRefine(workflowId),
      data: {'workflow_id': workflowId, 'answers': answers},
      hasToken: true,
      ref: _ref,
    );
    return EmmaAutomationWorkflowResult.fromJson(
      Map<String, dynamic>.from(res?.data as Map),
    );
  }

  /// Wykonuje dry-run workflow (symulacja bez efektów ubocznych).
  Future<EmmaAutomationDryRunResult> dryRun(String workflowId) async {
    final res = await ApiServices.post(
      URLsEmma.emmaAutomationDryRun(workflowId),
      data: {'workflow_id': workflowId},
      hasToken: true,
      ref: _ref,
    );
    return EmmaAutomationDryRunResult.fromJson(
      Map<String, dynamic>.from(res?.data as Map),
    );
  }

  /// Dezaktywuje workflow (status active → paused).
  Future<Map<String, dynamic>> deactivateWorkflow(String workflowId) async {
    final res = await ApiServices.post(
      URLsEmma.emmaAutomationDeactivate(workflowId),
      data: {'workflow_id': workflowId},
      hasToken: true,
      ref: _ref,
    );
    return Map<String, dynamic>.from(res?.data as Map);
  }

  /// Aktywuje workflow (status draft → active).
  Future<Map<String, dynamic>> activateWorkflow(String workflowId) async {
    final res = await ApiServices.post(
      URLsEmma.emmaAutomationActivate(workflowId),
      data: {'workflow_id': workflowId},
      hasToken: true,
      ref: _ref,
    );
    return Map<String, dynamic>.from(res?.data as Map);
  }

  /// Pobiera pojedynczy workflow.
  Future<Map<String, dynamic>> getWorkflow(String workflowId) async {
    final res = await ApiServices.get(
      URLsEmma.emmaAutomationGet(workflowId),
      hasToken: true,
      ref: _ref,
    );
    return Map<String, dynamic>.from(res?.data as Map);
  }

  /// Pobiera listę workflow (ostatnich N dla usera).
  Future<List<Map<String, dynamic>>> listWorkflows({int limit = 10}) async {
    final res = await ApiServices.get(
      '${URLsEmma.emmaAutomationList}?limit=$limit',
      hasToken: true,
      ref: _ref,
    );
    final data = res?.data;
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (data is Map && data['results'] is List) {
      final list = data['results'] as List;
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  /// Pobiera opis słowny jak działa workflow.
  Future<String> explainWorkflow(String workflowId) async {
    final res = await ApiServices.post(
      URLsEmma.emmaAutomationExplain(workflowId),
      data: {'workflow_id': workflowId},
      hasToken: true,
      ref: _ref,
    );
    final data = res?.data;
    if (data is Map) return (data['explanation'] ?? '').toString();
    return '';
  }

  /// Tworzy zewnętrzny konnektor API (OAuth / key).
  Future<Map<String, dynamic>> createConnector({
    required String name,
    required String baseUrl,
    required String authType,
    Map<String, dynamic>? credentials,
    Map<String, dynamic>? headers,
  }) async {
    final res = await ApiServices.post(
      URLsEmma.emmaAutomationConnectorCreate,
      data: {
        'name': name,
        'base_url': baseUrl,
        'auth_type': authType,
        if (credentials != null) 'credentials': credentials,
        if (headers != null) 'headers': headers,
      },
      hasToken: true,
      ref: _ref,
    );
    return Map<String, dynamic>.from(res?.data as Map);
  }

  /// Testuje połączenie z zewnętrznym konnektorem.
  Future<EmmaConnectorTestResult> testConnector(String connectorId) async {
    final res = await ApiServices.post(
      URLsEmma.emmaAutomationConnectorTest(connectorId),
      data: {'connector_id': connectorId},
      hasToken: true,
      ref: _ref,
    );
    return EmmaConnectorTestResult.fromJson(
      Map<String, dynamic>.from(res?.data as Map),
    );
  }
}

final emmaAutomationServiceProvider = Provider<EmmaAutomationService>((ref) {
  return EmmaAutomationService(ref);
});
