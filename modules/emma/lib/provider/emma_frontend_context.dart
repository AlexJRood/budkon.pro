// budkon: dynamic_app removed — buildDynamicAppNodeSnapshotContext not used here.

Map<String, dynamic> buildDynamicAppNodeSnapshotContext({
  required dynamic ref,
  required int appId,
  required int pageId,
  required String ownerKey,
  String? nodeId,
  List<int>? nodePath,
  String? nodeKind,
}) =>
    {'owner_key': ownerKey, 'app_id': appId, 'page_id': pageId};
