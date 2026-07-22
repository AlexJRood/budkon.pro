class BzpWynikModel {
  final String bzpId;
  final String tytul;
  final String zamawiajacy;
  final String opis;
  final DateTime? terminSkladania;
  final String? lokalizacja;
  final List<String> cpvKody;
  final String? url;
  final String? noticeNumber;
  final DateTime? publicationDate;

  const BzpWynikModel({
    required this.bzpId,
    required this.tytul,
    required this.zamawiajacy,
    required this.opis,
    this.terminSkladania,
    this.lokalizacja,
    required this.cpvKody,
    this.url,
    this.noticeNumber,
    this.publicationDate,
  });

  factory BzpWynikModel.fromJson(Map<String, dynamic> j) {
    DateTime? _dt(String? s) {
      if (s == null) return null;
      try {
        return DateTime.parse(s).toLocal();
      } catch (_) {
        return null;
      }
    }

    final cpvRaw = (j['cpv_kody'] as List?)?.cast<String>() ?? [];

    return BzpWynikModel(
      bzpId: j['bzp_id'] as String? ?? '',
      tytul: j['tytul'] as String? ?? '',
      zamawiajacy: j['zamawiajacy'] as String? ?? '',
      opis: j['opis'] as String? ?? '',
      terminSkladania: _dt(j['termin_skladania'] as String?),
      lokalizacja: j['lokalizacja'] as String?,
      cpvKody: cpvRaw,
      url: j['url'] as String?,
      noticeNumber: j['notice_number'] as String?,
      publicationDate: _dt(j['publication_date'] as String?),
    );
  }

  int? get dniDoTerminu {
    if (terminSkladania == null) return null;
    return terminSkladania!.difference(DateTime.now()).inDays;
  }
}
