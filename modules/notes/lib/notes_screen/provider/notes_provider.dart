import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:notes/notes_urls.dart';

import '../model/note_model.dart';

final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<NoteModel>>(NotesNotifier.new);

class NotesNotifier extends AsyncNotifier<List<NoteModel>> {
  @override
  Future<List<NoteModel>> build() => _fetch();

  Future<List<NoteModel>> _fetch() async {
    final response = await ApiServices.get(NotesUrls.notes, hasToken: true, ref: ref);
    if (response == null || response.statusCode != 200) return [];

    final data = response.data;
    final List<dynamic> results =
        data is Map ? (data['results'] ?? data['items'] ?? []) : data as List;

    return results
        .whereType<Map<String, dynamic>>()
        .map(NoteModel.fromJson)
        .toList();
  }

  Future<NoteModel?> createNote({
    required String title,
    required String content,
  }) async {
    final response = await ApiServices.post(
      NotesUrls.notes,
      data: {'title': title, 'content': content},
      hasToken: true,
      ref: ref,
    );

    if (response == null ||
        (response.statusCode != 200 && response.statusCode != 201)) {
      log('❌ Failed to create note: ${response?.statusCode}');
      return null;
    }

    final note = NoteModel.fromJson(response.data as Map<String, dynamic>);
    state = AsyncData([note, ...state.valueOrNull ?? []]);
    return note;
  }

  Future<bool> updateNote({
    required int id,
    required String title,
    required String content,
  }) async {
    final response = await ApiServices.patch(
      NotesUrls.note(id),
      data: {'title': title, 'content': content},
      hasToken: true,
      ref: ref,
    );

    if (response == null ||
        (response.statusCode != 200 && response.statusCode != 201)) {
      log('❌ Failed to update note $id: ${response?.statusCode}');
      return false;
    }

    final updated = NoteModel.fromJson(response.data as Map<String, dynamic>);
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((n) => n.id == id ? updated : n)
          .toList(),
    );
    return true;
  }

  Future<bool> deleteNote(int id) async {
    final response = await ApiServices.delete(
      NotesUrls.note(id),
      hasToken: true,
    );

    if (response == null ||
        (response.statusCode != 200 &&
            response.statusCode != 204 &&
            response.statusCode != 201)) {
      log('❌ Failed to delete note $id: ${response?.statusCode}');
      return false;
    }

    state = AsyncData(
      (state.valueOrNull ?? []).where((n) => n.id != id).toList(),
    );
    return true;
  }

  void refresh() => ref.invalidateSelf();
}
