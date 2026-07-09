

// =====================================================================
// lib/router_web/modules/crm_add_client_form_routes.dart
// =====================================================================
import 'package:core/shell/manager/bar_manager.dart';
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';
import "package:crm/draft/draft_list.dart" deferred as draft;
import "package:crm/draft/draft_view.dart" deferred as draft_view;
import 'package:crm/draft_ads_listview_model.dart';
import 'package:calendar/calendar/calendar_page.dart' deferred as calendar_page;
import 'package:calendar/widgets/calendar_search_screen_widget.dart'
    deferred as calendar_search_screen_widget;





    
import 'package:crm/contact_panel/mobile/components/transaction_full_screen.dart'
    deferred as transaction_screen;
import 'package:crm/contact_panel/mobile/screens/mobile_all_transaction.dart'
    deferred as mobile_all_transaction;



import 'package:fav_board/screens/fav_screen.dart' deferred as crm_fav;
import 'package:crm_agent/crm/finance_crm_page.dart'
    deferred as finance_crm_page;

import 'package:crm_agent/screens/tx/tx.dart' deferred as tx_page;

import 'package:emma/screens/emma_chat_screen.dart' deferred as emma_chat_page;
import 'package:crm/crm/add_field/add_field.dart' deferred as crm_add_pop;

final Map<Pattern, BeamRouteBuilder>  crmRoutes = {


          Routes.emmaChatScreen: (context, state, data) {
            setupMetaTag(context);
            return BeamPage(
              key: const ValueKey(Routes.emmaChatScreen),
              title: Routes.getWebsiteTitle(context),
              child: buildDeferredScreen(
                  emma_chat_page.loadLibrary, () => emma_chat_page.EmmaChatScreen()),
            );
          },





          Routes.crmFav: (context, state, data) {
            setupMetaTag(context);
            return BeamPage(
              key: const ValueKey(Routes.crmFav),
              title: Routes.getWebsiteTitle(context),
              child: buildDeferredScreen(
                  crm_fav.loadLibrary, () => crm_fav.FavScreen(appModule: AppModule.agentCrm,),),
            );
          },



        Routes.draft: (context, state, data) {
          setupMetaTag(context);
          return BeamPage(
            key: const ValueKey(Routes.draft),
            title: Routes.getWebsiteTitle(context),
            child: buildDeferredScreen(
                  draft.loadLibrary, () => draft.DraftList(),),
          );
        },



          Routes.proTxDraft: (context, state, data) {
            setupMetaTag(context);
            return BeamPage(
              key: const ValueKey(Routes.proTxDraft),
              title: Routes.getWebsiteTitle(context),
              child: buildDeferredScreen(
                  tx_page.loadLibrary, () => tx_page.TrasanctionPage()),
            );
          },

          Routes.proTx: (context, state, data) {
            setupMetaTag(context);
            return BeamPage(
              key: const ValueKey(Routes.proTx),
              title: Routes.getWebsiteTitle(context),
              child: buildDeferredScreen(
                  tx_page.loadLibrary, () => tx_page.TrasanctionPage()),
            );
          },

          Routes.proTxDashboard: (context, state, data) {
            setupMetaTag(context);
            return BeamPage(
              key: const ValueKey(Routes.proTxDashboard),
              title: Routes.getWebsiteTitle(context),
              child: buildDeferredScreen(
                  tx_page.loadLibrary, () => tx_page.TrasanctionPage()),
            );
          },

          Routes.draftView: (context, state, data) {
            final id = int.parse(state.pathParameters['id']!);
            final ad = data is DraftAdsListViewModel
                ? convertDraftToTransaction(data)
                : null;

            setupMetaTag(context);
            return BeamPage(
              key: const ValueKey(Routes.draftView),
              title: Routes.getWebsiteTitle(context),
              child: buildDeferredScreen(
                draft_view.loadLibrary,
                () => draft_view.DraftView(id: id, ad: ad),
              ),
            );
          },

          
          // Example for a general lazy-loaded route
          Routes.proCalendar: (context, state, data) {
            setupMetaTag(context);

            return BeamPage(
              key: const ValueKey(Routes.proCalendar),
              title: Routes.getWebsiteTitle(context),
              child: buildDeferredScreen(
                calendar_page.loadLibrary,
                () => calendar_page.AgentCalendarPage(),
              ),
            );
          },
          Routes.calendarSearchScreen: (context, state, data) {
            setupMetaTag(context);

            return BeamPage(
              key: const ValueKey(Routes.calendarSearchScreen),
              title: Routes.getWebsiteTitle(context),
              child: buildDeferredScreen(
                calendar_search_screen_widget.loadLibrary,
                () =>
                    calendar_search_screen_widget.CalendarSearchScreenWidget(),
              ),
            );
          },


          
          Routes.transaction: (context, state, data) {
            setupMetaTag(context);

            return BeamPage(
              key: ValueKey(Routes.transaction),
              title: Routes.getWebsiteTitle(context),
              child: buildDeferredScreen(transaction_screen.loadLibrary,
                  () => transaction_screen.TransactionScreen()),
            );
          },
          Routes.allTransaction: (context, state, data) {
            setupMetaTag(context);

            return BeamPage(
              key: const ValueKey(Routes.allTransaction),
              title: Routes.getWebsiteTitle(context),
              child: buildDeferredScreen(mobile_all_transaction.loadLibrary,
                  () => mobile_all_transaction.MobileAllTransaction()),
              routeBuilder: (context, settings, child) =>
                  transparentRouteBuilder(context, settings, child),
            );
          },

          // Add-viewer pop. CrmAddPopPc itself sets the URL to
          // '/pro/finance/revenue/add/<formName>', which is exactly
          // Routes.proFinanceRevenueAdd — the route was just never registered.
          Routes.proFinanceRevenueAdd: (context, state, data) => BeamPage(
                key: const ValueKey(Routes.proFinanceRevenueAdd),
                title: Routes.getWebsiteTitle(context),
                child: buildDeferredScreen(
                  crm_add_pop.loadLibrary,
                  () => crm_add_pop.CrmAddPopPc(initialForm: 'AddViewerForm'),
                ),
                routeBuilder: (ctx, settings, child) =>
                    transparentRouteBuilder(ctx, settings, child),
              ),

          Routes.proFinanceRevenue: (context, state, data) {
            setupMetaTag(context);
            return BeamPage(
                key: const ValueKey(Routes.proFinanceRevenue),
                title: Routes.getWebsiteTitle(context),
                child: buildDeferredScreen(
                  finance_crm_page.loadLibrary,
                  () => finance_crm_page.FinanceCrmPage(appModule: AppModule.agentCrm),
                ));
          },



          Routes.proFinanceExpenses: (context, state, data) {
            setupMetaTag(context);
            return BeamPage(
                key: const ValueKey(Routes.proFinanceExpenses),
                title: Routes.getWebsiteTitle(context),
                child: buildDeferredScreen(
                  finance_crm_page.loadLibrary,
                  () => finance_crm_page.FinanceCrmPage(appModule: AppModule.agentCrm),
                ));
          },



          Routes.proFinanceDashboard: (context, state, data) {
            setupMetaTag(context);
            return BeamPage(
                key: const ValueKey(Routes.proFinanceDashboard),
                title: Routes.getWebsiteTitle(context),
                child: buildDeferredScreen(
                  finance_crm_page.loadLibrary,
                  () => finance_crm_page.FinanceCrmPage(appModule: AppModule.agentCrm),
                ));
          },



          Routes.proDraggable: (context, state, data) {
            setupMetaTag(context);
            return BeamPage(
              key: const ValueKey(Routes.proDraggable),
              title: Routes.getWebsiteTitle(context),
              child: buildDeferredScreen(finance_crm_page.loadLibrary,
                  () => finance_crm_page.FinanceCrmPage(appModule: AppModule.agentCrm)),
            );
          },
          Routes.proDraggableRevenue: (context, state, data) {
            return BeamPage(
                key: const ValueKey(Routes.proDraggableRevenue),
                routeBuilder: (context, settings, child) =>
                    transparentRouteBuilder(context, settings, child),
                child: finance_crm_page.FinanceCrmPage(appModule: AppModule.agentCrm));
          },
          Routes.proDraggableExpenses: (context, state, data) {
            return BeamPage(
                key: const ValueKey(Routes.proDraggableExpenses),
                routeBuilder: (context, settings, child) =>
                    transparentRouteBuilder(context, settings, child),
                child: finance_crm_page.FinanceCrmPage(appModule: AppModule.agentCrm));
          },
};
