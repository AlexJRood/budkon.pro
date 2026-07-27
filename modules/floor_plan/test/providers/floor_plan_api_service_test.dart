import 'package:core/platform/api_services.dart';
import 'package:core/testing/fake_http_client_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floor_plan/providers/floor_plan_api_service.dart';
import 'package:floor_plan/providers/urls.dart';

const _api = FloorPlanApiService(baseUrl: URLsFloorPlan.baseUrl);

Map<String, dynamic> _projectJson(String id, {String title = 'Plan'}) => {
      'id': id,
      'title': title,
      'source_type': 'manual',
      'status': 'draft',
    };

/// Pumps a throwaway widget tree and hands back a real WidgetRef, since
/// FloorPlanApiService's methods all require WidgetRef (not a plain Ref).
Future<WidgetRef> _widgetRef(WidgetTester tester) async {
  late WidgetRef captured;
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      home: Consumer(builder: (context, ref, _) {
        captured = ref;
        return const SizedBox();
      }),
    ),
  ));
  await tester.pump();
  return captured;
}

void main() {
  late FakeHttpClientAdapter adapter;

  setUp(() {
    adapter = FakeHttpClientAdapter();
    ApiServices.debugHttpClientAdapter = adapter;
    ApiServices.token = 'test-token';
  });

  group('FloorPlanApiService.listProjects', () {
    testWidgets('parses a "results"-shaped list and drops entries with a blank id', (tester) async {
      final ref = await _widgetRef(tester);
      Map<String, dynamic>? capturedQuery;
      adapter.addRule(FakeHttpRule(
        method: 'GET',
        urlMatcher: (p) => p == '/floor-plans/projects/',
        bodyBuilder: (options) {
          capturedQuery = options.uri.queryParameters;
          return {
            'results': [
              _projectJson('p1'),
              {'id': '', 'title': 'No id'},
            ],
          };
        },
      ));

      late List<FloorPlanProjectDto> projects;
      await tester.runAsync(() async {
        projects = await _api.listProjects(ref: ref, status: 'draft');
      });

      expect(projects.map((p) => p.id), ['p1']);
      expect(capturedQuery?['status'], 'draft');
      expect(capturedQuery?.containsKey('target_object_id'), isFalse);
    });

    testWidgets('throws with the HTTP status and backend detail on error', (tester) async {
      final ref = await _widgetRef(tester);
      adapter.get(
        '/floor-plans/projects/',
        statusCode: 500,
        body: (_) => {'detail': 'server exploded'},
      );

      late Object? error;
      await tester.runAsync(() async {
        try {
          await _api.listProjects(ref: ref);
        } catch (e) {
          error = e;
        }
      });

      expect(error.toString(), contains('500'));
      expect(error.toString(), contains('server exploded'));
    });
  });

  group('FloorPlanApiService.getProject / createProject', () {
    testWidgets('getProject parses a single project', (tester) async {
      final ref = await _widgetRef(tester);
      adapter.get('/floor-plans/projects/p1/', body: (_) => _projectJson('p1', title: 'Solo'));

      late FloorPlanProjectDto project;
      await tester.runAsync(() async {
        project = await _api.getProject(ref: ref, projectId: 'p1');
      });
      expect(project.title, 'Solo');
    });

    testWidgets('createProject defaults a blank title and posts source_type', (tester) async {
      final ref = await _widgetRef(tester);
      Map<String, dynamic>? captured;
      adapter.post(
        '/floor-plans/projects/',
        body: (options) {
          captured = options.data as Map<String, dynamic>;
          return _projectJson('new-1', title: captured!['title'] as String);
        },
      );

      late FloorPlanProjectDto project;
      await tester.runAsync(() async {
        project = await _api.createProject(ref: ref, title: '   ');
      });

      expect(project.id, 'new-1');
      expect(captured?['title'], isNotEmpty);
      expect(captured?['source_type'], 'manual');
    });
  });

  group('FloorPlanApiService.deleteProject', () {
    testWidgets('completes without error on a 204 response', (tester) async {
      final ref = await _widgetRef(tester);
      adapter.delete('/floor-plans/projects/p1/', statusCode: 204);

      await tester.runAsync(() async {
        await _api.deleteProject(ref: ref, projectId: 'p1');
      });
    });

    testWidgets('throws on a non-204/error response', (tester) async {
      final ref = await _widgetRef(tester);
      adapter.delete('/floor-plans/projects/p1/', statusCode: 404);

      late Object? error;
      await tester.runAsync(() async {
        try {
          await _api.deleteProject(ref: ref, projectId: 'p1');
        } catch (e) {
          error = e;
        }
      });
      expect(error, isNotNull);
    });
  });

  group('FloorPlanApiService.startVectorizeJob / startFromPhotosJob', () {
    testWidgets('startVectorizeJob posts asset_ids and parses the job', (tester) async {
      final ref = await _widgetRef(tester);
      Map<String, dynamic>? captured;
      adapter.post(
        '/floor-plans/projects/p1/ai/vectorize/',
        body: (options) {
          captured = options.data as Map<String, dynamic>;
          return {'id': 'job-1', 'project': 'p1', 'job_type': 'vectorize', 'status': 'queued'};
        },
      );

      late FloorPlanAiJobDto job;
      await tester.runAsync(() async {
        job = await _api.startVectorizeJob(ref: ref, projectId: 'p1', assetIds: ['a1', 'a2']);
      });

      expect(job.id, 'job-1');
      expect(captured?['asset_ids'], ['a1', 'a2']);
    });
  });
}
