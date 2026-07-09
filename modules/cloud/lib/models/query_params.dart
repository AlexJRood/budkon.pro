import 'package:equatable/equatable.dart';

class FolderQueryParams extends Equatable {
  static const _unset = Object();
  final String? parent;
  final String? name;
  final int? user;
  final int? company;
  final int? team;
  final bool? isPublic;
  final DateTime? createdAtFrom;
  final DateTime? createdAtTo;
  final DateTime? updatedAtFrom;
  final DateTime? updatedAtTo;
  final String? search;
  final String? ordering;
  final int? page;
  final bool showAllFiles;

  // Assignment (pin to object)
  final String? appLabel; // app_label w DRF
  final String? model; // model w DRF
  final String? objectId; // object_id w DRF
  final String? relationType; // relation_type w DRF

  final String? additionalSection; // <-- NOWE
  final String? contents;
  final bool? isDeleted;
  final String? fileType;

  FolderQueryParams copyWith({
  Object? parent = _unset,
  Object? name = _unset,
  Object? user = _unset,
  Object? company = _unset,
  Object? team = _unset,
  Object? isPublic = _unset,
  Object? createdAtFrom = _unset,
  Object? createdAtTo = _unset,
  Object? updatedAtFrom = _unset,
  Object? updatedAtTo = _unset,
  Object? search = _unset,
  Object? ordering = _unset,
  Object? page = _unset,
  Object? appLabel = _unset,
  Object? model = _unset,
  Object? objectId = _unset,
  Object? relationType = _unset,
  Object? additionalSection = _unset,
  Object? contents = _unset,
  Object? fileType = _unset,
  Object? isDeleted = _unset,
  bool? showAllFiles,
}) {
  return FolderQueryParams(
    parent: parent == _unset ? this.parent : parent as String?,
    name: name == _unset ? this.name : name as String?,
    user: user == _unset ? this.user : user as int?,
    company: company == _unset ? this.company : company as int?,
    team: team == _unset ? this.team : team as int?,
    isPublic: isPublic == _unset ? this.isPublic : isPublic as bool?,
    createdAtFrom: createdAtFrom == _unset
        ? this.createdAtFrom
        : createdAtFrom as DateTime?,
    createdAtTo:
        createdAtTo == _unset ? this.createdAtTo : createdAtTo as DateTime?,
    updatedAtFrom: updatedAtFrom == _unset
        ? this.updatedAtFrom
        : updatedAtFrom as DateTime?,
    updatedAtTo:
        updatedAtTo == _unset ? this.updatedAtTo : updatedAtTo as DateTime?,
    search: search == _unset ? this.search : search as String?,
    ordering: ordering == _unset ? this.ordering : ordering as String?,
    page: page == _unset ? this.page : page as int?,
    appLabel: appLabel == _unset ? this.appLabel : appLabel as String?,
    model: model == _unset ? this.model : model as String?,
    objectId: objectId == _unset ? this.objectId : objectId as String?,
    relationType:
        relationType == _unset ? this.relationType : relationType as String?,
    additionalSection: additionalSection == _unset
        ? this.additionalSection
        : additionalSection as String?,
    contents: contents == _unset ? this.contents : contents as String?,
    fileType: fileType == _unset ? this.fileType : fileType as String?,
    isDeleted: isDeleted == _unset ? this.isDeleted : isDeleted as bool?,
    showAllFiles: showAllFiles ?? this.showAllFiles,
  );
}

  const FolderQueryParams({
    this.parent,
    this.name,
    this.user,
    this.company,
    this.team,
    this.isPublic,
    this.createdAtFrom,
    this.createdAtTo,
    this.updatedAtFrom,
    this.updatedAtTo,
    this.search,
    this.ordering,
    this.page,
    this.appLabel,
    this.model,
    this.objectId,
    this.relationType,
    this.additionalSection, // <-- NOWE
    this.contents, // <-- NOWE
    this.fileType, // <- Dodaj jeśli masz
    this.isDeleted, // <- Dodaj jeśli masz
    this.showAllFiles = false,
  });

  @override
  List<Object?> get props => [
    parent,
    name,
    user,
    company,
    team,
    isPublic,
    createdAtFrom,
    createdAtTo,
    updatedAtFrom,
    updatedAtTo,
    search,
    ordering,
    page,
    additionalSection,
    contents,
    appLabel,
    model,
    objectId,
    relationType,
    fileType,
    isDeleted,
    showAllFiles,
  ];

  Map<String, dynamic> toQuery() {
    final q = <String, dynamic>{};
    if (parent != null) q['parent'] = parent;
    if (name?.isNotEmpty == true) q['name'] = name;
    if (user != null) q['user'] = user;
    if (company != null) q['company'] = company;
    if (team != null) q['team'] = team;
    if (isPublic != null) q['is_public'] = isPublic.toString();
    if (createdAtFrom != null)
      q['created_at_after'] = createdAtFrom!.toIso8601String();
    if (createdAtTo != null)
      q['created_at_before'] = createdAtTo!.toIso8601String();
    if (updatedAtFrom != null)
      q['updated_at_after'] = updatedAtFrom!.toIso8601String();
    if (updatedAtTo != null)
      q['updated_at_before'] = updatedAtTo!.toIso8601String();
    if (search?.isNotEmpty == true) q['search'] = search;
    if (ordering?.isNotEmpty == true) q['ordering'] = ordering;
    if (page != null) q['page'] = page;
    if (appLabel?.isNotEmpty == true) q['app_label'] = appLabel;
    if (model?.isNotEmpty == true) q['model'] = model;
    if (objectId != null) q['object_id'] = objectId;
    if (relationType?.isNotEmpty == true) q['relation_type'] = relationType;
    if (fileType != null && fileType!.isNotEmpty) q['file_type'] = fileType;
    if (isDeleted != null) q['is_deleted'] = isDeleted.toString();
    return q;
  }
}
