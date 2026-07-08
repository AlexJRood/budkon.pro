import 'package:core/kernel/kernel.dart';

import 'package:budowa/core/module.dart';
import 'package:kosztorysy/core/module.dart';
import 'package:oferty/core/module.dart';
import 'package:harmonogram/core/module.dart';
import 'package:materialy/core/module.dart';
import 'package:podwykonawcy/core/module.dart';
import 'package:dziennik/core/module.dart';
import 'package:portal_klienta/core/module.dart';

void registerAppModules() {
  moduleRegistry.registerAll([
    BudowaModule(),
    KosztorysyModule(),
    OfertyModule(),
    HarmonogramModule(),
    MaterialyModule(),
    PodwykonawcyModule(),
    DziennikModule(),
    PortalKlientaModule(),
  ]);
}

Future<void> initAppModules() => moduleRegistry.initAll();
