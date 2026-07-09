import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:crm/data/clients/client_provider.dart';

class StatusFilterWidgetMobile extends ConsumerStatefulWidget {
  const StatusFilterWidgetMobile({super.key});

  @override
  ConsumerState<StatusFilterWidgetMobile> createState() =>
      StatusFilterWidgetMobileState();
}

class StatusFilterWidgetMobileState
    extends ConsumerState<StatusFilterWidgetMobile> {
  int? selectedStatus;
  var searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref
        .read(clientProvider.notifier)
        .fetchClients(
          status: selectedStatus,
          searchQuery: searchController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double searchWidth = screenWidth;
    final theme = ref.read(themeColorsProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 50,
              width: searchWidth,
              child: TextField(
                style: AppTextStyles.interMedium16.copyWith(
                  color: theme.textColor,
                ),
                controller: searchController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.dashboardContainer,
                  hintText: 'Search clients'.tr,
                  hintStyle: AppTextStyles.interMedium14.copyWith(
                    color: theme.textColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.textColor,
                    size: 25,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
