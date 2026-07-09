import 'dart:async';
import 'dart:ui' as ui;

import 'package:core/ui/device_type_util.dart';
import 'package:emma/model/chat_room.dart';
import 'package:emma/provider/emma_notifier.dart';
import 'package:emma/provider/emma_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';

final chatAiSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

class ChatAiSideBar extends ConsumerStatefulWidget {
  const ChatAiSideBar({
    super.key,
    this.isMobile = false,
    this.scaffoldKey,
  });

  final bool isMobile;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  ConsumerState<ChatAiSideBar> createState() => _ChatAiSideBarState();
}

class _ChatAiSideBarState extends ConsumerState<ChatAiSideBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _roomsLoaded = false;
  bool _roomsLoadFailed = false;
  bool _openingEmptyDraft = false;
  bool _openingRoom = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchController.clear();
      unawaited(_loadRooms());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _safeCloseMobileDrawer() {
    if (!mounted) return;
    if (!widget.isMobile) return;

    final scaffoldState = widget.scaffoldKey?.currentState;
    if (scaffoldState == null) return;

    if (scaffoldState.isEndDrawerOpen) {
      scaffoldState.closeEndDrawer();
    }
  }

  Future<void> _loadRooms() async {
    if (!mounted) return;

    final hadRooms = ref.read(chatAiRoomsProvider).isNotEmpty;

    setState(() {
      _roomsLoadFailed = false;
      if (!hadRooms) _roomsLoaded = false;
    });

    var fetchSucceeded = false;

    try {
      fetchSucceeded =
          await ref.read(chatAiRoomsProvider.notifier).getRooms();
    } catch (e, stack) {
      debugPrint('Emma sidebar rooms load error: $e');
      debugPrintStack(stackTrace: stack);
    } finally {
      if (!mounted) return;

      final rooms = ref.read(chatAiRoomsProvider);

      setState(() {
        _roomsLoaded = true;
        // Only a genuine network failure counts as an error. An empty list
        // after a successful fetch just means the user has no conversations.
        _roomsLoadFailed = !fetchSucceeded && rooms.isEmpty;
      });
    }
  }

  Future<void> _openEmptyDraftChat() async {
    if (_openingEmptyDraft) return;
    if (!mounted) return;

    final messageNotifier = ref.read(chatAiMessageProvider.notifier);

    setState(() {
      _openingEmptyDraft = true;
    });

    try {
      await messageNotifier.openEmptyDraftChat();

      if (!mounted) return;
      _safeCloseMobileDrawer();
    } catch (e, stack) {
      debugPrint('Emma open empty draft error: $e');
      debugPrintStack(stackTrace: stack);
    } finally {
      if (!mounted) return;

      setState(() {
        _openingEmptyDraft = false;
      });
    }
  }

  Future<void> _openRoom(ChatRoom room) async {
    if (_openingRoom) return;
    if (!mounted) return;

    final roomId = room.id;
    final roomIdText = roomId.toString();

    final selectedRoomNotifier = ref.read(selectedAiRoomProvider.notifier);
    final messageNotifier = ref.read(chatAiMessageProvider.notifier);

    setState(() {
      _openingRoom = true;
    });

    try {
      selectedRoomNotifier.state = roomIdText;

      await messageNotifier.connectToSession(roomId);

      if (!mounted) return;
      _safeCloseMobileDrawer();
    } catch (e, stack) {
      debugPrint('Emma open room error: $e');
      debugPrintStack(stackTrace: stack);
    } finally {
      if (!mounted) return;

      setState(() {
        _openingRoom = false;
      });
    }
  }

  Future<void> _deleteRoom(ChatRoom room) async {
    if (!mounted) return;

    final roomsNotifier = ref.read(chatAiRoomsProvider.notifier);
    final selectedRoom = ref.read(selectedAiRoomProvider);
    final messageNotifier = ref.read(chatAiMessageProvider.notifier);

    try {
      await roomsNotifier.removeRoom(room.id.toString());

      if (!mounted) return;

      await roomsNotifier.getRooms();

      if (!mounted) return;

      if (selectedRoom == room.id.toString()) {
        await messageNotifier.openEmptyDraftChat();
      }
    } catch (e, stack) {
      debugPrint('Emma delete room error: $e');
      debugPrintStack(stackTrace: stack);
    }
  }


  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(chatAiRoomsProvider);
    final searchQuery = ref.watch(chatAiSearchQueryProvider);

    final proactiveInbox =
        rooms.where((r) => r.isProactiveInbox).firstOrNull;

    final filteredRooms = searchQuery.trim().isEmpty
        ? rooms.where((r) => !r.isProactiveInbox).toList()
        : rooms.where((room) {
            final query = searchQuery.trim().toLowerCase();
            final title = (room.title ?? '').toLowerCase();
            final id = room.id.toString().toLowerCase();
            return !room.isProactiveInbox &&
                (title.contains(query) || id.contains(query));
          }).toList();
    final selectedRoom = ref.watch(selectedAiRoomProvider);
    final theme = ref.read(themeColorsProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = widget.isMobile ? 800.0 : 1500.0;
    final minWidth = widget.isMobile ? 400.0 : 1000.0;
    final maxDynamicContainerSize = widget.isMobile ? 600.0 : 400.0;
    final minDynamicContainerSize = widget.isMobile ? 300.0 : 300.0;

    double dynamicContainerSize = (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxDynamicContainerSize - minDynamicContainerSize) +
        minDynamicContainerSize;

    dynamicContainerSize = dynamicContainerSize.clamp(
      minDynamicContainerSize,
      maxDynamicContainerSize,
    );

    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
        child: Container(
          color: theme.sidebar,
          height: double.infinity,
          width: dynamicContainerSize,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    SizedBox(height: TopAppBarSize.clearPage(context)),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: const Color.fromARGB(21, 255, 255, 255),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Row(
                          children: [
                            AppIcons.search(
                              height: 25,
                              width: 25,
                              color: theme.textColor,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                cursorColor: theme.textColor,
                                style: TextStyle(color: theme.textColor),
                                onChanged: (value) {
                                  ref.read(chatAiSearchQueryProvider.notifier).state = value;
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search message'.tr,
                                  hintStyle: TextStyle(
                                    color: theme.textColor,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: false,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: !_roomsLoaded && rooms.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.redBeige,
                        ),
                      )
                    : filteredRooms.isEmpty && proactiveInbox == null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    searchQuery.trim().isEmpty &&
                                            _roomsLoadFailed
                                        ? 'network_error_try_again'.tr
                                        : 'no_conversations_message'.tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: theme.textColor.withAlpha(150),
                                      fontSize: widget.isMobile ? 13 : 15,
                                    ),
                                  ),
                                  if (searchQuery.trim().isEmpty &&
                                      _roomsLoadFailed) ...[
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: _loadRooms,
                                      child: Text(
                                        'retry'.tr,
                                        style: TextStyle(
                                          color: theme.textColor.withAlpha(200),
                                          fontSize: widget.isMobile ? 13 : 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.only(bottom: 8),
                            children: [
                              if (proactiveInbox != null &&
                                  searchQuery.trim().isEmpty)
                                _ProactiveInboxTile(
                                  room: proactiveInbox,
                                  isSelected: selectedRoom ==
                                      proactiveInbox.id.toString(),
                                  isMobile: widget.isMobile,
                                  theme: theme,
                                  onTap: _openingRoom
                                      ? null
                                      : () => _openRoom(proactiveInbox),
                                ),
                              ...groupRoomsByDate(filteredRooms).entries.map(
                              (entry) {
                                final sectionTitle = entry.key;
                                final sectionRooms = entry.value;

                                if (sectionRooms.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 8.0,
                                      ),
                                      child: Text(
                                        sectionTitle.tr,
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontSize: widget.isMobile ? 14 : 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    ...sectionRooms.map((room) {
                                      final isSelected =
                                          selectedRoom == room.id.toString();

                                      return InkWell(
                                        onTap: _openingRoom
                                            ? null
                                            : () => _openRoom(room),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? theme.textFieldColor
                                                    .withAlpha(
                                                    (255 * 0.2).toInt(),
                                                  )
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: ListTile(
                                            title: Text(
                                              room.title ?? 'Chat ${room.id}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? theme.textColor
                                                    : theme.textColor.withAlpha(
                                                        (255 * 0.75).toInt(),
                                                      ),
                                                fontWeight: FontWeight.w500,
                                                fontSize:
                                                    widget.isMobile ? 14 : 18,
                                              ),
                                            ),
                                            trailing: PopupMenuButton<String>(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              icon: AppIcons.moreVertical(
                                                color: theme.textColor,
                                                height: 20,
                                                width: 20,
                                              ),
                                              onSelected: (value) {
                                                if (value == 'delete') {
                                                  _deleteRoom(room);
                                                }
                                              },
                                              color: theme.textFieldColor
                                                  .withAlpha(
                                                (255 * 0.6).toInt(),
                                              ),
                                              itemBuilder:
                                                  (BuildContext context) => [
                                                PopupMenuItem<String>(
                                                  value: 'delete',
                                                  child: Text(
                                                    'Delete'.tr,
                                                    style: const TextStyle(
                                                      color:
                                                          AppColors.expensesRed,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              },
                            ).toList(),
                            ],
                          ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: ElevatedButton(
                  style: elevatedButtonStyleRounded10,
                  onPressed: _openingEmptyDraft || _openingRoom
                      ? null
                      : () => _openEmptyDraftChat(),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Text(
                          _openingEmptyDraft
                              ? 'opening_status'.tr
                              : 'create_new_chat_button'.tr,
                          style: AppTextStyles.interSemiBold16.copyWith(
                            color: theme.textColor,
                          ),
                        ),
                        const Spacer(),
                        AppIcons.newChat(
                          height: 25,
                          width: 25,
                          color: theme.textColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

Map<String, List<ChatRoom>> groupRoomsByDate(List<ChatRoom> rooms) {
  final now = DateTime.now();
  final todayStr = DateFormat('yyyy-MM-dd').format(now);
  final yesterdayStr = DateFormat('yyyy-MM-dd').format(
    now.subtract(const Duration(days: 1)),
  );

  final grouped = <String, List<ChatRoom>>{
    'Today': [],
    'Yesterday': [],
    'Previous 7 Days': [],
    'Previous 30 Days': [],
  };

  for (final room in rooms) {
    final rawDateStr = room.lastActivityAt ?? room.createdAt;
    if (rawDateStr == null) continue;

    final date = DateTime.tryParse(rawDateStr);
    if (date == null) continue;

    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    if (dateStr == todayStr) {
      grouped['Today']!.add(room);
    } else if (dateStr == yesterdayStr) {
      grouped['Yesterday']!.add(room);
    } else if (date.isAfter(now.subtract(const Duration(days: 7)))) {
      grouped['Previous 7 Days']!.add(room);
    } else if (date.isAfter(now.subtract(const Duration(days: 30)))) {
      grouped['Previous 30 Days']!.add(room);
    }
  }

  return grouped;
}

class _ProactiveInboxTile extends StatelessWidget {
  final ChatRoom room;
  final bool isSelected;
  final bool isMobile;
  final ThemeColors theme;
  final VoidCallback? onTap;

  const _ProactiveInboxTile({
    required this.room,
    required this.isSelected,
    required this.isMobile,
    required this.theme,
    required this.onTap,
  });

  static const _accent = Color(0xFF37B6FF);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? _accent.withAlpha(35)
                : _accent.withAlpha(12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _accent.withAlpha(isSelected ? 100 : 40),
              width: 1,
            ),
          ),
          child: ListTile(
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _accent.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: _accent,
                    size: 18,
                  ),
                ),
                if (room.unreadCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        room.unreadCount > 99 ? '99+' : '${room.unreadCount}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              room.title ?? 'Emma — skrzynka',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? _accent : theme.textColor,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 13 : 15,
              ),
            ),
            subtitle: Text(
              'Sugestie Emmy',
              style: TextStyle(
                color: _accent.withAlpha(160),
                fontSize: isMobile ? 10 : 11,
              ),
            ),
            dense: true,
          ),
        ),
      ),
    );
  }
}