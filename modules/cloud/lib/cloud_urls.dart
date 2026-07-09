import 'package:core/platform/url.dart';

/// cloud feature API endpoints, decentralized out of core's URLs God-package.
class CloudUrls {
  const CloudUrls._();

static final exploreDownloadZip = URLs.appendBaseUrl('/storage/explorer/download-zip/');
static final filaShares = URLs.appendBaseUrl('/storage/file-shares/');
static final folderShares = URLs.appendBaseUrl('/storage/folder-shares/');
}
