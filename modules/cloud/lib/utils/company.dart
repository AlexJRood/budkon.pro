import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart'; // Twój serwis!
import 'dart:convert';

final companyKeyStatusProvider = FutureProvider.family<CompanyKeyStatus, String>((ref, companyId) async {
  // Możesz pobrać token z secure storage lub z Providera, jeśli masz
  final url = 'https://twoje.api/api/company_key_status/?company_id=$companyId';

  final response = await ApiServices.get(
    url,
    hasToken: true,
    ref: ref,
  );

  if (response != null && response.statusCode == 200) {
    return CompanyKeyStatus.fromJson(
      jsonDecode(utf8.decode(response.data)),
    );
  } else {
    throw Exception('Błąd pobierania statusu klucza');
  }
});

class CompanyKeyStatus {
  final bool isRevoked;
  final String? revokedBy;
  final String? reason;

  CompanyKeyStatus({required this.isRevoked, this.revokedBy, this.reason});

  factory CompanyKeyStatus.fromJson(Map<String, dynamic> json) => CompanyKeyStatus(
        isRevoked: json['is_revoked'] as bool,
        revokedBy: json['revoked_by'] as String?,
        reason: json['reason'] as String?,
      );
}
