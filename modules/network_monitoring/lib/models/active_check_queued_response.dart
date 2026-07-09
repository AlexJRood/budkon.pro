class ActiveCheckQueuedResponse {
  final String status;
  final String message;
  final String url;
  final String taskId;

  ActiveCheckQueuedResponse({
    required this.status,
    required this.message,
    required this.url,
    required this.taskId,
  });

  factory ActiveCheckQueuedResponse.fromJson(Map<String, dynamic> json) {
    return ActiveCheckQueuedResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      url: json['url'] ?? '',
      taskId: json['task_id'] ?? '',
    );
  }
}