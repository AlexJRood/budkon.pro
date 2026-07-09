// lib/safehouse/url.dart

class URLsInvoice {
  static const httpOrHttps = 'https';
  static const host = 'www.superbee.cloud';

  // REST base
  static const baseUrl = '$httpOrHttps://$host/finance/';
  static const urlNetworkMonitoring = 'http://www.hously.space';

  static String appendBaseUrl(String url) => '$baseUrl$url';

  // --- REST endpoints ---
  static final invoiceTemplatesActive = appendBaseUrl('invoice-templates/active/');
  static final invoiceTemplates = appendBaseUrl('invoice-templates/');
  static final invoiceItemPresets = appendBaseUrl('invoice-item-presets/');

}
