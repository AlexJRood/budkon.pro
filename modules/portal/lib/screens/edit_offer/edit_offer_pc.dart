import 'dart:typed_data';
import 'dart:ui';

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/common/chrome/appbar_back.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:portal/screens/edit_offer/providers/edit_provider.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm/data/add_field/edit_sell_offer_provider.dart' as crm_edit;

// reuse nowych widgetów
import 'package:crm/contact_panel/sections/ad_view_widgets/main_image_widget.dart';
import 'package:crm/contact_panel/sections/ad_view_widgets/thumbnails_widget.dart';
import 'package:crm/contact_panel/sections/ad_view_widgets/price_row_widget.dart';
import 'package:crm/contact_panel/sections/ad_view_widgets/title_section_widget.dart';
import 'package:crm/contact_panel/sections/ad_view_widgets/address_text_widget.dart';
import 'package:crm/contact_panel/sections/ad_view_widgets/description_and_details_widget.dart';
import 'package:crm/contact_panel/sections/ad_view_widgets/map_section_widget.dart';
import 'package:crm/contact_panel/sections/ad_view_widgets/additional_details_widget.dart';

enum _MainPreviewSource {
  auto,
  local,
  server,
}

class PrivateEditOfferUnifiedPc extends ConsumerStatefulWidget {
  final int offerId;

  /// kept only for backward compatibility with old call sites
  final bool isMobile;

  const PrivateEditOfferUnifiedPc({
    super.key,
    required this.offerId,
    this.isMobile = false,
  });

  @override
  ConsumerState<PrivateEditOfferUnifiedPc> createState() =>
      _PrivateEditOfferUnifiedPcState();
}

class _PrivateEditOfferUnifiedPcState
    extends ConsumerState<PrivateEditOfferUnifiedPc> {
  late final ScrollController _scrollController;
  bool _showScrollToTop = false;
  _MainPreviewSource _previewSource = _MainPreviewSource.auto;
  final sideMenuKey = GlobalKey<SideMenuState>();


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

  _MainPreviewSource _resolvePreviewSource({
    required List<Uint8List> localImages,
    required List<String> serverUrls,
  }) {
    if (_previewSource == _MainPreviewSource.local && localImages.isNotEmpty) {
      return _MainPreviewSource.local;
    }

    if (_previewSource == _MainPreviewSource.server && serverUrls.isNotEmpty) {
      return _MainPreviewSource.server;
    }

    if (localImages.isNotEmpty) {
      return _MainPreviewSource.local;
    }

    if (serverUrls.isNotEmpty) {
      return _MainPreviewSource.server;
    }

    return _MainPreviewSource.auto;
  }

  Future<void> _save() async {
    final ok = await ref
        .read(privateEditOfferAdapterProvider(widget.offerId).notifier)
        .sendData(context, widget.offerId);

    if (!mounted) return;

    if (ok == true) {
      setState(() {
        _previewSource = _MainPreviewSource.auto;
      });

      await ref
          .read(privateEditOfferAdapterProvider(widget.offerId).notifier)
          .loadOfferData(widget.offerId, ref);
    }
  }

  Future<void> _reload() async {
    setState(() {
      _previewSource = _MainPreviewSource.auto;
    });

    await ref
        .read(privateEditOfferAdapterProvider(widget.offerId).notifier)
        .loadOfferData(widget.offerId, ref);
  }

  void _showPreviousImage({
    required List<Uint8List> localImages,
    required List<String> serverUrls,
  }) {
    final source = _resolvePreviewSource(
      localImages: localImages,
      serverUrls: serverUrls,
    );

    final notifier =
        ref.read(privateEditOfferAdapterProvider(widget.offerId).notifier);

    if (source == _MainPreviewSource.local) {
      if (localImages.length > 1) {
        notifier.cycleLocalImages(-1);
        return;
      }

      if (serverUrls.isNotEmpty) {
        setState(() {
          _previewSource = _MainPreviewSource.server;
        });
        return;
      }
    }

    if (source == _MainPreviewSource.server) {
      if (serverUrls.length > 1) {
        notifier.cycleServerImages(-1);
        return;
      }

      if (localImages.isNotEmpty) {
        setState(() {
          _previewSource = _MainPreviewSource.local;
        });
        return;
      }
    }
  }

  void _showNextImage({
    required List<Uint8List> localImages,
    required List<String> serverUrls,
  }) {
    final source = _resolvePreviewSource(
      localImages: localImages,
      serverUrls: serverUrls,
    );

    final notifier =
        ref.read(privateEditOfferAdapterProvider(widget.offerId).notifier);

    if (source == _MainPreviewSource.local) {
      if (localImages.length > 1) {
        notifier.cycleLocalImages(1);
        return;
      }

      if (serverUrls.isNotEmpty) {
        setState(() {
          _previewSource = _MainPreviewSource.server;
        });
        return;
      }
    }

    if (source == _MainPreviewSource.server) {
      if (serverUrls.length > 1) {
        notifier.cycleServerImages(1);
        return;
      }

      if (localImages.isNotEmpty) {
        setState(() {
          _previewSource = _MainPreviewSource.local;
        });
        return;
      }
    }
  }

  Future<void> _removeCurrentImage({
    required List<Uint8List> localImages,
    required List<String> serverUrls,
  }) async {
    final source = _resolvePreviewSource(
      localImages: localImages,
      serverUrls: serverUrls,
    );

    final notifier =
        ref.read(privateEditOfferAdapterProvider(widget.offerId).notifier);

    if (source == _MainPreviewSource.local && localImages.isNotEmpty) {
      notifier.removeImage(0);

      if (localImages.length == 1 && serverUrls.isNotEmpty && mounted) {
        setState(() {
          _previewSource = _MainPreviewSource.server;
        });
      }
      return;
    }

    if (source == _MainPreviewSource.server && serverUrls.isNotEmpty) {
      await notifier.removeServerImageAt(0);

      if (serverUrls.length == 1 && localImages.isNotEmpty && mounted) {
        setState(() {
          _previewSource = _MainPreviewSource.local;
        });
      }
    }
  }

  List<Widget> _buildStackChildren({
    required bool isMobileLayout,
    required ThemeColors theme,
    required crm_edit.EditOfferState state,
  }) {
    return [
      _buildPageBody(
        isMobileLayout: isMobileLayout,
        theme: theme,
        state: state,
      ),
      if (state.isLoading)
        Positioned.fill(
          child: Container(
            color: Colors.black.withAlpha(120),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      AnimatedPositioned(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        right: isMobileLayout ? 18 : 24,
        bottom: _showScrollToTop
            ? (isMobileLayout ? BottomBarSize.resolve(context) + 72 : 72)
            : -80,
        child: IgnorePointer(
          ignoring: !_showScrollToTop,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _showScrollToTop ? 1 : 0,
            child: FloatingActionButton.small(
              heroTag:
                  'private-edit-scroll-top-${widget.offerId}-${isMobileLayout ? 'mobile' : 'pc'}',
              backgroundColor: theme.themeColor,
              foregroundColor: theme.themeColorText,
              onPressed: () {
                _scrollToTop();
              },
              child: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildPageBody({
    required bool isMobileLayout,
    required ThemeColors theme,
    required crm_edit.EditOfferState state,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    final mainImageWidth = isMobileLayout
        ? (screenWidth - 16).toDouble()
        : (screenWidth * 0.62).clamp(700.0, 1320.0).toDouble();

    final mainImageHeight = mainImageWidth * (650 / 1200);

    final localImages = state.imagesData;
    final serverUrls = state.serverImageUrls;

    final visibleImagesCount = serverUrls.length + localImages.length;

    final previewSource = _resolvePreviewSource(
      localImages: localImages,
      serverUrls: serverUrls,
    );

    Uint8List? mainImageBytes;
    String? mainImageUrl;

    if (previewSource == _MainPreviewSource.local && localImages.isNotEmpty) {
      mainImageBytes = localImages.first;
    } else if (previewSource == _MainPreviewSource.server &&
        serverUrls.isNotEmpty) {
      mainImageUrl = serverUrls.first;
    } else if (localImages.isNotEmpty) {
      mainImageBytes = localImages.first;
    } else if (serverUrls.isNotEmpty) {
      mainImageUrl = serverUrls.first;
    }

    final mergedListenable = Listenable.merge([
      state.priceController,
      state.squareFootageController,
      state.currencyController,
    ]);

    final latitude = double.tryParse(
      state.latitudeController.text.trim().replaceAll(',', '.'),
    );
    final longitude = double.tryParse(
      state.longitudeController.text.trim().replaceAll(',', '.'),
    );

    return Column(
      children: [
        SizedBox(height: TopAppBarSize.withTopAppBar(context),),
        Expanded(
          child: SizedBox.expand(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  left: isMobileLayout ? 8 : 18,
                  right: isMobileLayout ? 8 : 18,
                  top: isMobileLayout ? TopAppBarSize.resolve(context) + 10 : 18,
                  bottom: isMobileLayout
                      ? BottomBarSize.resolve(context) + 24 + MediaQuery.of(context).viewInsets.bottom
                      : 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    children: [
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
                            final formattedPsm = NumberFormat.decimalPattern('fr')
                                .format(pricePerSquareMeter);
                            final currency =
                                state.currencyController.text.trim().isEmpty
                                    ? 'PLN'
                                    : state.currencyController.text.trim();

                            return Column(
                              children: [
                                _TopSummaryBar(
                                  theme: theme,
                                  imageCount: visibleImagesCount,
                                  priceText: '$formattedPrice $currency',
                                  psmText:
                                      areaVal > 0 ? '$formattedPsm $currency/m²' : '-',
                                  isMobile: isMobileLayout,
                                ),
                                const SizedBox(height: 14),
                                _EditModeNotice(theme: theme),
                                const SizedBox(height: 14),
                              ],
                            );
                          },
                        ),
                      ),

                      SizedBox(
                        width: mainImageWidth,
                        child: MainImageWidget(
                          mainImageBytes: mainImageBytes,
                          mainImageUrl: mainImageUrl,
                          mainImageWidth: mainImageWidth,
                          mainImageHeight: mainImageHeight,
                          canNavigateImages: visibleImagesCount > 1,
                          imageCount: visibleImagesCount,
                          onPrevPressed: visibleImagesCount > 1
                              ? () => _showPreviousImage(
                                    localImages: localImages,
                                    serverUrls: serverUrls,
                                  )
                              : null,
                          onNextPressed: visibleImagesCount > 1
                              ? () => _showNextImage(
                                    localImages: localImages,
                                    serverUrls: serverUrls,
                                  )
                              : null,
                          onRemovePressed: visibleImagesCount > 0
                              ? () {
                                  _removeCurrentImage(
                                    localImages: localImages,
                                    serverUrls: serverUrls,
                                  );
                                }
                              : null,
                          showRemoveButton: visibleImagesCount > 0,
                        ),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: mainImageWidth,
                        child: _ActionBar(
                          theme: theme,
                          onAddPhotos: () async {
                            final notifier = ref.read(
                              privateEditOfferAdapterProvider(widget.offerId).notifier,
                            );

                            await notifier.pickImage();

                            if (!mounted) return;

                            final freshState =
                                ref.read(privateEditOfferAdapterProvider(widget.offerId));

                            setState(() {
                              _previewSource = _resolvePreviewSource(
                                localImages: freshState.imagesData,
                                serverUrls: freshState.serverImageUrls,
                              );
                            });
                          },
                          onRemoveCurrent: visibleImagesCount > 0
                              ? () async {
                                  await _removeCurrentImage(
                                    localImages: localImages,
                                    serverUrls: serverUrls,
                                  );
                                }
                              : null,
                          onReload: _reload,
                          onSave: _save,
                        ),
                      ),

                      if (visibleImagesCount > 0) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: mainImageWidth,
                          child: _SectionCard(
                            theme: theme,
                            icon: Icons.photo_library_outlined,
                            title: 'Media'.tr,
                            subtitle: '$visibleImagesCount ${'elements'.tr}',
                            dense: true,
                            child: SizedBox(
                              height: 110,
                              child: Thumbnails(
                                adId: widget.offerId,
                                isEditing: true,
                                serverUrls: serverUrls,
                                localImages: localImages,
                                onServerTap: (url) {
                                  ref
                                      .read(
                                        privateEditOfferAdapterProvider(
                                          widget.offerId,
                                        ).notifier,
                                      )
                                      .setMainServerImageByUrl(url);

                                  if (mounted) {
                                    setState(() {
                                      _previewSource = _MainPreviewSource.server;
                                    });
                                  }
                                },
                                onLocalTap: (index) {
                                  ref
                                      .read(
                                        privateEditOfferAdapterProvider(
                                          widget.offerId,
                                        ).notifier,
                                      )
                                      .setMainImageIndex(index);

                                  if (mounted) {
                                    setState(() {
                                      _previewSource = _MainPreviewSource.local;
                                    });
                                  }
                                },
                                onServerRemove: (serverIndex, url) async {
                                  final ok = await ref
                                      .read(
                                        privateEditOfferAdapterProvider(widget.offerId).notifier,
                                      )
                                      .removeServerImageAt(serverIndex);

                                  if (!mounted) return ok;

                                  final freshState =
                                      ref.read(privateEditOfferAdapterProvider(widget.offerId));

                                  setState(() {
                                    _previewSource = _resolvePreviewSource(
                                      localImages: freshState.imagesData,
                                      serverUrls: freshState.serverImageUrls,
                                    );
                                  });

                                  return ok;
                                },
                                onLocalRemove: (localIndex) {
                                  ref
                                      .read(
                                        privateEditOfferAdapterProvider(widget.offerId).notifier,
                                      )
                                      .removeImage(localIndex);

                                  if (!mounted) return;

                                  final freshState =
                                      ref.read(privateEditOfferAdapterProvider(widget.offerId));

                                  setState(() {
                                    _previewSource = _resolvePreviewSource(
                                      localImages: freshState.imagesData,
                                      serverUrls: freshState.serverImageUrls,
                                    );
                                  });
                                },
                                onAddTap: () async {
                                  await ref
                                      .read(
                                        privateEditOfferAdapterProvider(widget.offerId).notifier,
                                      )
                                      .pickImage();

                                  if (!mounted) return;

                                  final freshState =
                                      ref.read(privateEditOfferAdapterProvider(widget.offerId));

                                  setState(() {
                                    _previewSource = _resolvePreviewSource(
                                      localImages: freshState.imagesData,
                                      serverUrls: freshState.serverImageUrls,
                                    );
                                  });
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
                                        isEditing: true,
                                        state: state,
                                        formattedPrice: formattedPrice,
                                        pricePerSquareMeter: pricePerSquareMeter,
                                        viewCurrency: viewCurrency,
                                        theme: theme,
                                      ),
                                      const SizedBox(height: 10),
                                      TitleSection(
                                        isEditing: true,
                                        titleController: state.titleController,
                                        theme: theme,
                                        mainWidth: mainImageWidth,
                                      ),
                                      const SizedBox(height: 6),
                                      AddressText(
                                        state: state,
                                        theme: theme,
                                      ),
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
                                isEditing: true,
                                state: state,
                                theme: theme,
                                isMobile: isMobileLayout,
                              ),
                            ),

                            const SizedBox(height: 16),

                            _SectionCard(
                              theme: theme,
                              icon: Icons.map_outlined,
                              title: 'location'.tr,
                              subtitle: 'map_and_location_subtitle'.tr,
                              child: MapSection(
                                adId: widget.offerId,
                                latitude: latitude,
                                longitude: longitude,
                              ),
                            ),

                            const SizedBox(height: 16),

                            _SectionCard(
                              theme: theme,
                              icon: Icons.tune_outlined,
                              title: 'additional_info'.tr,
                              subtitle: 'Media, Guilds and Status'.tr,
                              child: AdditionalDetails(
                                isEditing: true,
                                state: state,
                                theme: theme,
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: BottomBarSize.sizedBox40(context) + 20,),

      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(privateEditOfferAdapterProvider(widget.offerId));


    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      specialAppBar: const TopAppBarWithBack(),
      layoutTypePc: LayoutTypePc.stack,
      childrenPc: _buildStackChildren(
        isMobileLayout: false,
        theme: theme,
        state: state,
      ),
        childMobile: _buildPageBody(
          isMobileLayout: true,
          theme: theme,
          state: state,
        )
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.theme,
    required this.onAddPhotos,
    required this.onReload,
    required this.onSave,
    this.onRemoveCurrent,
  });

  final ThemeColors theme;
  final Future<void> Function() onAddPhotos;
  final Future<void> Function() onReload;
  final Future<void> Function() onSave;
  final Future<void> Function()? onRemoveCurrent;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            await onAddPhotos();
          },
          icon:  Icon(Icons.add_a_photo_outlined,color: theme.textColor),
          label: Text('add_photos'.tr,
          style: TextStyle(color: theme.textColor),),
        ),
        if (onRemoveCurrent != null)
          OutlinedButton.icon(
            onPressed: () async {
              await onRemoveCurrent!.call();
            },
            icon:  Icon(Icons.delete_outline_rounded,color: theme.textColor),
            label: Text('remove_current_photo'.tr,
              style: TextStyle(color: theme.textColor),),
          ),
        OutlinedButton.icon(
          onPressed: () async {
            await onReload();
          },
          icon:  Icon(Icons.refresh,color: theme.textColor),
          label: Text('refresh_tooltip'.tr,
            style: TextStyle(color: theme.textColor),),
        ),
        FilledButton.icon(
          onPressed: () async {
            await onSave();
          },
          icon:  Icon(Icons.save_outlined,color: theme.textColor),
          label: Text('save_changes_button'.tr,
            style: TextStyle(color: theme.textColor),),
        ),
      ],
    );
  }
}

class _TopSummaryBar extends StatelessWidget {
  const _TopSummaryBar({
    required this.theme,
    required this.imageCount,
    required this.priceText,
    required this.psmText,
    required this.isMobile,
  });

  final ThemeColors theme;
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
          icon: Icons.edit_outlined,
          label: 'edit_mode_label'.tr,
          accent: true,
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
              'The new view uses the old private API without touching CRM.'.tr,
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
    final borderColor = accent
        ? theme.themeColor.withAlpha(110)
        : theme.textFieldColor.withAlpha(110);

    final backgroundColor = accent
        ? theme.themeColor.withAlpha(22)
        : theme.textFieldColor.withAlpha(38);

    final iconColor = accent ? theme.themeColor : theme.textColor;

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