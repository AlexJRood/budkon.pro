import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'package:core/platform/navigation_service.dart';

import 'package:get/get_utils/get_utils.dart';

void showSortPopup(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    barrierDismissible:
        true, // Ustawienie, czy można zamknąć dialog poprzez kliknięcie w tło
    builder: (BuildContext context) {
      String? selectedSort;

      final sortOptions = {
        'Amount Ascending'.tr: 'amount_asc',
        'Amount Descending'.tr: 'amount_desc',
        'Date Created Ascending'.tr: 'date_create_asc',
        'Date Created Descending'.tr: 'date_create_desc',
        'Date Updated Ascending'.tr: 'date_update_asc',
        'Date Updated Descending'.tr: 'date_update_desc',
      };

      return AlertDialog(
        title: Text('Sort Clients'.tr),
        content: DropdownButtonFormField<String>(
          value: selectedSort,
          decoration: InputDecoration(labelText: 'Sort by'.tr),
          items: sortOptions.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.value,
              child: Text(entry.key),
            );
          }).toList(),
          onChanged: (newValue) {
            selectedSort = newValue;
          },
        ),
        actions: [
          TextButton(
            child: Text('Cancel'.tr),
            onPressed: () {
              ref.read(navigationService).beamPop();
            },
          ),
          ElevatedButton(
            child: Text('Apply'.tr),
            onPressed: () {
              ref
                  .read(clientProvider.notifier)
                  .fetchClients(sort: selectedSort);
              ref.read(navigationService).beamPop();
            },
          ),
        ],
      );
    },
  );
}
