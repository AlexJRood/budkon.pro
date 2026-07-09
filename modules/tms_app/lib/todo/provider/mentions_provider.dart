// tms_app/todo/provider/mentions_provider.dart


import 'package:crm/data/clients/client_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/user/user/user_provider.dart';

class MentionTextEditingController extends TextEditingController {
  MentionTextEditingController({required TextStyle mentionStyle})
    : _mentionStyle = mentionStyle;

  TextStyle _mentionStyle;
  set mentionStyle(TextStyle v) => _mentionStyle = v;

  // Matches @something or @@something until space/@
  static final RegExp _mentionRe = RegExp(r'@@?[^\s@]+');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    bool withComposing = false,
  }) {
    final text = value.text;
    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    final List<InlineSpan> children = [];
    int start = 0;

    for (final m in _mentionRe.allMatches(text)) {
      if (m.start > start) {
        children.add(
          TextSpan(text: text.substring(start, m.start), style: style),
        );
      }
      children.add(TextSpan(text: m.group(0), style: _mentionStyle));
      start = m.end;
    }
    if (start < text.length) {
      children.add(TextSpan(text: text.substring(start), style: style));
    }

    return TextSpan(style: style, children: children);
  }
}

enum MentionMode { none, clients, members }

class MentionState {
  final bool open;
  final bool loading;
  final MentionMode mode;
  final List<dynamic> items;
  final int activeIndex;
  final int? rangeStart;
  final int? rangeEnd;

  const MentionState({
    required this.open,
    required this.loading,
    required this.mode,
    required this.items,
    required this.activeIndex,
    required this.rangeStart,
    required this.rangeEnd,
  });

  factory MentionState.initial() => const MentionState(
    open: false,
    loading: false,
    mode: MentionMode.none,
    items: <dynamic>[],
    activeIndex: 0,
    rangeStart: null,
    rangeEnd: null,
  );

  MentionState copyWith({
    bool? open,
    bool? loading,
    MentionMode? mode,
    List<dynamic>? items,
    int? activeIndex,
    int? rangeStart,
    int? rangeEnd,
  }) {
    return MentionState(
      open: open ?? this.open,
      loading: loading ?? this.loading,
      mode: mode ?? this.mode,
      items: items ?? this.items,
      activeIndex: activeIndex ?? this.activeIndex,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
    );
  }
}

class MentionController extends StateNotifier<MentionState> {
  MentionController(this.ref) : super(MentionState.initial());
  final Ref ref;

  static String clientName(dynamic c) {
    final n = (c.name ?? '').toString().trim();
    if (n.isNotEmpty) return n;
    final first = (c.firstName ?? '').toString().trim();
    final last = (c.lastName ?? '').toString().trim();
    final full = ('$first $last').trim();
    return full.isNotEmpty ? full : c.toString();
  }

  static String memberName(dynamic m) {
    final first = (m.firstName ?? '').toString().trim();
    final last = (m.lastName ?? '').toString().trim();
    final full = ('$first $last').trim();
    return full.isNotEmpty ? full : m.toString();
  }

  void setRange(int start, int end) =>
      state = state.copyWith(rangeStart: start, rangeEnd: end);

  void resetRange() => state = state.copyWith(rangeStart: null, rangeEnd: null);

  void close() => state = MentionState.initial();

  void setActive(int i) {
    if (state.items.isEmpty) return;
    final clamped = i.clamp(0, state.items.length - 1);
    state = state.copyWith(activeIndex: clamped);
  }

  void next() => setActive(state.activeIndex + 1);
  void prev() => setActive(state.activeIndex - 1);

  void filterMembers(String query) {
    final user = ref.read(userProvider).value;
    if (user == null) {
      close();
      return;
    }
    final lower = query.toLowerCase();
    final list =
        user.companyMembers.where((m) {
          final name = memberName(m).toLowerCase();
          return name.contains(lower);
        }).toList();

    final items = list.isEmpty && query.isEmpty ? user.companyMembers : list;
    if (items.isEmpty) {
      close();
    } else {
      state = state.copyWith(
        open: true,
        loading: false,
        mode: MentionMode.members,
        items: items,
        activeIndex: 0,
      );
    }
  }

  void filterClients(String query) {
    final clientsAsync = ref.read(clientProvider);
    clientsAsync.when(
      data: (clients) {
        final lower = query.toLowerCase();
        final list =
            clients
                .where((c) => clientName(c).toLowerCase().contains(lower))
                .toList();
        final items = query.isEmpty ? clients : list;

        if (items.isEmpty) {
          close();
        } else {
          state = state.copyWith(
            open: true,
            loading: false,
            mode: MentionMode.clients,
            items: items,
            activeIndex: 0,
          );
        }
      },
      loading: () {
        state = state.copyWith(
          open: true,
          loading: true,
          mode: MentionMode.clients,
          items: const [],
          activeIndex: 0,
        );
      },
      error: (_, __) => close(),
    );
  }
}

final mentionControllerProvider = StateNotifierProvider.autoDispose
    .family<MentionController, MentionState, String>(
      (ref, taskId) => MentionController(ref),
    );
