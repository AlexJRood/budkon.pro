import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:network_monitoring/screens/list_with_save_searches/widget/save_search_list_view_widget.dart';
import 'package:network_monitoring/screens/list_with_save_searches/widget/saved_search_inbox_panel.dart';

class ListWithSaveSearchesPc extends ConsumerWidget {
  const ListWithSaveSearchesPc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Stack(
          children: [
            Image.asset(
              'assets/images/top-content.webp',
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
              height: 130,
            ),
             Positioned(
              bottom: 10,
              top: 10,
              left: 20,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'title_network_monitoring'.tr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color.fromRGBO(255, 255, 255, 1),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 430,
                child: SaveSearchListViewWidget(),
              ),
              SizedBox(width: 12),
              Expanded(
                child: SavedSearchInboxPanel(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}