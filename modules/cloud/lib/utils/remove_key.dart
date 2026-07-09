import 'package:flutter/material.dart';
import 'package:core/platform/api_services.dart'; // <- Zmień na właściwy import jeśli masz inną ścieżkę
import 'package:get/get_utils/get_utils.dart';

Future<void> revokeCompanyKey({
  required BuildContext context,
  required String userId,
  required String keyName,
  String reason = '',
}) async {
  final url = 'https://twoje.api/api/userrevokedkeys/revoke/';
  final data = {
    'user_id': userId,
    'key_name': keyName,
    'reason': reason,
  };

  final response = await ApiServices.post(
    url,
    data: data,
    hasToken: true, // Twój ApiServices automatycznie dodaje Authorization!
  );

  if (response != null && response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('The key has been blocked (revoked).'.tr)),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${'Error: Failed to lock key!'.tr}\n${response?.data ?? ''}'),
      ),
    );
  }
}
