import 'dart:ui' as ui;

import 'package:core/ui/device_type_util.dart';
import 'package:chat/models/chat_room_model.dart';
import 'package:chat/new_chat/provider/chat_message_provider.dart';
import 'package:chat/new_chat/provider/chat_room_provider.dart';
import 'package:chat/new_chat/widgets/chat_appbar_widget.dart';
import 'package:chat/new_chat/widgets/chat_messages_widget.dart';
import 'package:chat/new_chat/widgets/send_message_box_widget.dart';
import 'package:emma/screens/overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/user/user/user_provider.dart';

enum _SendAdChatMode {
  single,
  many,
  room,
}

OverlayEntry? _activeSendAdMinimizedEntry;

Future<void> showSendAdToChatOverlay({
  required BuildContext context,
  required WidgetRef ref,
  required MonitoringAdsModel ad,
}) async {
  final theme = ref.read(themeColorsProvider);

  if (!DeviceTypeUtil.isMobile(context)) {
    await showGenericAiSheet<void>(
      context: context,
      theme: theme,
      title: 'Post a chat ad'.tr,
      useScroll: false,
      cancelRow: false,
      child: SizedBox(
        width: 560,
        height: 760,
        child: SendAdToChatPanel(
          ad: ad,
          isMobile: false,
        ),
      ),
    );
    return;
  }

  await _showMobileSendAdSheet(
    context: context,
    ref: ref,
    ad: ad,
  );
}

Future<void> _showMobileSendAdSheet({
  required BuildContext context,
  required WidgetRef ref,
  required MonitoringAdsModel ad,
}) async {
  final theme = ref.read(themeColorsProvider);

  _removeMobileMinimizedBubble();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final keyboardHeight = MediaQuery.of(sheetContext).viewInsets.bottom;

      return AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: keyboardHeight,
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.96,
          maxChildSize: 1.0,
          snapSizes: const [0.55, 0.90, 1.0],
          minChildSize: 0.28,
          snap: true,
          builder: (context, _) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.adPopBackground.withAlpha(242),
                    border: Border(
                      top: BorderSide(color: theme.dashboardBoarder),
                    ),
                  ),
                  child: Column(
                    children: [
                      _MobileSheetHeader(
                        theme: theme,
                        title: 'Submit your ad'.tr,
                        onMinimize: () {
                          Navigator.of(sheetContext).pop();
                          _showMobileMinimizedBubble(
                            context: context,
                            ref: ref,
                            ad: ad,
                          );
                        },
                        onClose: () {
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                      Expanded(
                        child: SendAdToChatPanel(
                          ad: ad,
                          isMobile: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

void _removeMobileMinimizedBubble() {
  _activeSendAdMinimizedEntry?.remove();
  _activeSendAdMinimizedEntry = null;
}

void _showMobileMinimizedBubble({
  required BuildContext context,
  required WidgetRef ref,
  required MonitoringAdsModel ad,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  _removeMobileMinimizedBubble();

  final theme = ref.read(themeColorsProvider);

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (ctx) {
      final bottomPadding = MediaQuery.of(ctx).padding.bottom;

      return Positioned(
        right: 16,
        bottom: 16 + bottomPadding,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              _removeMobileMinimizedBubble();
              _showMobileSendAdSheet(
                context: context,
                ref: ref,
                ad: ad,
              );
            },
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dashboardBoarder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(70),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: theme.themeColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Submit your ad'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  _activeSendAdMinimizedEntry = entry;
  overlay.insert(entry);
}

class _MobileSheetHeader extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final VoidCallback onMinimize;
  final VoidCallback onClose;

  const _MobileSheetHeader({
    required this.theme,
    required this.title,
    required this.onMinimize,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border(
          bottom: BorderSide(color: theme.dashboardBoarder),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                Icons.drag_handle_rounded,
                color: theme.textColor.withAlpha(180),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          IconButton(
            onPressed: onMinimize,
            icon: Icon(
              Icons.remove_rounded,
              color: theme.textColor.withAlpha(220),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              color: theme.textColor.withAlpha(220),
            ),
          ),
        ],
      ),
    );
  }
}

class SendAdToChatPanel extends ConsumerStatefulWidget {
  final MonitoringAdsModel ad;
  final bool isMobile;

  const SendAdToChatPanel({
    super.key,
    required this.ad,
    required this.isMobile,
  });

  @override
  ConsumerState<SendAdToChatPanel> createState() => _SendAdToChatPanelState();
}

class _SendAdToChatPanelState extends ConsumerState<SendAdToChatPanel> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _bulkMessageController = TextEditingController();

  _SendAdChatMode _mode = _SendAdChatMode.single;
  final Set<int> _selectedUserIds = <int>{};

  bool _isBusy = false;
  bool _isRegularChatMode = false;
  Room? _openedRoom;

  ScaffoldMessengerState? _scaffoldMessenger;
  NavigatorState? _navigator;
  VoidCallback? _closeOverlayCallback;

  @override
  void initState() {
    super.initState();
    _bulkMessageController.text = _buildDefaultBulkMessage();

    Future.microtask(() async {
      await ref.read(fetchRoomsProvider.notifier).fetchRooms();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    _navigator = Navigator.maybeOf(context);
    _closeOverlayCallback = GenericAiOverlayScope.maybeOf(context)?.closeOverlay;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bulkMessageController.dispose();
    super.dispose();
  }

  void _closeOverlay() {
    final closeOverlay = _closeOverlayCallback;
    if (closeOverlay != null) {
      closeOverlay();
      return;
    }

    final navigator = _navigator;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    }
  }

  String _buildDefaultBulkMessage() {
    final title = (widget.ad.safeTitle ?? widget.ad.title ?? '').toString().trim();
    if (title.isNotEmpty) {
      return 'I will send you this ad: $title'.tr;
    }
    return 'I will send you this ad'.tr;
  }

  void _snack(String text) {
    final messenger = _scaffoldMessenger;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  bool _isDirect(Room r) => r.personalRoom != null;

  bool _directRoomHasMember(Room r, int memberId) {
    final pr = r.personalRoom;
    if (pr == null) return false;
    return pr.user1 == memberId || pr.user2 == memberId;
  }

  Room? _findDirectRoomWithMember(List<Room> rooms, int memberId) {
    try {
      return rooms.firstWhere(
        (r) => _isDirect(r) && _directRoomHasMember(r, memberId),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Room?> _ensureDirectRoom(int memberId) async {
    final currentRooms = ref.read(fetchRoomsProvider);
    final existing = _findDirectRoomWithMember(currentRooms, memberId);
    if (existing != null) return existing;

    final roomId = await ref.read(fetchRoomsProvider.notifier).createRoomUser(
          memberId,
          false,
          initialContent: '',
        );

    if (roomId == null || roomId.isEmpty) {
      return null;
    }

    await ref.read(fetchRoomsProvider.notifier).fetchRooms();
    final updatedRooms = ref.read(fetchRoomsProvider);
    return _findDirectRoomWithMember(updatedRooms, memberId);
  }

  Future<void> _sendTextAndCardToRoom({
    required String roomId,
    required String text,
  }) async {
    final trimmed = text.trim();

    if (trimmed.isNotEmpty) {
      await ref.read(chatMessageRoomProvider.notifier).sendMessage(
            trimmed,
            roomId,
          );
    }

    await ref.read(chatMessageRoomProvider.notifier).sendNmAdvertisementCardMessage(
          ad: widget.ad,
          roomId: roomId,
        );
  }

  Future<void> _openSingleChat(dynamic member) async {
    final memberId = int.tryParse(member.id.toString());
    if (memberId == null) {
      _snack('Invalid user'.tr);
      return;
    }

    if (mounted) {
      setState(() => _isBusy = true);
    }

    try {
      final room = await _ensureDirectRoom(memberId);

      if (!mounted) return;

      if (room == null) {
        _snack('Could not create or find room'.tr);
        return;
      }

      ref.read(selectedChatId.notifier).state = room.id;

      if (room.otherUser != null) {
        ref.read(otherUserData.notifier).state = room.otherUser!;
      }

      await ref.read(chatMessageRoomProvider.notifier).fetchRoomMessages(
            room.id,
            ref,
          );

      if (!mounted) return;

      ref.read(isChatSelected.notifier).state = true;

      setState(() {
        _openedRoom = room;
        _mode = _SendAdChatMode.room;
        _isRegularChatMode = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _sendToOpenedRoom() async {
    final room = _openedRoom;
    if (room == null) return;

    if (mounted) {
      setState(() => _isBusy = true);
    }

    try {
      await _sendTextAndCardToRoom(
        roomId: room.id,
        text: '',
      );

      await ref.read(chatMessageRoomProvider.notifier).fetchRoomMessages(
            room.id,
            ref,
          );

      if (!mounted) return;

      setState(() {
        _isRegularChatMode = true;
        _mode = _SendAdChatMode.room;
      });

      _snack('The announcement has been sent'.tr);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _sendToMany() async {
    if (_selectedUserIds.isEmpty) {
      _snack('Select at least one person'.tr);
      return;
    }

    final customMessage = _bulkMessageController.text.trim();

    if (mounted) {
      setState(() => _isBusy = true);
    }

    int sent = 0;
    int failed = 0;

    try {
      for (final userId in _selectedUserIds) {
        final room = await _ensureDirectRoom(userId);
        if (room == null) {
          failed++;
          continue;
        }

        await _sendTextAndCardToRoom(
          roomId: room.id,
          text: customMessage,
        );

        sent++;
      }

      await ref.read(fetchRoomsProvider.notifier).fetchRooms();

      if (!mounted) return;

      if (sent > 0) {
        if (failed > 0) {
          _snack('Sent to $sent people. Failed for $failed.'.tr);
        } else {
          _snack('Sent to $sent people'.tr);
        }
        _closeOverlay();
      } else {
        _snack('Failed to send message'.tr);
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _copyUrl() async {
    final url = widget.ad.url.toString().trim();
    if (url.isEmpty) {
      _snack('No link to copy'.tr);
      return;
    }

    await Clipboard.setData(ClipboardData(text: url));

    if (!mounted) return;
    _snack('Link copied to clipboard'.tr);
  }

  String _memberName(dynamic member) {
    final first = (member.firstName ?? '').toString().trim();
    final last = (member.lastName ?? '').toString().trim();
    final username = (member.username ?? '').toString().trim();
    final full = [first, last].where((e) => e.isNotEmpty).join(' ');
    return full.isNotEmpty ? full : (username.isNotEmpty ? username : 'User'.tr);
  }

  String _memberAvatar(dynamic member) {
    return (member.avatar ?? '').toString();
  }

  Widget _buildMemberTile({
    required dynamic member,
    required ThemeColors theme,
    required bool multiMode,
  }) {
    final memberId = int.tryParse(member.id.toString());
    final selected = memberId != null && _selectedUserIds.contains(memberId);
    final avatar = _memberAvatar(member);
    final title = _memberName(member);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _isBusy
          ? null
          : () async {
              if (multiMode) {
                if (memberId == null) return;
                setState(() {
                  if (selected) {
                    _selectedUserIds.remove(memberId);
                  } else {
                    _selectedUserIds.add(memberId);
                  }
                });
              } else {
                await _openSingleChat(member);
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.textFieldColor.withAlpha(selected ? 180 : 110),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? theme.themeColor : theme.dashboardBoarder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.dashboardBoarder,
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty
                  ? Icon(Icons.person, color: theme.textColor)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (multiMode)
              Checkbox(
                value: selected,
                onChanged: _isBusy
                    ? null
                    : (value) {
                        if (memberId == null) return;
                        setState(() {
                          if (value == true) {
                            _selectedUserIds.add(memberId);
                          } else {
                            _selectedUserIds.remove(memberId);
                          }
                        });
                      },
              )
            else
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.textColor.withAlpha(160),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAdCard(ThemeColors theme) {
    final url = widget.ad.url.toString().trim();
    final title =
        (widget.ad.safeTitle ?? widget.ad.title ?? '${'Announcement'.tr} #${widget.ad.id}')
            .toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home_work_outlined, color: theme.themeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: _copyUrl,
                icon: Icon(Icons.copy_rounded, color: theme.textColor),
                tooltip: 'Copy link'.tr,
              ),
            ],
          ),
          if (url.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              url,
              style: TextStyle(
                color: theme.textColor.withAlpha(220),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeSwitch(ThemeColors theme) {
    final isSingle =
        _mode == _SendAdChatMode.single || _mode == _SendAdChatMode.room;
    final isMany = _mode == _SendAdChatMode.many;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isBusy
                ? null
                : () {
                    setState(() {
                      _mode = _SendAdChatMode.single;
                      _openedRoom = null;
                      _isRegularChatMode = false;
                    });
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSingle
                  ? theme.themeColor
                  : theme.textFieldColor.withAlpha(120),
              foregroundColor: isSingle ? Colors.white : theme.textColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text('One person'.tr),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _isBusy
                ? null
                : () {
                    setState(() {
                      _mode = _SendAdChatMode.many;
                      _openedRoom = null;
                      _isRegularChatMode = false;
                    });
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isMany
                  ? theme.themeColor
                  : theme.textFieldColor.withAlpha(120),
              foregroundColor: isMany ? Colors.white : theme.textColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text('Many people'.tr),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleSelector(ThemeColors theme, List<dynamic> members) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          cursorColor: theme.textColor,
          style: TextStyle(color: theme.textColor),
          decoration: InputDecoration(
            hintText: 'Search for a person...'.tr,
            hintStyle: TextStyle(color: theme.textColor.withAlpha(140)),
            prefixIcon: Icon(Icons.search_rounded, color: theme.textColor),
            filled: true,
            fillColor: theme.textFieldColor.withAlpha(80),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final member = members[index];
              return _buildMemberTile(
                member: member,
                theme: theme,
                multiMode: false,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildManySelector(ThemeColors theme, List<dynamic> members) {
    return Column(
      children: [
        TextField(
          controller: _bulkMessageController,
          cursorColor: theme.textColor,
          style: TextStyle(color: theme.textColor),
          maxLines: 6,
          minLines: 4,
          decoration: InputDecoration(
            hintText: 'Message content...'.tr,
            hintStyle: TextStyle(color: theme.textColor.withAlpha(140)),
            filled: true,
            fillColor: theme.textFieldColor.withAlpha(80),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          cursorColor: theme.textColor,
          style: TextStyle(color: theme.textColor),
          decoration: InputDecoration(
            hintText: 'Search for people...'.tr,
            hintStyle: TextStyle(color: theme.textColor.withAlpha(140)),
            prefixIcon: Icon(Icons.search_rounded, color: theme.textColor),
            filled: true,
            fillColor: theme.textFieldColor.withAlpha(80),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '${'Marked:'.tr} ${_selectedUserIds.length}',
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isBusy ? null : _sendToMany,
              icon: _isBusy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text('Send to everyone'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.themeColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final member = members[index];
              return _buildMemberTile(
                member: member,
                theme: theme,
                multiMode: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatShell(ThemeColors theme) {
    return PieCanvas(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: theme.adPopBackground.withAlpha(210),
            border: Border.all(color: theme.dashboardBoarder),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 64,
                child: ChatAppBar(
                  ref: ref,
                  isMobile: widget.isMobile,
                ),
              ),
              Expanded(
                child: ChatMessagesWidget(
                  isMobile: widget.isMobile,
                ),
              ),
              const SendMessageBox(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpenedRoomView(ThemeColors theme) {
    if (_isRegularChatMode) {
      return _buildChatShell(theme);
    }

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _isBusy
                  ? null
                  : () {
                      setState(() {
                        _mode = _SendAdChatMode.single;
                        _openedRoom = null;
                        _isRegularChatMode = false;
                      });
                    },
              icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
            ),
            Expanded(
              child: Text(
                'Mini chat'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isBusy ? null : _sendToOpenedRoom,
              icon: const Icon(Icons.send_rounded),
              label: Text('Submit your ad'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.themeColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTopAdCard(theme),
        const SizedBox(height: 10),
        Expanded(
          child: _buildChatShell(theme),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return ref.watch(userProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Error loading users'.tr,
              style: TextStyle(color: theme.textColor),
            ),
          ),
          data: (user) {
            final currentUserId = (user?.userId ?? '').toString();

            final allMembers = List<dynamic>.from(user?.companyMembers ?? const []);
            final members = allMembers
                .where((m) => m.id.toString() != currentUserId)
                .toList();

            final q = _searchController.text.trim().toLowerCase();
            final filtered = q.isEmpty
                ? members
                : members.where((m) {
                    final haystack = [
                      (m.firstName ?? '').toString(),
                      (m.lastName ?? '').toString(),
                      (m.username ?? '').toString(),
                    ].join(' ').toLowerCase();

                    return haystack.contains(q);
                  }).toList();

            return Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  if (_mode != _SendAdChatMode.room) ...[
                    _buildTopAdCard(theme),
                    const SizedBox(height: 12),
                    _buildModeSwitch(theme),
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: _mode == _SendAdChatMode.room
                        ? _buildOpenedRoomView(theme)
                        : _mode == _SendAdChatMode.many
                            ? _buildManySelector(theme, filtered)
                            : _buildSingleSelector(theme, filtered),
                  ),
                ],
              ),
            );
          },
        );
  }
}