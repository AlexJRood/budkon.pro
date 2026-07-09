import '../models/mail_models.dart';

class MailboxState {
  final List<EmailMessage> items;
  final bool isLoadingLocal;
  final bool isSyncing;
  final bool isLoadingMore;
  final bool hasOlder;
  final int totalInScope;
  final String scopeKey;
  final String? error;

  const MailboxState({
    required this.items,
    required this.isLoadingLocal,
    required this.isSyncing,
    required this.isLoadingMore,
    required this.hasOlder,
    required this.totalInScope,
    required this.scopeKey,
    required this.error,
  });

  factory MailboxState.initial(String scopeKey) {
    return MailboxState(
      items: const [],
      isLoadingLocal: true,
      isSyncing: false,
      isLoadingMore: false,
      hasOlder: false,
      totalInScope: 0,
      scopeKey: scopeKey,
      error: null,
    );
  }

  MailboxState copyWith({
    List<EmailMessage>? items,
    bool? isLoadingLocal,
    bool? isSyncing,
    bool? isLoadingMore,
    bool? hasOlder,
    int? totalInScope,
    String? scopeKey,
    String? error,
    bool clearError = false,
  }) {
    return MailboxState(
      items: items ?? this.items,
      isLoadingLocal: isLoadingLocal ?? this.isLoadingLocal,
      isSyncing: isSyncing ?? this.isSyncing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasOlder: hasOlder ?? this.hasOlder,
      totalInScope: totalInScope ?? this.totalInScope,
      scopeKey: scopeKey ?? this.scopeKey,
      error: clearError ? null : (error ?? this.error),
    );
  }
}