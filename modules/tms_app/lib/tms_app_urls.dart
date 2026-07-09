import 'package:core/platform/url.dart';

/// tms_app feature API endpoints, decentralized out of core's URLs God-package.
class TmsAppUrls {
  const TmsAppUrls._();

static String addChecklist(String taskId) =>
      URLs.appendBaseUrl('/tms/task/$taskId/add-checklist/');
static final apiTask = URLs.appendBaseUrl('/tms/project/');
static String columnReorder(String projectId, String columnId) =>
      URLs.appendBaseUrl('/tms/project/$projectId/reorder-progress-bar/$columnId/');
static String editBoard(String id) => URLs.appendBaseUrl('/tms/project/$id/');
static String editTaskChecklist(String checklistId) =>
      URLs.appendBaseUrl('/tms/checklists/$checklistId/');
static String editTaskLabel(String labelId) =>
      URLs.appendBaseUrl('/tms/labels/$labelId/');
static String projectDetails(String projectId) =>
      URLs.appendBaseUrl('/tms/project/$projectId/');
static final reorderProjects = URLs.appendBaseUrl('/tms/project/reorder-projects/');
static final taskLabels = URLs.appendBaseUrl('/tms/labels/');
}
