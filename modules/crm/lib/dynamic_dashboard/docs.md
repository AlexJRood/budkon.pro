# Dynamic Dashboard — dokumentacja techniczna dla AI / developera

## Cel dokumentu

Ten dokument opisuje aktualną architekturę systemu **Dynamic Dashboard**, sposób działania frontendu i backendu, kontrakty danych, oraz dokładne procedury potrzebne do:

1. dodania dashboardu w nowym miejscu aplikacji,
2. dodania nowego widgetu,
3. podpięcia widgetu do marketplace,
4. zapisania i odczytu layoutu użytkownika,
5. kontrolowania dostępów do widgetów po stronie backendu.

Dokument jest napisany tak, aby AI lub nowy developer mógł na jego podstawie bezpiecznie rozwijać moduł bez zgadywania struktury systemu.

---

# 1. Architektura całości

System składa się z **dwóch głównych warstw**:

## Frontend Flutter

Frontend odpowiada za:

* renderowanie dashboardu,
* przeciąganie widgetów,
* resize widgetów,
* tryb edycji,
* zapis układu lokalnie i zdalnie,
* pobranie katalogu widgetów z backendu,
* dodawanie widgetów z marketplace,
* renderowanie konkretnych widgetów przez registry.

Najważniejsze pliki frontendowe:

* `dynamic_dashboard_page.dart`
* `dashboard_canvas.dart`
* `dashboard_widget_shell.dart`
* `dashboard_layout_provider.dart`
* `dashboard_layout_api.dart`
* `dashboard_layout_local_storage.dart`
* `dashboard_widget_registry.dart`
* `dashboard_default_config.dart`
* `catalog_models.dart`
* `catalog_api.dart`
* `urls_dashboard.dart`

## Backend Django

Backend odpowiada za:

* przechowywanie layoutu użytkownika,
* wersjonowanie layoutu (`revision`),
* check czy zdalny layout się zmienił,
* listowanie widgetów w katalogu,
* instalowanie / odinstalowanie widgetów marketowych,
* walidację dostępu do widgetów,
* sanityzację payloadu layoutu przed zapisem.

Najważniejsze elementy backendowe:

* `UserDashboardLayout`
* `DashboardWidgetCatalog`
* `UserInstalledDashboardWidget`
* `evaluate_widget_access(...)`
* `sanitize_dashboard_payload(...)`
* `DashboardWidgetCatalogSerializer`
* widoki layoutu / katalogu / install / uninstall
* komenda seedująca katalog widgetów

---

# 2. Kluczowe pojęcia domenowe

## dashboardKey

Id dashboardu. To główny identyfikator konfiguracji.

Przykłady z kodu:

* `crm_main`
* `agent_dashboard`
* `office_owner_dashboard`
* `client_panel_dashboard`
* `association_dashboard`

To właśnie `dashboardKey` decyduje:

* jaki layout ma być pobrany z backendu,
* gdzie widget może być dostępny,
* jaki default layout powinien się wygenerować,
* jakie widgety będą widoczne w marketplace.

## breakpoint

Dashboard ma osobny layout dla:

* `desktop`
* `tablet`
* `mobile`

Każdy breakpoint ma własne:

* `columns`
* `rowHeight`
* `gap`
* `canvasPadding`
* listę `items`

## instance

Instancja widgetu na dashboardzie.

Model frontendowy:

* `DashboardWidgetInstance`

Przechowuje m.in.:

* `id`
* `type`
* `titleOverride`
* `isVisible`
* `settings`
* `zoneKey`
* `catalogSlug`
* `sourceKey`

Jedna instancja = jedno logiczne wystąpienie widgetu.

## layout item

Pozycja i rozmiar instancji na siatce.

Model frontendowy:

* `DashboardLayoutItem`

Zawiera:

* `instanceId`
* `x`
* `y`
* `w`
* `h`
* `z`

## registry

Frontendowa mapa typów widgetów -> implementacje.

Za to odpowiada:

* `DashboardWidgetRegistry`
* `DashboardWidgetSpec`

Registry wie:

* jaki widget istnieje,
* jaki ma tytuł,
* jaki ma icon,
* jaki ma default size,
* jakie ma constraints,
* jak ma zostać wyrenderowany.

## catalog / marketplace

Backendowa lista widgetów możliwych do użycia.

To nie renderuje widgetu samo z siebie. Catalog mówi frontendowi:

* co można pokazać w marketplace,
* co można dodać,
* co wymaga instalacji,
* co jest premium,
* gdzie widget jest dozwolony.

---

# 3. Flow działania systemu

## 3.1 Wejście na ekran dashboardu

`DynamicDashboardPage`:

* dostaje `dashboardKey`,
* w `initState()` woła `dashboardLayoutProvider(dashboardKey).notifier.load()`.

## 3.2 Provider ładuje dane

`DashboardLayoutNotifier.load()` robi:

1. próba odczytu lokalnego layoutu z `SharedPreferences`,
2. zapytanie do backendu `/dashboard-layout/<dashboardKey>/check/`,
3. jeśli brak zmian -> może użyć lokalnej wersji,
4. jeśli są zmiany -> pobiera pełny layout z `/dashboard-layout/<dashboardKey>/`,
5. normalizuje layout,
6. zapisuje wynik lokalnie.

## 3.3 Render dashboardu

`DashboardCanvas`:

* pobiera `config` z providera,
* pobiera `registry`,
* bierze layout dla konkretnego breakpointu,
* filtruje tylko te itemy, które:

  * mają istniejącą instancję,
  * instancja jest widoczna,
  * istnieje `spec` w registry.

Każdy kafelek renderowany jest przez `DashboardWidgetShell`, a sam widget budowany jest przez:

* `spec.build(context, ref, instance, breakpoint, isEditMode)`

## 3.4 Edycja

W trybie edit mode użytkownik może:

* przesuwać widgety,
* zmieniać rozmiar,
* usuwać,
* duplikować,
* dodawać nowe z marketplace.

Zmiany trafiają do stanu providera, a następnie przez `scheduleSave()` są debounced i wysyłane do backendu.

## 3.5 Zapis

`saveNow()`:

* zapisuje lokalnie,
* wysyła `PUT /dashboard-layout/<dashboardKey>/`,
* backend sanityzuje payload,
* backend podbija `revision`,
* frontend zapisuje nową wersję jako `lastSyncedConfig`.

---

# 4. Modele frontendowe

## DashboardConfig

Najważniejsza struktura całego layoutu.

Zawiera:

* `dashboardKey`
* `revision`
* `updatedAt`
* `layouts`
* `instances`

### Zasada

`instances` opisują **co istnieje**, a `layouts` opisują **gdzie to leży**.

To bardzo ważne: widget bez instancji nie może się wyrenderować, a instancja bez pozycji w danym breakpointcie nie będzie widoczna na tym breakpointcie.

## DashboardBreakpointLayout

Layout dla jednego breakpointu.

Zawiera:

* `columns`
* `rowHeight`
* `gap`
* `canvasPadding`
* `items`

## DashboardWidgetInstance

Logika widgetu i jego metadata.

To miejsce na:

* ustawienia widgetu,
* źródło widgetu,
* powiązanie z catalogiem,
* informacje o widoczności.

## DashboardLayoutItem

Konkretne położenie w gridzie.

---

# 5. Registry widgetów na froncie

## Cel registry

Registry jest jedynym miejscem, które mówi frontendowi, jak wyrenderować widget po `type`.

Jeżeli widget istnieje w backendowym katalogu, ale **nie ma go w registry**, frontend go nie narysuje.

## Interfejs

Każdy widget implementuje `DashboardWidgetSpec`.

Wymagane elementy:

* `type`
* `title`
* `icon`
* `defaultSize(breakpoint)`
* `constraints`
* `build(...)`

Opcjonalne flagi:

* `allowMultiple`
* `canMove`
* `canResize`

## Ważna zasada

`component_key` w backendzie **musi być identyczny** z `type` we frontendowym `DashboardWidgetSpec`.

Przykład:

* backend: `component_key = 'calendar'`
* frontend spec: `String get type => 'calendar';`

Jeśli te wartości się różnią, widget będzie widoczny w katalogu, ale nie wyrenderuje się w dashboardzie.

---

# 6. Dashboard marketplace

## Jak działa marketplace

Marketplace pobiera listę widgetów z backendu przez:

* `GET /dashboard-widgets/catalog/`

Zapytanie zawiera zwykle:

* `dashboard_key`
* `zone_key`
* `source`
* `category`
* `search`
* `installed_only`

Backend filtruje katalog i dla każdego widgetu zwraca dodatkowo:

* `is_installed`
* `can_install`
* `can_add`
* `disabled_reason`

## Różnica między native i market

### native

Widget dostępny bez instalacji.

### market

Widget może wymagać najpierw instalacji przez `UserInstalledDashboardWidget`.

## Gdy user klika Install

Frontend woła:

* `POST /dashboard-widgets/catalog/<slug>/install/`

## Gdy user klika Add

Frontend tworzy nową instancję lokalnie i dodaje ją do layoutu.

---

# 7. Backend — odpowiedzialności modeli

## UserDashboardLayout

Przechowuje layout per user + dashboard.

Pola:

* `user`
* `dashboard_key`
* `config`
* `revision`
* `created_at`
* `updated_at`

### Zasada

Jeden użytkownik może mieć osobny layout dla każdego `dashboard_key`.

## DashboardWidgetCatalog

Katalog wszystkich widgetów.

To główne źródło prawdy o tym:

* jaki widget istnieje,
* gdzie może być używany,
* czy wymaga instalacji,
* czy można dodać wiele kopii,
* jakie ma default settings i constraints.

## UserInstalledDashboardWidget

Informuje, że user zainstalował widget marketowy.

---

# 8. Backend — access control

## `evaluate_widget_access(...)`

Ta funkcja rozstrzyga, czy user może:

* zainstalować widget,
* dodać widget,
* czy widget jest aktywny,
* czy widget pasuje do `dashboard_key`, `zone_key`, roli i permissions.

### Disabled reasons

Możliwe powody blokady:

* `inactive`
* `dashboard_not_allowed`
* `zone_not_allowed`
* `role_not_allowed`
* `missing_permissions`
* `install_required`

## `sanitize_dashboard_payload(...)`

Ta funkcja jest krytyczna przy `PUT /dashboard-layout/<dashboardKey>/`.

Jej zadanie:

* odrzucić instancje widgetów, do których user nie ma prawa,
* odrzucić instancje nieistniejące w katalogu,
* poprawić `type`, `catalogSlug`, `sourceKey`,
* odfiltrować z layoutów itemy, które wskazują na usunięte instancje.

### Dlaczego to jest ważne

Frontend nie może być źródłem prawdy w zakresie uprawnień. Użytkownik mógłby ręcznie zmodyfikować payload. Backend musi to wyczyścić.

---

# 9. Endpointy backendu

## 9.1 Layout detail

### GET `/dashboard-layout/<dashboard_key>/`

Zwraca pełny layout użytkownika.

### PUT `/dashboard-layout/<dashboard_key>/`

Zapisuje layout użytkownika po sanityzacji.

## 9.2 Layout check

### GET `/dashboard-layout/<dashboard_key>/check/`

Lekki endpoint do sprawdzenia, czy layout zmienił się zdalnie.

Query params:

* `last_check`
* `local_revision`

Response:

* `has_changes`
* `revision`
* `updated_at`

## 9.3 Reset

### POST `/dashboard-layout/<dashboard_key>/reset/`

Usuwa zapisany layout użytkownika.

## 9.4 Catalog list

### GET `/dashboard-widgets/catalog/`

Zwraca katalog widgetów z access metadata.

## 9.5 Install

### POST `/dashboard-widgets/catalog/<slug>/install/`

Instaluje widget dla użytkownika.

## 9.6 Uninstall

### POST `/dashboard-widgets/catalog/<slug>/uninstall/`

Odinstalowuje widget dla użytkownika.

---

# 10. Jak dodać dashboard w nowym miejscu aplikacji

To jest procedura do użycia wtedy, gdy chcesz mieć **ten sam system dynamic dashboard** na kolejnym ekranie.

## Krok 1 — wybierz nowy `dashboardKey`

Przykład:

* `association_analytics_dashboard`
* `agent_finance_dashboard`
* `client_home_dashboard`

Zasada:

* key musi być stabilny,
* key powinien opisywać ekran,
* nie zmieniaj go później bez migracji danych, bo user straci przypisany layout.

## Krok 2 — dodaj ekran frontendowy

Najprostsza forma:

```dart
class AssociationAnalyticsDashboardScreen extends StatelessWidget {
  const AssociationAnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DynamicDashboardPage(
      dashboardKey: 'association_analytics_dashboard',
    );
  }
}
```

## Krok 3 — dodaj route / miejsce osadzenia

Podepnij nowy ekran do routingu lub do wybranego modułu UI.

## Krok 4 — dodaj `dashboardKey` do backendowego katalogu widgetów

Jeżeli widgety mają być dostępne na tym nowym ekranie, backend musi wiedzieć, że wolno ich tam używać.

W praktyce:

* dodaj key do `dashboard_keys` w seedzie lub w danych katalogowych,
* albo ustaw per-widget osobne dozwolone dashboardy.

Przykład:

```python
COMMON_DASHBOARD_KEYS = [
    'crm_main',
    'agent_dashboard',
    'office_owner_dashboard',
    'client_panel_dashboard',
    'association_dashboard',
    'association_analytics_dashboard',
]
```

## Krok 5 — dodaj default config dla nowego dashboardu

Aktualnie `buildDefaultDashboardConfig(...)` zwraca jeden wspólny układ. Jeżeli nowy ekran ma mieć inny zestaw startowych widgetów, trzeba rozbudować factory.

Najlepszy kierunek:

```dart
DashboardConfig buildDefaultDashboardConfig({
  required String dashboardKey,
  required DashboardWidgetRegistry registry,
}) {
  switch (dashboardKey) {
    case 'association_analytics_dashboard':
      return buildAssociationAnalyticsDefaultConfig(registry: registry);
    case 'crm_main':
    default:
      return buildCrmMainDefaultConfig(registry: registry);
  }
}
```

## Krok 6 — upewnij się, że backendowy reset działa dla nowego key

Nie wymaga dodatkowego kodu, jeśli route jest już generyczne po `dashboard_key`.

## Krok 7 — sprawdź marketplace

Nowy dashboard musi wysyłać swój `dashboardKey` do catalog API, żeby backend poprawnie przefiltrował dozwolone widgety.

---

# 11. Jak dodać nowy widget — pełna procedura

Ta sekcja opisuje pełny proces od zera.

## Krok 1 — stwórz UI widgetu

Najpierw tworzysz zwykły widget Flutter.

Przykład:

```dart
class DashboardTasksWidget extends ConsumerWidget {
  const DashboardTasksWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      alignment: Alignment.center,
      child: const Text('Tasks widget'),
    );
  }
}
```

## Krok 2 — dodaj `DashboardWidgetSpec`

```dart
class TasksWidgetSpec extends DashboardWidgetSpec {
  const TasksWidgetSpec();

  @override
  String get type => 'tasks';

  @override
  String get title => 'Tasks';

  @override
  IconData get icon => Icons.checklist_rounded;

  @override
  bool get allowMultiple => false;

  @override
  DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) {
    switch (breakpoint) {
      case DashboardBreakpoint.desktop:
        return const DashboardGridSize(w: 4, h: 4);
      case DashboardBreakpoint.tablet:
        return const DashboardGridSize(w: 4, h: 4);
      case DashboardBreakpoint.mobile:
        return const DashboardGridSize(w: 4, h: 4);
    }
  }

  @override
  DashboardWidgetConstraints get constraints =>
      const DashboardWidgetConstraints(
        minW: 2,
        maxW: 8,
        minH: 2,
        maxH: 8,
      );

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetInstance instance,
    DashboardBreakpoint breakpoint,
    bool isEditMode,
  ) {
    return const DashboardTasksWidget();
  }
}
```

## Krok 3 — dodaj widget do registry

```dart
final dashboardWidgetRegistryProvider = Provider<DashboardWidgetRegistry>((ref) {
  return DashboardWidgetRegistry(const [
    WelcomeHeaderWidgetSpec(),
    MarketOverviewWidgetSpec(),
    LastMonthStatsWidgetSpec(),
    CalendarWidgetSpec(),
    RecentLeadsChartWidgetSpec(),
    FavoriteAdsWidgetSpec(),
    FinancialWidgetSpec(),
    EarningsChartWidgetSpec(),
    TasksWidgetSpec(),
  ]);
});
```

## Krok 4 — dodaj widget do backendowego katalogu

Dodaj wpis do seed command lub panelu zarządzania katalogiem.

Przykład:

```python
{
    'slug': 'tasks',
    'component_key': 'tasks',
    'title': 'Tasks',
    'description': 'Task list widget.',
    'icon': 'checklist_rounded',
    'category': 'productivity',
    'source': 'native',
    'dashboard_keys': COMMON_DASHBOARD_KEYS,
    'allowed_zones': ['main'],
    'allowed_roles': [],
    'required_permissions': [],
    'allow_multiple': False,
    'requires_installation': False,
    'default_settings': {},
    'default_sizes': {
        'desktop': {'w': 4, 'h': 4},
        'tablet': {'w': 4, 'h': 4},
        'mobile': {'w': 4, 'h': 4},
    },
    'constraints': {'minW': 2, 'maxW': 8, 'minH': 2, 'maxH': 8},
    'sort_order': 90,
}
```

## Krok 5 — seed / update katalogu

Uruchom komendę seedującą lub zaktualizuj rekord w bazie.

## Krok 6 — opcjonalnie dodaj widget do default layoutu

Jeżeli ma pojawiać się od razu użytkownikowi, dodaj go do `buildDefaultDashboardConfig(...)`.

Jeżeli ma być tylko dostępny w marketplace, nic więcej nie trzeba.

---

# 12. Jak dodać widget marketowy

Widget marketowy różni się od native głównie tym, że może wymagać instalacji.

## Warunki

W katalogu ustaw:

* `source = 'market'`
* `requires_installation = True`

## Flow

1. user widzi widget w marketplace,
2. `can_install = true`,
3. user klika Install,
4. backend tworzy `UserInstalledDashboardWidget`,
5. ponowny fetch catalogu zwraca `is_installed = true`, `can_add = true`,
6. user może kliknąć Add.

## Ważne

Nawet widget marketowy nadal **musi istnieć w frontend registry**, bo inaczej nie wyrenderuje się po dodaniu.

Jeżeli kiedyś chcesz zrobić prawdziwie zdalny plugin system, trzeba będzie dodać osobną warstwę renderowania dynamicznego. Obecna architektura nie wspiera ładowania kodu widgetu z backendu.

---

# 13. Jak ustawić inny default layout dla różnych ekranów

Aktualnie `buildDefaultDashboardConfig(...)` zwraca stały zestaw widgetów. To działa, ale słabo się skaluje.

## Rekomendowany kierunek

Rozdziel default layouty per dashboard:

* `buildCrmMainDefaultConfig(...)`
* `buildAgentDashboardDefaultConfig(...)`
* `buildAssociationDashboardDefaultConfig(...)`
* `buildClientPanelDefaultConfig(...)`

I wybieraj je po `dashboardKey`.

## Dlaczego to ważne

Różne ekrany zwykle mają inne cele biznesowe:

* CRM dashboard — KPI, leady, kalendarz,
* association dashboard — członkowie, płatności, komunikacja,
* client dashboard — ulubione oferty, statusy, wiadomości.

Wspólny default layout szybko stanie się chaotyczny.

---

# 14. Jak działa lokalny cache

`DashboardLayoutLocalStorage` trzyma:

* lokalny JSON configu,
* `last_check` dla konkretnego `dashboardKey`.

## Cel

* szybkie otwieranie dashboardu,
* ograniczenie niepotrzebnych pełnych fetchy,
* możliwość pracy przy chwilowych problemach sieciowych.

## Zasada

Lokalna wersja jest cachem, ale źródłem prawdy po stronie trwałej pozostaje backend.

---

# 15. Normalizacja i collision handling

## Gdzie to się dzieje

W `DashboardLayoutNotifier`:

* `_normalizeAll(...)`
* `_resolveLayout(...)`
* `_fitItemAgainstPlaced(...)`
* `_tryShrinkAgainst(...)`
* `_sanitizeToBounds(...)`

## Co to robi

Podczas move / resize / add system:

* przycina widget do constraints,
* pilnuje granic siatki,
* próbuje unikać kolizji,
* w razie konfliktu shrinkuje lub przesuwa widget niżej.

## Dlaczego to ważne

Bez tego użytkownik mógłby zapisać layout z nałożonymi na siebie kafelkami albo wyjść poza siatkę.

---

# 16. Najważniejsze zależności i kontrakty, których nie wolno łamać

## 1. `component_key` backend == `type` frontend spec

To jest krytyczne.

## 2. `dashboardKey` musi być spójny frontend/backend

Frontend wysyła `dashboardKey`, backend filtruje po `dashboard_keys`.

## 3. Widget musi istnieć w registry

Samo dodanie do backendu nie wystarczy.

## 4. Widget musi przejść `sanitize_dashboard_payload`

Jeśli user nie ma dostępu, backend go usunie z payloadu.

## 5. Instancja i layout item muszą się zgadzać

Jeżeli jest layout item bez instancji, frontend go odfiltruje.

## 6. `zoneKey` musi być zgodny z `allowed_zones`

Jeżeli w przyszłości dodasz wiele stref, backend już to wspiera logicznie.

---

# 17. Aktualne ograniczenia architektury

## 1. Registry jest statyczne

Każdy widget musi być skompilowany do aplikacji Flutter.

## 2. Marketplace nie dostarcza kodu widgetu

Marketplace zarządza katalogiem i dostępnością, ale nie renderuje nieznanego komponentu.

## 3. Default config jest jeszcze wspólny

Przy rozwoju wielu dashboardów trzeba go rozdzielić.

## 4. Zone system istnieje logicznie, ale UI ma jedną główną strefę

Masz `zoneKey`, `allowed_zones`, ale w praktyce używasz głównie `main`.

## 5. Widget settings nie mają jeszcze pełnego panelu konfiguracji

Instancje mają `settings`, ale obecny kod nie pokazuje jeszcze generycznego edytora ustawień widgetu.

---

# 18. Rekomendowany kierunek rozwoju

## Etap 1 — uporządkowanie dashboard factory

Rozdziel default layout per dashboard key.

## Etap 2 — wydzielenie osobnych zone

Np.:

* `main`
* `sidebar`
* `header`
* `footer`

## Etap 3 — panel konfiguracji widgetów

Każdy widget powinien móc czytać `instance.settings`, a UI powinno pozwalać je edytować.

## Etap 4 — metadata driven widgets

Dla prostych widgetów można dodać backendowe definicje settings schema.

## Etap 5 — widget permissions per module

Rozszerzyć `required_permissions` i role dla bardziej precyzyjnej kontroli.

---

# 19. Checklista — dodanie nowego dashboardu

## Frontend

* [ ] utwórz nowy ekran z `DynamicDashboardPage(dashboardKey: '...')`
* [ ] podepnij route / wejście do ekranu
* [ ] jeśli trzeba, rozbuduj `buildDefaultDashboardConfig(...)`
* [ ] upewnij się, że UI poprawnie wybiera breakpoint

## Backend

* [ ] dodaj nowy `dashboardKey` do dozwolonych dashboardów wybranych widgetów
* [ ] upewnij się, że katalog zwraca widgety dla tego key
* [ ] przetestuj GET layout / PUT layout / check / reset

## Testy manualne

* [ ] wejście pierwszy raz bez configu
* [ ] wygenerowanie default layoutu
* [ ] drag and drop
* [ ] resize
* [ ] save
* [ ] reload aplikacji
* [ ] reset layoutu
* [ ] dodawanie widgetu z marketplace

---

# 20. Checklista — dodanie nowego widgetu

## Frontend

* [ ] utwórz widget UI
* [ ] dodaj `DashboardWidgetSpec`
* [ ] dodaj spec do registry
* [ ] sprawdź `type`
* [ ] sprawdź `defaultSize(...)`
* [ ] sprawdź `constraints`
* [ ] opcjonalnie dodaj do default layoutu

## Backend

* [ ] dodaj rekord do `DashboardWidgetCatalog`
* [ ] ustaw poprawny `component_key`
* [ ] ustaw `dashboard_keys`
* [ ] ustaw `allowed_zones`
* [ ] ustaw `allow_multiple`
* [ ] ustaw `requires_installation`
* [ ] ustaw `default_sizes`
* [ ] ustaw `constraints`

## Testy manualne

* [ ] widget widoczny w catalog API
* [ ] widget widoczny w marketplace
* [ ] widget da się dodać
* [ ] widget renderuje się poprawnie
* [ ] widget zapisuje się i wraca po reloadzie
* [ ] widget nie wychodzi poza siatkę
* [ ] widget respektuje min/max size

---

# 21. Minimalny przykład: nowy dashboard + nowy widget

## Scenariusz

Chcesz dodać ekran:

* `association_analytics_dashboard`

I nowy widget:

* `tasks`

## Co trzeba zrobić

### Frontend

1. dodać ekran z `DynamicDashboardPage(dashboardKey: 'association_analytics_dashboard')`
2. stworzyć `TasksWidgetSpec`
3. dodać go do registry
4. opcjonalnie dodać go do default config dla `association_analytics_dashboard`

### Backend

1. dodać `association_analytics_dashboard` do `dashboard_keys`
2. dodać rekord catalogu dla `tasks`
3. uruchomić seed / migrację danych katalogu

### Test

1. otwórz nowy ekran,
2. sprawdź catalog,
3. dodaj widget,
4. przesuń i zmień rozmiar,
5. odśwież aplikację,
6. sprawdź, że layout wrócił.

---

# 22. Najczęstsze błędy

## Błąd 1

Widget jest w katalogu, ale nie renderuje się.

### Przyczyna

Brakuje go w frontend registry albo `component_key != type`.

## Błąd 2

Widget znika po zapisie.

### Przyczyna

Backend usunął go w `sanitize_dashboard_payload(...)`, bo user nie miał dostępu albo widget nie był poprawnie rozpoznany.

## Błąd 3

Widget nie pojawia się w marketplace na nowym ekranie.

### Przyczyna

Brak nowego `dashboardKey` w `dashboard_keys` katalogu.

## Błąd 4

Widget pojawia się dwa razy mimo że nie powinien.

### Przyczyna

Frontend sprawdza `allowMultiple`, ale trzeba też pilnować spójności danych katalogu i UI.

## Błąd 5

Layout nie wraca po reloadzie.

### Przyczyna

Problem z `saveNow()`, błędny payload albo backend odrzuca część instancji.

---

# 23. Rekomendowane refaktory przed dalszym skalowaniem

## 1. Rozdzielić dokumentację i kod na poziomie modułów

Na przykład:

* `dynamic_dashboard/core/...`
* `dynamic_dashboard/catalog/...`
* `dynamic_dashboard/widgets/...`
* `dynamic_dashboard/defaults/...`

## 2. Dodać `DashboardDefinition`

Warstwa opisująca dashboard:

* key,
* title,
* allowed zones,
* default widgets,
* feature flags.

## 3. Dodać backend serializer dla layout config

Obecnie layout to czysty JSON + sanitizacja. To jest szybkie, ale przy dużej skali warto mieć bardziej jawny kontrakt.

## 4. Dodać logowanie dropniętych widgetów

Teraz backend zwraca `meta.dropped_instances`. Warto też logować to serwerowo do debugowania.

## 5. Dodać UI dla `state.error`

Błędy istnieją w state, ale dashboard powinien mieć czytelny fallback UI.

---

# 24. Gotowy prompt dla AI do dodania nowego widgetu

Możesz przekazać AI taki prompt:

```text
Dodaj nowy widget do systemu Dynamic Dashboard.

Założenia:
- widget ma type = "tasks"
- title = "Tasks"
- ma działać w dashboardach: crm_main, association_dashboard
- ma być dostępny w zone "main"
- allowMultiple = false
- source = native
- requires_installation = false
- default size:
  - desktop: 4x4
  - tablet: 4x4
  - mobile: 4x4
- constraints:
  - minW: 2
  - maxW: 8
  - minH: 2
  - maxH: 8

Wygeneruj komplet zmian:
1. frontend widget UI,
2. DashboardWidgetSpec,
3. dodanie do registry,
4. backend catalog seed entry,
5. opcjonalne dodanie do default layoutu dla association_dashboard.

Zachowaj zgodność z istniejącą architekturą Dynamic Dashboard.
```

---

# 25. Gotowy prompt dla AI do dodania dashboardu w nowym miejscu

```text
Dodaj nowy ekran oparty o DynamicDashboardPage.

Założenia:
- nowy dashboardKey = "association_analytics_dashboard"
- ekran ma używać istniejącego systemu drag, resize, marketplace i save/load
- ma mieć własny default layout
- ma wspierać desktop, tablet i mobile
- backend catalog ma zwracać tylko widgety dozwolone dla tego dashboardKey

Wygeneruj komplet zmian:
1. nowy screen Flutter,
2. integrację z routingiem,
3. default config dla tego dashboardu,
4. update katalogu backendowego,
5. test checklist.
```

---

# 26. Finalne podsumowanie

Ten system już teraz ma solidny fundament:

* layout per user,
* wersjonowanie,
* cache lokalny,
* backendowe sanityzowanie,
* widget marketplace,
* frontend registry,
* drag + resize + save.

Żeby poprawnie go skalować do kolejnych ekranów, trzeba pilnować głównie czterech rzeczy:

1. **spójność `dashboardKey`,**
2. **spójność `component_key` i `type`,**
3. **obecność widgetu w frontend registry,**
4. **poprawna konfiguracja widgetu w backendowym katalogu.**

Jeżeli te cztery warunki są spełnione, dodanie nowego dashboardu albo nowego widgetu jest przewidywalne i bezpieczne.
