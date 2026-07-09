import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import 'client_saved_search_browser_panel.dart';
import 'package:core/ui/device_type_util.dart';

class SaveSearchByClientListViewWidget extends ConsumerStatefulWidget {
  final int clientId;

  const SaveSearchByClientListViewWidget({
    super.key,
    required this.clientId,
  });

  @override
  ConsumerState<SaveSearchByClientListViewWidget> createState() =>
      _SaveSearchByClientListViewWidgetState();
}

class _SaveSearchByClientListViewWidgetState
    extends ConsumerState<SaveSearchByClientListViewWidget> {
  final _panelKey = GlobalKey<ClientSavedSearchBrowserPanelState>();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClientSavedSearchBrowserPanel(
          key: _panelKey,
          clientId: widget.clientId,
          closeOverlayOnOpenSearch: false,
        ),
        Positioned(
          bottom: BottomBarSize.resolve(context) +5,
          right: 5,
          child: _SavedSearchVerticalButtons(panelKey: _panelKey),
        ),
      ],
    );
  }
}

class _SavedSearchVerticalButtons extends ConsumerWidget {
  final GlobalKey<ClientSavedSearchBrowserPanelState> panelKey;

  const _SavedSearchVerticalButtons({required this.panelKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        _VBtn(
          icon: AppIcons.filterAlt(color: theme.textColor),
          onTap: () => panelKey.currentState?.openFiltersSheet(),
          theme: theme,
        ),
        _VBtn(
          icon: Icon(Icons.auto_awesome_mosaic_outlined, color: theme.textColor, size: 22),
          onTap: () => panelKey.currentState?.openAllNewAds(),
          theme: theme,
        ),
      ],
    );
  }
}

class _VBtn extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  final ThemeColors theme;

  const _VBtn({required this.icon, required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        color: theme.textFieldColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ElevatedButton(
        style: elevatedButtonStyleRounded10,
        onPressed: onTap,
        child: SizedBox(width: 24, height: 24, child: icon),
      ),
    );
  }
}
