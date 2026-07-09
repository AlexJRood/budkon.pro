import 'package:core/ui/device_type_util.dart';
import 'package:chat/new_chat/provider/chat_room_provider.dart';
import 'package:chat/pages/chat_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:portal/screens/feed/provider/feed_pop/fav_provider.dart';
import 'package:portal/screens/feed/provider/feed_pop/hide_provider.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:core/theme/icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:portal/screens/feed/components/chat/send_portal_ad_message_overlay.dart';

class MobileLikeSectionFeedPop extends ConsumerWidget {
  final dynamic adFeedPop;

  const MobileLikeSectionFeedPop({super.key, required this.adFeedPop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final isFavorite = ref
        .watch(favAdsProvider)
        .maybeWhen(
          data: (ads) => ads.any((ad) => ad.id == adFeedPop.id),
          orElse: () => false,
        );

    final isHidden = ref
        .watch(hideAdsProvider)
        .maybeWhen(
          data: (ads) => ads.any((ad) => ad.id == adFeedPop.id),
          orElse: () => false,
        );

    return Container(
      height: TopAppBarSize.resolve(context),
      width: MediaQuery.of(context).size.width,
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📞 Call Button
          ActionButton(
            icon: AppIcons.call(color: theme.textColor),
            label: 'Call'.tr,
            theme: theme,
              onPressed: () async {
                final phone = adFeedPop.phoneNumber ?? 'brak numeru';

                if (phone.isNotEmpty && phone != 'brak numeru') {
                  if (kIsWeb) {
                    await Clipboard.setData(ClipboardData(text: phone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('phone_copied'.tr + phone)),
                    );
                  } else {
                    _launchPhoneDialer(phone);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('no_phone'.tr)),
                  );
                }
              }

          ),

          // 💬 Message Button
          ActionButton(
            icon: AppIcons.sendAbove(color: theme.textColor),
            label: 'message'.tr,
            theme: theme,

              onPressed: () {
                showPortalAdMessageOverlay(
                  context: context,
                  ref: ref,
                  ad: adFeedPop,
                );
              },

            // onPressed: () {
            //   ref.read(fetchRoomsProvider.notifier).createRoom(adFeedPop.id);
            //   Navigator.of(context).push(
            //     PageRouteBuilder(
            //       opaque: false,
            //       pageBuilder: (_, __, ___) => const ChatPage(),
            //       transitionsBuilder: (_, anim, __, child) {
            //         return FadeTransition(
            //           opacity: anim,
            //           child: child,
            //         );
            //       },
            //     ),
            //   );
            // },
          ),

          // 🔗 Share Button
          ActionButton(
            icon: AppIcons.share(color: theme.textColor),
            label: 'share'.tr,
            theme: theme,
            onPressed: () {
              handleShareAction(adFeedPop, context);
            },
          ),

          // 👁️ Hide/Show Button
          ActionButton(
            icon:
                isHidden
                    ? Icon(FontAwesomeIcons.eye, color: theme.textColor)
                    : Icon(FontAwesomeIcons.eyeSlash, color: theme.textColor),
            label: 'hide'.tr,
            theme: theme,
            onPressed: () {
              handleHideAction(ref, adFeedPop, context);
            },
          ),

          // ❤️ Favorite Button
          ActionButton(
            icon:
                isFavorite
                    ? Icon(FontAwesomeIcons.solidHeart, color: theme.textColor)
                    : Icon(FontAwesomeIcons.heart, color: theme.textColor),
            label: 'favorites'.tr,
            theme: theme,
            onPressed: () {
              handleFavoriteAction(ref, adFeedPop, context);
            },
          ),
        ],
      ),
    );
  }
}

// void _showCallBottomSheet(
//   BuildContext context,
//   String phoneNumber,
//   ThemeColors theme,
// ) {
//   showModalBottomSheet(
//     context: context,
//     backgroundColor: theme.adPopBackground,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     builder: (ctx) {
//       return Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Call',
//               style: Theme.of(
//                 context,
//               ).textTheme.titleLarge?.copyWith(color: theme.textColor),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'Do you want to call this number?',
//               style: Theme.of(
//                 context,
//               ).textTheme.bodyMedium?.copyWith(color: theme.textColor),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               phoneNumber,
//               style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: theme.textColor,
//                 fontSize: 18,
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.of(ctx).pop();
//                 _launchPhoneDialer(phoneNumber);
//               },
//               icon: const Icon(Icons.call),
//               label: Text(
//                 'Call',
//                 style: AppTextStyles.interMedium.copyWith(color: Colors.white),
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//                 minimumSize: const Size.fromHeight(45),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 10),
//             TextButton(
//               onPressed: () => Navigator.of(ctx).pop(),
//               child: Text(
//                 'Cancel',
//                 style: AppTextStyles.interMedium.copyWith(
//                   color: theme.textColor,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     },
//   );
// }

void _launchPhoneDialer(String phoneNumber) async {
  final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
  if (await canLaunchUrl(phoneUri)) {
    await launchUrl(phoneUri);
  } else {
    debugPrint('younis: Could not launch phone dialer');
  }
}

class ActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final dynamic theme;
  final VoidCallback onPressed;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.theme,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: ElevatedButton(
        style: elevatedButtonStyleRounded10,
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [SizedBox(width: 60, child: icon)],
          ),
        ),
      ),
    );
  }
}
