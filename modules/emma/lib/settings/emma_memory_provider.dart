import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emma/settings/emma_memory_service.dart';

final emmaMemoryProvider =
    FutureProvider.autoDispose<EmmaMemory?>((ref) async {
  return EmmaMemoryService.fetch(ref);
});
