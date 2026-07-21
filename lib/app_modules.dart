import 'package:core/kernel/kernel.dart';

import 'package:faktury/core/module.dart';
import 'package:kontakty/core/module.dart';
import 'package:pracownicy/core/module.dart';
import 'package:przetargi/core/module.dart';
import 'package:budowa/core/module.dart';
import 'package:kosztorysy/core/module.dart';
import 'package:oferty/core/module.dart';
import 'package:harmonogram/core/module.dart';
import 'package:materialy/core/module.dart';
import 'package:podwykonawcy/core/module.dart';
import 'package:dziennik/core/module.dart';
import 'package:portal_klienta/core/module.dart';
import 'package:notes/core/module.dart';
import 'package:chat/core/module.dart';
import 'package:emma/core/module.dart';
// import 'package:calendar/core/module.dart'; // CRM deps — disabled for now
import 'package:automation/core/module.dart';
// Batch 2
import 'package:crm/core/module.dart';
import 'package:crm_agent/core/module.dart';
import 'package:docs/core/module.dart';
import 'package:cloud/core/module.dart';
import 'package:importer/core/module.dart';
import 'package:profile/core/module.dart';
import 'package:mail/core/module.dart';
import 'package:tms_app/core/module.dart';
import 'package:portal/core/module.dart';
import 'package:network_monitoring/core/module.dart';
import 'package:notification/core/module.dart';
import 'package:wall/core/module.dart';
import 'package:payments/core/module.dart';
import 'package:reports/core/module.dart';
import 'package:articles/core/module.dart';
// import 'package:association/core/module.dart'; // errors — disabled for now

void registerAppModules() {
  moduleRegistry.registerAll([
    // Budkon-specific
    FakturyModule(),
    KontaktyModule(),
    PracownicyModule(),
    PrzetargiModule(),
    BudowaModule(),
    KosztorysyModule(),
    OfertyModule(),
    HarmonogramModule(),
    MaterialyModule(),
    PodwykonawcyModule(),
    DziennikModule(),
    PortalKlientaModule(),
    // Shared from superbee.core ecosystem
    NotesModule(),
    ChatModule(),
    EmmaModule(),
    // CalendarModule(), // CRM deps — disabled for now
    AutomationModule(),
    // Batch 2 — przeniesione z Hously.pro
    CrmModule(),
    CrmAgentModule(),
    DocsModule(),
    CloudModule(),
    ImporterModule(),
    ProfileModule(),
    MailModule(),
    TmsAppModule(),
    PortalModule(),
    NetworkMonitoringModule(),
    NotificationModule(),
    WallModule(),
    PaymentsModule(),
    ReportsModule(),
    ArticlesModule(),
    // AssociationModule(), // errors — disabled for now
  ]);
}

Future<void> initAppModules() => moduleRegistry.initAll(const ModuleScope());
