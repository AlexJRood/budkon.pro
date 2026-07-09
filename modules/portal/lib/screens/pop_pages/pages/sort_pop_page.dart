import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/shell/keyboard_shortcuts.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/screens/filters/widgets/components/sort_button.dart';
import 'package:core/platform/navigation_service.dart';

class SortPopPage extends ConsumerStatefulWidget {
  final Offset? buttonPosition;
  const SortPopPage({super.key, this.buttonPosition});

  @override
  SortPopPageState createState() => SortPopPageState();
}

class SortPopPageState extends ConsumerState<SortPopPage> with AutomaticKeepAliveClientMixin{
  late TextEditingController searchController;
  late TextEditingController excludeController;
  late TextEditingController minPriceController;
  late TextEditingController maxPriceController;
late FocusNode _focusNode;
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
     WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
    final filterNotifier = ref.read(filterProvider.notifier);
    searchController = TextEditingController(text: filterNotifier.searchQuery);
    excludeController =
        TextEditingController(text: filterNotifier.excludeQuery);
    minPriceController = TextEditingController(
        text: filterNotifier.filters['min_price']?.toString());
    maxPriceController = TextEditingController(
        text: filterNotifier.filters['max_price']?.toString());
  }

  @override
  void dispose() {
    searchController.dispose();
    excludeController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
     super.build(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Oblicz proporcję szerokości
    // double widthRatio = screenWidth / 1920.0;

    // Oblicz szerokość dla dynamicznego SizedBox
    //  double dynamicSizedBoxWidth = screenWidth * 0.5;
    //  double dynamicSizedBoxHeight = screenHeight * 0.5;

    return KeyboardListener(
       focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        // Check if the pressed key matches the stored pop key
        if (event.logicalKey == ref.read(popKeyProvider) &&
            event is KeyDownEvent) {
          if (Navigator.canPop(context)) {
            ref.read(navigationService).beamPop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Ta część odpowiada za efekt rozmycia tła
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withAlpha((255 * 0.5).toInt()),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Obsługa dotknięcia w dowolnym miejscu aby zamknąć modal
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Zawartość modalu
            Hero(
              tag: 'SortBarButton-${UniqueKey().toString()}', // need to be change both sides of hero need the same tag 
              child: Padding(
                padding: widget.buttonPosition != null
                    ? EdgeInsets.only(
                        left: widget.buttonPosition!.dx,
                        top: widget.buttonPosition!.dy)
                    : EdgeInsets.only(
                        right: screenWidth * 0.2, top: screenHeight * 0.05),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25.0),
                  child: Container(
                    width: screenWidth * 0.15 >= 250 ? 250 : 250,
                    height: screenHeight * 0.3 >= 450 ? 450 : 450,
                    padding: const EdgeInsets.all(20),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            FilterSortButton(
                              text: 'sort_price_asc'.tr,
                              filterKey: 'sort',
                              filterValue: 'price_asc',
                              icon: Icons
                                  .arrow_upward, // Ikona wskazująca rosnąco
                            ),
                            FilterSortButton(
                              text: 'sort_price_desc'.tr,
                              filterKey: 'sort',
                              filterValue: 'price_desc',
                              icon: Icons
                                  .arrow_downward, // Ikona wskazująca malejąco
                            ),
                            FilterSortButton(
                              text: 'sort_newest'.tr,
                              filterKey: 'sort',
                              filterValue: 'date_desc',
                              icon: Icons.new_releases,
                            ),
                            FilterSortButton(
                              text: 'sort_oldest'.tr,
                              filterKey: 'sort',
                              filterValue: 'date_asc',
                              icon: Icons.history, // Ikona dla najstarszych
                            ),

                            //Tutaj przyciski do sortowania
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
