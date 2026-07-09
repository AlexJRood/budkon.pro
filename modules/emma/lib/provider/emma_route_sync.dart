// emma/routing/emma_route_sync.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core/platform/route_constant.dart' show Routes;
import 'package:emma/provider/context.dart';

/// Normalize raw route:
/// - supports full URLs
/// - strips query
/// - strips fragments (hash) if needed
/// - trims trailing slashes (except "/")
String normalizeEmmaRoute(String rawRoute) {
  String takePath(String s) {
    final uri = Uri.tryParse(s);
    if (uri == null) return s;

    // If path strategy -> normal case
    if (uri.path.isNotEmpty) return uri.path;

    // Hash strategy fallback
    if (uri.fragment.isNotEmpty) {
      final frag = uri.fragment.startsWith('/') ? uri.fragment : '/${uri.fragment}';
      final fragUri = Uri.tryParse(frag);
      return fragUri?.path ?? frag;
    }

    return s;
  }

  var path = takePath(rawRoute).trim();
  if (path.isEmpty) path = '/';

  // Ensure it starts with "/"
  if (!path.startsWith('/')) path = '/$path';

  // Remove trailing slashes (except root)
  path = path.replaceAll(RegExp(r'/+$'), '');
  if (path.isEmpty) path = '/';

  return path;
}

/// More accurate module resolution using YOUR Routes.
/// IMPORTANT: module is only a hint (not a hard allowlist).
String resolveEmmaModuleFromRoutes(String rawRoute) {
  final p = normalizeEmmaRoute(rawRoute).toLowerCase();

  // ---------------- DYNAMIC APP ----------------
  // Your routes:
  // Routes.dynamic = '/dynamic-app'
  // Routes.dynamicApiStudio = '/dynamic/api-studio'
  // Routes.dynamicPage = '/dynamic-app/:id'
  if (p == Routes.dynamic || p.startsWith('${Routes.dynamic}/')) return 'dynamic_app';
  if (p == Routes.dynamicApiStudio || p.startsWith('${Routes.dynamicApiStudio}/')) {
    return 'dynamic_app';
  }
  if (p.startsWith('/dynamic/')) return 'dynamic_app'; // covers /dynamic/api-studio etc

  // ---------------- EMAIL ----------------
  // Routes.emailView = '/email'
  // lead email view: '/leads-panel/:id/email' -> endsWith('/email')
  if (p == Routes.emailView || p.startsWith('${Routes.emailView}/')) return 'email';
  if (p.endsWith('/email') || p.contains('/email/')) return 'email';
  if (p == Routes.settingsMail || p.startsWith('${Routes.settingsMail}/')) return 'email';

  // ---------------- CALENDAR ----------------
  if (p == Routes.proCalendar || p.startsWith('${Routes.proCalendar}/')) return 'calendar';
  if (p == Routes.calendarSearchScreen || p.startsWith('${Routes.calendarSearchScreen}/')) {
    return 'calendar';
  }
  if (p == Routes.settingCalendar || p.startsWith('${Routes.settingCalendar}/')) return 'calendar';
  if (p.contains('/calendar')) return 'calendar'; // association calendar etc.

  // ---------------- FINANCE ----------------
  if (p == Routes.proFinance || p.startsWith('${Routes.proFinance}/')) return 'finance';
  if (p == Routes.proFinanceDashboard || p.startsWith('${Routes.proFinanceDashboard}/')) {
    return 'finance';
  }
  // Standalone invoice routes
  if (p == Routes.invoiceGenerator || p.startsWith('${Routes.invoiceGenerator}/')) return 'finance';
  if (p == Routes.invoiceItems || p.startsWith('${Routes.invoiceItems}/')) return 'finance';
  if (p == Routes.invoiceTemplateList || p.startsWith('${Routes.invoiceTemplateList}/')) {
    return 'finance';
  }
  // Association finance
  if (p.startsWith('/association') && p.contains('/finance')) return 'finance';
  if (p.contains('/invoices')) return 'finance';

  // ---------------- TMS / TASKS ----------------
  // Your to-do/board:
  if (p == Routes.proTodo || p.startsWith('${Routes.proTodo}/')) return 'tms';
  if (p == Routes.proBoard || p.startsWith('${Routes.proBoard}/')) return 'tms';
  // Transactions area (often task-like workflows)
  if (p == Routes.proTx || p.startsWith('${Routes.proTx}/')) return 'tms';
  if (p.contains('/tasks') || p.startsWith('/tms')) return 'tms';

  // ---------------- DOCS ----------------
  if (p == Routes.docs || p.startsWith('${Routes.docs}/')) return 'docs';
  // Cloud storage is “docs-like” in your app
  if (p == Routes.cloudStorage || p.startsWith('${Routes.cloudStorage}/')) return 'docs';

  // ---------------- NOTES (fallback) ----------------
  // Wall often acts like notes/comments feed
  if (p == Routes.wall || p.startsWith('${Routes.wall}/')) return 'notes';
  if (p.startsWith('/notes') || p.startsWith('/memos')) return 'notes';

  return 'unknown';
}

/// Call this on every route change.
/// It updates EmmaContext in a single place.
void syncEmmaRoute(WidgetRef ref, String rawRoute) {
  final route = normalizeEmmaRoute(rawRoute);
  final module = resolveEmmaModuleFromRoutes(route);

  ref.read(emmaContextProvider.notifier).setRouteResolved(
        route: route,
        module: module,
      );
}
