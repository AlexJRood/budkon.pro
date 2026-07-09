import 'package:core/platform/url.dart';

/// reports feature API endpoints, decentralized out of core's URLs God-package.
class ReportsUrls {
  const ReportsUrls._();

static String airQuality({required String address, required String city}) =>
      '${URLs.appendBaseUrl('/reports/air-quality/')}?address=${Uri.encodeQueryComponent(address)}&city=${Uri.encodeQueryComponent(city)}';
static final createAdreport = URLs.appendBaseUrl('/reports/ad-portal/');
static final createNmReport = URLs.appendBaseUrl('/reports/ad-nm/');
static final createReport = URLs.appendBaseUrl('/reports/');
static final dashboardreport = URLs.appendBaseUrl('/reports/landing-page/');
static String floodRisk({required String address, required String city}) =>
      '${URLs.appendBaseUrl('/reports/flood-risk/')}?address=${Uri.encodeQueryComponent(address)}&city=${Uri.encodeQueryComponent(city)}';
static final getReports = URLs.appendBaseUrl('/reports/');
static String marketVelocityForReport({
    String? city,
    String? state,
    String? country,
    String? estateType,
  }) {
    final base = URLs.appendBaseUrl('/reports/market-velocity/');
    final params = <String>[];
    if (city != null && city.isNotEmpty) params.add('city=$city');
    if (state != null && state.isNotEmpty) params.add('state=$state');
    if (country != null && country.isNotEmpty) params.add('country=$country');
    if (estateType != null && estateType.isNotEmpty) params.add('estate_type=$estateType');
    if (params.isEmpty) return base;
    return '$base?${params.join('&')}';
  }
static String neighborhoodDemographics({required String city}) =>
      '${URLs.appendBaseUrl('/reports/neighborhood-demographics/')}?city=${Uri.encodeQueryComponent(city)}';
static String poi({required String address, required String city, int radius = 1000}) =>
      '${URLs.appendBaseUrl('/reports/poi/')}?address=${Uri.encodeQueryComponent(address)}&city=${Uri.encodeQueryComponent(city)}&radius=$radius';
static String priceTrendForReport({
    required String city,
    String? estateType,
    String? offerType,
    int months = 24,
  }) {
    final base = URLs.appendBaseUrl('/reports/price-trend/');
    final params = <String>['city=${Uri.encodeQueryComponent(city)}', 'months=$months'];
    if (estateType != null && estateType.isNotEmpty) params.add('estate_type=${Uri.encodeQueryComponent(estateType)}');
    if (offerType != null && offerType.isNotEmpty) params.add('offer_type=${Uri.encodeQueryComponent(offerType)}');
    return '$base?${params.join('&')}';
  }
static String reportShare(int reportId) => '${URLs.baseUrl}/reports/$reportId/share/';
static String reportTemplate(int id) => '${URLs.baseUrl}/reports/templates/$id/';
static String reportTemplateLogo(int id) => '${URLs.baseUrl}/reports/templates/$id/logo/';
static String reportTemplateSetDefault(int id) => '${URLs.baseUrl}/reports/templates/$id/set-default/';
static const String reportTemplates = '${URLs.baseUrl}/reports/templates/';
static String singlePdfReport(int reportId) =>
      URLs.appendBaseUrl('/reports/$reportId/pdf/');
static String singleReport(int reportId) =>
      URLs.appendBaseUrl('/reports/$reportId/');
}
