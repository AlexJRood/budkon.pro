import 'package:crm/contact_panel/navigation/enum.dart';
import 'package:crm/crm/clients/clients_view_page.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:core/user/user/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/platforms/html_utils_stub.dart'
    if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/user/user/user_provider.dart';

class DashboardCompanyMembersWidget extends ConsumerWidget {
  const DashboardCompanyMembersWidget({
    super.key,
    required this.isMobile,
    this.compact = false,
    this.backgroundMode = 'card',
    this.itemStyle = 'card',
    this.showHeader = true,
    this.isEditMode = false,
  });

  final bool isMobile;
  final bool compact;
  final String backgroundMode;
  final String itemStyle;
  final bool showHeader;
  final bool isEditMode;

  bool get _transparentBackground => backgroundMode == 'transparent';
  bool get _minimalItems => itemStyle == 'minimal';

  static const double _oneTileHeightThreshold = 150;
  static const double _oneTileWidthThreshold = 180;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final user = ref.watch(userProvider).value;

    if (user == null) {
      return _CompanyMembersFrame(
        theme: theme,
        title: 'Company members'.tr,
        transparent: _transparentBackground,
        showHeader: showHeader,
        child: _CompanyMembersEmptyState(
          theme: theme,
          icon: Icons.business_outlined,
          message: 'No company - member list unavailable'.tr,
        ),
      );
    }

    final allMembers = user.companyMembers.toList();

    if (allMembers.isEmpty) {
      return _CompanyMembersFrame(
        theme: theme,
        title: 'Company members'.tr,
        transparent: _transparentBackground,
        showHeader: showHeader,
        child: _CompanyMembersEmptyState(
          theme: theme,
          icon: Icons.groups_2_outlined,
          message: 'No company members found'.tr,
        ),
      );
    }

    final meId = user.userId.toString();

    final members = allMembers.where((m) {
      final id = _memberId(m)?.toString();
      return id != null && id != meId;
    }).toList();

    if (members.isEmpty) {
      return _CompanyMembersFrame(
        theme: theme,
        title: 'Company members'.tr,
        transparent: _transparentBackground,
        showHeader: showHeader,
        child: _CompanyMembersEmptyState(
          theme: theme,
          icon: Icons.person_outline_rounded,
          message: 'You are the only company member'.tr,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isOneTileHeight =
            constraints.maxHeight <= _oneTileHeightThreshold;

        final isOneTileWidth =
            constraints.maxWidth <= _oneTileWidthThreshold;

        // w: 1 => vertical avatar rail
        // h: 1 => horizontal avatar rail
        // Width has priority because horizontal mode looks bad inside w=1.
        if (isOneTileWidth) {
          return _CompanyMembersCompactPanel(
            theme: theme,
            members: members,
            direction: Axis.vertical,
            showBorder: !_transparentBackground,
            minimalItems: _minimalItems,
            isEditMode: isEditMode,
          );
        }

        if (isOneTileHeight) {
          return _CompanyMembersCompactPanel(
            theme: theme,
            members: members,
            direction: Axis.horizontal,
            showBorder: !_transparentBackground,
            minimalItems: _minimalItems,
            isEditMode: isEditMode,
          );
        }

        final isVerySmall =
            constraints.maxHeight < 220 || constraints.maxWidth < 360;

        final useCompact = compact || isVerySmall;

        return _CompanyMembersFrame(
          theme: theme,
          title: 'Company members'.tr,
          subtitle: '${members.length} ${'members'.tr}',
          transparent: _transparentBackground,
          showHeader: showHeader,
          child: useCompact
              ? _CompanyMembersCompactPanel(
                  theme: theme,
                  members: members,
                  direction: Axis.horizontal,
                  showBorder: false,
                  minimalItems: _minimalItems,
                  isEditMode: isEditMode,
                )
              : _CompanyMembersRichList(
                  theme: theme,
                  members: members,
                  isMobile: isMobile,
                  minimalItems: _minimalItems,
                  isEditMode: isEditMode,
                ),
        );
      },
    );
  }
}

class _CompanyMembersFrame extends StatelessWidget {
  const _CompanyMembersFrame({
    required this.theme,
    required this.title,
    required this.child,
    this.subtitle,
    this.transparent = false,
    this.showHeader = true,
  });

  final ThemeColors theme;
  final String title;
  final String? subtitle;
  final Widget child;
  final bool transparent;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: transparent
          ? null
          : BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dashboardBoarder,
                width: 1.1,
              ),
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            if (showHeader)
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: transparent
                      ? Colors.transparent
                      : theme.dashboardContainer,
                  border: Border(
                    bottom: BorderSide(
                      color: transparent
                          ? Colors.transparent
                          : theme.dashboardBoarder.withAlpha(150),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: theme.themeColor.withAlpha(24),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.themeColor.withAlpha(80),
                        ),
                      ),
                      child: Icon(
                        Icons.groups_2_rounded,
                        color: theme.themeColor,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(155),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _CompanyMembersCompactPanel extends StatelessWidget {
  const _CompanyMembersCompactPanel({
    required this.theme,
    required this.members,
    required this.direction,
    required this.showBorder,
    required this.minimalItems,
    required this.isEditMode,
  });

  final ThemeColors theme;
  final List<dynamic> members;
  final Axis direction;
  final bool showBorder;
  final bool minimalItems;
  final bool isEditMode;

  bool get _isVertical => direction == Axis.vertical;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final veryShort = constraints.maxHeight < 86;
        final veryNarrow = constraints.maxWidth < 120;

        final hideLabels =
            isEditMode && (veryShort || veryNarrow || _isVertical);

        final avatarRadius = hideLabels
            ? 17.0
            : veryShort
                ? 18.0
                : 22.0;

        final itemWidth = hideLabels
            ? 52.0
            : _isVertical
                ? double.infinity
                : 72.0;

        final itemHeight = _isVertical
            ? hideLabels
                ? 52.0
                : 78.0
            : null;

        return Container(
          height: double.infinity,
          decoration: showBorder
              ? BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dashboardBoarder,
                    width: 1.1,
                  ),
                )
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ListView.separated(
              scrollDirection: direction,
              padding: EdgeInsets.symmetric(
                horizontal: _isVertical ? 6 : 8,
                vertical: veryShort ? 4 : 6,
              ),
              itemCount: members.length,
              separatorBuilder: (_, __) => _isVertical
                  ? const SizedBox(height: 8)
                  : const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final member = members[index];

                return _CompanyMemberCompactCard(
                  theme: theme,
                  member: member,
                  direction: direction,
                  avatarRadius: avatarRadius,
                  itemWidth: itemWidth,
                  itemHeight: itemHeight,
                  hideLabel: hideLabels,
                  minimal: minimalItems,
                  onTap: () => _openCrmUserPanel(
                    context: context,
                    member: member,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _CompanyMembersRichList extends StatelessWidget {
  const _CompanyMembersRichList({
    required this.theme,
    required this.members,
    required this.isMobile,
    required this.minimalItems,
    required this.isEditMode,
  });

  final ThemeColors theme;
  final List<dynamic> members;
  final bool isMobile;
  final bool minimalItems;
  final bool isEditMode;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return _CompanyMembersCompactPanel(
        theme: theme,
        members: members,
        direction: Axis.horizontal,
        showBorder: false,
        minimalItems: minimalItems,
        isEditMode: isEditMode,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final member = members[index];

        return _CompanyMemberListTile(
          theme: theme,
          member: member,
          minimal: minimalItems,
          onTap: () => _openCrmUserPanel(
            context: context,
            member: member,
          ),
        );
      },
    );
  }
}

class _CompanyMemberCompactCard extends StatelessWidget {
  const _CompanyMemberCompactCard({
    required this.theme,
    required this.member,
    required this.direction,
    required this.avatarRadius,
    required this.itemWidth,
    required this.itemHeight,
    required this.hideLabel,
    required this.minimal,
    required this.onTap,
  });

  final ThemeColors theme;
  final dynamic member;
  final Axis direction;
  final double avatarRadius;
  final double itemWidth;
  final double? itemHeight;
  final bool hideLabel;
  final bool minimal;
  final VoidCallback onTap;

  bool get _isVertical => direction == Axis.vertical;

  @override
  Widget build(BuildContext context) {
    final avatar = _memberAvatar(member);
    final initials = _memberInitials(member);
    final displayName = _memberDisplayName(member);
    final useNetworkAvatar = avatar != null && !_isGoogleAvatarUrl(avatar);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: itemWidth,
        height: itemHeight,
        padding: EdgeInsets.symmetric(
          vertical: hideLabel ? 4 : 6,
          horizontal: hideLabel ? 4 : 6,
        ),
        decoration: minimal
            ? null
            : BoxDecoration(
                color: theme.textFieldColor.withAlpha(153),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dashboardBoarder.withAlpha(153),
                ),
              ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _CompanyMemberAvatar(
              theme: theme,
              avatar: avatar,
              initials: initials,
              radius: avatarRadius,
              useNetworkAvatar: useNetworkAvatar,
            ),
            if (!hideLabel) ...[
              const SizedBox(height: 5),
              Flexible(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _isVertical ? 10 : 11,
                    color: theme.textColor.withAlpha(230),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompanyMemberListTile extends StatelessWidget {
  const _CompanyMemberListTile({
    required this.theme,
    required this.member,
    required this.onTap,
    required this.minimal,
  });

  final ThemeColors theme;
  final dynamic member;
  final VoidCallback onTap;
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    final avatar = _memberAvatar(member);
    final initials = _memberInitials(member);
    final displayName = _memberDisplayName(member);
    final email = _memberEmail(member);
    final phone = _memberPhone(member);
    final useNetworkAvatar = avatar != null && !_isGoogleAvatarUrl(avatar);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 9,
          ),
          decoration: minimal
              ? null
              : BoxDecoration(
                  color: theme.adPopBackground.withAlpha(145),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: theme.dashboardBoarder.withAlpha(135),
                  ),
                ),
          child: Row(
            children: [
              _CompanyMemberAvatar(
                theme: theme,
                avatar: avatar,
                initials: initials,
                radius: 22,
                useNetworkAvatar: useNetworkAvatar,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email ?? phone ?? 'Open profile'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor.withAlpha(150),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.textColor.withAlpha(130),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyMemberAvatar extends StatelessWidget {
  const _CompanyMemberAvatar({
    required this.theme,
    required this.avatar,
    required this.initials,
    required this.radius,
    required this.useNetworkAvatar,
  });

  final ThemeColors theme;
  final String? avatar;
  final String initials;
  final double radius;
  final bool useNetworkAvatar;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.dashboardBoarder,
      child: ClipOval(
        child: useNetworkAvatar
            ? Image.network(
                avatar!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                cacheWidth: (radius * 4).round(),
                filterQuality: FilterQuality.low,
                errorBuilder: (_, __, ___) {
                  return _AvatarFallback(
                    theme: theme,
                    initials: initials,
                  );
                },
              )
            : _AvatarFallback(
                theme: theme,
                initials: initials,
              ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.theme,
    required this.initials,
  });

  final ThemeColors theme;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          fontSize: 12,
          color: theme.textColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CompanyMembersEmptyState extends StatelessWidget {
  const _CompanyMembersEmptyState({
    required this.theme,
    required this.icon,
    required this.message,
  });

  final ThemeColors theme;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: theme.textColor.withAlpha(115),
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompanyMembersSettingsPanel extends StatelessWidget {
  const CompanyMembersSettingsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final Map<String, dynamic> settings;
  final ValueChanged<Map<String, dynamic>> onSettingsChanged;

  bool get _transparentBackground {
    return (settings['backgroundMode'] ?? 'card').toString() == 'transparent';
  }

  bool get _minimalItems {
    return (settings['itemStyle'] ?? 'card').toString() == 'minimal';
  }

  bool get _showHeader {
    final raw = settings['showHeader'];
    if (raw is bool) return raw;
    return true;
  }

  bool get _compact {
    final raw = settings['compact'];
    if (raw is bool) return raw;
    return false;
  }

  void _patch(Map<String, dynamic> patch) {
    onSettingsChanged({
      ...settings,
      ...patch,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('Transparent background'.tr),
          subtitle: Text('Remove widget background and border'.tr),
          value: _transparentBackground,
          onChanged: (value) {
            _patch({
              'backgroundMode': value ? 'transparent' : 'card',
            });
          },
        ),
        const Divider(height: 1),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('Minimal member cards'.tr),
          subtitle: Text('Remove background from member items'.tr),
          value: _minimalItems,
          onChanged: (value) {
            _patch({
              'itemStyle': value ? 'minimal' : 'card',
            });
          },
        ),
        const Divider(height: 1),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('Show header'.tr),
          subtitle: Text('Show title and member count'.tr),
          value: _showHeader,
          onChanged: (value) {
            _patch({
              'showHeader': value,
            });
          },
        ),
        const Divider(height: 1),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('Compact mode'.tr),
          subtitle: Text('Prefer compact avatar list'.tr),
          value: _compact,
          onChanged: (value) {
            _patch({
              'compact': value,
            });
          },
        ),
      ],
    );
  }
}

Future<void> _openCrmUserPanel({
  required BuildContext context,
  required dynamic member,
}) async {
  final memberId = _memberId(member);

  if (memberId == null) return;

  updateUrl('/pro/crm-users/$memberId/dashboard');

  final contact = _companyMemberToContact(member);

  await Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha(18),
      pageBuilder: (_, __, ___) {
        return ClientsViewPop(
          clientViewPop: contact,
          tagClientViewPop: 'crm-user-$memberId',
          activeSection: 'dashboard',
          activeAd: '',
          contactType: ContactType.crmUser,
        );
      },
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ),
  );
}

UserContactModel _companyMemberToContact(dynamic member) {
  if (member is UserContactModel) return member;

  final m = member as CompanyMemberModel;
  return UserContactModel(
    id: m.id,
    name: m.firstName.isNotEmpty ? m.firstName : m.username,
    lastName: m.lastName.isNotEmpty ? m.lastName : null,
    email: m.email,
    avatar: m.avatar,
    phoneNumber: m.phoneNumber,
  );
}

int? _memberId(dynamic member) {
  final raw = member.id;
  if (raw is int) return raw;
  return int.tryParse(raw?.toString() ?? '');
}

String _memberDisplayName(dynamic member) {
  final firstName = _cleanString(member.firstName) ?? '';
  final lastName = _cleanString(member.lastName) ?? '';
  final username = _cleanString(member.username);

  final fullName = '$firstName $lastName'.trim();

  if (fullName.isNotEmpty) return fullName;
  if (username != null && username.isNotEmpty) return username;

  return 'Member'.tr;
}

String _memberInitials(dynamic member) {
  final firstName = _cleanString(member.firstName) ?? '';
  final lastName = _cleanString(member.lastName) ?? '';
  final username = _cleanString(member.username) ?? '';

  final first = firstName.isNotEmpty
      ? firstName[0]
      : username.isNotEmpty
          ? username[0]
          : '';

  final second = lastName.isNotEmpty ? lastName[0] : '';

  return '$first$second'.toUpperCase();
}

String? _memberAvatar(dynamic member) {
  return _cleanString(member.avatar);
}

String? _memberEmail(dynamic member) {
  return _cleanString(member.email);
}

String? _memberPhone(dynamic member) {
  return _cleanString(member.phoneNumber);
}

String? _cleanString(dynamic value) {
  if (value == null) return null;

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  return text;
}

bool _isGoogleAvatarUrl(String url) {
  final value = url.toLowerCase();

  return value.contains('googleusercontent.com') ||
      value.contains('google.com/a/') ||
      value.contains('lh3.googleusercontent.com');
}