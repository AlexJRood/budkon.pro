// lib/emma/routing/emma_module_resolver.dart
import 'package:core/platform/route_constant.dart';

/// Resolves Emma "module" based on current route path.
/// Uses your Routes constants + a few safe heuristics (contains/endsWith) for nested routes.
///
/// Returned values are module ids like:
/// - dynamic_app, email, calendar, finance, tms, docs, cloud, network_monitoring, reports, fav, settings, portal, association, crm, unknown
class EmmaModuleResolver {
  static String resolve(String rawRoute) {
    final p = _normalizePath(rawRoute);

    // ---------------- DYNAMIC APP ----------------
    // You have both "/dynamic-app" and "/dynamic/..." paths (api studio etc.)
    if (_startsWithAny(p, const [
      Routes.dynamic, // /dynamic-app
      Routes.dynamicApiStudio, // /dynamic/api-studio
      '/dynamic', // catch-all for /dynamic/*
      '/dynamic_app', // legacy fallback
    ])) {
      return 'dynamic_app';
    }

    // ---------------- EMAIL ----------------
    if (_startsWithAny(p, const [
      Routes.emailView, // /email
    ])) {
      return 'email';
    }
    // /leads-panel/:id/email
    if (p.startsWith(Routes.leadsPanel) && p.contains('/email')) {
      return 'email';
    }

    // ---------------- CALENDAR ----------------
    if (_startsWithAny(p, const [
      Routes.proCalendar, // /pro/calendar
    ])) {
      return 'calendar';
    }
    // Association calendar paths include "/association/admin/.../calendar"
    if (p.startsWith(Routes.association) && p.contains('/calendar')) {
      return 'calendar';
    }

    // ---------------- FINANCE ----------------
    if (_startsWithAny(p, const [
      Routes.proFinance, // /pro/finance
      Routes.invoiceGenerator, // /invoice-generator
      Routes.invoiceItems, // /invoice-items
      Routes.invoiceTemplateList, // /invoice-template-list
      Routes.dataImporter, // /data-importer
    ])) {
      return 'finance';
    }
    // Association finance paths include "/association/admin/.../finance"
    if (p.startsWith(Routes.association) && p.contains('/finance')) {
      return 'finance';
    }

    // ---------------- TASKS / TMS ----------------
    if (_startsWithAny(p, const [
      Routes.proTodo, // /pro/todo
      Routes.proBoard, // /pro/board
      Routes.proTx, // /pro/transactions
      Routes.proTxDraft, // /pro/transactions/drafts
      Routes.proTxDashboard, // /pro/transactions/dashboard
    ])) {
      return 'tms';
    }

    // ---------------- CRM / LEADS PANEL ----------------
    if (_startsWithAny(p, const [
      Routes.leadsPanel, // /leads-panel
      Routes.leadsBoard, // /leads-board
      Routes.leadsPanelFilters, // /leads-panel/filters
      Routes.leadsPanelSort, // /leads-panel/sort
      Routes.leadsBoardFilters, // /leads-board/filters
      Routes.addLead, // /leads-add
    ])) {
      return 'crm';
    }

    // ---------------- DOCS / CLOUD ----------------
    if (_startsWithAny(p, const [
      Routes.docs, // /docs
    ])) {
      return 'docs';
    }
    if (_startsWithAny(p, const [
      Routes.cloudStorage, // /cloud
    ])) {
      return 'cloud';
    }

    // ---------------- NETWORK MONITORING ----------------
    if (_startsWithAny(p, const [
      Routes.networkMonitoring, // /network-monitoring
      Routes.homeNetworkMonitoring, // /home-network-monitoring
      Routes.saveNetworkMonitoring, // /save-network-monitoring
      Routes.networkMonitorigManagment, // /nm-managment
    ])) {
      return 'network_monitoring';
    }

    // ---------------- REPORTS ----------------
    if (_startsWithAny(p, const [
      Routes.reports, // /reports
      Routes.allReports, // /all-reports
      Routes.createReport, // /create-report
      Routes.reportResult, // /compare
      '/compare-pdf', // routes contain params, prefix is enough
      Routes.dashboardReport, // /dashboard-report
    ])) {
      return 'reports';
    }

    // ---------------- FAV ----------------
    if (_startsWithAny(p, const [
      Routes.fav, // /fav
      Routes.favBoardDetailsBase, // /board-details
      Routes.crmFav, // /pro/fav
    ])) {
      return 'fav';
    }

    // ---------------- SETTINGS ----------------
    if (_startsWithAny(p, const [
      Routes.settings, // /settings
    ])) {
      return 'settings';
    }

    // ---------------- ASSOCIATION ----------------
    if (_startsWithAny(p, const [
      Routes.association, // /association
    ])) {
      return 'association';
    }

    // ---------------- CHAT / AI ----------------
    if (_startsWithAny(p, const [
      Routes.chatAi, // /chat-ai
      Routes.chat, // /chat
    ])) {
      return 'chat';
    }

    // ---------------- PORTAL / PUBLIC ----------------
    // Root and common public pages.
    if (_startsWithAny(p, const [
      Routes.entry, // /
      Routes.feedView, // /feed
      Routes.profile, // /profile
      Routes.company, // /company
      Routes.seller, // /seller
      Routes.learnCenter, // /learnCenter
      Routes.termsAndPolicy, // /terms-and-policy
      Routes.sellPage, // /sprzedaj-nieruchomosc
      Routes.rentPage, // /wynajmnij-nieruchomość
      Routes.aboutusview, // /aboutusview
      Routes.articlePage, // /read
    ])) {
      return 'portal';
    }

    return 'unknown';
  }

  static String _normalizePath(String rawRoute) {
    // Keep only the "path" part, ignore query params.
    // Also tolerate Beamer/hash fallback, but main.dart already normalizes strongly.
    final uri = Uri.tryParse(rawRoute.trim());
    var path = (uri?.path.isNotEmpty == true) ? uri!.path : rawRoute.trim();

    // If hash strategy leaks into the string, try to recover "/path" from fragment.
    if (path.isEmpty || path == '/') {
      final frag = uri?.fragment ?? '';
      if (frag.isNotEmpty) {
        final maybe = frag.startsWith('/') ? frag : '/$frag';
        final fragUri = Uri.tryParse(maybe);
        path = fragUri?.path ?? maybe;
      }
    }

    if (!path.startsWith('/')) path = '/$path';
    path = path.toLowerCase();

    // Remove trailing slash except root.
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return path;
  }

  static bool _startsWithAny(String p, List<String> prefixes) {
    for (final pre in prefixes) {
      final n = _normalizePrefix(pre);
      if (n == '/') {
        if (p == '/') return true;
        continue;
      }
      if (p.startsWith(n)) return true;
    }
    return false;
  }

  static String _normalizePrefix(String pre) {
    var s = pre.trim().toLowerCase();
    if (s.isEmpty) return '/';
    if (!s.startsWith('/')) s = '/$s';
    if (s.length > 1 && s.endsWith('/')) s = s.substring(0, s.length - 1);
    return s;
  }
}
