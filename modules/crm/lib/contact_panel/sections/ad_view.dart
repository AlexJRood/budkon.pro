import 'dart:typed_data';
import 'dart:ui';

import 'package:core/ui/device_type_util.dart';
import 'package:crm/draft_ads_listview_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm/data/add_field/edit_sell_offer_provider.dart';

// Sections
import 'ad_view_widgets/main_image_widget.dart';
import 'ad_view_widgets/price_row_widget.dart';
import 'ad_view_widgets/thumbnails_widget.dart';
import 'ad_view_widgets/title_section_widget.dart';
import 'ad_view_widgets/address_text_widget.dart';
import 'ad_view_widgets/description_and_details_widget.dart';
import 'ad_view_widgets/map_section_widget.dart';
import 'ad_view_widgets/additional_details_widget.dart';
import 'ad_view_widgets/floating_actions_widget.dart';



void copyToClipboard(BuildContext context, String listingUrl) async {
  await Clipboard.setData(ClipboardData(text: listingUrl));
  if (!context.mounted) return;
  final successSnackBar = Customsnackbar().showSnackBar(
    "success".tr,
    'link_copied_to_clipboard'.tr,
    "success",
    () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    },
  );
  ScaffoldMessenger.of(context).showSnackBar(successSnackBar);
}

extension ContextExtension on BuildContext {
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

double _parseNum(String? input) {
  var s = (input ?? '').trim();
  if (s.isEmpty) return 0.0;

  s = s.replaceAll(RegExp(r'[^\d,.\-]'), '');

  if (s.contains(',') && s.contains('.')) {
    s = s.replaceAll(',', '');
  } else if (s.contains(',')) {
    s = s.replaceAll(',', '.');
  }

  return double.tryParse(s) ?? 0.0;
}

int _getVisibleImagesCount({
  required bool isEditing,
  required List<String> serverUrls,
  required List<Uint8List> localImages,
}) {
  if (isEditing) {
    return serverUrls.length + localImages.length;
  }
  return serverUrls.length;
}

class AdViewClient extends ConsumerStatefulWidget {
  final DraftAdsListViewModel adFeedPop;
  final bool isMobile;
  final bool canEdit;
  final bool isClientPortal;
  final String? portalId;

  const AdViewClient({
    super.key,
    this.isMobile = false,
    required this.adFeedPop,
    this.canEdit = true,
    this.isClientPortal = false,
    this.portalId,
  });

  @override
  ConsumerState<AdViewClient> createState() => _AdViewClientState();
}

class _AdViewClientState extends ConsumerState<AdViewClient> {
  String? _lastAutoSyncedMainUrl;
  late final ScrollController _scrollController;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow =
        _scrollController.hasClients && _scrollController.offset > 500;
    if (shouldShow != _showScrollToTop && mounted) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _syncMainImageIfNeeded({
    required int adId,
    required List<String> serverUrls,
  }) {
    if (serverUrls.isEmpty) return;

    final firstUrl = serverUrls.first;
    final currentMain = ref.read(adMainImageUrlProvider(adId));

    if (currentMain.isNotEmpty) return;
    if (_lastAutoSyncedMainUrl == firstUrl) return;

    _lastAutoSyncedMainUrl = firstUrl;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final latest = ref.read(adMainImageUrlProvider(adId));
      if (latest.isEmpty) {
        ref.read(adMainImageUrlProvider(adId).notifier).state = firstUrl;
      }
    });
  }

  Future<void> _enterEditMode(int adId) async {
    ref.read(adEditingProvider(adId).notifier).state = true;
    await ref
        .read(crmEditSellOfferProvider(adId).notifier)
        .loadOfferData(adId, ref);
  }

  Future<void> _addPhotoFromEmptyState(int adId, bool isEditing) async {
    if (!isEditing) {
      await _enterEditMode(adId);
    }

    if (!mounted) return;

    await ref.read(crmEditSellOfferProvider(adId).notifier).pickImage();
  }

  Future<void> _saveChanges(BuildContext context, int adId) async {
    final ok = await ref.read(crmEditSellOfferProvider(adId).notifier).sendData(
          context,
          adId,
          isClientPortal: widget.isClientPortal,
          portalUuid: widget.portalId,
        );

    if (!mounted) return;

    if (ok == true) {
      await ref
          .read(crmEditSellOfferProvider(adId).notifier)
          .loadOfferData(adId, ref);

      if (!mounted) return;

      final newState = ref.read(crmEditSellOfferProvider(adId));
      if (newState.serverImageUrls.isNotEmpty) {
        ref.read(adMainImageUrlProvider(adId).notifier).state =
            newState.serverImageUrls.first;
      } else {
        ref.read(adMainImageUrlProvider(adId).notifier).state = '';
      }

      ref.read(adEditingProvider(adId).notifier).state = false;
    }
  }

  void _cancelEdit(BuildContext context, int adId) {
    ref.read(adEditingProvider(adId).notifier).state = false;
    context.showSnackBar('edit_cancelled_message'.tr);
  }

  void _showPreviousImage({
    required int adId,
    required bool isEditing,
    required List<String> serverUrls,
    required List<Uint8List> localImages,
  }) {
    if (isEditing && localImages.length > 1) {
      ref
          .read(crmEditSellOfferProvider(adId).notifier)
          .cycleLocalImages(-1);
      return;
    }

    if (serverUrls.length <= 1) return;

    final current = ref.read(adMainImageUrlProvider(adId));
    int index = current.isNotEmpty ? serverUrls.indexOf(current) : 0;
    if (index < 0) index = 0;

    final previousIndex = (index - 1 + serverUrls.length) % serverUrls.length;
    ref.read(adMainImageUrlProvider(adId).notifier).state =
        serverUrls[previousIndex];
  }

  void _showNextImage({
    required int adId,
    required bool isEditing,
    required List<String> serverUrls,
    required List<Uint8List> localImages,
  }) {
    if (isEditing && localImages.length > 1) {
      ref
          .read(crmEditSellOfferProvider(adId).notifier)
          .cycleLocalImages(1);
      return;
    }

    if (serverUrls.length <= 1) return;

    final current = ref.read(adMainImageUrlProvider(adId));
    int index = current.isNotEmpty ? serverUrls.indexOf(current) : 0;
    if (index < 0) index = 0;

    final nextIndex = (index + 1) % serverUrls.length;
    ref.read(adMainImageUrlProvider(adId).notifier).state =
        serverUrls[nextIndex];
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final adId = widget.adFeedPop.id;
    final state = ref.watch(crmEditSellOfferProvider(adId));
    final isEditing =
        widget.canEdit ? ref.watch(adEditingProvider(adId)) : false;

    final screenWidth = MediaQuery.of(context).size.width;
    final mainImageWidth = widget.isMobile ? screenWidth - 16 : screenWidth * 0.625;
    final mainImageHeight = mainImageWidth * (650 / 1200);

    final List<String> serverUrls = isEditing
        ? state.serverImageUrls
        : (state.serverImageUrls.isNotEmpty
            ? state.serverImageUrls
            : List<String>.from(widget.adFeedPop.images ?? const []));

    _syncMainImageIfNeeded(
      adId: adId,
      serverUrls: serverUrls,
    );

    final selectedMainUrl = ref.watch(adMainImageUrlProvider(adId));

    String? displayedServerUrl;
    if (serverUrls.isNotEmpty) {
      if (selectedMainUrl.isNotEmpty && serverUrls.contains(selectedMainUrl)) {
        displayedServerUrl = selectedMainUrl;
      } else {
        displayedServerUrl = serverUrls.first;
      }
    }

    final List<Uint8List> localImages = isEditing ? state.imagesData : const [];
    final visibleImagesCount = _getVisibleImagesCount(
      isEditing: isEditing,
      serverUrls: serverUrls,
      localImages: localImages,
    );
    final showThumbnails = visibleImagesCount > 1 || isEditing;

    Uint8List? mainImageBytes;
    if (isEditing && localImages.isNotEmpty) {
      mainImageBytes = localImages.first;
    }

    final mergedListenable = Listenable.merge([
      state.priceController,
      state.squareFootageController,
      state.currencyController,
    ]);

    final double actionBottomPadding =
        widget.canEdit ? (widget.isMobile ? 118 : 40) : 24;

    return SizedBox.expand(
      child: Stack(
        children: [
          Align(
            alignment: widget.isMobile 
                ? Alignment.center 
                : widget.isClientPortal 
                  ? Alignment.center 
                  : Alignment.topLeft,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.only(
                left: widget.isMobile ? 8 : 0,
                right: widget.isMobile ? 8 : 12,
                bottom: actionBottomPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // if (widget.isMobile)
                  //   SizedBox(height: TopAppBarSize.resolve(context) + 10),

                  SizedBox(
                    width: mainImageWidth,
                    child: AnimatedBuilder(
                      animation: mergedListenable,
                      builder: (_, __) {
                        final priceVal = _parseNum(state.priceController.text);
                        final areaVal =
                            _parseNum(state.squareFootageController.text);
                        final pricePerSquareMeter =
                            areaVal > 0 ? (priceVal / areaVal) : 0.0;
                        final formattedPrice =
                            NumberFormat.decimalPattern('fr').format(priceVal);
                        final formattedPsm =
                            NumberFormat.decimalPattern('fr').format(
                          pricePerSquareMeter,
                        );
                        final currency =
                            state.currencyController.text.trim().isEmpty
                                ? 'PLN'
                                : state.currencyController.text.trim();

                        return Column(
                          children: [
                            _TopSummaryBar(
                              theme: theme,
                              isEditing: isEditing,
                              imageCount: visibleImagesCount,
                              priceText: '$formattedPrice $currency',
                              psmText: areaVal > 0
                                  ? '$formattedPsm $currency/m²'
                                  : '-',
                              isMobile: widget.isMobile,
                            ),
                            const SizedBox(height: 14),
                          ],
                        );
                      },
                    ),
                  ),

                  if (isEditing)
                    SizedBox(
                      width: mainImageWidth,
                      child: Column(
                        children: [
                          _EditModeNotice(theme: theme),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),

                  SizedBox(
                    width: mainImageWidth,
                    child: MainImageWidget(
                      mainImageBytes: mainImageBytes,
                      mainImageUrl: mainImageBytes == null ? displayedServerUrl : null,
                      mainImageWidth: mainImageWidth,
                      mainImageHeight: mainImageHeight,
                      canNavigateImages: visibleImagesCount > 1,
                      imageCount: visibleImagesCount,
                      onPrevPressed: () => _showPreviousImage(
                        adId: adId,
                        isEditing: isEditing,
                        serverUrls: serverUrls,
                        localImages: localImages,
                      ),
                      onNextPressed: () => _showNextImage(
                        adId: adId,
                        isEditing: isEditing,
                        serverUrls: serverUrls,
                        localImages: localImages,
                      ),
                      onAddPressed: widget.canEdit && visibleImagesCount == 0
                          ? () => _addPhotoFromEmptyState(adId, isEditing)
                          : null,
                    ),
                  ),

                  if (showThumbnails) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: mainImageWidth,
                      child: _SectionCard(
                        theme: theme,
                        icon: Icons.photo_library_outlined,
                        title: 'photos_title'.tr,
                        subtitle: '${visibleImagesCount.toString()} ${'items_count_label'.tr}',
                        dense: true,
                        child: SizedBox(
                          height: 110,
                          child: Thumbnails(
                            adId: adId,
                            isEditing: isEditing,
                            serverUrls: serverUrls,
                            localImages: localImages,
                            onServerTap: (url) {
                              ref.read(adMainImageUrlProvider(adId).notifier).state =
                                  url;
                            },
                            onLocalTap: (index) {
                              ref
                                  .read(crmEditSellOfferProvider(adId).notifier)
                                  .setMainImageIndex(index);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  SizedBox(
                    width: mainImageWidth,
                    child: Column(
                      children: [
                        _SectionCard(
                          theme: theme,
                          icon: Icons.sell_outlined,
                          title: 'offer_summary_title'.tr,
                          child: AnimatedBuilder(
                            animation: mergedListenable,
                            builder: (_, __) {
                              final priceVal = _parseNum(state.priceController.text);
                              final areaVal =
                                  _parseNum(state.squareFootageController.text);
                              final pricePerSquareMeter =
                                  areaVal > 0 ? (priceVal / areaVal) : 0.0;
                              final formattedPrice =
                                  NumberFormat.decimalPattern('fr')
                                      .format(priceVal);
                              final viewCurrency = state.currencyController.text;

                              return Column(
                                children: [
                                  PriceRow(
                                    isEditing: isEditing,
                                    state: state,
                                    formattedPrice: formattedPrice,
                                    pricePerSquareMeter: pricePerSquareMeter,
                                    viewCurrency: viewCurrency,
                                    theme: theme,
                                  ),
                                  const SizedBox(height: 10),
                                  TitleSection(
                                    isEditing: isEditing,
                                    titleController: state.titleController,
                                    theme: theme,
                                    mainWidth: mainImageWidth,
                                  ),
                                  const SizedBox(height: 6),
                                  AddressText(state: state, theme: theme),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        _SectionCard(
                          theme: theme,
                          icon: Icons.description_outlined,
                          title: 'description_and_basic_data_title'.tr,
                          child: DescriptionAndDetails(
                            isEditing: isEditing,
                            state: state,
                            theme: theme,
                            isMobile: widget.isMobile,
                          ),
                        ),

                        const SizedBox(height: 16),

                        _SectionCard(
                          theme: theme,
                          icon: Icons.map_outlined,
                          title: 'location_title'.tr,
                          subtitle: 'map_and_location_subtitle'.tr,
                          child: MapSection(
                            adId: adId,
                            latitude: widget.adFeedPop.latitude,
                            longitude: widget.adFeedPop.longitude,
                          ),
                        ),

                        const SizedBox(height: 16),

                        _SectionCard(
                          theme: theme,
                          icon: Icons.tune_outlined,
                          title: 'additional_information_title'.tr,
                          subtitle: 'media_features_status_subtitle'.tr,
                          child: AdditionalDetails(
                            isEditing: isEditing,
                            state: state,
                            theme: theme,
                          ),
                        ),

                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (widget.canEdit && !widget.isMobile)
            Positioned(
              top: !widget.isClientPortal
                  ? TopAppBarSize.resolve(context) + 10
                  : 10,
              right: 10,
              child: FloatingActions(
                isClientPortal: widget.isClientPortal,
                canEdit: widget.canEdit,
                adId: adId,
                isEditing: isEditing,
                theme: theme,
                onEnterEdit: () => _enterEditMode(adId),
                onSave: () => _saveChanges(context, adId),
                onCancel: () => _cancelEdit(context, adId),
                adFeedPop: widget.adFeedPop,
              ),
            ),

          if (widget.canEdit && widget.isMobile)
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: SafeArea(
                top: false,
                child: FloatingActions(
                  isClientPortal: widget.isClientPortal,
                  canEdit: widget.canEdit,
                  adId: adId,
                  isEditing: isEditing,
                  theme: theme,
                  onEnterEdit: () => _enterEditMode(adId),
                  onSave: () => _saveChanges(context, adId),
                  onCancel: () => _cancelEdit(context, adId),
                  adFeedPop: widget.adFeedPop,
                ),
              ),
            ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            right: widget.isMobile ? 12 : 24,
            bottom: _showScrollToTop
                ? (widget.isMobile && widget.canEdit ? 86 : 20)
                : -80,
            child: IgnorePointer(
              ignoring: !_showScrollToTop,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showScrollToTop ? 1 : 0,
                child: FloatingActionButton.small(
                  heroTag: 'ad-view-scroll-top-${widget.adFeedPop.id}',
                  backgroundColor: theme.themeColor,
                  foregroundColor: theme.themeColorText,
                  onPressed: _scrollToTop,
                  child: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopSummaryBar extends StatelessWidget {
  const _TopSummaryBar({
    required this.theme,
    required this.isEditing,
    required this.imageCount,
    required this.priceText,
    required this.psmText,
    required this.isMobile,
  });

  final ThemeColors theme;
  final bool isEditing;
  final int imageCount;
  final String priceText;
  final String psmText;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final content = Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _InfoPill(
          theme: theme,
          icon: Icons.sell_outlined,
          label: priceText,
          strong: true,
        ),
        _InfoPill(
          theme: theme,
          icon: Icons.square_foot_outlined,
          label: psmText,
        ),
        _InfoPill(
          theme: theme,
          icon: Icons.photo_library_outlined,
          label: '$imageCount ${'photos_count_label'.tr}',
        ),
        _InfoPill(
          theme: theme,
          icon: isEditing ? Icons.edit_outlined : Icons.visibility_outlined,
          label: isEditing ? 'edit_mode_label'.tr : 'preview_label'.tr,
          accent: isEditing,
        ),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: isMobile ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: theme.dashboardContainer.withAlpha(180),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.textFieldColor.withAlpha(120),
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}

class _EditModeNotice extends StatelessWidget {
  const _EditModeNotice({
    required this.theme,
  });

  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.themeColor.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: theme.themeColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'edit_mode_notice_message'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.theme,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.dense = false,
  });

  final ThemeColors theme;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: EdgeInsets.all(dense ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.dashboardContainer.withAlpha(92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.textFieldColor.withAlpha(115),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.themeColor.withAlpha(22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: theme.themeColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(165),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.theme,
    required this.icon,
    required this.label,
    this.strong = false,
    this.accent = false,
  });

  final ThemeColors theme;
  final IconData icon;
  final String label;
  final bool strong;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = accent
        ? theme.themeColor.withAlpha(110)
        : theme.textFieldColor.withAlpha(110);

    final Color backgroundColor = accent
        ? theme.themeColor.withAlpha(22)
        : theme.textFieldColor.withAlpha(38);

    final Color iconColor = accent ? theme.themeColor : theme.textColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 13,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}