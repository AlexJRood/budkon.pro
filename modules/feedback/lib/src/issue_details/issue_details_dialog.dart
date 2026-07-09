library issue_details_dialog;
import 'package:feedback/src/provider/open_issues_provider.dart';
import 'package:feedback/src/theme/feedback_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/user/user/user_provider.dart';
part 'issue_details_dialog_constants.dart';
part 'issue_details_dialog_widgets.dart';
part 'issue_details_dialog_state.dart';

class IssueDetailsDialog extends ConsumerStatefulWidget {
  final FeedbackModel issue;

  const IssueDetailsDialog({super.key, required this.issue});

  @override
  ConsumerState<IssueDetailsDialog> createState() =>
      _IssueDetailsDialogState();
}