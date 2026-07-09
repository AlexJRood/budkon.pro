import 'package:core/ui/device_type_util.dart';
import 'package:chat/models/chat_room_model.dart';
import 'package:chat/new_chat/provider/chat_message_provider.dart';
import 'package:chat/new_chat/provider/chat_room_provider.dart';
import 'package:chat/new_chat/widgets/chat_bubble_overlay.dart';
import 'package:chat/new_chat/widgets/chat_messages_widget.dart';
import 'package:chat/new_chat/widgets/send_message_box_widget.dart';
import 'package:emma/screens/overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';

Future<void> showPortalAdMessageOverlay({
  required BuildContext context,
  required WidgetRef ref,
  required dynamic ad,
}) async {
  final theme = ref.read(themeColorsProvider);
  final isMobile = DeviceTypeUtil.isMobile(context);

  final panel = PortalAdMessagePanel(
    ad: ad,
    isMobile: isMobile,
  );

  if (!isMobile) {
    await showGenericAiSheet<void>(
      context: context,
      theme: theme,
      title: 'write_a_message'.tr,
      useScroll: false,
      cancelRow: false,
      child: panel,
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final keyboard = MediaQuery.of(sheetContext).viewInsets.bottom;

      return AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboard),
        child: SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.88,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                margin: const EdgeInsets.only(top: 24),
                decoration: BoxDecoration(
                  color: theme.adPopBackground,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: PortalAdMessagePanel(
                  ad: ad,
                  isMobile: isMobile,
                  scrollController: scrollController,
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

class PortalAdMessagePanel extends ConsumerStatefulWidget {
  final dynamic ad;
  final bool isMobile;
  final ScrollController? scrollController;

  const PortalAdMessagePanel({
    super.key,
    required this.ad,
    required this.isMobile,
    this.scrollController,
  });

  @override
  ConsumerState<PortalAdMessagePanel> createState() =>
      _PortalAdMessagePanelState();
}

class _PortalAdMessagePanelState extends ConsumerState<PortalAdMessagePanel> {
  final TextEditingController _messageController = TextEditingController();
  bool _isBusy = false;

  List<String> get _quickActions => [
    'is_offer_still_available'.tr,
    'can_we_schedule_a_presentation'.tr,
    'is_price_negotiable'.tr,
    'please_more_photos_and_details'.tr,
    'is_offer_available_immediately'.tr,
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _str(List<dynamic Function()> getters) {
    for (final getter in getters) {
      try {
        final value = getter();
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      } catch (_) {}
    }
    return '';
  }

  dynamic _val(List<dynamic Function()> getters) {
    for (final getter in getters) {
      try {
        final value = getter();
        if (value != null) return value;
      } catch (_) {}
    }
    return null;
  }

  String get _title {
    final t = _str([
      () => widget.ad.title,
      () => widget.ad.safeTitle,
      () => widget.ad.name,
    ]);
    if (t.isNotEmpty) return t;
    return 'advertisement'.tr + ' #${_val([() => widget.ad.id]) ?? ''}';
  }

  String get _address {
    final street = _str([() => widget.ad.street]);
    final city = _str([() => widget.ad.city]);
    final state = _str([() => widget.ad.state]);
    return [street, city, state].where((e) => e.isNotEmpty).join(', ');
  }

  String get _priceText {
    final priceText = _str([() => widget.ad.priceText]);
    if (priceText.isNotEmpty) return priceText;

    final price = _val([() => widget.ad.price]);
    final currency = _str([() => widget.ad.currency]);
    if (price == null) return '';
    return currency.isEmpty ? '$price' : '$price $currency';
  }

  String get _imageUrl {
    final direct = _str([
      () => widget.ad.mainImageUrl,
      () => widget.ad.imageUrl,
      () => widget.ad.thumbnail,
      () => widget.ad.thumbnailUrl,
    ]);
    if (direct.isNotEmpty) return direct;

    try {
      final images = widget.ad.images;
      if (images is List && images.isNotEmpty) {
        final first = images.first?.toString() ?? '';
        if (first.trim().isNotEmpty) return first.trim();
      }
    } catch (_) {}

    return '';
  }

  int get _adId {
    final raw = _val([() => widget.ad.id]);
    return int.tryParse('$raw') ?? 0;
  }

  void _applyQuickAction(String text) {
    final current = _messageController.text.trim();
    if (current.isEmpty) {
      _messageController.text = text;
    } else {
      _messageController.text = '$current\n$text';
    }

    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );

    setState(() {});
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Room? _findRoomById(List<Room> rooms, String roomId) {
    try {
      return rooms.firstWhere((room) => room.id == roomId);
    } catch (_) {
      return null;
    }
  }

  String _bubbleTitle(Room? room) {
    final other = room?.otherUser;
    if (other == null) return 'mini_chat'.tr;

    final first = (other.firstName ?? '').toString().trim();
    final last = (other.lastName ?? '').toString().trim();
    final full = [first, last].where((e) => e.isNotEmpty).join(' ');
    if (full.isNotEmpty) return full;

    final username = (other.username ?? '').toString().trim();
    if (username.isNotEmpty) return username;

    return 'mini_chat'.tr;
  }

  void _closeComposer() {
    final scope = GenericAiOverlayScope.maybeOf(context);
    if (scope != null) {
      scope.closeOverlay();
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _send() async {
    if (_adId <= 0) {
      _snack('invalid_ad'.tr);
      return;
    }

    setState(() => _isBusy = true);

    try {
      final roomId = await ref.read(fetchRoomsProvider.notifier).createRoom(
            _adId,
            initialContent: '',
          );

      if (roomId == null || roomId.isEmpty) {
        _snack('failed_to_create_chat'.tr);
        return;
      }

      await ref.read(fetchRoomsProvider.notifier).fetchRooms();
      final rooms = ref.read(fetchRoomsProvider);
      final room = _findRoomById(rooms, roomId);

      ref.read(selectedChatId.notifier).state = roomId;

      if (room?.otherUser != null) {
        ref.read(otherUserData.notifier).state = room!.otherUser!;
      }

      final text = _messageController.text.trim();

      if (text.isNotEmpty) {
        await ref.read(chatMessageRoomProvider.notifier).sendMessage(
              text,
              roomId,
            );
      }

      await ref
          .read(chatMessageRoomProvider.notifier)
          .sendPortalAdvertisementCardMessage(
            ad: widget.ad,
            roomId: roomId,
          );

      await ref.read(chatMessageRoomProvider.notifier).fetchRoomMessages(
            roomId,
            ref,
          );

      await showChatBubbleOverlay(
        context: context,
        title: _bubbleTitle(room),
        avatarUrl: room?.otherUser?.avatar,
        subtitle: 'mini_chat'.tr,
        child: Column(
          children: [
            Expanded(
              child: ChatMessagesWidget(
                isMobile: widget.isMobile,
              ),
            ),
            const SendMessageBox(),
          ],
        ),
      );

      _closeComposer();
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Widget _buildAdCard(ThemeColors theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _imageUrl.isNotEmpty
                ? Image.network(
                    _imageUrl,
                    width: 96,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return _PortalAdFallbackThumb(
                        title: _title,
                        theme: theme,
                      );
                    },
                  )
                : _PortalAdFallbackThumb(
                    title: _title,
                    theme: theme,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (_address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(180),
                      fontSize: 12,
                    ),
                  ),
                ],
                if (_priceText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _priceText,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
      return SingleChildScrollView(
        controller: widget.scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24
        ),
        child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child:  Column(
          children: [
            _buildAdCard(theme),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'quick_actions'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final action in _quickActions)
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: _isBusy ? null : () => _applyQuickAction(action),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.textFieldColor.withAlpha(110),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: theme.dashboardBoarder),
                        ),
                        child: Text(
                          action,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: widget.isMobile ? 100 : 260 ,
              child: TextField(
                controller: _messageController,
                minLines: 5,
                maxLines: null,
                cursorColor: theme.textColor,
                scrollPadding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 120,
                ),
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  hintText: 'write_message_here'.tr,
                  hintStyle: TextStyle(color: theme.textColor.withAlpha(140)),
                  filled: true,
                  fillColor: theme.textFieldColor.withAlpha(80),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isBusy ? null : _closeComposer,
                    child: Text('Cancel'.tr, style: TextStyle(color: theme.textColor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                      style: buttonStyleRounded10ThemeRedWithPadding15,

                      onPressed: _isBusy ? null : _send,
                      child:
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            Text('send'.tr, style: TextStyle(color: AppColors.white)),

                            const SizedBox(width: 16),
                            _isBusy
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Icon(Icons.send_rounded, color: AppColors.white),

                          ]
                      )
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      );
    },);
  }
}

class _PortalAdFallbackThumb extends StatelessWidget {
  final ThemeColors theme;
  final String title;

  const _PortalAdFallbackThumb({
    required this.theme,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.textFieldColor.withAlpha(120),
            theme.dashboardContainer.withAlpha(200),
          ],
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        title,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: theme.textColor,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}