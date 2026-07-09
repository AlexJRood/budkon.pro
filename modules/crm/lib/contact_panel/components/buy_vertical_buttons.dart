




import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/add_search.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/filtered_button.dart';
import 'package:crm/contact_panel/tabs/saved_search_client/components/sort.dart';
import 'package:crm/contact_panel/tabs/transactions/transaction_docs_view.dart';
import 'package:crm/contact_panel/tabs/transactions/transaction_view.dart';
import 'package:crm/contact_panel/tabs/transactions/view_provider.dart';
import 'package:crm/data/clients/ad_provider.dart';
import 'package:crm/data/clients/client_saved_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/utils.dart';
import 'package:network_monitoring/browselist/widget/pc.dart';
import 'package:network_monitoring/components/cards/provider.dart';
import 'package:network_monitoring/models/saved_search_model.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';




class ClientPanelVerticalButtons extends ConsumerStatefulWidget {
  final int? transactionId;
  final int? clientId;

  const ClientPanelVerticalButtons({
    super.key,
    this.transactionId,
    this.clientId,
  });

  @override
  ConsumerState<ClientPanelVerticalButtons> createState() =>
      _ClientPanelVerticalButtonsState();
}

class _ClientPanelVerticalButtonsState extends ConsumerState<ClientPanelVerticalButtons>
    with SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(viewModeControllerProvider(TransactionType.buy));
    final mode = vm.selected;
    final theme = ref.read(themeColorsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 2,
      children: [

        if(mode == TransactionViewMode.search)...[


        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          color: theme.textFieldColor,
          ),
          height: 45,
          width: 45,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed:() => _openSearchSheet(context, ref, widget.transactionId!, widget.clientId!),
            child: SizedBox(
              height: 25,
              width: 25,
              child: AppIcons.filterAlt(color: theme.textColor)
            )
              ),
        ), 

        
        
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          color: theme.textFieldColor,
          ),
          height: 45,
          width: 45,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed:() => _openSortSheet(context, ref),
            child: SizedBox(
              height: 25,
              width: 25,
              child: AppIcons.sort(color: theme.textColor)
            )
              ),
        ),  
        ],
        


        if(mode == TransactionViewMode.search || mode == TransactionViewMode.fav)...[

                Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          color: theme.textFieldColor,
          ),
          height: 45,
          width: 45,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed:() => _openBrowseSheet(context, ref, widget.transactionId!, widget.clientId!),
            child: SizedBox(
              height: 25,
              width: 25,
              child: AppIcons.archive(color: theme.textColor)
            )
              ),
        ),
        ],
        

        
        if (mode == TransactionViewMode.docs) ...[
          const TransactionDocsUploadFileButton(),
          const TransactionDocsAddFolderButton(),
        ],
        



        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          color: theme.textFieldColor,
          ),
          height: 45,
          width: 45,
          child: ElevatedButton(
            style: elevatedButtonStyleRounded10,
            onPressed:() => _openViewSheet(context, ref),
            child: SizedBox(
              height: 25,
              width: 25,
              child: AppIcons.viewList(color: theme.textColor)
            )
              ),
        ), 
      ],
    );
  }
}





Future<void> _openViewSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final theme = ref.read(themeColorsProvider);

  await showHouslyBottomSheet(
    context: context,
    ref: ref,
    title: 'View'.tr,
    initialChildSize: 0.65,
    minChildSize: 0.4,
    maxChildSize: 0.95,
    bodyBuilder: (ctx, ref, controller) {
      // Non-scrollable content? Wrap in SingleChildScrollView to enable sheet drag + internal scroll.
      return  Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ViewModeTransaction(
              isMobile: true,
              isClientView: true,
              type: TransactionType.buy, // lub sell w innym miejscu (patrz AdActionsPanel)
            ),

            const SizedBox(height: 20),
          ],
      );
    },
  );
}




Future<void> _openSortSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final theme = ref.read(themeColorsProvider);

  await showHouslyBottomSheet(
    context: context,
    ref: ref,
    title: 'View'.tr,
    initialChildSize: 0.6,
    minChildSize: 0.2,
    maxChildSize: 0.9,
    bodyBuilder: (ctx, ref, controller) {
      return SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Cards type
            CardTypeSelectorNM(),
            const SizedBox(height: 10),

            // Quick filter chips (your existing buttons)
            ClientPanelAdditionalInfoFilteredButton(
              hasIcon: true,
              height: 45,
              text: 'Favorites'.tr,
              filterKey: 'exclude_favorites',
              onClick: () {
                ref.read(filterProvider.notifier)
                  .applyFiltersFromCache(ref.read(filterCacheProvider.notifier), ref);
              },
              hasBorder: false,
            ),
            ClientPanelAdditionalInfoFilteredButton(
              height: 45,
              hasIcon: true,
              text: 'hide'.tr,
              filterKey: 'exclude_hide',
              onClick: () {
                ref.read(filterProvider.notifier)
                  .applyFiltersFromCache(ref.read(filterCacheProvider.notifier), ref);
              },
              hasBorder: false,
            ),
            ClientPanelAdditionalInfoFilteredButton(
              hasIcon: true,
              height: 45,
              text: 'Displayed'.tr,
              filterKey: 'exclude_displayed',
              onClick: () {
                ref.read(filterProvider.notifier)
                  .applyFiltersFromCache(ref.read(filterCacheProvider.notifier), ref);
              },
              hasBorder: false,
            ),

            const SizedBox(height: 15),

            // Sort dropdown area
            Container(
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              width: double.infinity,
              height: 50,
              child: ClientPanelDropdownSortSelector(),
            ),

            const SizedBox(height: 15),
          ],
        ),
      );
    },
  );
}













Future<void> _openSearchSheet(
  BuildContext context,
  WidgetRef ref,
  int transactionId,
  int clientId,
) async {
  final theme = ref.read(themeColorsProvider);
  final savedSearchesAsyncValue =
      ref.watch(transactionSavedSearchesProvider(transactionId));

  await showHouslyBottomSheet(
    context: context,
    ref: ref,
    title: 'Saved searches'.tr,
    initialChildSize: 0.87,
    minChildSize: 0.7,
    maxChildSize: 0.95,
    bodyBuilder: (ctx, ref, controller) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // "Add Search" button aligned right (under title)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: elevatedButtonStyleRounded10withoutPadding,
                onPressed: () {
                  // If you still want a nested full-screen sheet, you can reuse the same launcher:
                  showHouslyBottomSheet(
                    context: ctx,
                    ref: ref,
                    title: 'Add Search'.tr,
                    initialChildSize: 0.9,
                    minChildSize: 0.7,
                    maxChildSize: 0.95,
                    bodyBuilder: (ctx, ref, innerController) {
                      return SingleChildScrollView(
                        controller: innerController,
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: AddSearchClientPanel(
                            sheetController: innerController,
                            isMobile:true,
                            needBackground: false,
                            transactionId: transactionId,
                            clientId: clientId,
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: theme.dashboardContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: theme.textColor, size: 18),
                      const SizedBox(width: 6),
                      Text('Add Search'.tr, style: TextStyle(color: theme.textColor)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // The core content (attach controller if list needs to scroll the sheet)
            Expanded(
              child: savedSearchesAsyncValue.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, __) => SavedSearchCardsInline(
                  sheetController: controller,
                  savedSearches: const [],
                  clientId: clientId,
                  transactionId: transactionId,
                ),
                data: (savedSearches) => SavedSearchCardsInline(
                  sheetController: controller,
                  savedSearches: savedSearches,
                  clientId: clientId,
                  transactionId: transactionId,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}








class SavedSearchCardsInline extends ConsumerStatefulWidget {
  final List<SavedSearchModel> savedSearches;
  final int clientId;
  final int transactionId;
  final ScrollController? sheetController;

  const SavedSearchCardsInline({
    super.key,
    this.sheetController,
    required this.savedSearches,
    required this.clientId,
    required this.transactionId,
  });

  @override
  ConsumerState<SavedSearchCardsInline> createState() =>
      _SavedSearchCardsInlineState();
}

class _SavedSearchCardsInlineState
    extends ConsumerState<SavedSearchCardsInline> {
  // Keep temporary selected IDs for this sheet session
  late Set<int> temp;

  @override
  void initState() {
    super.initState();
    // start with currently selected ids from filterProvider
    temp = {
      ...ref.read(filterProvider.notifier).selectedSavedSearchIds,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // "Show all" toggle (empty set => show all)
        Container(
          decoration: BoxDecoration(
            color: theme.adPopBackground.withAlpha(75),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CheckboxListTile(
            value: temp.isEmpty,
            onChanged: (checked) {
              setState(() {
                // if user ticks "Show all" -> clear selection (means show all)
                if (checked == true) {
                  temp.clear();
                }
              });
            },
            title: Text('Show all'.tr,
                style: TextStyle(color: theme.textColor)),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: theme.themeColor,
            checkColor: Colors.white,
          ),
        ),

        const SizedBox(height: 10),

        // List (expand to available space inside the sheet)
        Expanded(
          child: widget.savedSearches.isEmpty
              ? Center(
                  child: Text(
                    'no_saved_searches'.tr,
                    style: TextStyle(color: theme.textColor.withAlpha(178)),
                  ),
                )
              : ListView.separated(
                  controller: widget.sheetController,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: widget.savedSearches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final s = widget.savedSearches[i];
                    final selected = temp.contains(s.id);
                    return SavedSearchSelectableCard(
                      search: s,
                      selected: selected,
                      onToggle: () {
                        setState(() {
                          if (selected) {
                            temp.remove(s.id);
                          } else {
                            temp.add(s.id);
                          }
                        });
                      },
                      onPreview: () => openSavedSearchDetails(
                        context,
                        ref,
                        search: s,
                        transactionId: widget.transactionId,
                        clientId: widget.clientId,
                      ),
                    );
                  },
                ),
        ),

        const SizedBox(height: 12),

        // Actions
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child:
                  Text('Cancel'.tr, style: TextStyle(color: theme.textColor)),
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: () => setState(() => temp.clear()), // Show all
              child:
                  Text('Clear'.tr, style: TextStyle(color: theme.textColor)),
            ),
            const Spacer(),
            ElevatedButton(
              style: buttonStyleRounded10ThemeRed,
              onPressed: () {
                final notifier = ref.read(filterProvider.notifier);
                notifier.setClientId('', ref);
                notifier.filteredScope(
                    widget.clientId, widget.transactionId, ref);
                notifier.setSavedSearches(temp, ref, widget.transactionId);
                Navigator.of(context).maybePop();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0),
                child: Text('Apply'.tr, style: TextStyle(color: AppColors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}



Future<void> _openBrowseSheet(
  BuildContext context,
  WidgetRef ref,
  int transactionId,
  int clientId,
) async {
  await showHouslyBottomSheet(
    context: context,
    ref: ref,
    title: 'Browse list'.tr,
    initialChildSize: 0.9,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    bodyBuilder: (ctx, ref, controller) {

      final theme =ref.read(themeColorsProvider);
      // If the inner widget has its own scrolling, we don't need to attach [controller].
      // Wrap with Padding and Expanded to fill available body space.
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: PieCanvas(
            theme: PieTheme(
              rightClickShowsMenu: true,
              leftClickShowsMenu: false,
              buttonTheme: PieButtonTheme(
                backgroundColor: theme.themeColor.withAlpha(
                  (255 * 0.7).toInt(),
                ),
                iconColor: AppColors.white,
              ),
              buttonThemeHovered: PieButtonTheme(
                backgroundColor: theme.themeColor,
                iconColor: AppColors.white,
              ),
            ),
      child: BrowseListNetworkMonitoringPcWidget(
                  sheetScrollController: controller,
                  isWhiteSpaceNeeded: false,
                  isMobile: true,
                  transactionId: transactionId,
                  clientId: clientId,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
