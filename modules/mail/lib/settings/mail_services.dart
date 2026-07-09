import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

final emailAccountProvider =
StateNotifierProvider<EmailAccountNotifier, AsyncValue<void>>((ref) {
  return EmailAccountNotifier();
});

class EmailAccountNotifier extends StateNotifier<AsyncValue<void>> {
  EmailAccountNotifier() : super(const AsyncValue.data(null));

  Future<bool> saveEmailAccount(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final res = await ApiServices.post(
        '${URLs.baseUrl}/mail/email-accounts/',
        data: data,
        hasToken: true,
      );

      if (res != null && res.statusCode == 201) {
        state = const AsyncValue.data(null);
        return true;
      }

      state = const AsyncValue.data(null);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateEmailAccount(int id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      debugPrint('Updating email account $id with data: $data');
      final res = await ApiServices.patch(
        '${URLs.baseUrl}/mail/email-accounts/$id/',
        data: data,
        hasToken: true,
      );
      if (res != null && res.statusCode == 200) {
        state = const AsyncValue.data(null);
        return true;
      }
      debugPrint('Server response: ${res?.statusCode} - ${res?.data}');
      state = const AsyncValue.data(null);
      return false;
    } catch (e, st) {
      debugPrint('Update email account error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteEmailAccount(int id) async {
    state = const AsyncValue.loading();
    try {
      final res = await ApiServices.delete(
        '${URLs.baseUrl}/mail/email-accounts/$id/',
        hasToken: true,
      );
      if (res != null && res.statusCode == 204) {
        state = const AsyncValue.data(null);
        return true;
      }
      state = const AsyncValue.data(null);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
