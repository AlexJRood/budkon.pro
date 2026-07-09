import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rive/rive.dart';

const String kCatRiveAsset = 'packages/company_cat/assets/cat.riv';

/// Renderuje kota z pliku .riv (Cat_01 by COLINCOLIN, CC BY) lub emoji fallback.
///
/// Mapowanie stanów na inputy state machine "State Machine 1":
///   Switch_01Action_Sitting  (SMIBool) → sleeping
///   Switch_02Action_Eating   (SMIBool) → pet (krótki impuls przy głaskaniu)
///   Switch_03Action_Play     (SMIBool) → happy lub moving
class CatVisual extends StatefulWidget {
  const CatVisual({
    super.key,
    required this.sleeping,
    required this.happy,
    required this.moving,
    required this.fallbackEmoji,
    this.petSignal = 0,
    this.size = 54,
  });

  final bool sleeping;
  final bool happy;
  final bool moving;
  final String fallbackEmoji;
  final int petSignal;
  final double size;

  @override
  State<CatVisual> createState() => _CatVisualState();
}

class _CatVisualState extends State<CatVisual> {
  StateMachineController? _sm;
  SMIBool? _sitting;
  SMIBool? _eating;
  SMIBool? _play;
  bool? _hasAsset;
  Timer? _eatTimer;

  @override
  void initState() {
    super.initState();
    _checkAsset();
  }

  Future<void> _checkAsset() async {
    bool ok;
    try {
      await rootBundle.load(kCatRiveAsset);
      ok = true;
    } catch (_) {
      ok = false;
    }
    if (mounted) setState(() => _hasAsset = ok);
  }

  void _onRiveInit(Artboard artboard) {
    StateMachineController? ctrl;
    for (final name in ['State Machine 1', 'Big Cat', 'Cat', 'SM', 'cat']) {
      ctrl = StateMachineController.fromArtboard(artboard, name);
      if (ctrl != null) break;
    }
    if (ctrl == null) return;
    artboard.addController(ctrl);
    _sm = ctrl;
    _sitting = ctrl.findSMI('Switch_01Action_Sitting') as SMIBool?;
    _eating  = ctrl.findSMI('Switch_02Action_Eating')  as SMIBool?;
    _play    = ctrl.findSMI('Switch_03Action_Play')    as SMIBool?;
    _apply();
  }

  void _apply() {
    _sitting?.value = widget.sleeping;
    _play?.value    = widget.happy || widget.moving;
  }

  @override
  void didUpdateWidget(covariant CatVisual old) {
    super.didUpdateWidget(old);
    _apply();
    if (widget.petSignal != old.petSignal) _triggerEat();
  }

  /// Włącza Eating na 1.2 s przy głaskaniu, potem wraca.
  void _triggerEat() {
    if (_eating == null) return;
    _eating!.value = true;
    _eatTimer?.cancel();
    _eatTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) _eating?.value = false;
    });
  }

  @override
  void dispose() {
    _eatTimer?.cancel();
    _sm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasAsset == true) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: RiveAnimation.asset(
          kCatRiveAsset,
          artboard: 'main',
          stateMachines: const ['State Machine 1'],
          fit: BoxFit.contain,
          onInit: _onRiveInit,
        ),
      );
    }
    return Text(
      widget.fallbackEmoji,
      style: TextStyle(fontSize: widget.size * 0.85),
    );
  }
}
