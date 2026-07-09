import 'dart:convert' show utf8, json;

import 'package:flutter/foundation.dart';
import 'package:crm/crm_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crm/shared/models/contact_type_model.dart';
import 'package:crm/shared/models/service_type_model.dart';
import 'package:crm/shared/models/user_contact_status_model.dart'
    show UserContactStatusModel;

import 'package:core/platform/api_services.dart';

import 'package:core/user/user/user_model.dart' show UserModel;
import 'package:core/user/user/user_provider.dart' show ApiServiceUser;

/// Publiczny provider do wstrzykiwania ContactTypeProvider
final contactTypeProvider = ChangeNotifierProvider((ref) => ContactTypeProvider());

/// „Triggery” do wygodnego pobrania list (możesz po prostu `ref.watch(...)` w widżecie)
final contactTypesFetchProvider = FutureProvider<void>((ref) async {
  await ref.read(contactTypeProvider).getContactType(ref);
});

final serviceTypesFetchProvider = FutureProvider<void>((ref) async {
  await ref.read(contactTypeProvider).getContactServiceType(ref);
});

final contactStatusesFetchProvider = FutureProvider<void>((ref) async {
  await ref.read(contactTypeProvider).getContactStatus(ref);
});

/// Zarządza słownikami: typ kontaktu, typ usługi, status kontaktu + user
class ContactTypeProvider extends ChangeNotifier {
  // --- Pamiętane listy ---
  List<ContactTypeModel> _contactType = [];
  List<ContactTypeModel> get contactType => _contactType;

  List<ServiceTypeModel> _contactServiceType = [];
  List<ServiceTypeModel> get contactServiceType => _contactServiceType;

  List<UserContactStatusModel> _contactStatus = [];
  List<UserContactStatusModel> get contactStatus => _contactStatus;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  /// Uniwersalne wydobycie listy z response.data (bytes/String/Map/List)
  List<dynamic> _decodeList(dynamic data) {
    if (data == null) return const [];

    // 1) Najpierw bajty -> String -> JSON
    if (data is List<int>) {
      try {
        final s = utf8.decode(data);
        final decoded = json.decode(s);
        return _decodeList(decoded); // rekurencyjnie
      } catch (_) {
        return const [];
      }
    }

    // 2) String JSON -> dynamic
    if (data is String) {
      try {
        final decoded = json.decode(data);
        return _decodeList(decoded);
      } catch (_) {
        return const [];
      }
    }

    // 3) Docelowa tablica obiektów
    if (data is List) return data;

    // 4) Paginacja / wyniki w polu "results"
    if (data is Map && data['results'] is List) {
      return (data['results'] as List).cast<dynamic>();
    }

    // (opcjonalnie) jeśli API czasem zwraca pojedynczy obiekt:
    if (data is Map) return [data];

    return const [];
  }

  /// Pobierz Typy kontaktu
  /// Uwaga: `ref` jest `dynamic`, by przyjąć i `WidgetRef`, i `FutureProviderRef`.
  Future<void> getContactType(dynamic ref) async {
    try {
      final response = await ApiServices.get(
        CrmUrls.contactType,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final list = _decodeList(response.data);
        _contactType = list
            .where((e) => e is Map) // prosty filtr
            .map((e) => ContactTypeModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        if (kDebugMode) debugPrint('Contact types loaded: ${_contactType.length}');
      } else {
        _contactType = [];
        if (kDebugMode) debugPrint('getContactType: HTTP ${response?.statusCode}');
      }
    } catch (e) {
      _contactType = [];
      if (kDebugMode) debugPrint('getContactType error: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Pobierz Typy usług
  Future<void> getContactServiceType(dynamic ref) async {
    try {
      final response = await ApiServices.get(
        CrmUrls.contactServiceType,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final list = _decodeList(response.data);
        _contactServiceType = list
            .whereType<Map>()
            .map((m) => ServiceTypeModel.fromJson(m.cast<String, dynamic>()))
            .toList();
        if (kDebugMode) debugPrint('Service types loaded: ${_contactServiceType.length}');
      } else {
        _contactServiceType = [];
        if (kDebugMode) debugPrint('getContactServiceType: HTTP ${response?.statusCode}');
      }
    } catch (e) {
      _contactServiceType = [];
      if (kDebugMode) debugPrint('getContactServiceType error: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Pobierz Statusy kontaktu
  Future<void> getContactStatus(dynamic ref) async {
    try {
      final response = await ApiServices.get(
        CrmUrls.userContactsStatuses,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final list = _decodeList(response.data);
        _contactStatus = list
            .whereType<Map>()
            .map((m) => UserContactStatusModel.fromJson(m.cast<String, dynamic>()))
            .toList();
        if (kDebugMode) debugPrint('Contact statuses loaded: ${_contactStatus.length}');
      } else {
        _contactStatus = [];
        if (kDebugMode) debugPrint('getContactStatus: HTTP ${response?.statusCode}');
      }
    } catch (e) {
      _contactStatus = [];
      if (kDebugMode) debugPrint('getContactStatus error: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Pobierz dane użytkownika
  Future<void> getUserDetails(dynamic ref) async {
    try {
      final apiService = ApiServiceUser();
      _userModel = await apiService.fetchUser(ref); // akceptuje WidgetRef? -> dynamic rozwiązuje konflikt typów
    } catch (e) {
      _userModel = null;
      if (kDebugMode) debugPrint('getUserDetails error: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Wygodny „refresh” wszystkiego na raz
  Future<void> refreshAll(dynamic ref) async {
    try {
      await Future.wait([
        getContactType(ref),
        getContactServiceType(ref),
        getContactStatus(ref),
        getUserDetails(ref),
      ]);
    } catch (_) {
      // pojedyncze metody i tak obsługują błędy i wywołują notifyListeners
    }
  }








  // contact_type_provider.dart (dopisz do klasy ContactTypeProvider)

  // Create a new contact type
  Future<void> createContactType(dynamic ref, ContactTypeModel newType) async {
    try {
      final resp = await ApiServices.post(
        CrmUrls.contactType, // e.g. POST /api/contact-types/
        hasToken: true,
        data: {
          'contact_type': newType.contactType,
          'label': newType.label,
          'index': newType.index,
        },
      );
      if (resp != null && (resp.statusCode == 200 || resp.statusCode == 201)) {
        await getContactType(ref);
      }
    } catch (_) {
      // Keep silent; UI stays responsive
    } finally {
      notifyListeners();
    }
  }

  // Update existing contact type
  Future<void> updateContactType(dynamic ref, ContactTypeModel updated) async {
    try {
      final resp = await ApiServices.patch(
        '${CrmUrls.contactType}${updated.id}/',
        hasToken: true,
        data: {
          'contact_type': updated.contactType,
          'label': updated.label,
          'index': updated.index,
        },
      );
      if (resp != null && (resp.statusCode == 200 || resp.statusCode == 202)) {
        await getContactType(ref);
      }
    } catch (_) {
    } finally {
      notifyListeners();
    }
  }

  // Delete contact type
  Future<void> deleteContactType(dynamic ref, int id) async {
    try {
      final resp = await ApiServices.delete(
        '${CrmUrls.contactType}$id/',
        hasToken: true,
      );
      if (resp != null && (resp.statusCode == 200 || resp.statusCode == 204 || resp.statusCode == 202)) {
        await getContactType(ref);
      }
    } catch (_) {
    } finally {
      notifyListeners();
    }
  }

  // Reorder (bulk update indices)
  Future<void> reorderContactTypes(dynamic ref, List<ContactTypeModel> reordered) async {
    try {
      // Try bulk PATCH; if you have a different endpoint, change here.
      final resp = await ApiServices.patch(
        '${CrmUrls.contactType}reorder/', // e.g. PATCH /api/contact-types/reorder/
        hasToken: true,
        data: {
          'items': reordered
              .map((t) => {
                    'id': t.id,
                    'index': t.index,
                  })
              .toList(),
        },
      );
      if (resp != null && (resp.statusCode == 200 || resp.statusCode == 202)) {
        await getContactType(ref);
      } else {
        // Fallback: refresh anyway
        await getContactType(ref);
      }
    } catch (_) {
      await getContactType(ref);
    } finally {
      notifyListeners();
    }
  }


  /// Ręczny „ping” na rebuild
  void resetState() {
    notifyListeners();
  }
}
