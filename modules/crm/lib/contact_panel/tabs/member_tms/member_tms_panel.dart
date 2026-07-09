import 'package:crm/contact_panel/tabs/member_tms/member_tms_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:tms_app/todo/view/crm_tms_board.dart';

class MemberTmsPanel extends ConsumerWidget {
  final int memberId;
  final bool isMobile;

  const MemberTmsPanel({
    super.key,
    required this.memberId,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(memberTmsProvider(memberId));
    final notifier = ref.read(memberTmsProvider(memberId).notifier);

    if (state.forbidden) {
      return _MessageState(
        icon: Icons.lock_outline,
        title: 'Brak dostępu',
        message: state.error ?? 'Nie masz dostępu do zadań tego pracownika.',
      );
    }

    if (state.isLoadingBoards && state.boards.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: theme.themeColor),
      );
    }

    if (state.error != null && state.boards.isEmpty) {
      return _MessageState(
        icon: Icons.error_outline,
        title: 'Nie udało się załadować TMS',
        message: state.error!,
        actionLabel: 'Spróbuj ponownie',
        onAction: notifier.refresh,
      );
    }

    if (state.boards.isEmpty) {
      return _MessageState(
        icon: Icons.view_kanban_outlined,
        title: 'Brak tablic',
        message:
            'Pracownik nie ma tablic ani zadań pasujących do wybranego filtra.',
        actionLabel: 'Odśwież',
        onAction: notifier.refresh,
      );
    }

    final toolbar = _MemberTmsToolbar(
      state: state,
      onScopeChanged: notifier.setScope,
      onRefresh: notifier.refresh,
    );

    if (isMobile) {
      return Column(
        children: [
          toolbar,
          SizedBox(
            height: 102,
            child: _MobileBoardSelector(
              state: state,
              onSelected: notifier.selectBoard,
            ),
          ),
          Expanded(
            child: _BoardBody(
              state: state,
              isMobile: true,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        toolbar,
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 250,
                child: _DesktopBoardSelector(
                  state: state,
                  onSelected: notifier.selectBoard,
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: theme.dashboardBoarder,
              ),
              Expanded(
                child: _BoardBody(
                  state: state,
                  isMobile: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberTmsToolbar extends ConsumerWidget {
  final MemberTmsState state;
  final Future<void> Function(MemberTmsTaskScope scope) onScopeChanged;
  final Future<void> Function() onRefresh;

  const _MemberTmsToolbar({
    required this.state,
    required this.onScopeChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border(
          bottom: BorderSide(color: theme.dashboardBoarder),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.view_kanban_outlined, color: theme.themeColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Zadania pracownika',
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Podgląd tylko do odczytu',
                  style: TextStyle(
                    color: theme.textColor.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<MemberTmsTaskScope>(
              value: state.scope,
              dropdownColor: theme.adPopBackground,
              style: TextStyle(color: theme.textColor, fontSize: 12),
              items: MemberTmsTaskScope.values
                  .map(
                    (scope) => DropdownMenuItem(
                      value: scope,
                      child: Text(scope.label),
                    ),
                  )
                  .toList(),
              onChanged: state.isLoadingBoards
                  ? null
                  : (scope) {
                      if (scope != null) onScopeChanged(scope);
                    },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: state.isLoadingBoards ? null : onRefresh,
            tooltip: 'Odśwież',
            icon: state.isLoadingBoards
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.themeColor,
                    ),
                  )
                : Icon(Icons.refresh, color: theme.textColor),
          ),
        ],
      ),
    );
  }
}

class _DesktopBoardSelector extends ConsumerWidget {
  final MemberTmsState state;
  final Future<void> Function(int boardId) onSelected;

  const _DesktopBoardSelector({
    required this.state,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      color: theme.dashboardContainer,
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: state.boards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final board = state.boards[index];
          return _BoardTile(
            board: board,
            selected: state.selectedBoardId == board.id,
            onTap: () => onSelected(board.id),
          );
        },
      ),
    );
  }
}

class _MobileBoardSelector extends ConsumerWidget {
  final MemberTmsState state;
  final Future<void> Function(int boardId) onSelected;

  const _MobileBoardSelector({
    required this.state,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      scrollDirection: Axis.horizontal,
      itemCount: state.boards.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final board = state.boards[index];
        return SizedBox(
          width: 220,
          child: _BoardTile(
            board: board,
            selected: state.selectedBoardId == board.id,
            onTap: () => onSelected(board.id),
          ),
        );
      },
    );
  }
}

class _BoardTile extends ConsumerWidget {
  final MemberTmsBoardSummary board;
  final bool selected;
  final VoidCallback onTap;

  const _BoardTile({
    required this.board,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final avatar = (board.avatar ?? '').trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? theme.themeColor.withOpacity(0.14)
                : theme.textFieldColor.withOpacity(0.35),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? theme.themeColor : theme.dashboardBoarder,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: theme.adPopBackground,
                backgroundImage:
                    avatar.isNotEmpty ? NetworkImage(avatar) : null,
                child: avatar.isEmpty
                    ? Icon(Icons.view_kanban, color: theme.textColor, size: 18)
                    : null,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      board.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 7,
                      children: [
                        _counter(
                          '${board.openTaskCount}',
                          Icons.pending_actions_outlined,
                          theme.textColor,
                        ),
                        if (board.overdueTaskCount > 0)
                          _counter(
                            '${board.overdueTaskCount}',
                            Icons.warning_amber_rounded,
                            Colors.redAccent,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.chevron_right, color: theme.themeColor, size: 19),
            ],
          ),
        ),
      ),
    );
  }

  Widget _counter(String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 10),
        ),
      ],
    );
  }
}

class _BoardBody extends ConsumerWidget {
  final MemberTmsState state;
  final bool isMobile;

  const _BoardBody({
    required this.state,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    if (state.isLoadingBoard && state.boardDetails == null) {
      return Center(
        child: CircularProgressIndicator(color: theme.themeColor),
      );
    }

    final details = state.boardDetails;
    if (details == null) {
      return const _MessageState(
        icon: Icons.space_dashboard_outlined,
        title: 'Wybierz tablicę',
        message: 'Wybierz tablicę pracownika, aby zobaczyć jego zadania.',
      );
    }

    return Stack(
      children: [
        CrmToDoBoard(
          key: ValueKey(
            'member-board-${details.id}-${state.scope.apiValue}',
          ),
          isMobile: isMobile,
          readOnly: true,
          boardDetailsOverride: details,
        ),
        if (state.isLoadingBoard)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: theme.dashboardContainer.withOpacity(0.3),
                child: Center(
                  child: CircularProgressIndicator(color: theme.themeColor),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
