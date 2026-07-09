import 'package:flutter_riverpod/flutter_riverpod.dart';

final mailTypeProvider = StateProvider<String>((ref) => 'all');
final mailSearchProvider = StateProvider<String>((ref) => '');
final mailPageProvider = StateProvider<int>((ref) => 1);
final mailPageSizeProvider = StateProvider<int>((ref) => 20);
final mailSortProvider = StateProvider<String>((ref) => 'received_at_desc');

final mailLeadIdProvider = StateProvider<int?>((ref) => null);
final mailEmailProvider = StateProvider<String?>((ref) => null);

final mailSelectionModeProvider = StateProvider<bool>((ref) => false);
final selectedMailIdsProvider = StateProvider<Set<int>>((ref) => <int>{});

final scheduledPendingPageProvider = StateProvider<int>((ref) => 1);
final scheduledSentPageProvider = StateProvider<int>((ref) => 1);

final selectedEmailTabIdProvider = StateProvider<int?>((ref) => null);
final selectedEmailTagIdsProvider =
    StateProvider<Set<int>>((ref) => <int>{});

/// Bump this whenever some external action should force mailbox refresh
/// (DnD move to tab, bulk changes, etc.).
final mailRefreshTickProvider = StateProvider<int>((ref) => 0);

void triggerMailRefresh(WidgetRef ref) {
  ref.read(mailRefreshTickProvider.notifier).state++;
}

void resetMailExtraFilters(WidgetRef ref) {
  ref.read(selectedEmailTabIdProvider.notifier).state = null;
  ref.read(selectedEmailTagIdsProvider.notifier).state = <int>{};
  ref.read(mailPageProvider.notifier).state = 1;
  triggerMailRefresh(ref);
}final mailSidebarVisibleProvider = StateProvider<bool>((ref) => true);




class EmailFilterParams {
  final String? searchQuery;
  final bool? isOutgoing;
  final int? page;
  final int? pageSize;
  final String? ordering;
  final int? leadId; // ✅ DODANE
  final String? email;

  EmailFilterParams(
      {this.searchQuery,
      this.isOutgoing,
      this.page,
      this.pageSize,
      this.ordering,
      this.leadId,
      this.email});
}
