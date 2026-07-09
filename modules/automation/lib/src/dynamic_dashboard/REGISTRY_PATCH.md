# Dynamic Dashboard integration

Your current dynamic dashboard registry follows this pattern:

```dart
final dashboardWidgetRegistryProvider = Provider<DashboardWidgetRegistry>((ref) {
  return DashboardWidgetRegistry(const [
    WelcomeHeaderWidgetSpec(),
    // ...
    CompanyMembersWidgetSpec(),
  ]);
});
```

Add the Automation Studio widget spec to this list:

```dart
import 'package:automation_studio/automation_studio.dart';
// If you keep the adapter in your app:
import 'package:crm/dynamic_dashboard/widgets/automation_studio_dashboard_widget_spec.dart';

final dashboardWidgetRegistryProvider = Provider<DashboardWidgetRegistry>((ref) {
  return DashboardWidgetRegistry(const [
    WelcomeHeaderWidgetSpec(),
    MarketOverviewWidgetSpec(),
    LastMonthStatsWidgetSpec(),
    CalendarWidgetSpec(),
    RecentLeadsWidgetSpec(),
    FavoriteAdsWidgetSpec(),
    FinancialWidgetSpec(),
    EarningsChartWidgetSpec(),

    MailDashboardWidgetSpec(),
    TmsDashboardWidgetSpec(),
    CloudRecentWidgetSpec(),

    AssociationWelcomeHeaderWidgetSpec(),
    AssociationOverviewWidgetSpec(),
    AssociationAnnouncementsWidgetSpec(),
    AssociationMembershipStatusWidgetSpec(),
    AssociationLoyaltyWidgetSpec(),

    ClientProfileWidgetSpec(),
    ClientDetailsWidgetSpec(),
    ClientEventsWidgetSpec(),
    ClientTransactionsWidgetSpec(),
    ClientTodoWidgetSpec(),
    CloudShortcutWidgetSpec(),
    CompanyMembersWidgetSpec(),

    AutomationStudioDashboardWidgetSpec(),
  ]);
});
```

The adapter file is in this folder:

```txt
docs/dynamic_dashboard/automation_studio_dashboard_widget_spec.dart
```

Why it is in `docs/` and not exported from `lib/`:

- the reusable package cannot safely import `package:crm/dynamic_dashboard/...`;
- the app-specific `DashboardWidgetSpec`, `DashboardGridSize`, `DashboardWidgetConstraints` live in your CRM app;
- the real widget is exported from the package as `AutomationStudioDashboardWidget`;
- the adapter/spec should live in the host CRM app where those dashboard classes exist.

## Required wrapper

Place `AutomationStudioConfigScope` above your dashboard route/screen:

```dart
AutomationStudioConfigScope(
  config: AutomationStudioConfig(
    baseUrl: 'https://www.superbee.cloud',
    tokenProvider: () async => await SecureStorage.getToken(),
    translate: (context, key) => key.tr,
    colorsResolver: (context) {
      final theme = ref.watch(themeColorsProvider);
      return AutomationStudioColors(
        background: theme.backgroundColor,
        surface: theme.dashboardContainer,
        surfaceAlt: theme.popupcontainercolor,
        border: theme.dashboardBoarder,
        primary: theme.themeColor,
        text: theme.textColor,
        mutedText: theme.textColor.withAlpha(170),
        success: Colors.green,
        danger: Colors.red,
        warning: Colors.orange,
        shadow: Colors.black.withAlpha(35),
      );
    },
  ),
  child: YourDynamicDashboardScreen(),
)
```

If `theme.backgroundColor` does not exist in your `ThemeColors`, use your closest app background property.
