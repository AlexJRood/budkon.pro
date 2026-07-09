import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/contact_panel/tabs/dashboard/new_clients_view_full.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/platform/platforms/html_utils_stub.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_client_card_pc.dart';

class ClientPhotowidget extends ConsumerWidget {
  final UserContactModel clientViewPop;
  const ClientPhotowidget({super.key, required this.clientViewPop});

  @override
  Widget build(BuildContext context, ref) {
    final theme = ref.watch(themeColorsProvider);
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                      gradient: LinearGradient(
                        colors: [theme.themeColor, theme.textFieldColor],
                      ),
                    ),
                  ),
                  const SizedBox(height: 70),
                ],
              ),
              Positioned(
                top: 15,
                left: 15,
                child: NewClientCardPc(
                  onTap: () {},
                  id: clientViewPop.id,
                  avatar: clientViewPop.avatar ?? '',
                  name: clientViewPop.name ?? '',
                  lastName: clientViewPop.lastName ?? '',
                  email: clientViewPop.email ?? '',
                  phoneNumber: clientViewPop.phoneNumber ?? '',
                ),
              ),
              Positioned(
                right: 20,
                bottom: 5,
                child: IconButton(
                  icon: Icon(Icons.edit, size: 15, color: theme.textColor),
                  onPressed: () {
                    ref.read(activeSectionProvider.notifier).state = 'edit-contact';
                    ref
                        .read(navigationHistoryProvider.notifier)
                        .addPage('edit-contact');
                    updateUrl('/pro/clients/${clientViewPop.id}/edit-contact');
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
