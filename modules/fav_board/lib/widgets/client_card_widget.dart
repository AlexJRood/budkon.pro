import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crm_agent/models/clients_model.dart';

import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class ClientCardWidget extends ConsumerWidget {
  final UserContactModel client;
  final bool isEdit;
  const ClientCardWidget({super.key, required this.client, required this.isEdit});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(
          client.avatar?.isNotEmpty == true ? client.avatar! : defaultAvatarUrl,
        ),
      ),
      title: Text(
        '${client.name} ${client.lastName ?? ''}',
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.bold,
          color: theme.textColor,
        ),
      ),
      subtitle: Text(
        client.email ?? '',
        style: TextStyle(fontSize: 11.sp, color: theme.textColor),
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(color: theme.textColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isEdit ? 'Invite'.tr : 'Add'.tr,
          style: TextStyle(color: theme.textColor),
        ),
      ),
    );
  }
}
