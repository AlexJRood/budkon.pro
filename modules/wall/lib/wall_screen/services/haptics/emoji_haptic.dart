import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmojiBurstService {
  EmojiBurstService._();
  static final EmojiBurstService instance = EmojiBurstService._();

  OverlayEntry? _activeEntry;
  bool _isShowing = false;

  void success(BuildContext context, Offset position) {
    _show(context, position, _likeIcons);
  }

  void celebrate(BuildContext context, Offset position) {
    _show(context, position, _celebrateIcons);
  }

  void love(BuildContext context, Offset position) {
   // HapticFeedback.mediumImpact(); 
    _show(context, position, _loveIcons);
  }

  void dislike(BuildContext context, Offset position) {
    _show(context, position, _dislikeIcons);
  }
  void copy(BuildContext context, Offset position) {
    _show(context, position, _copyIcons);
  }

  void share(BuildContext context, Offset position) {
    _show(context, position, _shareIcons);
  }

  static const List<IconData> _shareIcons = [
    Icons.share_outlined,
    Icons.send_outlined,
    Icons.reply_outlined,
    Icons.forward_outlined,
    Icons.near_me_outlined,
  ];

    static const List<IconData> _copyIcons = [
      Icons.copy_outlined,
      Icons.content_copy_outlined,
      Icons.file_copy_outlined,
      Icons.assignment_outlined,
      Icons.note_outlined,
    ];

  static const List<IconData> _dislikeIcons = [
    Icons.thumb_down_outlined,
    Icons.sentiment_dissatisfied_outlined,
    Icons.block_outlined,
    Icons.warning_amber_outlined,
    Icons.cancel_outlined,
  ];

  // Like/thumb icons — matches the "success" preset style from second code
  static const List<IconData> _likeIcons = [
    Icons.thumb_up_outlined,
    Icons.star_outline,
    Icons.favorite_border,
    Icons.bolt,
    Icons.auto_awesome,
  ];

  static const List<IconData> _celebrateIcons = [
    Icons.celebration_outlined,
    Icons.star_outline,
    Icons.auto_awesome,
    Icons.emoji_events_outlined,
    Icons.rocket_launch_outlined,
  ];

  static const List<IconData> _loveIcons = [
    Icons.favorite_border,
    Icons.star_outline,
    Icons.auto_awesome,
    Icons.volunteer_activism_outlined,
    Icons.sentiment_very_satisfied_outlined,
  ];

  void _show(BuildContext context, Offset position, List<IconData> icons) {
    if (_isShowing) return;

    final overlay = Overlay.of(context);

    _activeEntry?.remove();
    _activeEntry = null;
    _isShowing = true;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _EmojiBurstWidget(
        position: position,
        icons: icons,
        onComplete: () {
          if (_isShowing) {
            entry.remove();
            _activeEntry = null;
            _isShowing = false;
          }
        },
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }
}

class _EmojiBurstWidget extends StatefulWidget {
  final Offset position;
  final List<IconData> icons;
  final VoidCallback onComplete;

  const _EmojiBurstWidget({
    required this.position,
    required this.icons,
    required this.onComplete,
  });

  @override
  State<_EmojiBurstWidget> createState() => _EmojiBurstWidgetState();
}

class _EmojiBurstWidgetState extends State<_EmojiBurstWidget>
    with TickerProviderStateMixin {
  final List<_Particle> _particles = [];
  final _random = Random();
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _spawnParticles();
  }

  void _spawnParticles() {
    // Matches second code: 5 + random 0–3 = 5–8 particles
    final count = 5 + _random.nextInt(4);
    int completedCount = 0;

    for (var i = 0; i < count; i++) {
      final controller = AnimationController(
        // Matches second code duration range: 800–1400ms
        duration: Duration(milliseconds: 800 + _random.nextInt(600)),
        vsync: this,
      );

      final particle = _Particle(
        icon: widget.icons[_random.nextInt(widget.icons.length)],
        // Slight spawn spread around tap point, like second code
        startX: widget.position.dx - 10 + _random.nextDouble() * 20,
        startY: widget.position.dy - 10,
        // Matches second code dx/dy ranges exactly
        dx: (_random.nextDouble() - 0.5) * 120,
        dy: -(80 + _random.nextDouble() * 180),
        // Matches second code size range: 16–28
        size: 16 + _random.nextDouble() * 12,
        // Matches second code rotation range
        rotation: (_random.nextDouble() - 0.5) * 1.2,
        controller: controller,
      );

      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          completedCount++;
          if (mounted) {
            setState(() => _particles.remove(particle));
          }
          controller.dispose();

          // All particles done → fire onComplete
          if (completedCount >= count && !_completed) {
            _completed = true;
            widget.onComplete();
          }
        }
      });

      _particles.add(particle);
      controller.forward();
    }
  }

  @override
  void dispose() {
    for (final p in _particles) {
      p.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final particle in _particles)
              AnimatedBuilder(
                animation: particle.controller,
                builder: (context, _) {
                  final t = particle.controller.value;
                  // Exact same easing as second code
                  final ease = Curves.easeOut.transform(t);
                  return Positioned(
                    left: particle.startX + particle.dx * ease,
                    top: particle.startY + particle.dy * ease,
                    child: Opacity(
                      opacity: (1.0 - t).clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: particle.rotation * t,
                        child: Icon(
                          particle.icon,
                          size: particle.size,
                          // Exact same color as second code
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  final IconData icon;
  final double startX;
  final double startY;
  final double dx;
  final double dy;
  final double size;
  final double rotation;
  final AnimationController controller;

  _Particle({
    required this.icon,
    required this.startX,
    required this.startY,
    required this.dx,
    required this.dy,
    required this.size,
    required this.rotation,
    required this.controller,
  });
}