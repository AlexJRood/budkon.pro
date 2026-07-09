import 'dart:math' as math;

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:profile/emma/anchors/anchors_profile.dart';
import 'package:profile/screens/user_profile_default_mobile.dart';
import 'package:profile/screens/user_profile_default_pc.dart';
import 'package:profile/screens/user_profile_default_tablet.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/user/onboarding/providers/onboarding_provider.dart';
import 'package:core/user/onboarding/tour/post_onboarding_tour.dart';
import 'package:core/user/user/user_model.dart';

final selectedTabIndexProvider = StateProvider<int>((ref) => 0);

class UserProfileDefaultScreen extends ConsumerStatefulWidget {
  final UserModel? profileData;
  final bool isCurrentUser;

  const UserProfileDefaultScreen({
    super.key,
    this.profileData,
    this.isCurrentUser = true,
  });

  @override
  ConsumerState<UserProfileDefaultScreen> createState() => _UserProfileDefaultScreenState();
}

class _UserProfileDefaultScreenState extends ConsumerState<UserProfileDefaultScreen> {
  final sideMenuKey = GlobalKey<SideMenuState>();
  bool _tourChecked = false;

  void _maybeLaunchTour() {
    final pending = ref.read(postOnboardingTourPendingProvider);
    if (!pending) return;
    ref.read(postOnboardingTourPendingProvider.notifier).state = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      startPostOnboardingTour(ref, context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fires if the provider changes while this screen is already mounted.
    ref.listen<bool>(postOnboardingTourPendingProvider, (_, pending) {
      if (pending) _maybeLaunchTour();
    });

    // Catches the case where the provider was already true when we first built.
    if (!_tourChecked) {
      _tourChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLaunchTour());
    }

   final tabs = <String>[
      'All'.tr,
      'User Advertisements'.tr,
      'Wall Posts'.tr,
      'User Archived Ads'.tr,
    ];
    final screenWidth = MediaQuery.of(context).size.width;

    final int grid;
    if (screenWidth >= 1440) {
      grid = math.max(1, (screenWidth / 500).ceil());
    } else if (screenWidth >= 1080) {
      grid = 3;
    } else if (screenWidth >= 600) {
      grid = 2;
    } else {
      grid = 1;
    }


    final theme = ref.watch(themeColorsProvider);

    return EmmaUiAnchorTarget(
      anchorKey: 'profile.screen.root',
      // @emma-backend: ProfileEmmaAnchors.screenRoot,
      child: BarManager(
        sideMenuKey: sideMenuKey,
        appModule: AppModule.portal,
        enableScrool: false,
        childPc: UserProfileDefaultPc(
          theme: theme,
          tabs: tabs,
          grid: grid,
          profileData:widget. profileData,
        isCurrentUser: widget.isCurrentUser,
      ),
      childTablet: UserProfileDefaultTablet(
        theme: theme,
        tabs: tabs,
        grid: 2, // ✅ Tablet specific grid count
        profileData: widget.profileData,
          isCurrentUser: widget.isCurrentUser,
        ),
        childMobile: UserProfileDefaultMobile(
          theme: theme,
          tabs: tabs,
          grid: grid,
          profileData: widget.profileData,
          isCurrentUser: widget.isCurrentUser,
        ),
      ),
    );
  }
}

/// Tabs widget used by BOTH PC and Mobile.
/// - Default: uses selectedTabIndexProvider.
/// - Optional controlled mode: selectedIndex + onTabChanged.
class ProjectTabsScreen extends ConsumerWidget {
  final ThemeColors theme;
  final List<String> tabs;

  final int? selectedIndex;
  final ValueChanged<int>? onTabChanged;

  final String? anchorPlatform;
  final List<String>? tabIds;

  const ProjectTabsScreen({
    super.key,
    required this.theme,
    required this.tabs,
    this.selectedIndex,
    this.onTabChanged,
    this.anchorPlatform,
    this.tabIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerSelected = ref.watch(selectedTabIndexProvider);
    final currentIndex = selectedIndex ?? providerSelected;

    final backendTabs =
        anchorPlatform == 'mobile'
            ? ProfileEmmaAnchors.mobileTabs
            : ProfileEmmaAnchors.desktopTabs;

    final content = Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(tabs.length, (index) {
            final isSelected = currentIndex == index;
            final String? tabId =
                tabIds != null && index < tabIds!.length ? tabIds![index] : null;

            Widget tabChild = InkWell(
              onTap: () {
                if (onTabChanged != null) {
                  onTabChanged!(index);
                  return;
                }
                ref.read(selectedTabIndexProvider.notifier).state = index;
              },
              borderRadius: BorderRadius.circular(6.r),
              splashColor: theme.textColor.withAlpha(26),
              hoverColor: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: 24.w),
                padding: EdgeInsets.symmetric(vertical: 6.h),
                decoration: BoxDecoration(
                  border:
                      isSelected
                          ? const Border(
                            bottom: BorderSide(
                              color: Colors.cyanAccent,
                              width: 2.0,
                            ),
                          )
                          : null,
                ),
                child: Text(
                  tabs[index],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color:
                        isSelected
                            ? theme.textColor
                            : theme.textColor.withAlpha(128),
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            );

            if (anchorPlatform != null && tabId != null) {
              final backend = ProfileEmmaAnchors.tabItem(
                platform: anchorPlatform!,
                tabId: tabId,
                label: tabs[index],
              );

              tabChild = EmmaUiAnchorTarget(
                anchorKey: 'profile.$anchorPlatform.tabs.$tabId',
                // @emma-backend: backend,
                child: tabChild,
              );
            }

            return tabChild;
          }),
        ),
      ),
    );

    if (anchorPlatform == null) {
      return content;
    }

    return EmmaUiAnchorTarget(
      anchorKey: 'profile.$anchorPlatform.tabs',
      // @emma-backend: backendTabs,
      child: content,
    );
  }
}