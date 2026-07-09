import 'dart:math' as math;
import 'package:crm/crm_urls.dart';

import 'package:crm/contact_panel/sections/status_list.dart';
import 'package:crm/data/clients/client_fav_provider.dart';
import 'package:crm/pie_menu/ads_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/components/open_nm_ad.dart';
import 'package:network_monitoring/models/fav_status.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/data_table_with_infinity_scroll.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/status_dropdown.dart';
import 'package:core/platform/url.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:crm/contact_panel/sections/fav_status.dart';
import 'package:core/theme/font_size.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';

class FavListClientTable extends ConsumerStatefulWidget {
  final int? transactionId;
  final int? clientId;
  final bool isMobile;

  const FavListClientTable({
    super.key,
    this.transactionId,
    this.isMobile = false,
    this.clientId,
  });

  @override
  ConsumerState<FavListClientTable> createState() => _FavListClientTableState();
}

String truncateChars(String? src, {int max = 40, String ellipsis = '…'}) {
  final s = (src ?? '').trim();
  if (s.isEmpty) return 'no_title_label'.tr;
  final ch = s.characters;
  if (ch.length <= max) return s;
  return ch.take(max).toString() + ellipsis;
}

class _FavListClientTableState extends ConsumerState<FavListClientTable> {
  int _currentPage = 1;
  int _pageSize = 25;

  /// 🔘 Nowy filtr: ukrywanie wygasłych ogłoszeń
  bool _hideExpiredAds = false;

  // BEZPIECZNY SLICE: nigdy nie poda end > length
  List<MonitoringAdsModel> _slice(List<MonitoringAdsModel> all) {
    final start = (_currentPage - 1) * _pageSize;
    if (start >= all.length) return const [];
    final end = math.min(start + _pageSize, all.length);
    return all.sublist(start, end);
  }

  // ---- FavoriteMeta / Status helpers ----

  FavoriteMeta? _pickMeta(MonitoringAdsModel ad) {
    final metas = ad.favoriteMeta; // LISTA
    if (metas.isEmpty) return null;

    if (widget.transactionId != null) {
      final m = metas.firstWhereOrNull(
        (m) => m.transactions.any((t) => t.transactionId == widget.transactionId),
      );
      if (m != null) return m;
    }

    if (widget.clientId != null) {
      final m = metas.firstWhereOrNull((m) => m.clientId == widget.clientId);
      if (m != null) return m;
    }

    return metas.first;
  }

  int? _selectedStatusId(MonitoringAdsModel ad) {
    final meta = _pickMeta(ad);
    if (meta == null) return null;

    if (widget.transactionId != null) {
      final txLink =
          meta.transactions.firstWhereOrNull((t) => t.transactionId == widget.transactionId);
      if (txLink?.status?.id != null) {
        return txLink!.status!.id;
      }
    }
    return meta.status?.id;
  }

  Future<void> _onChangeStatus(
    BuildContext ctx,
    MonitoringAdsModel ad,
    int? newStatusId,
  ) async {
    final meta = _pickMeta(ad);
    if (meta == null) return;

    try {
      if (widget.transactionId != null) {
        await ApiServices.patch(
          CrmUrls.favoriteTxSetStatus(meta.favoriteId, widget.transactionId!),
          data: {'status_id': newStatusId},
          hasToken: true,
        );
      } else {
        await ApiServices.patch(
          CrmUrls.favoriteSetStatus(meta.favoriteId),
          data: {'status_id': newStatusId},
          hasToken: true,
        );
      }

      if (widget.transactionId != null) {
        ref.invalidate(clientFavProvider(widget.transactionId!));
      }
      ScaffoldMessenger.of(ctx).showSnackBar(
         SnackBar(content: Text('status_updated_message'.tr)),
      );
    } catch (e) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('${'failed_to_change_status'.tr} $e')),
      );
    }
  }

  Future<void> updateFavStatusType(
    WidgetRef ref,
    int id, {
    required String label,
    int? index,
  }) async {
    final resp = await ApiServices.patch(
      URLs.favoriteStatusTypesEdit(id),
      hasToken: true,
      data: {
        'label': label,
        if (index != null) 'index': index,
      },
    );
    if (resp == null || (resp.statusCode ?? 0) >= 300) {
      throw Exception('failed_to_change_status'.tr);
    }
    ref.invalidate(favStatusTypesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final size = ref.watch(fontSizeProvider(context));
    final sizeTitle = size.logoSize(25, 40).toInt();
    final sizeLocation = size.logoSize(20, 30).toInt();
    final padding = size.logoSize(4, 12);

    final asyncFavs = ref.watch(clientFavProvider(widget.transactionId!));
    final statusTypesAsync = ref.watch(favStatusTypesProvider);

    return asyncFavs.when(
      data: (allFavs) {
        if (allFavs.isEmpty) {
          return Center(
            child: Column(
              children: [
                AppLottie.noResults(),
                Text(
                  'no_search_results_message'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ],
            ),
          );
        }

        // ✅ Filtr UI: ukryj wygasłe
        final visibleFavs = _hideExpiredAds
            ? allFavs.where((ad) => ad.isActive == true).toList()
            : allFavs;

        // ✅ Zabezpieczenie paginacji po zmianie filtra
        final maxPage = visibleFavs.isEmpty ? 1 : ((visibleFavs.length - 1) ~/ _pageSize) + 1;
        if (_currentPage > maxPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _currentPage = 1);
            }
          });
        }

        final rows = _slice(visibleFavs);

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔘 Przycisk / przełącznik ukrywania wygasłych
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Switch(
                      value: _hideExpiredAds,
                      onChanged: (value) {
                        setState(() {
                          _hideExpiredAds = value;
                          _currentPage = 1;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'hide_expired_ads_label'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                    Text(
                      '${'visible_label'.tr}: ${visibleFavs.length}/${allFavs.length}',
                      style: TextStyle(
                        color: theme.textColor.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: AppPaginatedTable<MonitoringAdsModel>(
                  selectable: false,
                  rows: rows,
                  totalCount: visibleFavs.length,
                  rowKey: (ad) => ad.id,
                  headingColor: theme.dashboardContainer,
                  columns: [
                    AppTableColumn<MonitoringAdsModel>(
                      header: Text(''.tr, style: TextStyle(color: theme.textColor)),
                      width: 42,
                      cellBuilder: (ctx, ad) {
                        return Row(
                          children: [
                            IconButton(
                              tooltip: 'remove_from_favorite_tooltip'.tr,
                              icon: AppIcons.heart(color: theme.textColor),
                              onPressed: () async {
                                await handleFavoriteActionNM(
                                  ref,
                                  ad.id,
                                  widget.transactionId,
                                  widget.clientId,
                                  context,
                                );
                                if (widget.transactionId != null) {
                                  ref.invalidate(clientFavProvider(widget.transactionId!));
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),

                    // Miniatura
                    AppTableColumn<MonitoringAdsModel>(
                      header: Text('photo_column_header'.tr, style: TextStyle(color: theme.textColor)),
                      width: 72,
                      cellBuilder: (ctx, ad) {
                        final thumb = ad.mainImageUrl;
                        final isDefault = thumb.isEmpty || thumb == 'default_image_url';
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 56,
                            height: 40,
                            color: theme.dashboardContainer,
                            child: isDefault
                                ? Image.asset(
                                    'assets/images/deafult/house.webp',
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(thumb, fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),

                    // Tytuł
                    AppTableColumn<MonitoringAdsModel>(
                      header: Text('title_column_header'.tr, style: TextStyle(color: theme.textColor)),
                      flex: 3,
                      cellBuilder: (ctx, ad) {
                        final full = (ad.title == null || ad.title!.trim().isEmpty)
                            ? 'no_title_placeholder'.tr
                            : ad.title!;
                        final title = truncateChars(full, max: sizeTitle);

                        return Tooltip(
                          message: full,
                          child: Text(
                            ad.isActive == true ? title : 'ad_expired_label'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: TextStyle(color: theme.textColor),
                          ),
                        );
                      },
                    ),

                    // Cena
                    AppTableColumn<MonitoringAdsModel>(
                      header: Text('price_column_header'.tr, style: TextStyle(color: theme.textColor)),
                      width: 140,
                      cellBuilder: (ctx, ad) =>
                          Text(ad.priceText, style: TextStyle(color: theme.textColor)),
                    ),

                    // Lokalizacja
                    AppTableColumn<MonitoringAdsModel>(
                      header: Text('localization_column_header'.tr, style: TextStyle(color: theme.textColor)),
                      flex: 3,
                      cellBuilder: (ctx, ad) {
                        final city = (ad.city == null || ad.city!.isEmpty) ? '—' : ad.city!;
                        final district =
                            (ad.district == null || ad.district!.isEmpty) ? '' : ', ${ad.district!}';
                        final full = district.isEmpty ? city : '$city$district';
                        final addr = truncateChars(full, max: sizeLocation);

                        return Tooltip(
                          message: full,
                          child: Text(
                            addr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: TextStyle(color: theme.textColor),
                          ),
                        );
                      },
                    ),

                    // Parametry
                    AppTableColumn<MonitoringAdsModel>(
                      header: Text('parameters_column_header'.tr, style: TextStyle(color: theme.textColor)),
                      flex: 2,
                      cellBuilder: (ctx, ad) {
                        final parts = <String>[];
                        if (ad.squareFootage != null) {
                          parts.add('${ad.squareFootageText} m²');
                        }
                        if (ad.rooms != null) {
                          parts.add('${ad.roomsText} pok.');
                        }
                        return Text(
                          parts.isEmpty ? '—' : parts.join(' • '),
                          style: TextStyle(color: theme.textColor),
                        );
                      },
                    ),

                    // Statusy
                    AppTableColumn<MonitoringAdsModel>(
                      header: Text('statuses_column_header'.tr, style: TextStyle(color: theme.textColor)),
                      width: 300,
                      cellBuilder: (ctx, ad) {
                        final selectedId = _selectedStatusId(ad);

                        return statusTypesAsync.when(
                          data: (options) {
                            // PUSTA LISTA — pokaż CTA "Add first status"
                            if (options.isEmpty) {
                              return Row(
                                children: [
                                  ElevatedButton(
                                    style: elevatedButtonStyleRounded10,
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (dCtx) => Dialog(
                                        backgroundColor: theme.adPopBackground,
                                        insetPadding: const EdgeInsets.all(12),
                                        child: const SizedBox(
                                          width: 520,
                                          height: 520,
                                          child: FavStatusDialog(),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          'add_first_status_button'.tr,
                                          style: TextStyle(color: theme.textColor),
                                        ),
                                        AppIcons.add(color: theme.textColor),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }

                            // Są opcje — zwykły dropdown + przycisk zarządzania
                            return Row(
                              children: [
                                Expanded(
                                  child: AppStatusDropdownField(
                                    ref: ref,
                                    value: selectedId,
                                    options: options,
                                    onChanged: (v) => _onChangeStatus(ctx, ad, v),
                                    haveBorder: false,
                                    haveLabel: false,
                                    width: 220,
                                    height: 44,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'manage_statuses_tooltip'.tr,
                                  icon: AppIcons.moreVertical(color: theme.textColor),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (dCtx) => Dialog(
                                      backgroundColor: theme.adPopBackground,
                                      insetPadding: const EdgeInsets.all(12),
                                      child: const SizedBox(
                                        width: 520,
                                        height: 520,
                                        child: FavStatusDialog(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox(
                            width: 220,
                            height: 44,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => Text('${'error_prefix'.tr} $e'),
                        );
                      },
                    ),
                  ],
                  selectedKeys: const <Object>{},
                  onSelectionChanged: (set) {},
                  onRowTap: (ad) {
                    openAdUrl(
                      context,
                      ref,
                      ad,
                      widget.transactionId,
                      widget.clientId,
                      '${ad.id} - ${widget.transactionId} - ${widget.clientId}',
                    );
                  },
                  currentPage: _currentPage,
                  pageSize: _pageSize,
                  onPageChanged: (p) => setState(() => _currentPage = p),
                  onPageSizeChanged: (s) => setState(() {
                    _pageSize = s;
                    _currentPage = 1;
                  }),
                  enableInfiniteScroll: true,
                  appendPaging: false,
                  emptyText: _hideExpiredAds
                      ? 'no_active_favorites_message'.tr
                      : 'no_favorites_for_transaction'.tr,
                  rowExtent: 56,
                  headerExtent: 56,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('${'error_prefix'.tr} $e'.tr, style: AppTextStyles.interLight),
      ),
    );
  }
}