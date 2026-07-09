import 'package:calendar/enums/event/repeat_enum.dart';
import 'package:calendar/enums/event/visibility_type_enum.dart';
import 'package:calendar/models/event_model.dart';
import 'package:calendar/models/offer_preview_model.dart';
import 'package:crm/provider/events_provider.dart';
import 'package:crm/dynamic_dashboard/models/daily_market_overview_model.dart';
import 'package:crm/dynamic_dashboard/models/agent_dashboard_model.dart';
import 'package:crm/dynamic_dashboard/providers/daily_market_overview_provider.dart';
import 'package:crm/dynamic_dashboard/providers/dashboard_provider.dart' show dashboardProvider;
import 'package:crm/dynamic_dashboard/providers/dashboard_service.dart' show recentContactsProvider;
import 'package:crm/shared/models/clients_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider overrides that inject realistic-looking demo data so widget
/// marketplace screenshots always show populated content, regardless of the
/// current user's actual data or network state.
List<Override> buildDemoProviderOverrides() => [
      recentContactsProvider.overrideWith((ref) => Future.value(_kContacts)),
      dailyMarketOverviewProvider.overrideWith((ref) => Future.value(_kMarketOverview)),
      dashboardProvider.overrideWith((ref) => Future.value(_kMetrics)),
      allCalendarEventsProvider.overrideWithValue(_kEvents),
    ];

// ── contacts ──────────────────────────────────────────────────────────────────

const _kContacts = <UserContactModel>[
  UserContactModel(
    id: 1,
    name: 'Anna',
    lastName: 'Kowalska',
    email: 'anna.kowalska@gmail.com',
    phoneNumber: '+48 601 234 567',
    contactType: 1,
    contactStatus: 'active',
  ),
  UserContactModel(
    id: 2,
    name: 'Marek',
    lastName: 'Wiśniewski',
    email: 'marek.wisniewski@outlook.com',
    phoneNumber: '+48 722 345 678',
    contactType: 2,
    contactStatus: 'active',
    isStar: true,
  ),
  UserContactModel(
    id: 3,
    name: 'Katarzyna',
    lastName: 'Dąbrowska',
    email: 'k.dabrowska@firma.pl',
    phoneNumber: '+48 533 456 789',
    contactType: 1,
    contactStatus: 'new',
  ),
  UserContactModel(
    id: 4,
    name: 'Piotr',
    lastName: 'Zieliński',
    email: 'pzielinski@gmail.com',
    phoneNumber: '+48 664 567 890',
    contactType: 3,
    contactStatus: 'active',
  ),
  UserContactModel(
    id: 5,
    name: 'Monika',
    lastName: 'Lewandowska',
    email: 'monika.lewandowska@wp.pl',
    phoneNumber: '+48 798 678 901',
    contactType: 1,
    contactStatus: 'lead',
    isStar: true,
  ),
];

// ── market overview ───────────────────────────────────────────────────────────

final _kMarketOverview = DailyMarketOverviewModel(
  id: 1,
  summaryDate: '2026-06-25',
  city: 'Warszawa',
  state: 'Mazowieckie',
  country: 'Polska',
  scope: 'city',
  currency: 'PLN',
  title: 'Przegląd rynku nieruchomości – Warszawa',
  status: 'published',
  sampleSize: 1847,
  generatedAt: '2026-06-25T08:00:00Z',
  isFreshlyGenerated: true,
  emmaEnabled: false,
  emmaPlaceholder: false,
  overview: {
    'avg_price_per_sqm': 14500,
    'total_listings': 1847,
    'new_listings_7d': 143,
    'sold_7d': 89,
    'avg_days_on_market': 24,
  },
  saleSnapshot: {
    'avg_price': 650000,
    'avg_price_per_sqm': 14500,
    'min_price': 249000,
    'max_price': 3200000,
    'listings_count': 1247,
    'trend': '+2.3%',
    'median_price': 585000,
  },
  rentSnapshot: {
    'avg_price': 3800,
    'min_price': 1800,
    'max_price': 12000,
    'listings_count': 600,
    'trend': '+1.1%',
    'median_price': 3400,
  },
  propertyTypeBreakdown: [
    {'type': 'Mieszkanie', 'count': 980, 'share': 0.53},
    {'type': 'Dom', 'count': 420, 'share': 0.23},
    {'type': 'Komercyjne', 'count': 280, 'share': 0.15},
    {'type': 'Działka', 'count': 167, 'share': 0.09},
  ],
  offerTypeBreakdown: [
    {'type': 'Sprzedaż', 'count': 1247, 'share': 0.67},
    {'type': 'Wynajem', 'count': 600, 'share': 0.33},
  ],
  fastestSegments: [
    {'segment': 'Kawalerki', 'avg_days': 12},
    {'segment': 'Domy <200m²', 'avg_days': 18},
    {'segment': '2-pokojowe', 'avg_days': 21},
  ],
  narrative: {
    'summary':
        'Rynek nieruchomości w Warszawie wykazuje stabilny wzrost w Q2 2026.',
    'key_insights': [
      'Średnia cena za m² wzrosła o 2.3% w porównaniu do poprzedniego miesiąca.',
      'Kawalerki sprzedają się najszybciej – średnio 12 dni.',
    ],
  },
);

// ── dashboard metrics ─────────────────────────────────────────────────────────

final _kMetrics = DashboardMetrics(
  period: 'june_2026',
  previousPeriod: 'may_2026',
  transactions: TransactionsData(
    total: 43,
    closed: 28,
    success: 24,
    failed: 4,
    newOnes: 15,
    conversionRatePeriod: 55.8,
    conversionRateLifetime: 62.3,
  ),
  revenue: RevenueData(
    closedCommissions: 98500,
    expectedCommissions: 125000,
    failedCommissions: 14200,
  ),
  expenses: ExpensesData(total: 32400),
  contacts: ContactsData(total: 187),
  averageTimeToClose: 18.5,
  compareToPrevious: null,
);

// ── calendar events ───────────────────────────────────────────────────────────

List<EventModel> get _kEvents {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  DateTime at(int h, int m) => today.add(Duration(hours: h, minutes: m));

  return [
    EventModel(
      id: 'demo-1',
      title: 'Prezentacja mieszkania – ul. Mokotowska',
      from: at(9, 0),
      to: at(10, 0),
      dateCreated: today,
      repeat: RepeatEnum.doesNotRepeat,
      timeZone: 'Europe/Warsaw',
      location: 'ul. Mokotowska 12, Warszawa',
      onlineCallLink: '',
      reminders: const [],
      busy: true,
      visibility: VisibilityTypeEnum.public,
      description: 'Prezentacja dla klientów zainteresowanych nieruchomością.',
      offerLink: '',
      offerPreview: const OfferPreview(id: '', keyMetrics: '', mainPhotoUrl: ''),
      color: '#4A90D9',
    ),
    EventModel(
      id: 'demo-2',
      title: 'Spotkanie z klientem – Anna Kowalska',
      from: at(11, 30),
      to: at(12, 30),
      dateCreated: today,
      repeat: RepeatEnum.doesNotRepeat,
      timeZone: 'Europe/Warsaw',
      location: 'Biuro, ul. Nowy Świat 5',
      onlineCallLink: '',
      reminders: const [],
      busy: true,
      visibility: VisibilityTypeEnum.public,
      description: 'Omówienie warunków zakupu mieszkania 3-pokojowego.',
      offerLink: '',
      offerPreview: const OfferPreview(id: '', keyMetrics: '', mainPhotoUrl: ''),
      color: '#7B68EE',
    ),
    EventModel(
      id: 'demo-3',
      title: 'Podpisanie umowy przedwstępnej',
      from: at(14, 0),
      to: at(15, 0),
      dateCreated: today,
      repeat: RepeatEnum.doesNotRepeat,
      timeZone: 'Europe/Warsaw',
      location: 'Kancelaria notarialna, pl. Bankowy 2',
      onlineCallLink: '',
      reminders: const [],
      busy: true,
      visibility: VisibilityTypeEnum.public,
      description: 'Podpisanie umowy przedwstępnej z Markiem Wiśniewskim.',
      offerLink: '',
      offerPreview: const OfferPreview(id: '', keyMetrics: '', mainPhotoUrl: ''),
      color: '#2ECC71',
    ),
    EventModel(
      id: 'demo-4',
      title: 'Wycena nieruchomości – Ursynów',
      from: at(16, 0),
      to: at(17, 0),
      dateCreated: today,
      repeat: RepeatEnum.doesNotRepeat,
      timeZone: 'Europe/Warsaw',
      location: 'ul. Puławska 180, Warszawa',
      onlineCallLink: '',
      reminders: const [],
      busy: false,
      visibility: VisibilityTypeEnum.public,
      description: '',
      offerLink: '',
      offerPreview: const OfferPreview(id: '', keyMetrics: '', mainPhotoUrl: ''),
      color: '#E67E22',
    ),
    EventModel(
      id: 'demo-5',
      title: 'Rozmowa telefoniczna – Piotr Zieliński',
      from: today.add(const Duration(days: 1, hours: 10)),
      to: today.add(const Duration(days: 1, hours: 10, minutes: 30)),
      dateCreated: today,
      repeat: RepeatEnum.doesNotRepeat,
      timeZone: 'Europe/Warsaw',
      location: '',
      onlineCallLink: '',
      reminders: const [],
      busy: false,
      visibility: VisibilityTypeEnum.public,
      description: 'Omówienie oferty wynajmu lokalu komercyjnego.',
      offerLink: '',
      offerPreview: const OfferPreview(id: '', keyMetrics: '', mainPhotoUrl: ''),
      color: '#E74C3C',
    ),
  ];
}
