import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/user/user/user_provider.dart'; // userStateProvider
import 'package:core/user/user/user_model.dart';    // CompanyModel

/// What scope Finance is currently using.
enum FinanceScopeKind { company, association }

/// Current scope kind (companies vs associations)
final financeScopeKindProvider =
    StateProvider<FinanceScopeKind>((ref) => FinanceScopeKind.company);

/// Selected "company/association" ID for Finance module.
final financeCompanyIdProvider = StateProvider<int?>((ref) => null);

/// Entities available for current scope kind.
final financeAvailableCompaniesProvider = Provider<List<CompanyModel>>((ref) {
  final user = ref.watch(userStateProvider);
  if (user == null) return const <CompanyModel>[];

  final kind = ref.watch(financeScopeKindProvider);

  if (kind == FinanceScopeKind.association) {
    return user.associations; // stowarzyszenia z profilu
  }
  return user.company; // firmy z profilu
});

/// Selected entity object for UI (name/logo).
final financeSelectedCompanyProvider = Provider<CompanyModel?>((ref) {
  final list = ref.watch(financeAvailableCompaniesProvider);
  if (list.isEmpty) return null;

  final id = ref.watch(financeCompanyIdProvider);
  if (id == null) return list.first;

  return list.firstWhere(
    (c) => c.id == id,
    orElse: () => list.first,
  );
});

/// ✅ IMPORTANT: resolves a usable companyId as soon as profile is available.
/// - If financeCompanyIdProvider is set -> returns it.
/// - Else returns first entity from the current scope list.
/// - If list empty -> null.
final financeResolvedCompanyIdProvider = Provider<int?>((ref) {
  final selected = ref.watch(financeCompanyIdProvider);
  if (selected != null) return selected;

  final list = ref.watch(financeAvailableCompaniesProvider);
  if (list.isEmpty) return null;

  return list.first.id;
});

/// Appends `company_id` query parameter to any URL.
String withCompanyId(String url, int? companyId) {
  if (companyId == null) return url;
  final sep = url.contains('?') ? '&' : '?';
  return '$url${sep}company_id=$companyId';
}
