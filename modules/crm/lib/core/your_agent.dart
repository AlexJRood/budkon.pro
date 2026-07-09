// =====================================================================
// lib/router_web/modules/crm_add_client_form_routes.dart
// =====================================================================
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';
import 'package:crm/your_agent/your_agent.dart' deferred as your_agent;
import 'package:crm/your_agent/invite_screen.dart' deferred as your_agent_invite;



final Map<Pattern, BeamRouteBuilder> yourAgentRoutes = {

  Routes.yourAgent: (context, state, data) {

    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.yourAgent),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        your_agent.loadLibrary,
        () => your_agent.ClientPortalCasesListScreen(),
      ),
    );
  },

    Routes.yourAgentId: (context, state, data) {
    final id = state.pathParameters['id']!;

    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.yourAgentId),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        your_agent.loadLibrary,
        () => your_agent.ClientPortalCaseScreen(portalId: id),
      ),
    );
  },


    Routes.yourAgentInvite: (context, state, data) {
    final token = state.pathParameters['token']!;

    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.yourAgentInvite),
      title: Routes.getWebsiteTitle(context),
      
      child: buildDeferredScreen(
        your_agent_invite.loadLibrary,
        () => your_agent_invite.ClientPortalInviteScreen(
        token: token,
        loginRoute: Routes.login, // albo Routes.login
        registerRoute: Routes.register, // albo Routes.register
       ),
      ),
    );
  }


};