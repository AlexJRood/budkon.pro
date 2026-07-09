// =====================================================================
// lib/router_web/modules/crm_add_client_form_routes.dart
// =====================================================================
import "package:core/shell/manager/bar_manager.dart";
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';

import "package:association/admin.dart" deferred as association_admin;
import "package:association/association.dart" deferred as association;
import "package:association/screens/notifications.dart"
    deferred as association_notifications;
import "package:association/screens/create_social_event.dart"
    deferred as create_association_events;
import "package:association/screens/events/screen/social_events.dart"
    deferred as association_events;
import "package:association/screens/application.dart"
    deferred as association_members_application;
import "package:association/screens/join_application.dart"
    deferred as join_association;
import "package:association/screens/articles/list_article.dart"
    deferred as association_articles;
import "package:association/screens/articles/create_articles.dart"
    deferred as association_articles_create;
import "package:association/screens/articles/edit_article.dart"
    deferred as association_articles_edit;
import "package:association/screens/loyalty/loyalty_details.dart"
    deferred as association_loyalty_id;
import "package:association/screens/loyalty/loyalty_rewards.dart"
    deferred as association_loyalty_id_rewards;
import "package:association/screens/loyalty/loyalyty_dashboard.dart"
    deferred as association_loyalty_dashboard;
import "package:association/screens/loyalty/loyalty.dart"
    deferred as association_loyalty;
import "package:association/screens/members.dart"
    deferred as association_members;

import 'package:crm_agent/crm/finance_crm_page.dart'
    deferred as association_finance;

import 'package:calendar/calendar/calendar_page.dart' deferred as calendar_page;
import 'package:calendar/widgets/calendar_search_screen_widget.dart'
    deferred as calendar_search_screen_widget;


import 'package:tms_app/todo/board/board_page.dart' deferred as tms_board;
import 'package:tms_app/todo/todo_page.dart' deferred as tms;

// budkon: dynamic_app removed — profile editor routes disabled

/// ✅ Key MUST be unique per (route-template + path params),
/// but not "full uri" aggressive.
ValueKey<String> _pageKey(String routeTemplate, BeamState state) {
  final params = state.pathParameters.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  final suffix = params.isEmpty
      ? ''
      : params.map((e) => '${e.key}=${e.value}').join('&');

  return ValueKey('$routeTemplate|$suffix');
}

final Map<Pattern, BeamRouteBuilder> associtationRoutes = {
  Routes.associationMemberId: (context, state, data) {
    final id = int.parse(state.pathParameters['id']!);

    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationMemberId, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        association.loadLibrary,
        () => association.AssociationMember(
          assosiationId: id,
        ),
      ),
    );
  },

  // budkon: associationListings, associationArticlesPublic, associationMembersPublic,
  // associationId, profile-editor routes disabled (dynamic_app removed)

  Routes.associationAdmin: (context, state, data) {
    final id = int.parse(state.pathParameters['id']!);

    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationAdmin, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        association_admin.loadLibrary,
        () => association_admin.AssociationAdmin(assosiationId: id),
      ),
    );
  },

  Routes.associationNotifications: (context, state, data) {
    final id = int.parse(state.pathParameters['id']!);

    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationNotifications, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        association_notifications.loadLibrary,
        () => association_notifications.AssociationNotificationsScreen(
          associationId: id,
          baseUrl: 'https://www.superbee.cloud',
        ),
      ),
    );
  },

  Routes.associationNotificationsId: (context, state, data) {
    final id = int.parse(state.pathParameters['id']!);
    final notificationId = state.pathParameters['notificationId'];

    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationNotificationsId, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        association_notifications.loadLibrary,
        () => association_notifications.AssociationNotificationsScreen(
          associationId: id,
          notificationId: notificationId,
          baseUrl: 'https://www.superbee.cloud',
        ),
      ),
    );
  },

  Routes.associationFinance: (context, state, data) {
    final id = int.parse(state.pathParameters['id']!);

    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationFinance, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        association_finance.loadLibrary,
        () => association_finance.FinanceCrmPage(
          appModule: AppModule.association,
          companyId: id,
        ),
      ),
    );
  },

  Routes.associationFinanceRevenue: (context, state, data) {
    final id = int.parse(state.pathParameters['id']!);

    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationFinanceRevenue, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        association_finance.loadLibrary,
        () => association_finance.FinanceCrmPage(
          appModule: AppModule.association,
          companyId: id,
        ),
      ),
    );
  },

  Routes.associationFinanceExpense: (context, state, data) {
    final id = int.parse(state.pathParameters['id']!);

    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationFinanceExpense, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        association_finance.loadLibrary,
        () => association_finance.FinanceCrmPage(
          appModule: AppModule.association,
          companyId: id,
        ),
      ),
    );
  },

  Routes.associationMembers: (context, state, data) {
    final id = int.parse(state.pathParameters['id']!);

    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationMembers, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        association_members.loadLibrary,
        () => association_members.AssociationMemebrsScreen(
          associationId: id,
          baseUrl: 'https://www.superbee.cloud',
        ),
      ),
    );
  },

  Routes.associationEvents: (context, state, data) {
    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationEvents, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        association_events.loadLibrary,
        () => association_events.PublicEventsPage(
          appModule: AppModule.association,
        ),
      ),
    );
  },

  Routes.associationEventsDetails: (context, state, data) {
    final slug = state.pathParameters['slug']!;

    if (slug == 'create') {
      setupMetaTag(context);
      return BeamPage(
        key: _pageKey(Routes.associationEventsDetails, state),
        title: Routes.getWebsiteTitle(context),
        child: buildDeferredScreen(
          create_association_events.loadLibrary,
          () => create_association_events.PublicEventCreatePage(
            baseUrl: 'https://www.superbee.cloud',
            appModule: AppModule.association,
          ),
        ),
      );
    } else {
      setupMetaTag(context);
      return BeamPage(
        key: _pageKey(Routes.associationEventsDetails, state),
        title: Routes.getWebsiteTitle(context),
        child: buildDeferredScreen(
          association_events.loadLibrary,
          () => association_events.PublicEventDetailsPage(
            slug: slug,
            appModule: AppModule.association,
          ),
        ),
      );
    }
  },

  Routes.associationApplications: (context, state, data) {
    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationApplications, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        association_members_application.loadLibrary,
        () => association_members_application.MembershipApplicationsPage(),
      ),
    );
  },

  Routes.associationJoinApplications: (context, state, data) {
    final id = int.tryParse(state.pathParameters['id'] ?? '');
    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationJoinApplications, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        join_association.loadLibrary,
        () => join_association.JoinAssociationPage(prefilledAssociationId: id),
      ),
    );
  },

  Routes.associationArticles: (context, state, data) {
    final id = int.parse(state.pathParameters['id']!);

    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationArticles, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        association_articles.loadLibrary,
        () => association_articles.ListAssociationArticlesPage(
          associationId: id,
        ),
      ),
    );
  },

  Routes.associationArticlesCreate: (context, state, data) {
    final id = int.parse(state.pathParameters['id']!);

    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationArticlesCreate, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        association_articles_create.loadLibrary,
        () => association_articles_create.CreateAssociationArticlePage(
          associationId: id,
        ),
      ),
    );
  },

  Routes.associationArticlesEdit: (context, state, data) {
    final id = int.parse(state.pathParameters['id']!);
    final articleId = int.parse(state.pathParameters['articleId']!);

    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationArticlesEdit, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        association_articles_edit.loadLibrary,
        () => association_articles_edit.EditAssociationArticlePage(
          associationId: id,
          articleId: articleId,
        ),
      ),
    );
  },

  Routes.associationLoyalty: (context, state, data) {
    final id = int.parse(state.pathParameters['id']!);

    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationLoyalty, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        association_loyalty.loadLibrary,
        () => association_loyalty.LoyaltyProgramsScreen(
          associationId: id,
        ),
      ),
    );
  },

  Routes.associationLoyaltyId: (context, state, data) {
    final loyaltyId = int.parse(state.pathParameters['loyaltyId']!);

    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationLoyaltyId, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        association_loyalty_id.loadLibrary,
        () => association_loyalty_id.LoyaltyAdminScreen(programId: loyaltyId),
      ),
    );
  },

  Routes.associationLoyaltyIdRewards: (context, state, data) {
    final loyaltyId = int.parse(state.pathParameters['loyaltyId']!);

    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationLoyaltyIdRewards, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        association_loyalty_id_rewards.loadLibrary,
        () => association_loyalty_id_rewards.LoyaltyRewardsScreen(
          programId: loyaltyId,
        ),
      ),
    );
  },

  Routes.associationLoyaltyIdDashboard: (context, state, data) {
    final loyaltyId = int.parse(state.pathParameters['loyaltyId']!);

    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationLoyaltyIdDashboard, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        association_loyalty_dashboard.loadLibrary,
        () => association_loyalty_dashboard.LoyaltyProgramDashboardScreen(
          programId: loyaltyId,
        ),
      ),
    );
  },

  Routes.associationCalendar: (context, state, data) {
    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationCalendar, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        calendar_page.loadLibrary,
        () => calendar_page.AgentCalendarPage(
          appModule: AppModule.association,
        ),
      ),
    );
  },

  Routes.associationCalendarSearchScreen: (context, state, data) {
    setupMetaTag(context);
    return BeamPage(
      key: _pageKey(Routes.associationCalendarSearchScreen, state),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        calendar_search_screen_widget.loadLibrary,
        () => calendar_search_screen_widget.CalendarSearchScreenWidget(),
      ),
    );
  },

  Routes.associationTodo: (context, state, data) => BeamPage(
        key: _pageKey(Routes.associationTodo, state),
        child: buildDeferredScreen(
          tms.loadLibrary,
          () => tms.ToDoPage(appModule: AppModule.association),
        ),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
      ),

  Routes.associationBoard: (context, state, data) => BeamPage(
        key: _pageKey(Routes.associationBoard, state),
        child: buildDeferredScreen(
          tms_board.loadLibrary,
          () => tms_board.BoardPage(appModule: AppModule.association),
        ),
        routeBuilder: (ctx, settings, child) =>
            transparentRouteBuilder(ctx, settings, child),
      ),
};
