import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/cat_prefs_provider.dart';
import '../provider/company_cat_provider.dart';
import 'company_cat_overlay.dart';

/// Pozycjonuje [CompanyCatOverlay] i zarządza ruchem kota po ekranie.
///
/// Przeciąganie (lewy przycisk) przerywa ruch — używamy [Listener] zamiast
/// [GestureDetector] żeby nie blokować right-click obsługiwanego przez
/// [CompanyCatOverlay] (secondary tap → menu).
class CatRoamLayer extends ConsumerStatefulWidget {
  const CatRoamLayer({super.key});

  @override
  ConsumerState<CatRoamLayer> createState() => _CatRoamLayerState();
}

class _CatRoamLayerState extends ConsumerState<CatRoamLayer>
    with SingleTickerProviderStateMixin {
  static const _catW = 100.0;
  static const _catH = 160.0;
  static const _speed = 70.0;   // px/s — wolniej = spokojniejszy ruch
  static const _minIdleSec = 15;
  static const _maxIdleSec = 35;

  late final AnimationController _ctrl;
  Animation<Offset>? _posAnim;

  Offset _pos = const Offset(-_catW - 10, 300);
  Size _screen = Size.zero;
  bool _screenReady = false;
  bool _dragging = false;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this)
      ..addListener(_onTick)
      ..addStatusListener(_onAnimStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sz = MediaQuery.sizeOf(context);
    if (sz == Size.zero) return;
    _screen = sz;
    if (!_screenReady) {
      _screenReady = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _enter());
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  // ── ruch ───────────────────────────────────────────────────────────────────

  void _enter() {
    if (!mounted) return;
    final rng = math.Random();
    final midY = _screen.height * (0.3 + rng.nextDouble() * 0.4);
    final midX = _screen.width * (0.2 + rng.nextDouble() * 0.55);
    Offset start;
    switch (rng.nextInt(3)) {
      case 1:
        start = Offset(_screen.width + 10, midY);
      case 2:
        start = Offset(midX, _screen.height + 10);
      default:
        start = Offset(-_catW - 10, midY);
    }
    _pos = start;
    _moveTo(_randomTarget());
  }

  Offset _randomTarget() {
    final rng = math.Random();
    return Offset(
      (_catW + rng.nextDouble() * (_screen.width - _catW * 2 - 20))
          .clamp(10.0, _screen.width - _catW),
      (_screen.height * (0.25 + rng.nextDouble() * 0.5))
          .clamp(40.0, _screen.height - _catH),
    );
  }

  void _moveTo(Offset target) {
    final dist = (_pos - target).distance;
    if (dist < 2) { _arrive(); return; }
    final ms = (dist / _speed * 1000).round().clamp(800, 18000);
    _posAnim = Tween<Offset>(begin: _pos, end: target)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _setMoving(true);
    _ctrl
      ..duration = Duration(milliseconds: ms)
      ..forward(from: 0);
  }

  void _onTick() {
    final a = _posAnim;
    if (a != null) setState(() => _pos = a.value);
  }

  void _onAnimStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) _arrive();
  }

  void _arrive() {
    _setMoving(false);
    if (!_isOnscreen(_pos)) return; // wyszedł — serwer zadecyduje
    _scheduleNext();
  }

  bool _isOnscreen(Offset p) =>
      p.dx > -_catW && p.dx < _screen.width &&
      p.dy > -_catH && p.dy < _screen.height;

  void _scheduleNext() {
    final secs = _minIdleSec + math.Random().nextInt(_maxIdleSec - _minIdleSec);
    _idleTimer?.cancel();
    _idleTimer = Timer(Duration(seconds: secs), _decideNext);
  }

  void _decideNext() {
    if (!mounted || _dragging) return;
    if (math.Random().nextDouble() < 0.20) {
      _leave();
    } else {
      _moveTo(_randomTarget());
    }
  }

  void _leave() {
    final rng = math.Random();
    final midY = _screen.height * (0.3 + rng.nextDouble() * 0.4);
    final midX = _screen.width * (0.2 + rng.nextDouble() * 0.55);
    Offset target;
    switch (rng.nextInt(3)) {
      case 1: target = Offset(_screen.width + 10, midY);
      case 2: target = Offset(midX, _screen.height + 10);
      default: target = Offset(-_catW - 10, midY);
    }
    _moveTo(target);
  }

  void _setMoving(bool v) {
    if (!mounted) return;
    ref.read(catIsMovingProvider.notifier).state = v;
  }

  // ── drag (Listener — nie blokuje secondary tap / right-click) ─────────────

  void _onPointerDown(PointerDownEvent e) {
    if (e.buttons != kPrimaryMouseButton) return; // tylko lewy przycisk
    _dragging = true;
    _ctrl.stop();
    _idleTimer?.cancel();
    _setMoving(false);
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_dragging) return;
    setState(() {
      _pos = Offset(
        (_pos.dx + e.delta.dx).clamp(0.0, _screen.width - _catW),
        (_pos.dy + e.delta.dy).clamp(40.0, _screen.height - _catH),
      );
    });
  }

  void _onPointerUp(PointerUpEvent e) {
    if (!_dragging) return;
    _dragging = false;
    ref.read(catPrefsProvider.notifier)
      ..setLocalPosition(_pos.dx, _pos.dy)
      ..savePosition();
    _idleTimer = Timer(const Duration(seconds: 10), _decideNext);
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _pos.dx,
      top: _pos.dy,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        child: const CompanyCatOverlay(),
      ),
    );
  }
}
