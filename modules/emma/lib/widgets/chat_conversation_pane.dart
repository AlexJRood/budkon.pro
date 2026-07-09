import 'package:emma/widgets/appbar_chat.dart';
import 'package:emma/widgets/message_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emma/provider/emma_provider.dart';
import 'package:emma/widgets/send_message_box.dart';
import 'package:emma/widgets/empty_chat_state.dart';

class ChatConversationPane extends ConsumerWidget {
  const ChatConversationPane({super.key, this.isMobile = false, this.isAppBar = true});
  final bool isMobile;
  final bool isAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedAiRoomProvider).trim();
    final inChat = selected.isNotEmpty;

    return Column(
      children: [
        if(isAppBar)
        AiAppBar(isMobile: isMobile,),
        Expanded(
          child: inChat
              ? MessageListView(isMobile: isMobile)
              : const EmptyChatState(),
        ),

        // Only show bottom SendMessageBox when in an active chat.
        if (inChat) const SendMessageBox(),
      ],
    );
  }
}
