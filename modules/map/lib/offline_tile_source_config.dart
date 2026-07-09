// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';

// @immutable
// class OfflineTileSourceConfig {
//   final String providerId;
//   final String providerLabel;
//   final String urlTemplate;
//   final String userAgentPackageName;
//   final List<String> subdomains;
//   final Map<String, String> additionalOptions;
//   final Map<String, String>? headers;

//   /// Must stay false for public OSM tiles.
//   final bool allowBulkDownload;

//   /// Browse cache can still be enabled even if bulk download is forbidden.
//   final bool allowBrowseCache;

//   final String browseStoreName;
//   final Duration cachedValidDuration;

//   const OfflineTileSourceConfig({
//     required this.providerId,
//     required this.providerLabel,
//     required this.urlTemplate,
//     required this.userAgentPackageName,
//     this.subdomains = const [],
//     this.additionalOptions = const {},
//     this.headers,
//     this.allowBulkDownload = false,
//     this.allowBrowseCache = true,
//     this.browseStoreName = 'browse_default',
//     this.cachedValidDuration = const Duration(days: 14),
//   });

//   String cityStoreName(String packId) => 'city_pack__${providerId}__$packId';

//   TileLayer toTileLayer({
//     TileProvider? tileProvider,
//   }) {
//     return TileLayer(
//       urlTemplate: urlTemplate,
//       userAgentPackageName: userAgentPackageName,
//       subdomains: subdomains,
//       additionalOptions: additionalOptions,
//       tileProvider: tileProvider,
//     );
//   }
// }

// /// Safe default for your current public OSM setup:
// const portalPublicOsmTileSource = OfflineTileSourceConfig(
//   providerId: 'osm_public',
//   providerLabel: 'OpenStreetMap Public',
//   urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//   userAgentPackageName: 'cloud.hously.portal',
//   allowBulkDownload: false,
//   allowBrowseCache: true,
//   browseStoreName: 'portal_browse_osm_public',
// );

// /// Example for a provider / own server that explicitly allows offline packs:
// const portalOfflineCapableTileSource = OfflineTileSourceConfig(
//   providerId: 'offline_capable',
//   providerLabel: 'Offline-Capable Tiles',
//   urlTemplate: 'https://your-tile-server/{z}/{x}/{y}.png',
//   userAgentPackageName: 'cloud.hously.portal',
//   allowBulkDownload: true,
//   allowBrowseCache: true,
//   browseStoreName: 'portal_browse_offline_capable',
// );