import 'package:core/platform/url.dart';

/// profile feature API endpoints, decentralized out of core's URLs God-package.
class ProfileUrls {
  const ProfileUrls._();

static final companyBackground = URLs.appendBaseUrl('/user/companies/upload_background/');
static String publicCompany(String companyId) =>
      URLs.appendBaseUrl('/user/companies/$companyId/');
static String publicProfile(String userId) =>
      URLs.appendBaseUrl('/user/profile/$userId/');
}
