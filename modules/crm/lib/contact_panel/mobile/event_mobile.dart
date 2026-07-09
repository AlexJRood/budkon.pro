import 'package:crm/contact_panel/components/client_calendar.dart';
// ignore: duplicate_import
import 'package:crm/contact_panel/components/client_calendar.dart';
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_client_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewClientEventMobile extends ConsumerWidget {
  final String clientId;
  const NewClientEventMobile({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: ClientEvettile(clientId: clientId, isMobile: true),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 400,
          child: CustomTableCalendarPc(
            clientId: clientId,
            primaryColor: Theme.of(context).primaryColor,
            fillColor: Colors.white,
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
          ),
        ),
      ],
    );
  }
}