// Public Events: List & Details (Flutter Web/Desktop)
// Riverpod + your ApiServices.
// Comments are in English.

import 'dart:async';

import 'package:association/screens/events/models/event_models.dart';
import 'package:association/screens/events/providers/event_provider.dart';
import 'package:association/screens/events/widgets/categories_chips.dart';
import 'package:association/screens/events/widgets/event_helper_widgets.dart';
import 'package:association/screens/events/widgets/events_grid.dart';
import 'package:association/screens/events/widgets/filters_bar.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:intl/intl.dart';

import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';
import 'package:core/theme/text_field.dart';

// ==============================
// LIST PAGE
// ==============================

class PublicEventsPage extends ConsumerStatefulWidget {
  final AppModule appModule;
  const PublicEventsPage({super.key, this.appModule = AppModule.wall});

  @override
  ConsumerState<PublicEventsPage> createState() => _PublicEventsPageState();
}

class _PublicEventsPageState extends ConsumerState<PublicEventsPage> {
  final GlobalKey<SideMenuState> _sideMenuKey = GlobalKey<SideMenuState>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _currentSortLabel = 'Newest';

  static  List<Map<String, String>> _sortOptions = [
    {'label': 'Newest'.tr, 'value': '-start_time'},
    {'label': 'Oldest'.tr, 'value': 'start_time'},
    {'label': 'Title A–Z'.tr, 'value': 'title'},
    {'label': 'Title Z–A'.tr, 'value': '-title'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
      ref.read(eventsFilterProvider.notifier).state = ref
          .read(eventsFilterProvider)
          .copyWith(q: query);
    }
    });
  }

  void _onSortSelected(String label, String value) {
    setState(() => _currentSortLabel = label);
    // Sort is tracked locally; extend EventsFilter with a sort field
    // on the backend when needed.
  }

  Widget _buildToolbarRow(BuildContext context) {
    final nav = ref.read(navigationService);
    final currentPath = nav.currentPath;
    final textColor = CustomColors.secondaryWidgetTextColor(context, ref);

    return Row(
      children: [
        // ── Sort ─────────────────────────────────────────────────────────────
        Text(
          'Sort By:'.tr,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 10),
        PopupMenuButton<Map<String, String>>(
          tooltip: 'Sort options'.tr,
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: CustomColors.secondaryWidgetColor(context, ref),
          onSelected: (item) => _onSortSelected(item['label']!, item['value']!),
          itemBuilder: (_) => _sortOptions
              .map(
                (item) => PopupMenuItem<Map<String, String>>(
                  value: Map<String, String>.from(item),
                  child: Text(
                    item['label']!,
                    style: TextStyle(color: textColor),
                  ),
                ),
              )
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: textColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentSortLabel,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: textColor),
              ],
            ),
          ),
        ),

        const SizedBox(width: 10),

        // ── Filter ────────────────────────────────────────────────────────────
        OutlinedButton.icon(
        style: elevatedButtonStyleRounded10,
        icon: Icon(Icons.tune, size: 16, color: textColor),
        label: Text(
              'Filter'.tr,
        style: TextStyle(color: textColor, fontSize: 13),
      ),
      onPressed: () async {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 800; 
    final theme = ref.watch(themeColorsProvider);
    if (isDesktop) {
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: theme.dashboardContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: FiltersBar(filter: ref.read(eventsFilterProvider)),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: FiltersBar(filter: ref.read(eventsFilterProvider)),
            ),
          ),
        ),
      );
    }
  },
),

        const Spacer(),

        // ── Create Event ──────────────────────────────────────────────────────
        SizedBox(
          height: 36,
          width: 140,
          child: ElevatedButton.icon(
            style: buttonStyleRounded10ThemeRed,
            onPressed: () => nav.pushNamedScreen('$currentPath/create'),
            icon: AppIcons.add(color: AppColors.white, width: 16, height: 16),
            label:  Text(
              'New Event'.tr,
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the scrollable event list (CustomScrollView pattern
  /// matching all_reports_screen_pc.dart).
  Widget _buildContent(BuildContext context, {required bool isMobile}) {
    final catsAsync = ref.watch(categoriesProvider);
    final theme = ref.read(themeColorsProvider);
    final sidePad = isMobile ? 16.0 : MediaQuery.of(context).size.width * 0.1;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: isMobile ? 70 : 10)),

        // ── PAGE TITLE ───────────────────────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: sidePad),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Public Events'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),

        // ── SEARCH BAR ───────────────────────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: sidePad),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _SearchBar(
                controller: _searchController,
                onSearch: _onSearchChanged,
              ),
            ),
          ),
        ),

        // ── TOOLBAR ROW (Sort / Filter / New Event) — PC only ────────────────
        if (!isMobile)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: sidePad),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _buildToolbarRow(context),
              ),
            ),
          ),

        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: sidePad),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // ── Category chips ───────────────────────────────────────────
                catsAsync.maybeWhen(
                  data: (cats) => cats.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CategoriesChips(cats: cats),
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),

        // ── EVENTS GRID ──────────────────────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: sidePad),
          sliver: _EventsGridSliver(theme: theme),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(navigationService);
    final currentPath = nav.currentPath;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return BarManager(
          sideMenuKey: _sideMenuKey,
          appModule: widget.appModule,
          paddingPc: 10,
          paddingMobile: 0,

          // Mobile floating action buttons
          verticalButtons: isMobile
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MobileFilterButton(
                      theme: ref.read(themeColorsProvider),
                      onPressed: () async {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: SafeArea(
                              top: false,
                              child: SingleChildScrollView(
                                child: FiltersBar(
                                  filter: ref.read(eventsFilterProvider),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    MobileCreateEventButton(
                      onPressed: () =>
                          nav.pushNamedScreen('$currentPath/create'),
                    ),
                  ],
                )
              : null,

          // PC side panel: floating create button
          childPc: _buildContent(context, isMobile: false),
          childMobile: _buildContent(context, isMobile: true),
        );
      },
    );
  }
}

class _SearchBar extends ConsumerWidget {
  const _SearchBar({required this.controller, required this.onSearch});
  final TextEditingController controller;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      key: const ValueKey('event_search_field'), // Stable key to preserve focus
      controller: controller,
      onChanged: onSearch,
      cursorColor: CustomColors.secondaryWidgetTextColor(context, ref),
      style: TextStyle(
        color: CustomColors.secondaryWidgetTextColor(context, ref),
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        fillColor: CustomColors.secondaryWidgetColor(context, ref),
        filled: true,
        hintText: 'Search events…'.tr,
        hintStyle: TextStyle(
          color: CustomColors.secondaryWidgetTextColor(context, ref),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: AppIcons.search(
            width: 20,
            height: 20,
            color: CustomColors.secondaryWidgetTextColor(context, ref),
          ),
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: CustomColors.secondaryWidgetTextColor(context, ref),
                  size: 18,
                ),
                onPressed: () {
                  controller.clear();
                  onSearch('');
                },
              )
            : null,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: CustomColors.secondaryWidgetTextColor(context, ref),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }
}

class _EventsGridSliver extends ConsumerWidget {
  const _EventsGridSliver({required this.theme});
  final ThemeColors theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(publicEventsProvider);

    return SliverToBoxAdapter(
      child: RefreshIndicator(
        onRefresh: () async => ref.refresh(publicEventsProvider.future),
        child: eventsAsync.when(
          data: (items) => EventsGrid(items: items, theme: theme),
          error: (e, _) => CenteredMsg('Error: $e', theme),
          loading: () => SizedBox(
            height: 300,
            child: Center(child: AppLottie.loading(size: 20)),
          ),
        ),
      ),
    );
  }
}
// ==============================
// DETAILS PAGE
// ==============================
final eventBySlugProvider =
    FutureProvider.family<EventSocialDetailModel, String>((ref, slug) async {
      return ref.read(publicEventsApiProvider).bySlug(slug);
    });

class PublicEventDetailsPage extends ConsumerWidget {
  const PublicEventDetailsPage({
    super.key,
    required this.slug,
    this.appModule = AppModule.wall,
  });

  final String slug;
  final AppModule appModule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final async = ref.watch(eventBySlugProvider(slug));
    final theme = ref.read(themeColorsProvider);

    final body = async.when(
      data: (m) => _EventDetailsBody(m: m),
      error: (e, st) => CenteredMsg(e.toString(), theme),
      loading: () => const CenteredLoader(),
    );

    return BarManager(
      appModule: appModule,
      sideMenuKey: sideMenuKey,
      childPc: body,
      childMobile: body,
    );
  }
}

class _EventDetailsBody extends ConsumerStatefulWidget {
  const _EventDetailsBody({required this.m});
  final EventSocialDetailModel m;

  @override
  ConsumerState<_EventDetailsBody> createState() => _EventDetailsBodyState();
}

class _EventDetailsBodyState extends ConsumerState<_EventDetailsBody> {
  late String? _myStatus; // "going" | "maybe" | "decline" | null
  late int _goingCount;
  late int _interestedCount;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _myStatus = widget.m.myStatus;
    _goingCount = widget.m.goingCount;
    _interestedCount = widget.m.interestedCount;
  }

  Future<void> _setRsvp(String newStatus) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    final prevStatus = _myStatus;
    final prevGoing = _goingCount;
    final prevInterested = _interestedCount;

    void applyDelta(String? from, String to) {
      if (from == 'going'.tr) _goingCount = (_goingCount - 1).clamp(0, 1 << 30);
      if (from == 'maybe'.tr)
        _interestedCount = (_interestedCount - 1).clamp(0, 1 << 30);
      if (to == 'going'.tr) _goingCount += 1;
      if (to == 'maybe'.tr) _interestedCount += 1;
      _myStatus = to;
    }

      if (mounted) {
      setState(() => applyDelta(prevStatus, newStatus));
    }

    try {
      await ref
          .read(publicEventsApiProvider)
          .rsvp(eventId: widget.m.eventId, status: newStatus);
      ref.invalidate(eventBySlugProvider(widget.m.slug));
    } catch (err) {
       if (mounted) {
        setState(() {
          _myStatus = prevStatus;
          _goingCount = prevGoing;
          _interestedCount = prevInterested;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd: $err')));
      }
    } finally {
       if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.m.event;
    final isGoing = _myStatus == 'going'.tr;
    final isMaybe = _myStatus == 'maybe'.tr;
    final isDecl = _myStatus == 'decline'.tr;
    final theme = ref.read(themeColorsProvider);

    final when = e.startTime != null
        ? DateFormat(
            'EEEE, d MMM yyyy • HH:mm',
            'pl_PL',
          ).format(e.startTime!.toLocal())
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cinematic Header
              Stack(
                children: [
                  if (widget.m.coverImageUrl?.isNotEmpty == true)
                    Container(
                      height: 400,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(32),
                        ),
                        child: Image.network(
                          widget.m.coverImageUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.textColor.withValues(alpha: 0.05),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(32),
                        ),
                      ),
                      child: Icon(
                        Icons.event,
                        size: 64,
                        color: theme.textColor.withValues(alpha: 0.1),
                      ),
                    ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Category
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            e.title,
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.textColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.m.isFree ? 'FREE ENTRY'.tr : 'TICKETED'.tr,
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick Info Cards
                    Row(
                      children: [
                        _buildInfoItem(
                          context,
                          AppIcons.calendar(
                            color: theme.textColor,
                            width: 20,
                            height: 20,
                          ),
                          'DATE & TIME'.tr,
                          when,
                        ),
                        const SizedBox(width: 24),
                        if (e.location?.isNotEmpty == true)
                          _buildInfoItem(
                            context,
                            AppIcons.location(
                              color: theme.textColor,
                              width: 20,
                              height: 20,
                            ),
                            'LOCATION'.tr,
                            e.location!,
                          ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Description Section
                    Text(
                      'ABOUT THIS EVENT'.tr,
                      style: TextStyle(
                        color: theme.textColor.withValues(alpha: 0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if ((e.description ?? '').isNotEmpty)
                      Text(
                        e.description!,
                        style: TextStyle(
                          color: theme.textColor.withValues(alpha: 0.8),
                          fontSize: 16,
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                    const SizedBox(height: 48),

                    // Community Stats
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: CustomColors.secondaryWidgetColor(context, ref),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.textColor.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildStatItem('GOING'.tr, '$_goingCount'),
                          _buildStatDivider(),
                          _buildStatItem('INTERESTED'.tr, '$_interestedCount'),
                          if (widget.m.city?.isNotEmpty == true) ...[
                            _buildStatDivider(),
                            _buildStatItem(
                              'CITY'.tr,
                              widget.m.city!.toUpperCase(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Actions
                    Text(
                      'ARE YOU GOING?'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _RsvpButton(
                          label: 'I\'M GOING'.tr,
                          icon: Icons.check_circle_outline,
                          isSelected: isGoing,
                          isLoading: _isBusy,
                          onPressed: () => _setRsvp('going'),
                        ),
                        _RsvpButton(
                          label: 'INTERESTED'.tr,
                          icon: Icons.star_outline,
                          isSelected: isMaybe,
                          isLoading: _isBusy,
                          onPressed: () => _setRsvp('maybe'),
                        ),
                        _RsvpButton(
                          label: 'DECLINE'.tr,
                          icon: Icons.cancel_outlined,
                          isSelected: isDecl,
                          isLoading: _isBusy,
                          onPressed: () => _setRsvp('decline'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Secondary Actions
                    Row(
                      children: [
                        Text(
                          'Invite friends to join you'.tr,
                          style: TextStyle(
                            color: theme.textColor.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 36,
                          width: 140,
                          child: ElevatedButton(
                            onPressed: _isBusy
                                ? null
                                : () async {
                                    final email = await _askForEmail(context);
                                    if (email == null || email.isEmpty) return;
                                    try {
                                      final count = await ref
                                          .read(publicEventsApiProvider)
                                          .invite(widget.m.eventId, {
                                            "email": email,
                                            "name": "",
                                            "message": "",
                                          });
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Invitations sent: $count'.tr,
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                            style: buttonStyleRounded10ThemeRed,
                            child: Text(
                              'Invite by Email'.tr,
                              style: TextStyle(color: AppColors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    Widget icon,
    String label,
    String value,
  ) {
    final theme = ref.read(themeColorsProvider);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textColor.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              icon,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    final theme = ref.read(themeColorsProvider);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    final theme = ref.read(themeColorsProvider);
    return Container(
      height: 30,
      width: 1,
      color: theme.textColor.withValues(alpha: 0.1),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _RsvpButton extends StatelessWidget {
  const _RsvpButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final theme = ref.watch(themeColorsProvider);
        return InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.redBeige
                  : theme.textColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.redBeige
                    : theme.textColor.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : theme.textColor,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : theme.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<String?> _askForEmail(BuildContext context) async {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (_) => Consumer(
      builder: (context, ref, __) => AlertDialog(
        title: Text('Invite by Email'.tr),
        content: CoreTextField(
          label: 'E-mail'.tr,
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child:  Text('send'.tr),
          ),
        ],
      ),
    ),
  );
}
