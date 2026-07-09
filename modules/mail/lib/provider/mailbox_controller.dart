import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mail_models.dart';
import '../models/mailbox_query.dart';
import '../utils/email_local_storage_service.dart';
import '../utils/email_remote_service.dart';
import 'mailbox_state.dart';

class MailboxController extends StateNotifier<MailboxState> {
  final MailboxQuery query;
  final EmailLocalStorageService localStorage;
  final EmailRemoteService remoteService;

  bool _disposed = false;

  MailboxController({
    required this.query,
    required this.localStorage,
    required this.remoteService,
  }) : super(MailboxState.initial(query.scopeKey)) {
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool get isDisposed => _disposed;

  void _setState(MailboxState next) {
    if (_disposed) return;
    try {
      state = next;
    } catch (_) {
      // Widget listeners may be deactivated before the provider disposes —
      // silently ignore rather than crashing the app.
    }
  }

  void _replaceEmailInState(EmailMessage updatedEmail) {
    if (_disposed) return;

    final current = state;
    final index = current.items.indexWhere((e) => e.id == updatedEmail.id);
    if (index == -1) return;

    final next = [...current.items];
    next[index] = updatedEmail;
    _setState(current.copyWith(items: next));
  }

  Future<void> _persistEmailLocally(EmailMessage email) async {
    if (email.body.isNotEmpty) {
      await localStorage.storeEmailDetail(query.storageNamespace, email);
    } else {
      await localStorage.upsertEmailSummaries(query.storageNamespace, [email]);
    }
  }

  Future<void> _refreshSingleEmailFromServer(int emailId) async {
    final refreshed = await remoteService.fetchEmailDetail(emailId);
    if (_disposed) return;

    await _persistEmailLocally(refreshed);
    if (_disposed) return;

    _replaceEmailInState(refreshed);
  }

  Future<void> _bootstrap() async {
    try {
      final exactScope = await localStorage.getScope(
        query.storageNamespace,
        query.scopeKey,
      );
      if (_disposed) return;

      List<EmailMessage> localItems = [];
      int totalInScope = 0;
      bool hasOlder = false;

      if (exactScope != null) {
        localItems = await localStorage.getEmailsByIds(
          query.storageNamespace,
          exactScope.ids,
        );
        if (_disposed) return;

        totalInScope = exactScope.totalInScope;
        hasOlder = exactScope.hasOlder;
      } else if (query.normalizedSearch.isNotEmpty) {
        final baseScope = await localStorage.getScope(
          query.storageNamespace,
          query.copyWith(search: "").scopeKey,
        );
        if (_disposed) return;

        if (baseScope != null) {
          final baseItems = await localStorage.getEmailsByIds(
            query.storageNamespace,
            baseScope.ids,
          );
          if (_disposed) return;

          localItems = _filterLocally(baseItems, query.search);
          totalInScope = localItems.length;
          hasOlder = false;
        }
      }

      _setState(
        state.copyWith(
          items: localItems,
          isLoadingLocal: false,
          totalInScope: totalInScope,
          hasOlder: hasOlder,
          clearError: true,
        ),
      );

      if (_disposed) return;
      unawaited(syncInBackground());
    } catch (e) {
      if (_disposed) return;

      _setState(
        state.copyWith(
          isLoadingLocal: false,
          error: e.toString(),
        ),
      );
    }
  }

  List<EmailMessage> _filterLocally(List<EmailMessage> items, String search) {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((mail) {
      return mail.subject.toLowerCase().contains(q) ||
          mail.sender.toLowerCase().contains(q) ||
          mail.senderDisplayName.toLowerCase().contains(q) ||
          mail.email.toLowerCase().contains(q) ||
          mail.recipients.any((e) => e.toLowerCase().contains(q)) ||
          mail.cc.any((e) => e.toLowerCase().contains(q)) ||
          mail.bcc.any((e) => e.toLowerCase().contains(q)) ||
          mail.body.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> syncInBackground({bool doRemoteSync = true}) async {
    if (_disposed) return;

    final current = state;
    if (current.isSyncing) return;

    _setState(current.copyWith(isSyncing: true, clearError: true));

    try {
      final currentScope = await localStorage.getScope(
        query.storageNamespace,
        query.scopeKey,
      );
      if (_disposed) return;

      final response = await remoteService.cacheSync(
        query: query,
        lastCheckAt: currentScope?.lastCheckAt,
        cachedCount: currentScope?.ids.length ?? 0,
        oldestCachedAt: currentScope?.oldestCachedAt,
        knownIds: currentScope?.ids ?? const [],
        doRemoteSync: doRemoteSync,
      );
      if (_disposed) return;

      await localStorage.upsertEmailSummaries(
        query.storageNamespace,
        response.addedOrChanged,
      );
      if (_disposed) return;

      final oldestCachedAt =
          response.windowIds.isEmpty ? null : response.oldestServerAt;

      final snapshot = LocalMailboxScopeSnapshot(
        scopeKey: query.scopeKey,
        ids: response.windowIds,
        totalInScope: response.totalInScope,
        hasOlder: response.hasOlder,
        lastCheckAt: response.serverTime,
        oldestCachedAt: oldestCachedAt,
        maxLocal: query.maxLocal,
      );

      await localStorage.saveScope(query.storageNamespace, snapshot);
      if (_disposed) return;

      await localStorage.compactNamespace(query.storageNamespace);
      if (_disposed) return;

      final items = await localStorage.getEmailsByIds(
        query.storageNamespace,
        response.windowIds,
      );
      if (_disposed) return;

      _setState(
        state.copyWith(
          items: items,
          isSyncing: false,
          hasOlder: response.hasOlder,
          totalInScope: response.totalInScope,
          clearError: true,
        ),
      );
    } catch (e) {
      if (_disposed) return;

      _setState(
        state.copyWith(
          isSyncing: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> refreshHard() async {
    if (_disposed) return;
    await syncInBackground(doRemoteSync: true);
  }

  Future<void> loadOlder() async {
    if (_disposed) return;

    final current = state;
    if (current.isLoadingMore || current.items.isEmpty || !current.hasOlder) {
      return;
    }

    final olderThan = current.items.last.timelineAtIso;
    if (olderThan == null || olderThan.isEmpty) return;

    _setState(current.copyWith(isLoadingMore: true, clearError: true));

    try {
      final response = await remoteService.loadOlder(
        query: query,
        olderThan: olderThan,
        count: 100,
      );
      if (_disposed) return;

      await localStorage.upsertEmailSummaries(
        query.storageNamespace,
        response.results,
      );
      if (_disposed) return;

      final currentScope = await localStorage.getScope(
        query.storageNamespace,
        query.scopeKey,
      );
      if (_disposed) return;

      final existingIds =
          currentScope?.ids ?? current.items.map((e) => e.id).toList();

      final newIds = [
        ...existingIds,
        ...response.results.map((e) => e.id),
      ];

      final dedupedIds = <int>[];
      final seen = <int>{};
      for (final id in newIds) {
        if (seen.add(id)) {
          dedupedIds.add(id);
        }
      }

      final snapshot = LocalMailboxScopeSnapshot(
        scopeKey: query.scopeKey,
        ids: dedupedIds,
        totalInScope: currentScope?.totalInScope ?? current.totalInScope,
        hasOlder: response.hasMore,
        lastCheckAt: currentScope?.lastCheckAt,
        oldestCachedAt: response.results.isNotEmpty
            ? response.results.last.timelineAtIso
            : currentScope?.oldestCachedAt,
        maxLocal: query.maxLocal,
      );

      await localStorage.saveScope(query.storageNamespace, snapshot);
      if (_disposed) return;

      final items = await localStorage.getEmailsByIds(
        query.storageNamespace,
        dedupedIds,
      );
      if (_disposed) return;

      _setState(
        state.copyWith(
          items: items,
          isLoadingMore: false,
          hasOlder: response.hasMore,
          clearError: true,
        ),
      );
    } catch (e) {
      if (_disposed) return;

      _setState(
        state.copyWith(
          isLoadingMore: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<EmailMessage?> getLocalEmailDetail(int emailId) {
    return localStorage.getEmailById(query.storageNamespace, emailId);
  }

  Future<EmailMessage> getEmailDetail(int emailId) async {
    final local = await localStorage.getEmailById(
      query.storageNamespace,
      emailId,
    );

    if (local != null && local.body.isNotEmpty) {
      unawaited(() async {
        try {
          final remote = await remoteService.fetchEmailDetail(emailId);
          if (_disposed) return;

          await localStorage.storeEmailDetail(query.storageNamespace, remote);
          if (_disposed) return;

          _replaceEmailInState(remote);
        } catch (_) {
          // Silent refresh only
        }
      }());

      return local;
    }

    final remote = await remoteService.fetchEmailDetail(emailId);
    if (_disposed) return remote;

    await localStorage.storeEmailDetail(query.storageNamespace, remote);
    if (_disposed) return remote;

    final currentItems = state.items;
    final index = currentItems.indexWhere((e) => e.id == emailId);
    if (index != -1) {
      final next = [...currentItems];
      next[index] = remote;
      _setState(state.copyWith(items: next));
    }

    return remote;
  }

  Future<void> markEmailAsRead(int emailId) async {
    final local = await localStorage.getEmailById(
      query.storageNamespace,
      emailId,
    );

    if (local == null || local.isRead) {
      return;
    }

    final updated = local.copyWith(isRead: true);

    await localStorage.updateEmailReadState(
      query.storageNamespace,
      emailId,
      true,
    );
    if (_disposed) return;

    _replaceEmailInState(updated);

    try {
      await remoteService.markEmailRead(emailId);
    } catch (_) {
      // UI already updated locally. Intentionally ignored.
    }
  }

  Future<void> markEmailAsUnread(int emailId) async {
    final local = await localStorage.getEmailById(
      query.storageNamespace,
      emailId,
    );

    if (local == null || !local.isRead) {
      return;
    }

    final updated = local.copyWith(isRead: false);

    await localStorage.updateEmailReadState(
      query.storageNamespace,
      emailId,
      false,
    );
    if (_disposed) return;

    _replaceEmailInState(updated);

    try {
      await remoteService.markEmailUnread(emailId);
    } catch (_) {
      // UI already updated locally. Intentionally ignored.
    }
  }

  Future<void> touchEmmaSeen(int emailId) async {
    try {
      await remoteService.touchEmmaSeen(emailId);
      if (_disposed) return;

      await _refreshSingleEmailFromServer(emailId);
    } catch (_) {
      // Silent on purpose - non critical UX helper
    }
  }

  Future<void> touchEmmaUsed(int emailId) async {
    try {
      await remoteService.touchEmmaUsed(emailId);
      if (_disposed) return;

      await _refreshSingleEmailFromServer(emailId);
    } catch (_) {
      // Silent on purpose - non critical UX helper
    }
  }
}