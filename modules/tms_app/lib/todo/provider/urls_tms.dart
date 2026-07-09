class TmsURLs {
  // Production setup
  static const baseUrl = 'https://www.superbee.cloud';

  /// Append base URL.
  static String appendBaseUrl(String url) => '$baseUrl$url';

  ////////////////////////////////// TMS URLs //////////////////////////////////

  static final apiTask = appendBaseUrl('/tms/project/');
  static String editBoard(String id) => appendBaseUrl('/tms/project/$id/');

  static final taskSyncCheck = appendBaseUrl('/tms/task/sync-check/');
  static final taskSyncPull = appendBaseUrl('/tms/task/sync-pull/');

  static String addComment(String taskId) =>
      appendBaseUrl('/tms/task/$taskId/add-comment/');

  static String getComments(String taskId) =>
      appendBaseUrl('/tms/task/$taskId/get-comments/');

  static String deleteComments(String taskId, String commentId) =>
      appendBaseUrl('/tms/task/$taskId/delete-task-comment/$commentId/');

  static final addTask = appendBaseUrl('/tms/task/');

  static String addProgressBar(String projectId) =>
      appendBaseUrl('/tms/project/$projectId/create-progress-bar-field/');

  static String projectDetails(String projectId) =>
      appendBaseUrl('/tms/project/$projectId/');

  static String editTask(String progressId) =>
      appendBaseUrl('/tms/task/$progressId/');

  static String reOrderTask(String projectId) =>
      appendBaseUrl('/tms/project/$projectId/ordering-tasks/');

  static String reProgressTask(String taskId) =>
      appendBaseUrl('/tms/task/$taskId/update-progress-bar/');

  static String addFileToTask(String taskId) =>
      appendBaseUrl('/tms/task/$taskId/add-task-file/');

  static String deleteProgressBar(String projectId, String progressId) =>
      appendBaseUrl(
        '/tms/project/$projectId/update-progress-bar-field/$progressId/',
      );

  static String updateProgressBar(String projectId, String progressId) =>
      appendBaseUrl(
        '/tms/project/$projectId/update-progress-bar-field/$progressId/',
      );

  static String filterTaskByClient(String clientId) =>
      appendBaseUrl('/tms/task/tasks-by-client/$clientId/');

  static String assignTaskToClient(String taskId) =>
      appendBaseUrl('/tms/assign-client/$taskId/');

  static final taskLabels = appendBaseUrl('/tms/labels/');

  static String editTaskLabel(String labelId) =>
      appendBaseUrl('/tms/labels/$labelId/');

  static String addMemberToProject(String projectId) =>
      appendBaseUrl('/tms/project/$projectId/add-members/');

  static String deleteTask(String taskId) =>
      appendBaseUrl('/tms/task/$taskId/');

  static String addChecklist(String taskId) =>
      appendBaseUrl('/tms/task/$taskId/add-checklist/');

  static String editTaskChecklist(String checklistId) =>
      appendBaseUrl('/tms/checklists/$checklistId/');

  static String columnReorder(String projectId, String columnId) =>
      appendBaseUrl('/tms/project/$projectId/reorder-progress-bar/$columnId/');

  static final reorderProjects =
      appendBaseUrl('/tms/project/reorder-projects/');

  ////////////////////////////// Member panel //////////////////////////////

  static String memberBoards(int memberId) =>
      appendBaseUrl('/tms/project/member/$memberId/');

  static String memberBoardDetails(int memberId, int projectId) =>
      appendBaseUrl('/tms/project/member/$memberId/$projectId/');
}
