import 'package:core/platform/url.dart';

/// crm_agent feature API endpoints, decentralized out of core's URLs God-package.
class CrmAgentUrls {
  const CrmAgentUrls._();

static const String agentKwPreview = '${URLs.baseUrl}/agent/kw/preview/';
static final buyTransAction = URLs.appendBaseUrl('/agent/add/buy/offer/');
static final estateViewing = URLs.appendBaseUrl('/agent/add/viewer/');
static final financeChartData = URLs.appendBaseUrl('/finance/chart/');
static final sellTransAction = URLs.appendBaseUrl('/agent/add/sell/offer/');
}
