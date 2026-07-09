import 'package:flutter/material.dart';

import '../../config/automation_studio_config.dart';
import '../../models/automation_common.dart';
import 'automation_badge.dart';

class AutomationRiskBadge extends StatelessWidget {
  final AutomationWorkflowRiskLevel riskLevel;
  const AutomationRiskBadge({super.key, required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    final colors = automationColors(context);
    final color = switch (riskLevel) {
      AutomationWorkflowRiskLevel.low => colors.success,
      AutomationWorkflowRiskLevel.medium => colors.warning,
      AutomationWorkflowRiskLevel.high => Colors.deepOrange,
      AutomationWorkflowRiskLevel.critical => Colors.red,
    };
    return AutomationBadge(label: enumName(riskLevel), color: color);
  }
}

class AutomationReviewBadge extends StatelessWidget {
  final AutomationWorkflowReviewStatus reviewStatus;
  const AutomationReviewBadge({super.key, required this.reviewStatus});

  @override
  Widget build(BuildContext context) {
    final colors = automationColors(context);
    final color = switch (reviewStatus) {
      AutomationWorkflowReviewStatus.approved => colors.success,
      AutomationWorkflowReviewStatus.pending => colors.warning,
      AutomationWorkflowReviewStatus.rejected => Colors.red,
      AutomationWorkflowReviewStatus.changesRequested => Colors.deepOrange,
      AutomationWorkflowReviewStatus.expired => colors.mutedText,
      AutomationWorkflowReviewStatus.notRequired => colors.border,
    };
    return AutomationBadge(label: enumName(reviewStatus), color: color);
  }
}

class AutomationSourceBadge extends StatelessWidget {
  final AutomationWorkflowSource source;
  const AutomationSourceBadge({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final colors = automationColors(context);
    return AutomationBadge(
      label: enumName(source),
      color: source == AutomationWorkflowSource.emma ? colors.primary : colors.mutedText,
    );
  }
}
