import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/projekt_model.dart';
import '../services/projekt_api.dart';

final _api = ProjektApi();

// Wynik parsowania (null = nic nie parsowano)
final parsedProjektProvider =
    StateProvider<ParsedProjekt?>((ref) => null);

// Stan uploadu/parsowania
class ParseState {
  final bool isLoading;
  final String? error;
  final double? progress; // 0.0–1.0

  const ParseState({
    this.isLoading = false,
    this.error,
    this.progress,
  });

  ParseState copyWith({
    bool? isLoading,
    String? error,
    double? progress,
  }) =>
      ParseState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        progress: progress ?? this.progress,
      );
}

class ParseNotifier extends StateNotifier<ParseState> {
  ParseNotifier(this._ref) : super(const ParseState());

  final Ref _ref;

  Future<ParsedProjekt?> parseFile(String path, String name) async {
    state = const ParseState(isLoading: true, progress: 0.1);
    try {
      state = state.copyWith(progress: 0.3);
      final result = await _api.parseProject(path, name);
      state = state.copyWith(progress: 1.0);
      _ref.read(parsedProjektProvider.notifier).state = result;
      state = const ParseState();
      return result;
    } catch (e) {
      state = ParseState(error: e.toString());
      return null;
    }
  }

  Future<ParsedProjekt?> parseBytes(List<int> bytes, String name) async {
    state = const ParseState(isLoading: true, progress: 0.1);
    try {
      state = state.copyWith(progress: 0.3);
      final result = await _api.parseProjectBytes(bytes, name);
      state = state.copyWith(progress: 1.0);
      _ref.read(parsedProjektProvider.notifier).state = result;
      state = const ParseState();
      return result;
    } catch (e) {
      state = ParseState(error: e.toString());
      return null;
    }
  }

  void reset() {
    state = const ParseState();
    _ref.read(parsedProjektProvider.notifier).state = null;
  }
}

final parseProvider =
    StateNotifierProvider.autoDispose<ParseNotifier, ParseState>(
  (ref) => ParseNotifier(ref),
);

// Edycja floor planu (lista pomieszczeń, można modyfikować)
final floorPlanRoomsProvider =
    StateProvider.autoDispose<List<PomieszczenieProjekt>>((ref) {
  final parsed = ref.watch(parsedProjektProvider);
  return parsed?.pomieszczenia ?? [];
});
