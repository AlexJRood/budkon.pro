class UserContactStatusModel {
  final int statusId;
  final String statusName;
  final int statusIndex;
  final List<int> contactIndex;

  const UserContactStatusModel({
    required this.statusId,
    required this.statusName,
    required this.statusIndex,
    required this.contactIndex,
  });

  factory UserContactStatusModel.fromJson(Map<String, dynamic> json) {
    return UserContactStatusModel(
      statusId: json['id'],
      statusName: json['status_name'],
      statusIndex: json['status_index'],
      contactIndex: List<int>.from(json['contact_index'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contact_status': statusId,
      'status_name': statusName.toString(),
      'status_index': statusIndex,
      'contact_index': contactIndex,
    };
  }

  UserContactStatusModel copyWith({
    int? statusId,
    String? statusName,
    int? statusIndex,
    List<int>? transactionIndex,
  }) {
    return UserContactStatusModel(
      statusId: statusId ?? this.statusId,
      statusName: statusName ?? this.statusName,
      statusIndex: statusIndex ?? this.statusIndex,
      contactIndex: transactionIndex ?? contactIndex,
    );
  }
}
