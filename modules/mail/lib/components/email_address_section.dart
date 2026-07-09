import 'dart:async';
import 'dart:math' as math;

import 'package:calendar/state_managers/suggestion_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';

class EmailAddressSection extends StatelessWidget {
  final String label;
  final List<TextEditingController> controllers;
  final ThemeColors theme;
  final bool isRequired;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final Widget? trailing;

  const EmailAddressSection({
    super.key,
    required this.label,
    required this.controllers,
    required this.theme,
    required this.isRequired,
    required this.onAdd,
    required this.onRemove,
    this.trailing,
  });

  bool _anyFilled() => controllers.any((c) => c.text.trim().isNotEmpty);

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);
  }

  Set<String> _selectedEmailsForIndex(int index) {
    final result = <String>{};

    for (int i = 0; i < controllers.length; i++) {
      if (i == index) continue;

      final value = controllers[i].text.trim().toLowerCase();
      if (value.isNotEmpty) {
        result.add(value);
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 8),

        ...controllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == controllers.length - 1 ? 0 : 8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ScrollAwareEmailField(
                    controller: controller,
                    theme: theme,
                    excludedEmails: _selectedEmailsForIndex(index),
                    validator: (value) {
                      final v = value?.trim() ?? '';

                      if (isRequired && index == 0 && !_anyFilled()) {
                        return '${"Field".tr} "$label" ${"is required".tr}';
                      }

                      if (v.isNotEmpty && !_isValidEmail(v)) {
                        return 'Invalid email'.tr;
                      }

                      return null;
                    },
                  ),
                ),
                if (controllers.length > 1)
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: theme.textColor.withAlpha(150),
                      size: 20,
                    ),
                    onPressed: () => onRemove(index),
                    padding: const EdgeInsets.only(left: 8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
              ],
            ),
          );
        }),

        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: TextButton(
            onPressed: onAdd,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: theme.textColor.withAlpha(180),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Add another email'.tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(180),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScrollAwareEmailField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final ThemeColors theme;
  final String? Function(String?)? validator;
  final Set<String> excludedEmails;

  const _ScrollAwareEmailField({
    required this.controller,
    required this.theme,
    required this.validator,
    required this.excludedEmails,
  });

  @override
  ConsumerState<_ScrollAwareEmailField> createState() =>
      _ScrollAwareEmailFieldState();
}

class _ScrollAwareEmailFieldState
    extends ConsumerState<_ScrollAwareEmailField>
    with WidgetsBindingObserver {
  final GlobalKey _fieldKey = GlobalKey();

  late final FocusNode _focusNode;

  Timer? _debounce;
  OverlayEntry? _overlayEntry;
  ScrollPosition? _scrollPosition;

  String _query = '';

  static final RegExp _tokenSeparator = RegExp(r'[,\s;]+');

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!mounted) return;

      if (_focusNode.hasFocus) {
        _attachScrollListener();
        _refreshQuery(widget.controller.text, immediate: true);
        _ensureVisible();
      } else {
        _detachScrollListener();

        Future.delayed(const Duration(milliseconds: 140), () {
          if (!mounted || _focusNode.hasFocus) return;

          _query = '';
          _removeOverlay();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _ScrollAwareEmailField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rebuildOverlay();
  }

  @override
  void didChangeMetrics() {
    _rebuildOverlay();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _detachScrollListener();
    _removeOverlay();
    _focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _attachScrollListener() {
    final scrollable = Scrollable.maybeOf(context);
    final newPosition = scrollable?.position;

    if (_scrollPosition == newPosition) return;

    _detachScrollListener();

    _scrollPosition = newPosition;
    _scrollPosition?.addListener(_rebuildOverlay);
  }

  void _detachScrollListener() {
    _scrollPosition?.removeListener(_rebuildOverlay);
    _scrollPosition = null;
  }

  void _ensureVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.15,
      );

      _rebuildOverlay();
    });
  }

  void _refreshQuery(String value, {bool immediate = false}) {
    _debounce?.cancel();

    void updateQuery() {
      if (!mounted) return;

      final lastToken = value.split(_tokenSeparator).last.trim();

      _query = lastToken;

      if (_focusNode.hasFocus && _query.isNotEmpty) {
        _showOrUpdateOverlay();
      } else {
        _removeOverlay();
      }
    }

    if (immediate) {
      updateQuery();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 180), updateQuery);
  }

  void _showOrUpdateOverlay() {
    if (!mounted) return;

    if (!_focusNode.hasFocus || _query.trim().isEmpty) {
      _removeOverlay();
      return;
    }

    _attachScrollListener();

    if (_overlayEntry != null) {
      _rebuildOverlay();
      return;
    }

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: _buildOverlay,
    );

    overlay.insert(_overlayEntry!);
  }

  void _rebuildOverlay() {
    if (_overlayEntry == null) return;
    _overlayEntry?.markNeedsBuild();
  }

  void _removeOverlay() {
    final entry = _overlayEntry;
    _overlayEntry = null;
    entry?.remove();
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final query = _query.trim();

    if (!_focusNode.hasFocus || query.isEmpty) {
      return const SizedBox.shrink();
    }

    final fieldContext = _fieldKey.currentContext;
    if (fieldContext == null) {
      return const SizedBox.shrink();
    }

    final renderObject = fieldContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) {
      return const SizedBox.shrink();
    }

    final media = MediaQuery.of(overlayContext);
    final fieldSize = renderObject.size;
    final fieldOffset = renderObject.localToGlobal(Offset.zero);

    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    const horizontalMargin = 8.0;
    const verticalGap = 6.0;

    final width = math.min(
      fieldSize.width,
      screenWidth - (horizontalMargin * 2),
    );

    final left = fieldOffset.dx.clamp(
      horizontalMargin,
      math.max(horizontalMargin, screenWidth - width - horizontalMargin),
    );

    final fieldTop = fieldOffset.dy;
    final fieldBottom = fieldOffset.dy + fieldSize.height;

    final keyboardBottom = media.viewInsets.bottom;
    final safeTop = media.padding.top;
    final safeBottom = media.padding.bottom + keyboardBottom;

    final availableBelow =
        screenHeight - safeBottom - fieldBottom - verticalGap - 8;
    final availableAbove = fieldTop - safeTop - verticalGap - 8;

    final shouldOpenUp = availableBelow < 150 && availableAbove > availableBelow;

    final availableSpace = shouldOpenUp ? availableAbove : availableBelow;

    final maxHeight = math.min(
      230.0,
      math.max(96.0, availableSpace),
    );

    final top = shouldOpenUp
        ? math.max(
            safeTop + 8,
            fieldTop - maxHeight - verticalGap,
          )
        : fieldBottom + verticalGap;

    return Positioned(
      left: left.toDouble(),
      top: top.toDouble(),
      width: width.toDouble(),
      child: _EmailSuggestionsDropdown(
        query: query,
        theme: widget.theme,
        excludedEmails: widget.excludedEmails,
        maxHeight: maxHeight,
        onSelect: _selectSuggestion,
      ),
    );
  }

  void _selectSuggestion({
    required String email,
    String? name,
  }) {
    final cleanEmail = email.trim();

    widget.controller.text = cleanEmail;
    widget.controller.selection = TextSelection.collapsed(
      offset: cleanEmail.length,
    );

    _query = '';
    _removeOverlay();

    Form.maybeOf(context)?.validate();

    FocusScope.of(context).nextFocus();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: _fieldKey,
      controller: widget.controller,
      focusNode: _focusNode,
      style: TextStyle(color: widget.theme.textColor),
      validator: widget.validator,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [
        AutofillHints.email,
      ],
      onChanged: _refreshQuery,
      onFieldSubmitted: (_) {
        _query = '';
        _removeOverlay();
        FocusScope.of(context).nextFocus();
      },
      scrollPadding: const EdgeInsets.only(
        left: 20,
        top: 20,
        right: 20,
        bottom: 120,
      ),
      onTap: () {
        _ensureVisible();
        _refreshQuery(widget.controller.text, immediate: true);
      },
      decoration: InputDecoration(
        hintText: 'adres@email.com',
        hintStyle: TextStyle(
          color: widget.theme.textColor.withAlpha(120),
        ),
        filled: true,
        fillColor: widget.theme.dashboardContainer,
        prefixIcon: Icon(
          Icons.alternate_email,
          size: 18,
          color: widget.theme.textColor.withAlpha(120),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.theme.textColor.withAlpha(120),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.theme.textColor.withAlpha(70),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.theme.textColor.withAlpha(140),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
    );
  }
}

class _EmailSuggestionsDropdown extends ConsumerWidget {
  final String query;
  final ThemeColors theme;
  final Set<String> excludedEmails;
  final double maxHeight;
  final void Function({
    required String email,
    String? name,
  }) onSelect;

  const _EmailSuggestionsDropdown({
    required this.query,
    required this.theme,
    required this.excludedEmails,
    required this.maxHeight,
    required this.onSelect,
  });

  bool _isAlreadySelected(String email) {
    return excludedEmails.contains(email.trim().toLowerCase());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(guestSuggestionsProvider(query));

    return suggestionsAsync.when(
      data: (items) {
        final visibleItems = items
            .where((s) {
              final email = s.email.trim();
              if (email.isEmpty) return false;
              return !_isAlreadySelected(email);
            })
            .take(6)
            .toList();

        if (visibleItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
            ),
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.textColor.withAlpha(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: visibleItems.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 0.4,
                  color: theme.textColor.withAlpha(18),
                ),
                itemBuilder: (context, i) {
                  final suggestion = visibleItems[i];

                  final email = suggestion.email.trim();
                  final name = suggestion.name?.trim();
                  final avatarUrl = suggestion.avatarUrl;

                  final displayName =
                      name != null && name.isNotEmpty ? name : email;

                  return InkWell(
                    onTap: () => onSelect(
                      email: email,
                      name: name,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      child: Row(
                        children: [
                          _EmailSuggestionAvatar(
                            url: avatarUrl,
                            fallbackText: displayName,
                            theme: theme,
                            radius: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                if (displayName != email)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: theme.textColor.withAlpha(150),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.north_west,
                            size: 15,
                            color: theme.textColor.withAlpha(110),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _EmailSuggestionAvatar extends StatelessWidget {
  final String? url;
  final String fallbackText;
  final ThemeColors theme;
  final double radius;

  const _EmailSuggestionAvatar({
    required this.url,
    required this.fallbackText,
    required this.theme,
    this.radius = 16,
  });

  String _normalize(String value) {
    final u = value.trim();

    if (u.startsWith('http://')) {
      return u.replaceFirst('http://', 'https://');
    }

    if (u.contains('lh3.googleusercontent.com') && !u.contains('=s')) {
      return '$u=s64-c';
    }

    return u;
  }

  @override
  Widget build(BuildContext context) {
    final initials = fallbackText.trim().isNotEmpty
        ? fallbackText.trim()[0].toUpperCase()
        : '?';

    final rawUrl = url?.trim();

    if (rawUrl == null || rawUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: theme.textColor.withAlpha(25),
        child: Text(
          initials,
          style: TextStyle(
            color: theme.textColor,
            fontSize: radius * 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final safeUrl = _normalize(rawUrl);

    return ClipOval(
      child: Image.network(
        safeUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: radius,
          backgroundColor: theme.textColor.withAlpha(25),
          child: Text(
            initials,
            style: TextStyle(
              color: theme.textColor,
              fontSize: radius * 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}