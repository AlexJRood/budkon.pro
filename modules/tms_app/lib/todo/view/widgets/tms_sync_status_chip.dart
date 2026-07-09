import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tms_app/todo/local/tms_sync_status_provider.dart';

class TmsSyncStatusChip extends ConsumerWidget {
  const TmsSyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(tmsSyncUiStateProvider);
    final theme = Theme.of(context);

    IconData icon;
    Color color;

    switch (sync.kind) {
      case TmsSyncUiKind.synced:
        icon = Icons.cloud_done_rounded;
        color = Colors.green;
        break;
      case TmsSyncUiKind.pending:
        icon = Icons.cloud_off_rounded;
        color = Colors.orange;
        break;
      case TmsSyncUiKind.syncing:
        icon = Icons.sync_rounded;
        color = Colors.blue;
        break;
      case TmsSyncUiKind.failed:
        icon = Icons.error_outline_rounded;
        color = Colors.deepOrange;
        break;
      case TmsSyncUiKind.conflict:
        icon = Icons.warning_amber_rounded;
        color = Colors.redAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              sync.message?.trim().isNotEmpty == true
                  ? sync.message!
                  : sync.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}