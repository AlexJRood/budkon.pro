import 'package:core/platform/url.dart';

/// docs feature API endpoints, decentralized out of core's URLs God-package.
class DocsUrls {
  const DocsUrls._();

static String document(String id) => '${URLs.baseUrl}/docs/documents/$id/';
static String documentComment(String id) =>
    '${URLs.baseUrl}/docs/document-comments/$id/';
static const String documentComments =
    '${URLs.baseUrl}/docs/document-comments/';
static const String documentVersions =
    '${URLs.baseUrl}/docs/document-versions/';
static String documentWebSocket(String documentId) =>
      '${URLs.webSocketUrl}/ws/document/$documentId/';
static const String documents = '${URLs.baseUrl}/docs/documents/';
static String fillSession(String id) =>
    '${URLs.baseUrl}/docs/fill-sessions/$id/';
static const String fillSessions =
    '${URLs.baseUrl}/docs/fill-sessions/';
static const String generatedDocuments =
    '${URLs.baseUrl}/docs/generated-documents/';
static String publicFillSession(String token) =>
    '${URLs.baseUrl}/docs/public/fill-session/$token/';
static String template(String id) => '${URLs.baseUrl}/docs/templates/$id/';
static String templateField(String id) =>
    '${URLs.baseUrl}/docs/template-fields/$id/';
static const String templateFields = '${URLs.baseUrl}/docs/template-fields/';
static const String templates = '${URLs.baseUrl}/docs/templates/';
}
