// profile_hover_region.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm/contact_panel/viewer/viewer_models.dart';

/// Uniwersalne dane do karty profilu
class ProfileHoverData {
  final String title;          // główna linia – imię/nazwisko / username
  final String? subtitle;      // np. rola, lokalizacja
  final String? avatarUrl;
  final String? email;
  final String? phone;

  const ProfileHoverData({
    required this.title,
    this.subtitle,
    this.avatarUrl,
    this.email,
    this.phone,
  });

  /// Helper dla ViewerItem – żeby nie kopiować logiki joinowania imienia/nazwiska
  factory ProfileHoverData.fromViewer(ViewerItem v) {
    String _joinName(ViewerItem v) =>
        [v.name, v.lastName]
            .where((e) => (e ?? '').toString().trim().isNotEmpty)
            .join(' ')
            .trim();

    final name = _joinName(v);
    return ProfileHoverData(
      title: name.isEmpty ? '—' : name,
      avatarUrl: v.avatar,
      email: v.email,
      phone: v.phone,
    );
  }
}

class ProfileHoverRegion extends StatefulWidget {
  const ProfileHoverRegion({
    super.key,
    required this.child,
    required this.profile,
    required this.theme,
    this.showDelay = const Duration(milliseconds: 120),
    this.hideDelay = const Duration(milliseconds: 160),
    this.width = 400,
    this.height = 300,
    this.offset = const Offset(0, 8),
  });

  /// Widget, nad którym reagujemy na hover (avatar + nazwa, itd.)
  final Widget child;

  /// Dane profilu do wyświetlenia w karcie
  final ProfileHoverData profile;

  /// Theme – żeby ładnie się wpasować w Twój system kolorów
  final ThemeColors theme;

  final Duration showDelay;
  final Duration hideDelay;
  final double width;
  final double height;
  final Offset offset;

  @override
  State<ProfileHoverRegion> createState() => _ProfileHoverRegionState();
}

class _ProfileHoverRegionState extends State<ProfileHoverRegion> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  Timer? _timerShow;
  Timer? _timerHide;

  bool _overTrigger = false;
  bool _overCard = false;

  bool get _shouldBeVisible => _overTrigger || _overCard;

  void _ensureShown() {
    if (!mounted) return;
    if (_entry != null) return;

    _entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: CompositedTransformFollower(
          link: _link,
          offset: widget.offset,
          showWhenUnlinked: false,
          child: Align(
            alignment: Alignment.topLeft,
            child: _HoverCard(
              profile: widget.profile,
              theme: widget.theme,
              width: widget.width,
              height: widget.height,
              onEnter: _onCardEnter,
              onExit: _onCardExit,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  void _ensureHidden() {
    _entry?.remove();
    _entry = null;
  }

  void _onTriggerEnter() {
    _overTrigger = true;
    _timerHide?.cancel();
    _timerShow?.cancel();
    _timerShow = Timer(widget.showDelay, () {
      if (_shouldBeVisible) _ensureShown();
    });
  }

  void _onTriggerExit() {
    _overTrigger = false;
    _scheduleHide();
  }

  void _onCardEnter() {
    _overCard = true;
    _timerHide?.cancel();
    // jeśli opuściliśmy trigger zanim karta się pojawiła, to teraz pokaż
    if (_entry == null) _ensureShown();
  }

  void _onCardExit() {
    _overCard = false;
    _scheduleHide();
  }

  void _scheduleHide() {
    _timerShow?.cancel();
    _timerHide?.cancel();
    _timerHide = Timer(widget.hideDelay, () {
      if (!_shouldBeVisible) _ensureHidden();
    });
  }

  @override
  void dispose() {
    _timerShow?.cancel();
    _timerHide?.cancel();
    _ensureHidden();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Na desktop/web tylko – na mobile hover pomijamy.
    final hoverEnabled = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (!hoverEnabled) return widget.child;

    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        opaque: false,
        onEnter: (_) => _onTriggerEnter(),
        onExit: (_) => _onTriggerExit(),
        child: widget.child,
      ),
    );
  }
}

class _HoverCard extends StatelessWidget {
  const _HoverCard({
    required this.profile,
    required this.theme,
    required this.width,
    required this.height,
    required this.onEnter,
    required this.onExit,
  });

  final ProfileHoverData profile;
  final ThemeColors theme;
  final double width;
  final double height;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final title = profile.title.trim().isEmpty ? '—' : profile.title.trim();
    final subtitle = profile.subtitle?.trim() ?? '';
    final email = profile.email ?? '';
    final phone = profile.phone ?? '';

    return IgnorePointer(
      ignoring: false,
      child: MouseRegion(
        onEnter: (_) => onEnter(),
        onExit: (_) => onExit(),
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: width,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: height),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  child: Container(
                    // “mostek” 8px u góry, by łatwiej wejść z triggera na kartę
                    padding: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: theme.adPopBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dashboardBoarder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(89),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: DefaultTextStyle(
                        style: TextStyle(color: theme.textColor),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundImage: (profile.avatarUrl != null &&
                                          profile.avatarUrl!.isNotEmpty)
                                      ? NetworkImage(profile.avatarUrl!)
                                      : null,
                                  child: (profile.avatarUrl == null ||
                                          profile.avatarUrl!.isEmpty)
                                      ? Icon(Icons.person, color: theme.textColor)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (subtitle.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.textColor
                                                  .withAlpha(178),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (email.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 16,
                                    color: theme.textColor.withAlpha(204),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      email,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            if (phone.isNotEmpty) const SizedBox(height: 6),
                            if (phone.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: theme.textColor.withAlpha(204),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      phone,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
