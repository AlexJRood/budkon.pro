import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:flutter/material.dart';
import 'package:crm_agent/add_client_form/add_client_form_mobile.dart';
import 'package:crm_agent/add_client_form/add_client_form_tablet.dart';
import 'package:crm_agent/add_client_form/add_client_form_pc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class AddClientFormScreen extends ConsumerWidget {
  final bool isClientView;
  final String? state;

  const AddClientFormScreen({
    super.key,
    this.isClientView = false,
    this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isMobile = screenWidth < 800;
        final isTablet = screenWidth >= 800 && screenWidth < 1200;

        return PopPageLauncher(
          parentContext: context,
          tag: 'add-client-form',
          shouldBeADrawer: isMobile,
          width: isMobile ? screenWidth : screenWidth * 0.98,
          height: isMobile ? screenHeight : screenHeight * 0.96,
          isBig: true,
          hasBackButton: false,
          hasPaddingMobile: false,
          isNamedRoute: false,
          wrapChildInListView: false,
          child: isMobile
              ? AddClientFormMobile(
            isClientView: isClientView,
            state: state,
          )
              : isTablet
              ? AddClientFormTablet(
            isClientView: isClientView,
            state: state,
            isNamedRoute: true,
          )
              : AddClientFormPc(
            isClientView: isClientView,
            state: state,
            isNamedRoute: true,
          ),
        );
      },
    );
  }
}