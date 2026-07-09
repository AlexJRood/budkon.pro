import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class AssociationDashboardScope {
  final int associationId;
  final String baseUrl;
  final int loyaltyProgramId;

  const AssociationDashboardScope({
    required this.associationId,
    required this.baseUrl,
    this.loyaltyProgramId = 1,
  });
}

final associationDashboardScopeProvider = Provider<AssociationDashboardScope>((ref) {
  throw UnimplementedError(
    'associationDashboardScopeProvider must be overridden before using association dashboard widgets.',
  );
});