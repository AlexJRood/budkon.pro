import 'dart:convert';
import 'package:feedback/feedback_urls.dart';

import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

/// Feedback model class representing the feedback API object
class FeedbackModel {
  final int? id;
  final String title;
  final String description;
  final Uint8List? image;
  final DateTime? createdAt;
  final bool isSolved;
  final String note;
  final int? problem;
  final String? problemString;
  final int? user;
  final int? responsiblePerson;
  final String? path;
  final String? app;
  final String? feature;
  final String? team;
  final String? priority;

  const FeedbackModel({
    this.id,
    required this.title,
    required this.description,
    this.image,
    this.createdAt,
    this.isSolved = false,
    required this.note,
    this.problem,
    this.problemString,
    this.user,
    this.responsiblePerson,
    this.path,
    this.app,
    this.feature,
    this.team,
    this.priority,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      image: json['image'] as Uint8List?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      isSolved: json['is_solved'] as bool? ?? false,
      note: json['note'] as String? ?? '',
      problem: json['problem'] as int?,
      problemString: json['problem_string'] as String?,
      user: json['user'] as int?,
      responsiblePerson: json['responsible_person'] as int?,
      path: json['path'] as String?,
      app: json['app'] as String?,
      feature: json['feature'] as String?,
      team: json['team'] as String?,
      priority: json['priority'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'note': note,
      'problem': problem,
      'problem_string': problemString,
      'user': user,
      'responsible_person': responsiblePerson,
      'is_solved': isSolved,
      'path': path,
      'app': app,
      'feature': feature,
      'team': team,
      'priority': priority,
    };
  }
}

/// Feedback problem model class
class FeedbackProblem {
  final int id;
  final String title;
  final String? description;

  FeedbackProblem({required this.id, required this.title, this.description});

  factory FeedbackProblem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final intId = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    return FeedbackProblem(
      id: intId,
      title: json['title'] as String,
      description: json['description'] as String?,
    );
  }
}

/// A StateNotifier to manage the list of feedback messages
class FeedbackNotifier extends StateNotifier<List<FeedbackModel>> {
  FeedbackNotifier() : super([]);

  Future<String?> sendFeedback(FeedbackModel feedback) async {
    try {
      debugPrint('=== FeedbackNotifier.sendFeedback START ===');
      debugPrint('title: ${feedback.title}');
      debugPrint('description: ${feedback.description}');
      debugPrint('note: ${feedback.note}');
      debugPrint('problem: ${feedback.problem}');
      debugPrint('problemString: ${feedback.problemString}');
      debugPrint('user: ${feedback.user}');
      debugPrint('responsiblePerson: ${feedback.responsiblePerson}');
      debugPrint('isSolved: ${feedback.isSolved}');
      debugPrint('path: ${feedback.path}');
      debugPrint('app: ${feedback.app}');
      debugPrint('feature: ${feedback.feature}');
      debugPrint('team: ${feedback.team}');
      debugPrint('priority: ${feedback.priority}');
      debugPrint('image is null: ${feedback.image == null}');

      final formData = FormData();

      formData.fields.addAll([
        MapEntry('title', feedback.title.trim()),
        MapEntry('description', feedback.description.trim()),
        if (feedback.note.trim().isNotEmpty)
          MapEntry('note', feedback.note.trim()),
        MapEntry('is_solved', feedback.isSolved.toString()),
        if (feedback.user != null)
          MapEntry('user', feedback.user.toString()),
        if (feedback.problem != null)
          MapEntry('problem', feedback.problem.toString()),
        if (feedback.problemString != null &&
            feedback.problemString!.trim().isNotEmpty)
          MapEntry('problem_string', feedback.problemString!.trim()),
        if (feedback.responsiblePerson != null)
          MapEntry(
            'responsible_person',
            feedback.responsiblePerson.toString(),
          ),
        if (feedback.path != null && feedback.path!.trim().isNotEmpty)
          MapEntry('path', feedback.path!.trim()),
        if (feedback.app != null && feedback.app!.trim().isNotEmpty)
          MapEntry('app', feedback.app!.trim()),
        if (feedback.feature != null && feedback.feature!.trim().isNotEmpty)
          MapEntry('feature', feedback.feature!.trim()),
        if (feedback.team != null && feedback.team!.trim().isNotEmpty)
          MapEntry('team', feedback.team!.trim()),
        if (feedback.priority != null && feedback.priority!.trim().isNotEmpty)
          MapEntry('priority', feedback.priority!.trim()),
      ]);

      if (feedback.image != null) {
        formData.files.add(
          MapEntry(
            'image',
            MultipartFile.fromBytes(
              feedback.image!,
              filename: 'feedback.png',
              contentType: MediaType('image', 'png'),
            ),
          ),
        );
      }

      debugPrint('=== FINAL FORM DATA FIELDS ===');
      for (final field in formData.fields) {
        debugPrint('${field.key}: ${field.value}');
      }

      debugPrint('=== FINAL FORM DATA FILES ===');
      for (final file in formData.files) {
        debugPrint('${file.key}: ${file.value.filename}');
      }

      final resp = await ApiServices.post(
        FeedbackUrls.feedback,
        formData: formData,
        hasToken: true,
      );

      final code = resp?.statusCode ?? 500;

      debugPrint('=== FEEDBACK API RESPONSE ===');
      debugPrint('statusCode: $code');
      debugPrint('data: ${resp?.data}');

      if (code == 200 || code == 201) {
        return 'Dziękujemy! Feedback został wysłany ✅';
      }

      if (code == 400) {
        final errors = resp?.data;
        String combined = '';
        if (errors is Map<String, dynamic>) {
          errors.forEach((k, v) {
            combined +=
            '• $k: ${v.toString().replaceAll('[', '').replaceAll(']', '')}\n';
          });
        } else {
          combined = errors.toString();
        }
        return combined.trim();
      }

      return 'Nie udało się wysłać feedbacku (HTTP $code)';
    } catch (e, stack) {
      debugPrint('=== FeedbackNotifier.sendFeedback EXCEPTION ===');
      debugPrint('$e');
      debugPrintStack(stackTrace: stack);
      return 'Błąd podczas wysyłki: $e';
    }
  }
  /// Fetch feedback problems for dropdown
  Future<List<FeedbackProblem>> getFeedbackProblems(WidgetRef ref) async {
    try {
      final response =
      await ApiServices.get(FeedbackUrls.feedbackProblems, hasToken: true, ref: ref);
      if (response != null && response.statusCode == 200) {
        final rawData = response.data;
        final decoded = rawData is List<int>
            ? jsonDecode(utf8.decode(rawData))
            : rawData;
    final results = decoded['results'];
    if (results is List) {
    return results
        .map((e) => FeedbackProblem.fromJson(e as Map<String, dynamic>))
        .toList();
    } else {
    debugPrint('❌ "results" is not a List. Actual type: ${results.runtimeType}');
    debugPrint('❌ Full response: $decoded');
    return [];
    }
    } else {
    debugPrint('❌ Failed to fetch feedback problems: ${response?.statusCode}');
    debugPrint('❌ Response: ${response?.data}');
    return [];
    }
    } catch (e, stack) {
    debugPrint("❌ Exception in getFeedbackProblems: $e");
    debugPrint("📌 Stack trace: $stack");
    return [];
    }
  }
}

/// Global provider for FeedbackNotifier
final feedbackProvider =
StateNotifierProvider<FeedbackNotifier, List<FeedbackModel>>(
      (ref) => FeedbackNotifier(),
);