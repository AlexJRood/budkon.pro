class DashboardURLs {
  static const baseUrl = 'https://www.superbee.cloud';
  static const httpOrHttps = 'https';
  static const webSocketUrl = 'wss://www.superbee.cloud';
  static const urlNetworkMonitoring = 'http://www.hously.space';

  static String appendBaseUrl(String url) => '$baseUrl$url';

  static final dashboardLayoutBase = appendBaseUrl('/dashboard-layout/');
  static final dashboardWidgetCatalogBase =
      appendBaseUrl('/dashboard-widgets/catalog/');
}