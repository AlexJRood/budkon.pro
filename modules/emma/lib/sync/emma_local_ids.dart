// lib/emma/sync/emma_local_ids.dart

class EmmaLocalIds {
  static int negativeNow() {
    return -DateTime.now().microsecondsSinceEpoch;
  }

  static String sessionUuid(int localId) {
    return 'emma_session_${localId.abs()}';
  }

  static String messageUuid(int localId) {
    return 'emma_message_${localId.abs()}';
  }
}