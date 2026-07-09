import 'package:core/kernel/kernel.dart';

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
import 'package:calendar/core/module.dart';
import 'package:automation/core/module.dart';

void registerAppModules() {
  moduleRegistry.registerAll([
    // Budkon-specific
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
    CalendarModule(),
    AutomationModule(),
  ]);
}

Future<void> initAppModules() => moduleRegistry.initAll();
