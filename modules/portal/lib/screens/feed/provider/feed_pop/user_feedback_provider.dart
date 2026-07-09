import 'package:flutter/foundation.dart';
import 'package:portal/portal_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class ContactFormModel {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String title;
  final String description;
  final DateTime? createdAt;
  final bool? isSolved;
  final String? note;
  final int? responsiblePerson;

  ContactFormModel({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.title,
    required this.description,
    this.createdAt,
    this.isSolved,
    this.note,
    this.responsiblePerson,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'title': title,
      'description': description,
    };
  }

  factory ContactFormModel.fromJson(Map<String, dynamic> json) {
    return ContactFormModel(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      title: json['title'],
      description: json['description'],
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'])
              : null,
      isSolved: json['is_solved'],
      note: json['note'],
      responsiblePerson: json['responsible_person'],
    );
  }
  @override
  String toString() {
    return '''
ContactFormModel {
  first_name: $firstName,
  last_name: $lastName,
  email: $email,
  title: $title,
  description: $description,
  created_at: $createdAt,
  is_solved: $isSolved,
  note: $note,
  responsible_person: $responsiblePerson
}
''';
  }
}

final userFeedbackProvider =
    StateNotifierProvider<UserFeedbackNotifier, AsyncValue<void>>(
      (ref) => UserFeedbackNotifier(),
    );

class UserFeedbackNotifier extends StateNotifier<AsyncValue<void>> {
  UserFeedbackNotifier() : super(const AsyncValue.data(null));
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final phoneController = TextEditingController();

  Future<void> submitUserFeedback() async {
    state = const AsyncValue.loading();

    final feedback = ContactFormModel(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      email: emailController.text.trim(),
      title: 'User feedback',
      description: descriptionController.text.trim(),
    );

    try {
      final response = await ApiServices.post(
        PortalUrls.feedbackContact,
        hasToken: true,
        data: feedback.toJson(),
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        debugPrint('✅ Feedback added successfully');
        clearControllers();
        state = const AsyncValue.data(null);
      } else {
        debugPrint('❌ Feedback failed: ${response?.statusCode} - ${response?.statusMessage}');
        clearControllers();
        state = AsyncValue.error('Failed to submit feedback', StackTrace.current);
      }
    } catch (e, stack) {
      debugPrint('❌ Exception while submitting feedback: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  void clearControllers() {
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    titleController.clear();
    descriptionController.clear();
    phoneController.clear();
  }
  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
