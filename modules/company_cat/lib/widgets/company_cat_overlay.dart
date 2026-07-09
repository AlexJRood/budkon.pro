import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core/platform/navigation_service.dart';

import '../provider/cat_gift_provider.dart';
import '../provider/cat_prefs_provider.dart';
import '../provider/company_cat_provider.dart';
import 'cat_cosmetics_sheet.dart';
import 'cat_profile_sheet.dart';
import 'cat_send_pat_sheet.dart';
import 'cat_settings_sheet.dart';
import 'cat_visual.dart';

/// Sam kot: animowany (delikatny bob), tap = głask (serce), long-press = menu
/// (karm / zmień imię / a sio). Emoji-based (MVP; sprite/Lottie później).
class CompanyCatOverlay extends ConsumerStatefulWidget {
  const CompanyCatOverlay({super.key});

  @override
  ConsumerState<CompanyCatOverlay> createState() => _CompanyCatOverlayState();
}

class _CompanyCatOverlayState extends ConsumerState<CompanyCatOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob;
  bool _heart = false;
  int _petCount = 0;
  String? _saying;
  Timer? _speechTimer;

  static const _lines = [
    'miau 🐾',
    'jak leci?',
    'zróbże przerwę 😌',
    'dobra robota 😺',
    'mrubr...',
    'pogłaszcz mnie?',
  ];

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _speechTimer =
        Timer.periodic(const Duration(seconds: 35), (_) => _maybeSpeak());
  }

  void _maybeSpeak() {
    if (!mounted) return;
    if (ref.read(companyCatProvider).quiet) return; // śpi
    if (!math.Random().nextBool()) return; // ~50% szansy
    setState(() => _saying = _lines[math.Random().nextInt(_lines.length)]);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _saying = null);
    });
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    _bob.dispose();
    super.dispose();
  }

  void _pet() {
    ref.read(companyCatProvider.notifier).pet();
    setState(() {
      _heart = true;
      _petCount++;
    });
    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) setState(() => _heart = false);
    });
  }

  void _openMenu() {
    final navCtx =
        ref.read(navigationService).navigatorKey.currentContext ?? context;
    final notifier = ref.read(companyCatProvider.notifier);
    showModalBottomSheet<void>(
      context: navCtx,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🍗', style: TextStyle(fontSize: 20)),
              title: const Text('Nakarm'),
              onTap: () {
                notifier.feed();
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🐟', style: TextStyle(fontSize: 20)),
              title: const Text('Przysmak'),
              onTap: () {
                notifier.treat();
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🐾', style: TextStyle(fontSize: 20)),
              title: const Text('Wyślij głaska koledze'),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet<void>(
                  context: navCtx,
                  builder: (_) => const CatSendPatSheet(),
                );
              },
            ),
            ListTile(
              leading: const Text('✏️', style: TextStyle(fontSize: 20)),
              title: const Text('Zmień imię'),
              onTap: () {
                Navigator.pop(ctx);
                _renameDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.checkroom_outlined),
              title: const Text('Ubranka'),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet<void>(
                  context: navCtx,
                  builder: (_) => const CatCosmeticsSheet(),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Profil kota'),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet<void>(
                  context: navCtx,
                  builder: (_) => const CatProfileSheet(),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Ustawienia'),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet<void>(
                  context: navCtx,
                  builder: (_) => const CatSettingsSheet(),
                );
              },
            ),
            ListTile(
              leading: const Text('👋', style: TextStyle(fontSize: 20)),
              title: const Text('A sio (idź do kogoś)'),
              onTap: () {
                notifier.nudge();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _renameDialog() {
    final navCtx =
        ref.read(navigationService).navigatorKey.currentContext ?? context;
    final controller =
        TextEditingController(text: ref.read(companyCatProvider).name);
    showDialog<void>(
      context: navCtx,
      builder: (ctx) => AlertDialog(
        title: const Text('Imię kota'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              ref.read(companyCatProvider.notifier).rename(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = ref.watch(companyCatProvider);
    final muted = ref.watch(catPrefsProvider).muteReactions;
    final gift = ref.watch(catGiftProvider);
    final isMoving = ref.watch(catIsMovingProvider);

    return GestureDetector(
      onTap: _pet,
      onSecondaryTap: _openMenu, // PC: prawy przycisk
      onLongPress: _openMenu, // dotyk: przytrzymanie
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_saying != null)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(_saying!, style: const TextStyle(fontSize: 11)),
            ),
          if (gift != null)
            GestureDetector(
              onTap: () => ref.read(catGiftProvider.notifier).clear(),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                constraints: const BoxConstraints(maxWidth: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(gift.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kot ci przyniósł 🎁',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            gift.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (cat.patFrom != null)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEC407A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '🐾 ${cat.patFrom} przesyła głaska',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          // reakcja na event produktu (🔔/📋/💬) albo serce po głasku
          SizedBox(
            height: 22,
            child: AnimatedOpacity(
              opacity: (cat.quiet ||
                      cat.celebrating ||
                      (cat.reaction != null && !muted) ||
                      _heart)
                  ? 1
                  : 0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                cat.quiet
                    ? '💤'
                    : (cat.celebrating
                        ? '🎉'
                        : ((cat.reaction != null && !muted)
                            ? cat.reaction!
                            : '❤️')),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              cat.youAreFavorite ? '${cat.name} 💕' : cat.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 2),
          AnimatedBuilder(
            animation: _bob,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -5 * (1 - (2 * _bob.value - 1).abs())),
              child: child,
            ),
            child: SizedBox(
              height: 90,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  CatVisual(
                    sleeping: cat.quiet,
                    happy: cat.celebrating,
                    moving: isMoving,
                    petSignal: _petCount,
                    size: 90,
                    fallbackEmoji: cat.quiet
                        ? '😴'
                        : (cat.celebrating ? '🥳' : cat.moodEmoji),
                  ),
                  if (cat.accessory.isNotEmpty)
                    Positioned(
                      top: -8,
                      child: Text(
                        cat.accessory,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
