
import 'dart:convert';
import 'package:association/association_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:association/models/overview_models.dart';


// ---------- Providers ----------

/// Family provider pobiera overview dla danego stowarzyszenia.
/// Jeśli [associationId] == null, backend sam wybierze jedyne stowarzyszenie usera.
// typ parametru to rekord:
typedef OverviewArgs = ({int? associationId, int days});

final associationOverviewProvider =
    FutureProvider.family.autoDispose<AssociationOverview, OverviewArgs>((ref, args) async {
  final uri = Uri.parse(AssociationUrls.associationsOverview).replace(queryParameters: {
    if (args.associationId != null) 'association_id': '${args.associationId}',
    'days': '${args.days}',
  });
  final resp = await ApiServices.get(ref: ref, uri.toString(), hasToken: true);
  if (resp == null) throw Exception('No response');
  if (resp.statusCode != 200) {
    try {
      final decoded = utf8.decode(resp.data);
      throw Exception('HTTP ${resp.statusCode}: $decoded');
    } catch (_) {
      throw Exception('HTTP ${resp.statusCode}');
    }
  }
  final decodedBody = utf8.decode(resp.data);
  return AssociationOverview.fromJson(json.decode(decodedBody));
});




