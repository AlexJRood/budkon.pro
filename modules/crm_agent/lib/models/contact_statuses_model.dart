class ContactStatusModel {
  final int id;
  final String statusName;
  final int statusIndex;
  final List<int> contactIndex; // Zmieniamy na listę intów

  const ContactStatusModel({
    required this.id,
    required this.statusName,
    required this.statusIndex,
    required this.contactIndex,
  });

  factory ContactStatusModel.fromJson(Map<String, dynamic> json) {
    return ContactStatusModel(
      id: json['id'],
      statusName: json['status_name'],
      statusIndex: json['status_index'],
      contactIndex: List<int>.from(json['contact_index']), // Konwersja na listę intów
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status_name': statusName,
      'status_index': statusIndex,
      'contact_index': contactIndex,
    };
  }

  ContactStatusModel copyWith({
    int? id,
    String? statusName,
    int? statusIndex,
    List<int>? transactionIndex,
  }) {
    return ContactStatusModel(
      id: id ?? this.id,
      statusName: statusName ?? this.statusName,
      statusIndex: statusIndex ?? this.statusIndex,
      contactIndex: transactionIndex ?? contactIndex,
    );
  }
}
