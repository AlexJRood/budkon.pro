import 'package:core/platform/url.dart';

/// association feature API endpoints, decentralized out of core's URLs God-package.
class AssociationUrls {
  const AssociationUrls._();

  static const String _assoc = '/association';
  static final associationMembers = URLs.appendBaseUrl('$_assoc/members/');
  static final associationApplications = URLs.appendBaseUrl('$_assoc/applications/');
  static final associationRequestOptions = URLs.appendBaseUrl(
    '$_assoc/request-options/',
  );
  static final associationRequests = URLs.appendBaseUrl('$_assoc/requests/');
  static final associationAnnouncements = URLs.appendBaseUrl(
    '$_assoc/announcements/',
  );
  static final associationRoles = URLs.appendBaseUrl('$_assoc/roles/');
  static final associationAudit = URLs.appendBaseUrl('$_assoc/audit/');
  static final associationIntegrations = URLs.appendBaseUrl('$_assoc/integrations/');
  static final associationAgreements = URLs.appendBaseUrl('$_assoc/agreements/');
  static final associationAgreementVersions = URLs.appendBaseUrl(
    '$_assoc/agreement-versions/',
  );
  static final associationConsents = URLs.appendBaseUrl('$_assoc/consents/');
  static final associationsOverview = URLs.appendBaseUrl('$_assoc/overview/');
  static String associationMemberDetail(dynamic id) =>
      URLs.appendBaseUrl('$_assoc/members/$id/');
  static String associationApplicationDetail(dynamic id) =>
      URLs.appendBaseUrl('$_assoc/applications/$id/');
  static String associationRequestDetail(dynamic id) =>
      URLs.appendBaseUrl('$_assoc/requests/$id/');
  static String associationAnnouncementDetail(dynamic id) =>
      URLs.appendBaseUrl('$_assoc/announcements/$id/');
  static String associationIntegrationDetail(dynamic id) =>
      URLs.appendBaseUrl('$_assoc/integrations/$id/');
  static String associationAgreementDetail(dynamic id) =>
      URLs.appendBaseUrl('$_assoc/agreements/$id/');
  static String associationAgreementVersionDetail(dynamic id) =>
      URLs.appendBaseUrl('$_assoc/agreement-versions/$id/');
  static String associationMemberActivate(dynamic id) =>
      URLs.appendBaseUrl('$_assoc/members/$id/activate/');
  static String associationMemberSuspend(dynamic id) =>
      URLs.appendBaseUrl('$_assoc/members/$id/suspend/');
  static String associationApplicationReview(dynamic id) =>
      URLs.appendBaseUrl('$_assoc/applications/$id/review/');
  static String associationRequestAddAttachment(dynamic id) =>
      URLs.appendBaseUrl('$_assoc/requests/$id/add_attachment/');
  static String associationRequestMessage(dynamic id) =>
      URLs.appendBaseUrl('$_assoc/requests/$id/message/');
  static String associationAnnouncementAddAttachment(dynamic id) =>
      URLs.appendBaseUrl('$_assoc/announcements/$id/add_attachment/');
  static final associationAgreementCurrent = URLs.appendBaseUrl(
    '$_assoc/agreements/current/',
  );
  static final associationConsentAccept = URLs.appendBaseUrl(
    '$_assoc/consents/accept/',
  );
  static final associationConsentWithdraw = URLs.appendBaseUrl(
    '$_assoc/consents/withdraw/',
  );
  static String associationsOverviewWith({int? associationId, int days = 30}) {
    final qp = <String, String>{'days': '$days'};
    if (associationId != null) qp['association_id'] = '$associationId';
    final q = qp.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '${associationsOverview}?$q';
  }
}
