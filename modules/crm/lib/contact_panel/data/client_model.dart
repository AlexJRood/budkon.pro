import 'package:get/get_utils/get_utils.dart';

class Client {
  final int id;
  final bool star;
  final String? avatar;
  final String name;
  final String? lastName;
  final String email;
  final String? phoneNumber;
  final String? description;
  final String? note;
  final String serviceType;
  final DateTime dateCreated;
  final DateTime lastUpdated;
  final int? contactType;
  final int contactStatus;
  final int createdBy;
  final int? responsiblePerson;

  Client({
    required this.id,
    required this.star,
    this.avatar,
    required this.name,
    this.lastName,
    required this.email,
    this.phoneNumber,
    this.description,
    this.note,
    required this.serviceType,
    required this.dateCreated,
    required this.lastUpdated,
    this.contactType,
    required this.contactStatus,
    required this.createdBy,
    this.responsiblePerson,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? 0,
      star: json['star'] ?? false,
      avatar: json['avatar'],
      name: json['name'] ?? 'Unknown'.tr,
      lastName: json['last_name'],
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      description: json['description'],
      note: json['note'],
      serviceType: json['service_type'] ?? 'Unknown'.tr,
      dateCreated: DateTime.tryParse(json['date_created'] ?? '') ?? DateTime.now(),
      lastUpdated: DateTime.tryParse(json['last_updated'] ?? '') ?? DateTime.now(),
      contactType: json['contact_type'],
      contactStatus: json['contact_status'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      responsiblePerson: json['responsible_person'],
    );
  }
}