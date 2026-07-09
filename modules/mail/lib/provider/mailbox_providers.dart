import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mailbox_query.dart';
import '../utils/email_local_storage_service.dart';
import '../utils/email_remote_service.dart';
import 'mailbox_controller.dart';
import 'mailbox_state.dart';

final emailLocalStorageServiceProvider =
    Provider<EmailLocalStorageService>((ref) {
  return EmailLocalStorageService();
});

final emailRemoteServiceProvider = Provider<EmailRemoteService>((ref) {
  return EmailRemoteService(ref: ref);
});

final mailboxControllerProvider = StateNotifierProvider.autoDispose
    .family<MailboxController, MailboxState, MailboxQuery>((ref, query) {
  return MailboxController(
    query: query,
    localStorage: ref.read(emailLocalStorageServiceProvider),
    remoteService: ref.read(emailRemoteServiceProvider),
  );
});