import 'package:flutter/material.dart';
import 'package:core/theme/apptheme.dart';

import '../../models/automation_graph.dart';
import 'automation_node_ports.dart';

class AutomationNodeCard extends StatelessWidget {
  final AutomationGraphNode node;
  final ThemeColors theme;
  final bool selected;
  final bool multiSelected;
  final bool connecting;
  final String? connectionSourceNodeId;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(String sourceHandle) onStartConnect;
  final VoidCallback onFinishConnect;
  final VoidCallback? onInputPortTap;
  final void Function(String sourceHandle)? onOutputPortTap;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback? onDragEnd;
  final void Function(String sourceHandle, DragStartDetails details)? onConnectionDragStart;
  final GestureDragUpdateCallback? onConnectionDragUpdate;
  final GestureDragEndCallback? onConnectionDragEnd;
  final VoidCallback? onDuplicate;
  final VoidCallback? onCopy;
  final VoidCallback? onCut;

  const AutomationNodeCard({
    super.key,
    required this.node,
    required this.theme,
    required this.selected,
    this.multiSelected = false,
    required this.connecting,
    this.connectionSourceNodeId,
    required this.onTap,
    required this.onDelete,
    required this.onStartConnect,
    required this.onFinishConnect,
    this.onInputPortTap,
    this.onOutputPortTap,
    required this.onDragStart,
    required this.onDragUpdate,
    this.onDragEnd,
    this.onConnectionDragStart,
    this.onConnectionDragUpdate,
    this.onConnectionDragEnd,
    this.onDuplicate,
    this.onCopy,
    this.onCut,
  });

  static const double _cardWidth = AutomationNodePortResolver.nodeWidth;

  bool get isConnectionSource => connectionSourceNodeId == node.id;
  bool get canReceiveConnection => connecting && !isConnectionSource;

  IconData get icon {
    switch (node.type) {
      case 'trigger':
        return Icons.flash_on_rounded;
      case 'condition':
        return Icons.rule_rounded;
      case 'switch':
        return Icons.alt_route_rounded;
      case 'delay':
        return Icons.schedule_rounded;
      case 'approval':
        return Icons.verified_user_rounded;
      case 'ai_prompt':
        return Icons.auto_awesome_rounded;
      case 'code':
      case 'code_run':
        return Icons.code_rounded;
      case 'api':
      case 'http':
        return Icons.http_rounded;
      case 'for_each':
        return Icons.repeat_rounded;
      case 'parallel':
        return Icons.call_split_rounded;
      case 'wait_for_event':
        return Icons.notifications_paused_rounded;
      case 'set_variable':
        return Icons.edit_note_rounded;
      case 'loop_until':
        return Icons.loop_rounded;
      case 'subworkflow':
        return Icons.account_tree_rounded;
      case 'end':
        return Icons.flag_rounded;
      case 'action':
      default:
        return Icons.play_circle_fill_rounded;
    }
  }

  Color _accent() {
    switch (node.type) {
      case 'trigger':
        return Colors.green;
      case 'condition':
      case 'switch':
        return Colors.orange;
      case 'approval':
        return Colors.indigo;
      case 'ai_prompt':
        return Colors.purple;
      case 'code':
      case 'code_run':
        return Colors.blueGrey;
      case 'api':
      case 'http':
        return Colors.teal;
      case 'for_each':
        return Colors.cyan.shade700;
      case 'parallel':
        return Colors.blue;
      case 'wait_for_event':
        return Colors.amber.shade700;
      case 'set_variable':
        return Colors.teal.shade600;
      case 'loop_until':
        return Colors.deepPurple.shade400;
      case 'subworkflow':
        return Colors.indigo.shade400;
      case 'end':
        return theme.textColor.withAlpha(150);
      case 'action':
      default:
        return theme.themeColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent();
    final borderColor = selected || isConnectionSource
        ? accent
        : theme.dashboardBoarder.withAlpha(150);
    final subtitle = _Subtitle.fromNode(node);
    final outputPorts = AutomationNodePortResolver.outputPorts(node);
    final visualHeight = AutomationNodePortResolver.visualHeight(node);

    // Important:
    // The widget is wider than the visible card so output labels/dots placed
    // slightly outside the card still receive pointer events.
    final hitWidth = outputPorts.length <= 1 ? _cardWidth + 42 : _cardWidth + 152;

    return SizedBox(
      width: hitWidth,
      height: visualHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: _cardWidth,
            height: visualHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              onPanStart: onDragStart,
              onPanUpdate: onDragUpdate,
              onPanEnd: onDragEnd,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                width: _cardWidth,
                constraints: BoxConstraints(minHeight: visualHeight),
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: borderColor,
                    width: selected || isConnectionSource ? 2.2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selected || isConnectionSource
                          ? accent.withAlpha(58)
                          : Colors.black.withAlpha(22),
                      blurRadius: selected || isConnectionSource ? 26 : 12,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Decorative layer must never participate in hit-testing.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withAlpha(selected || isConnectionSource ? 28 : 12),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 44, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: accent.withAlpha(28),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: accent.withAlpha(55)),
                            ),
                            child: Icon(icon, size: 18, color: accent),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DefaultTextStyle(
                              style: TextStyle(color: theme.textColor),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          node.label,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            color: theme.textColor,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ),
                                      if (multiSelected || isConnectionSource)
                                        Container(
                                          margin: const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accent.withAlpha(25),
                                            borderRadius: BorderRadius.circular(99),
                                          ),
                                          child: Text(
                                            isConnectionSource ? 'source' : 'selected',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: accent,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    node.type,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.textColor.withAlpha(150),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (subtitle.text.isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      subtitle.text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: theme.textColor.withAlpha(145),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: PopupMenuButton<String>(
                        tooltip: '',
                        color: theme.dashboardContainer,
                        surfaceTintColor: Colors.transparent,
                        elevation: 10,
                        icon: Icon(
                          Icons.more_horiz,
                          color: theme.textColor.withAlpha(150),
                          size: 18,
                        ),
                        onSelected: (value) {
                          if (value == 'delete') onDelete();
                          if (value == 'connect') onStartConnect('default');
                          if (value == 'finish') onFinishConnect();
                          if (value == 'duplicate') onDuplicate?.call();
                          if (value == 'copy') onCopy?.call();
                          if (value == 'cut') onCut?.call();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: connecting ? 'finish' : 'connect',
                            child: Text(
                              connecting ? 'Connect here' : 'Connect from here',
                              style: TextStyle(color: theme.textColor),
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'copy',
                            child: Text('Copy', style: TextStyle(color: theme.textColor)),
                          ),
                          PopupMenuItem(
                            value: 'cut',
                            child: Text('Cut', style: TextStyle(color: theme.textColor)),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Text('Duplicate', style: TextStyle(color: theme.textColor)),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete', style: TextStyle(color: theme.textColor)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Ports are rendered AFTER the card surface, so they win the hit test.
          Positioned(
            left: -10,
            top: visualHeight / 2 - 16,
            child: _ConnectionPort(
              color: canReceiveConnection ? Colors.green : theme.dashboardBoarder,
              active: canReceiveConnection,
              pulse: canReceiveConnection,
              icon: canReceiveConnection
                  ? Icons.add_link_rounded
                  : Icons.radio_button_unchecked_rounded,
              tooltip: canReceiveConnection ? 'Click to connect here' : 'Input',
              onTap: onInputPortTap ?? (connecting ? onFinishConnect : null),
            ),
          ),
          for (var i = 0; i < outputPorts.length; i++)
            Positioned(
              // Keep the visual dot aligned with x ~= 250 used by the edge painter,
              // while still giving the whole port pill a real hit-test area.
              left: outputPorts.length == 1 ? _cardWidth - 24 : _cardWidth - 142,
              top: outputPorts.length == 1
                  ? visualHeight / 2 - 16
                  : AutomationNodePortResolver.outputTopPadding +
                      i * AutomationNodePortResolver.outputStep -
                      8,
              child: _OutputPortButton(
                port: outputPorts[i],
                theme: theme,
                accent: outputPorts[i].color ?? accent,
                compact: outputPorts.length == 1,
                active: isConnectionSource && connectionSourceNodeId == node.id,
                onTap: () => (onOutputPortTap ?? onStartConnect)(outputPorts[i].id),
                onPanStart: onConnectionDragStart == null
                    ? null
                    : (details) => onConnectionDragStart!(outputPorts[i].id, details),
                onPanUpdate: onConnectionDragUpdate,
                onPanEnd: onConnectionDragEnd,
              ),
            ),
        ],
      ),
    );
  }
}

class _OutputPortButton extends StatefulWidget {
  final AutomationNodePort port;
  final ThemeColors theme;
  final Color accent;
  final bool compact;
  final bool active;
  final VoidCallback onTap;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;

  const _OutputPortButton({
    required this.port,
    required this.theme,
    required this.accent,
    required this.compact,
    required this.active,
    required this.onTap,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  });

  @override
  State<_OutputPortButton> createState() => _OutputPortButtonState();
}

class _OutputPortButtonState extends State<_OutputPortButton> {
  bool _tapStartedConnection = false;

  void _startFromTap() {
    // This runs before the card surface can react to a tap.
    // If parent selection also fires later, connection mode is already active.
    _tapStartedConnection = true;
    widget.onTap();
  }

  void _handleTap() {
    if (_tapStartedConnection) {
      _tapStartedConnection = false;
      return;
    }

    widget.onTap();
  }

  void _handlePanStart(DragStartDetails details) {
    _tapStartedConnection = false;
    widget.onPanStart?.call(details);
  }

  @override
  Widget build(BuildContext context) {
    final dot = _ConnectionPort(
      color: widget.active ? Colors.green : widget.accent,
      active: widget.active,
      pulse: widget.active,
      icon: widget.active ? Icons.polyline_rounded : widget.port.icon,
      tooltip: widget.active
          ? 'Connection started. Click target input dot.'
          : 'Output: ${widget.port.label}',
      onTap: _startFromTap,
    );

    final child = widget.compact
        ? dot
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 108),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.theme.dashboardContainer.withAlpha(245),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: widget.accent.withAlpha(130)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  widget.port.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.theme.textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              dot,
            ],
          );

    return Tooltip(
      message: widget.port.description.isEmpty
          ? 'Output: ${widget.port.label}'
          : widget.port.description,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _startFromTap(),
          onTap: _handleTap,
          onPanStart: _handlePanStart,
          onPanUpdate: widget.onPanUpdate,
          onPanEnd: widget.onPanEnd,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ConnectionPort extends StatelessWidget {
  final Color color;
  final bool active;
  final bool pulse;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ConnectionPort({
    required this.color,
    required this.active,
    required this.pulse,
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final port = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      width: active ? 24 : 20,
      height: active ? 24 : 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(pulse ? 150 : 90),
            blurRadius: pulse ? 18 : 9,
            spreadRadius: pulse ? 2 : 0,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: active ? 12 : 10,
        color: Colors.white,
      ),
    );

    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: port,
          ),
        ),
      ),
    );
  }
}

class _Subtitle {
  final String text;

  const _Subtitle(this.text);

  factory _Subtitle.fromNode(AutomationGraphNode node) {
    final data = node.data;
    String value(String key) => data[key]?.toString().trim() ?? '';

    switch (node.type) {
      case 'trigger':
        return _Subtitle(
          value('signal_key').isNotEmpty ? value('signal_key') : value('trigger_type'),
        );
      case 'action':
        return _Subtitle(value('action_key'));
      case 'condition':
        return const _Subtitle('if / condition');
      case 'switch':
        return _Subtitle(
          value('field').isNotEmpty ? 'switch ${value('field')}' : 'switch',
        );
      case 'ai_prompt':
        return _Subtitle(
          value('output_key').isNotEmpty ? 'output: ${value('output_key')}' : 'AI prompt',
        );
      case 'delay':
        return const _Subtitle('scheduled delay');
      case 'for_each':
        return _Subtitle(
          value('items_path').isNotEmpty ? value('items_path') : 'for each item',
        );
      case 'parallel':
        return const _Subtitle('parallel branches');
      case 'wait_for_event':
        return _Subtitle(
          value('signal_key').isNotEmpty ? value('signal_key') : 'waiting for event',
        );
      case 'set_variable':
        return _Subtitle(
          value('key').isNotEmpty ? '{{vars.${value('key')}}}' : 'set variable',
        );
      case 'loop_until':
        final attempts = data['max_attempts']?.toString() ?? '10';
        return _Subtitle('max $attempts attempts');
      case 'subworkflow':
        return _Subtitle(
          value('workflow_id').isNotEmpty
              ? 'workflow: ${value('workflow_id').substring(0, 8)}…'
              : 'subworkflow',
        );
      default:
        return const _Subtitle('');
    }
  }
}
