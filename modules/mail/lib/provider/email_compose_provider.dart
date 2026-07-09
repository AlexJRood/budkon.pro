import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mail/utils/utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:mail/settings/settings_mail_pc.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

import '../utils/api_services.dart';

enum ComposeAttachmentDeliveryMode {
  direct,
  link,
}

@immutable
class ComposeAttachmentItem {
  final String fileId;
  final String name;
  final int sizeBytes;
  final String? url;
  final ComposeAttachmentDeliveryMode deliveryMode;

  const ComposeAttachmentItem({
    required this.fileId,
    required this.name,
    required this.sizeBytes,
    required this.url,
    required this.deliveryMode,
  });

  ComposeAttachmentItem copyWith({
    String? fileId,
    String? name,
    int? sizeBytes,
    String? url,
    ComposeAttachmentDeliveryMode? deliveryMode,
  }) {
    return ComposeAttachmentItem(
      fileId: fileId ?? this.fileId,
      name: name ?? this.name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      url: url ?? this.url,
      deliveryMode: deliveryMode ?? this.deliveryMode,
    );
  }
}

@immutable
class EmailComposeState {
  final bool isCollapsed;
  final bool showCC;
  final bool showBCC;
  final String? lastSubject;
  final bool isSending;
  final bool isUploadingAttachments;
  final List<ComposeAttachmentItem> attachments;

  const EmailComposeState({
    required this.isCollapsed,
    required this.showCC,
    required this.showBCC,
    required this.lastSubject,
    required this.isSending,
    required this.isUploadingAttachments,
    required this.attachments,
  });

  factory EmailComposeState.initial() => const EmailComposeState(
        isCollapsed: false,
        showCC: false,
        showBCC: false,
        lastSubject: null,
        isSending: false,
        isUploadingAttachments: false,
        attachments: [],
      );

  EmailComposeState copyWith({
    bool? isCollapsed,
    bool? showCC,
    bool? showBCC,
    String? lastSubject,
    bool? isSending,
    bool? isUploadingAttachments,
    List<ComposeAttachmentItem>? attachments,
  }) {
    return EmailComposeState(
      isCollapsed: isCollapsed ?? this.isCollapsed,
      showCC: showCC ?? this.showCC,
      showBCC: showBCC ?? this.showBCC,
      lastSubject: lastSubject ?? this.lastSubject,
      isSending: isSending ?? this.isSending,
      isUploadingAttachments:
          isUploadingAttachments ?? this.isUploadingAttachments,
      attachments: attachments ?? this.attachments,
    );
  }
}

class EmailComposeNotifier extends StateNotifier<EmailComposeState> {
  EmailComposeNotifier(this.ref) : super(EmailComposeState.initial()) {
    ref.onDispose(() {
      _removeSendMenu();
      subjectController.dispose();
      bodyController.dispose();

      for (final c in toControllers) {
        c.dispose();
      }
      for (final c in ccControllers) {
        c.dispose();
      }
      for (final c in bccControllers) {
        c.dispose();
      }
    });
  }

  final Ref ref;

  static const int _directAttachmentMaxBytes = 10 * 1024 * 1024;
  static const int _directAttachmentMaxTotalBytes = 20 * 1024 * 1024;

  final TextEditingController subjectController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();

  final List<TextEditingController> toControllers = [];
  final List<TextEditingController> ccControllers = [];
  final List<TextEditingController> bccControllers = [];

  OverlayEntry? _sendMenuEntry;
  bool _initialized = false;

  bool _hasAnyText(List<TextEditingController> list) {
    for (final c in list) {
      if (c.text.trim().isNotEmpty) return true;
    }
    return false;
  }

  List<String> _getEmailsFromControllers(
    List<TextEditingController> controllers,
  ) {
    final seen = <String>{};
    final result = <String>[];

    for (final c in controllers) {
      final value = c.text.trim();
      if (value.isEmpty) continue;

      final normalized = value.toLowerCase();
      if (seen.contains(normalized)) continue;

      seen.add(normalized);
      result.add(value);
    }

    return result;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w.\-+]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);
  }

  bool _validateEmails(
    BuildContext context,
    List<String> emails, {
    String? prefix,
  }) {
    for (final email in emails) {
      if (!_isValidEmail(email)) {
        _showMsg(
          context,
          '${prefix ?? 'Incorrect email format'.tr}: $email',
          title: 'Warning'.tr,
          type: 'warning',
          isError: true,
          seconds: 5,
        );
        return false;
      }
    }
    return true;
  }

  void _showMsg(
    BuildContext? context,
    String message, {
    String title = 'Info',
    String type = 'info',
    bool isError = false,
    int seconds = 3,
    void Function()? onPressed,
  }) {
    if (context != null && context.mounted) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: seconds),
              backgroundColor: isError
                  ? Colors.redAccent
                  : (type == 'success'
                      ? Colors.green
                      : type == 'warning'
                          ? Colors.orange
                          : null),
            ),
          );
        return;
      }
    }

    ref.read(navigationService).showSnackbar(
          Customsnackbar().showSnackBar(
            title,
            message,
            type,
            onPressed,
          ),
        );
  }

  void resetComposer() {
    subjectController.clear();
    bodyController.clear();

    for (final c in toControllers) {
      c.dispose();
    }
    toControllers
      ..clear()
      ..add(TextEditingController());

    for (final c in ccControllers) {
      c.dispose();
    }
    ccControllers.clear();

    for (final c in bccControllers) {
      c.dispose();
    }
    bccControllers.clear();

    _removeSendMenu();
    _initialized = false;

    state = EmailComposeState.initial();
  }

  Future<bool> _confirmDeleteField(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    if (!context.mounted) return false;

    final theme = ref.read(themeColorsProvider);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: theme.dashboardContainer,
        title: Text(title, style: TextStyle(color: theme.textColor)),
        content: Text(message, style: TextStyle(color: theme.textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('No'.tr, style: TextStyle(color: theme.textColor)),
          ),
          InkWell(
            onTap: () => Navigator.of(dialogContext).pop(true),
            child: Container(
              width: 110,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: theme.themeColor,
              ),
              child: Center(
                child: Text(
                  'Yes, delete'.tr,
                  style: TextStyle(color: theme.themeTextColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return ok == true;
  }

  ComposeAttachmentDeliveryMode _estimateAttachmentDeliveryMode(
    int sizeBytes,
    int currentDirectTotal,
  ) {
    if (sizeBytes <= 0) {
      return ComposeAttachmentDeliveryMode.link;
    }

    if (sizeBytes > _directAttachmentMaxBytes) {
      return ComposeAttachmentDeliveryMode.link;
    }

    if ((currentDirectTotal + sizeBytes) > _directAttachmentMaxTotalBytes) {
      return ComposeAttachmentDeliveryMode.link;
    }

    return ComposeAttachmentDeliveryMode.direct;
  }

  List<String> get attachmentIds {
    final seen = <String>{};
    final out = <String>[];

    for (final item in state.attachments) {
      final id = item.fileId.trim();
      if (id.isEmpty) continue;
      if (seen.add(id)) {
        out.add(id);
      }
    }

    return out;
  }

  Future<void> pickAndUploadAttachments(BuildContext context) async {
    if (state.isSending || state.isUploadingAttachments) return;

    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );

    if (picked == null || picked.files.isEmpty) return;

    state = state.copyWith(isUploadingAttachments: true);

    try {
      int currentDirectTotal = state.attachments
          .where((e) => e.deliveryMode == ComposeAttachmentDeliveryMode.direct)
          .fold<int>(0, (sum, item) => sum + item.sizeBytes);

      final newItems = <ComposeAttachmentItem>[];

      for (final file in picked.files) {
        final uploaded = await EmailService.uploadAttachment(file: file);

        final deliveryMode = _estimateAttachmentDeliveryMode(
          uploaded.sizeBytes,
          currentDirectTotal,
        );

        if (deliveryMode == ComposeAttachmentDeliveryMode.direct) {
          currentDirectTotal += uploaded.sizeBytes;
        }

        newItems.add(
          ComposeAttachmentItem(
            fileId: uploaded.id,
            name: uploaded.name,
            sizeBytes: uploaded.sizeBytes,
            url: uploaded.url,
            deliveryMode: deliveryMode,
          ),
        );
      }

      state = state.copyWith(
        isUploadingAttachments: false,
        attachments: [...state.attachments, ...newItems],
      );

      _showMsg(
        context,
        newItems.length == 1
            ? 'Added 1 attachment.'.tr
            : 'Added ${newItems.length} attachments.'.tr,
        title: 'Success'.tr,
        type: 'success',
      );
    } catch (e, st) {
      debugPrint('[EmailComposeNotifier] pickAndUploadAttachments error: $e');
      debugPrint('$st');

      state = state.copyWith(isUploadingAttachments: false);

      _showMsg(
        context,
        'Could not add attachments: $e',
        title: 'Error'.tr,
        type: 'error',
        isError: true,
        seconds: 5,
      );
    }
  }

  void removeAttachment(String fileId) {
    state = state.copyWith(
      attachments: state.attachments.where((e) => e.fileId != fileId).toList(),
    );
  }

  Future<void> initialize({
    required dynamic lead,
    required String? initialSubject,
    required String? initialBody,
    required List<String>? initialEmails,
    required List<String>? initialCC,
    required List<String>? initialBCC,
    required int? initialEmailAccountId,
  }) async {
    if (_initialized) return;
    _initialized = true;

    String replySubject = '';
    String replyBody = '';

    if (initialEmailAccountId != null) {
      ref.read(selectedEmailAccountIdProvider.notifier).state =
          initialEmailAccountId;
    } else if (ref.read(selectedEmailAccountIdProvider) == null) {
      try {
        final accounts = await ref.read(emailAccountListProvider.future);
        if (accounts.isNotEmpty) {
          ref.read(selectedEmailAccountIdProvider.notifier).state =
              accounts.first.id;
        }
      } catch (_) {
        // Ignore preload errors here.
      }
    }

    if (lead != null) {
      final leadSubject = lead.subject?.toString() ?? '';
      final leadBody = lead.body?.toString();

      if (leadSubject.isNotEmpty && !leadSubject.startsWith('Re:')) {
        replySubject = 'Re: $leadSubject';
      } else {
        replySubject = leadSubject;
      }

      if (leadBody != null && leadBody.isNotEmpty) {
        final dateTimeString = lead.isOutgoing ? lead.sentAt : lead.receivedAt;

        String date = '';
        String time = '';

        if (dateTimeString != null) {
          try {
            final dateTime = DateTime.parse(dateTimeString.toString());
            date = DateFormat('EEE, dd MMM yyyy').format(dateTime);
            time = DateFormat('hh:mma').format(dateTime).toLowerCase();
          } catch (_) {
            // Ignore parsing error.
          }
        }

        final sender = lead.sender?.toString() ?? '';

        final quotedBody = containsHtml(leadBody)
            ? '<blockquote>$leadBody</blockquote>'
            : leadBody.split('\n').map((line) => '> $line').join('\n');

        replyBody = '\n\nOn $date at $time <$sender> wrote:\n$quotedBody';
      }
    }

    subjectController.text =
        replySubject.isNotEmpty ? replySubject : (initialSubject ?? '');
    bodyController.text =
        replyBody.isNotEmpty ? replyBody : (initialBody ?? '');

    if (lead?.sender != null && lead.sender.toString().trim().isNotEmpty) {
      toControllers.add(TextEditingController(text: lead.sender.toString()));
    } else if (initialEmails != null && initialEmails.isNotEmpty) {
      for (final email in initialEmails) {
        toControllers.add(TextEditingController(text: email));
      }
    } else {
      toControllers.add(TextEditingController());
    }

    if (initialCC != null && initialCC.isNotEmpty) {
      for (final email in initialCC) {
        ccControllers.add(TextEditingController(text: email));
      }
      state = state.copyWith(showCC: true);
    }

    if (initialBCC != null && initialBCC.isNotEmpty) {
      for (final email in initialBCC) {
        bccControllers.add(TextEditingController(text: email));
      }
      state = state.copyWith(showBCC: true);
    }

    state = state.copyWith(
      lastSubject: subjectController.text.trim().isEmpty
          ? null
          : subjectController.text.trim(),
    );
  }

  void toggleCollapse() {
    final next = !state.isCollapsed;

    state = state.copyWith(
      isCollapsed: next,
      lastSubject: next ? subjectController.text.trim() : state.lastSubject,
    );

    if (next) {
      _removeSendMenu();
    }
  }

  void showCc() {
    if (state.showCC) return;

    if (ccControllers.isEmpty) {
      ccControllers.add(TextEditingController());
    }

    state = state.copyWith(showCC: true);
  }

  void showBcc() {
    if (state.showBCC) return;

    if (bccControllers.isEmpty) {
      bccControllers.add(TextEditingController());
    }

    state = state.copyWith(showBCC: true);
  }

  Future<void> removeCc(BuildContext context) async {
    if (!_hasAnyText(ccControllers)) {
      for (final c in ccControllers) {
        c.dispose();
      }
      ccControllers.clear();
      state = state.copyWith(showCC: false);
      return;
    }

    final ok = await _confirmDeleteField(
      context,
      title: 'Remove Cc?'.tr,
      message: 'Cc has values. Do you want to clear and remove it?'.tr,
    );
    if (!ok) return;

    for (final c in ccControllers) {
      c.clear();
      c.dispose();
    }
    ccControllers.clear();
    state = state.copyWith(showCC: false);
  }

  Future<void> removeBcc(BuildContext context) async {
    if (!_hasAnyText(bccControllers)) {
      for (final c in bccControllers) {
        c.dispose();
      }
      bccControllers.clear();
      state = state.copyWith(showBCC: false);
      return;
    }

    final ok = await _confirmDeleteField(
      context,
      title: 'Remove Bcc?'.tr,
      message: 'Bcc has values. Do you want to clear and remove it?'.tr,
    );
    if (!ok) return;

    for (final c in bccControllers) {
      c.clear();
      c.dispose();
    }
    bccControllers.clear();
    state = state.copyWith(showBCC: false);
  }

  void addEmailField(List<TextEditingController> list) {
    list.add(TextEditingController());
    state = state.copyWith();
  }

  void removeEmailField(List<TextEditingController> list, int index) {
    if (list.length <= 1) return;
    final controller = list.removeAt(index);
    controller.dispose();
    state = state.copyWith();
  }

  void _removeSendMenu() {
    _sendMenuEntry?.remove();
    _sendMenuEntry = null;
  }

  void toggleSendMenu({
    required BuildContext context,
    required LayerLink link,
    required BuildContext rootContext,
    VoidCallback? onCloseComposer,
    GlobalKey<FormState>? formKey,
  }) {
    if (_sendMenuEntry != null) {
      _removeSendMenu();
      return;
    }

    final overlay = Overlay.of(context, rootOverlay: true);

    _sendMenuEntry = OverlayEntry(
      builder: (ctx) {
        final theme = ref.read(themeColorsProvider);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeSendMenu,
                child: const SizedBox(),
              ),
            ),
            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              offset: const Offset(-160, -45),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 180,
                  decoration: BoxDecoration(
                    color: theme.dashboardContainer.withAlpha(255),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dashboardBoarder),
                  ),
                  child: InkWell(
                    onTap: () async {
                      _removeSendMenu();

                      final ok = formKey?.currentState?.validate() ?? false;
                      if (!ok) return;

                      await scheduleSendFlow(
                        context: context,
                        rootContext: rootContext,
                        onClose: onCloseComposer,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 18,
                            color: theme.textColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Schedule mail…'.tr,
                              style: TextStyle(color: theme.textColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_sendMenuEntry!);
  }

  Future<bool> scheduleSendFlow({
    required BuildContext context,
    required BuildContext rootContext,
    VoidCallback? onClose,
  }) async {
    final toEmails = _getEmailsFromControllers(toControllers);
    final ccEmails = _getEmailsFromControllers(ccControllers);
    final bccEmails = _getEmailsFromControllers(bccControllers);

    final subject = subjectController.text.trim();
    final body = bodyController.text.trim();

    if (subject.isEmpty || body.isEmpty || toEmails.isEmpty) {
      _showMsg(
        rootContext,
        'Fill in the fields: To, Subject and Body'.tr,
        title: 'Warning'.tr,
        type: 'warning',
        isError: true,
      );
      return false;
    }

    final selectedEmailAccountId = ref.read(selectedEmailAccountIdProvider);
    if (selectedEmailAccountId == null) {
      _showMsg(
        rootContext,
        'Before scheduling a shipment, select an email address (sender).'.tr,
        title: 'Warning'.tr,
        type: 'warning',
        isError: true,
      );
      return false;
    }

    if (!_validateEmails(rootContext, toEmails)) return false;
    if (!_validateEmails(
      rootContext,
      ccEmails,
      prefix: 'Incorrect email format in Cc'.tr,
    )) {
      return false;
    }
    if (!_validateEmails(
      rootContext,
      bccEmails,
      prefix: 'Incorrect email format in Bcc'.tr,
    )) {
      return false;
    }

    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      firstDate: now,
      useRootNavigator: true,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now,
      builder: (context, child) {
        final t = ref.read(themeColorsProvider);
        final base = Theme.of(context);

        final scheme = base.colorScheme.copyWith(
          brightness: Brightness.dark,
          primary: t.themeColor,
          onPrimary: AppColors.white,
          surface: t.dashboardContainer,
          onSurface: t.textColor,
          secondary: t.themeColor,
          onSecondary: AppColors.white,
        );

        return Theme(
          data: base.copyWith(
            colorScheme: scheme,
            dialogBackgroundColor: t.dashboardContainer,
            datePickerTheme: DatePickerThemeData(
              backgroundColor: t.dashboardContainer,
              headerBackgroundColor: t.themeColor,
              headerForegroundColor: AppColors.white,
              todayForegroundColor: WidgetStateProperty.all(t.themeColor),
              todayBackgroundColor:
                  WidgetStateProperty.all(Colors.transparent),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.white;
                }
                return t.textColor;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return t.themeColor;
                }
                return Colors.transparent;
              }),
              dayOverlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return t.textColor.withAlpha(30);
                }
                return Colors.transparent;
              }),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: t.textColor,
              ),
              confirmButtonStyle: TextButton.styleFrom(
                foregroundColor: t.textColor,
              ),
              weekdayStyle: TextStyle(color: t.textColor.withAlpha(170)),
              dayStyle: TextStyle(color: t.textColor),
              yearStyle: TextStyle(color: t.textColor),
            ),
          ),
          child: child!,
        );
      },
    );

    if (!context.mounted || pickedDate == null) return false;

    final pickedTime = await showTimePicker(
      useRootNavigator: true,
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        final t = ref.read(themeColorsProvider);
        final base = Theme.of(context);

        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              brightness: Brightness.dark,
              primary: t.themeColor,
              onPrimary: AppColors.white,
              surface: t.dashboardContainer,
              onSurface: t.textColor,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: t.dashboardContainer,
              helpTextStyle: TextStyle(
                color: t.textColor,
                fontWeight: FontWeight.w600,
              ),
              dialBackgroundColor: t.dashboardContainer.withAlpha(200),
              dialHandColor: t.themeColor,
              dialTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.white;
                }
                return t.textColor;
              }),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.white;
                }
                return t.textColor;
              }),
              hourMinuteColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return t.themeColor;
                }
                return t.dashboardContainer;
              }),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.white;
                }
                return t.textColor.withAlpha(180);
              }),
              dayPeriodColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return t.themeColor;
                }
                return Colors.transparent;
              }),
              dayPeriodBorderSide: BorderSide(
                color: t.textColor.withAlpha(60),
              ),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: t.textColor,
              ),
              confirmButtonStyle: TextButton.styleFrom(
                foregroundColor: t.textColor,
              ),
              entryModeIconColor: t.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!context.mounted || pickedTime == null) return false;

    final scheduledLocal = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (!scheduledLocal.isAfter(now)) {
      _showMsg(
        rootContext,
        'Select a time in the future.'.tr,
        title: 'Warning'.tr,
        type: 'warning',
        isError: true,
      );
      return false;
    }

    final sendAtUtc = scheduledLocal.toUtc();
    final sendAt = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(sendAtUtc);

    if (state.isSending) return false;
    state = state.copyWith(isSending: true);

    try {
      final data = {
        'email_account_id': selectedEmailAccountId,
        'to': toEmails,
        if (ccEmails.isNotEmpty) 'cc': ccEmails,
        if (bccEmails.isNotEmpty) 'bcc': bccEmails,
        'subject': subject,
        'body': body,
        'send_at': sendAt,
        if (attachmentIds.isNotEmpty) 'attachments': attachmentIds,
      };

      await EmailService.scheduleEmail(ref: ref, data: data);
      resetComposer();
      _removeSendMenu();
      onClose?.call();

      _showMsg(
        rootContext,
        'The email has been scheduled.'.tr,
        title: 'Success'.tr,
        type: 'success',
      );

      return true;
    } catch (e, st) {
      debugPrint('[EmailComposeNotifier] scheduleSendFlow error: $e');
      debugPrint('$st');

      _showMsg(
        rootContext,
        '${"Planning error".tr}: $e',
        title: 'Error'.tr,
        type: 'error',
        isError: true,
        seconds: 5,
      );
      return false;
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  Future<bool> sendNow({
    required BuildContext context,
    required int? leadId,
  }) async {
    final toEmails = _getEmailsFromControllers(toControllers);
    final ccEmails = _getEmailsFromControllers(ccControllers);
    final bccEmails = _getEmailsFromControllers(bccControllers);

    final subject = subjectController.text.trim();
    final body = bodyController.text.trim();

    if (subject.isEmpty || body.isEmpty || toEmails.isEmpty) {
      _showMsg(
        context,
        'Fill in the fields: To, Subject and Body'.tr,
        title: 'Warning'.tr,
        type: 'warning',
        isError: true,
      );
      return false;
    }

    final selectedEmailAccountId = ref.read(selectedEmailAccountIdProvider);
    if (selectedEmailAccountId == null) {
      _showMsg(
        context,
        'Before scheduling a shipment, select an email address (sender).'.tr,
        title: 'Warning'.tr,
        type: 'warning',
        isError: true,
      );
      return false;
    }

    if (!_validateEmails(context, toEmails)) return false;
    if (!_validateEmails(
      context,
      ccEmails,
      prefix: 'Incorrect email format in Cc'.tr,
    )) {
      return false;
    }
    if (!_validateEmails(
      context,
      bccEmails,
      prefix: 'Incorrect email format in Bcc'.tr,
    )) {
      return false;
    }

    if (state.isSending) return false;
    state = state.copyWith(isSending: true);

    try {
      final data = {
        'email_account_id': selectedEmailAccountId,
        'subject': subject,
        'body': body,
        'to': toEmails,
        if (ccEmails.isNotEmpty) 'cc': ccEmails,
        if (bccEmails.isNotEmpty) 'bcc': bccEmails,
        if (attachmentIds.isNotEmpty) 'attachments': attachmentIds,
        if (leadId != null) 'lead': leadId,
      };

      await EmailService.sendEmail(data: data);

      resetComposer();

      _showMsg(
        context,
        'The email has been sent.'.tr,
        title: 'Success'.tr,
        type: 'success',
      );

      return true;
    } catch (e, st) {
      debugPrint('[EmailComposeNotifier] sendNow error: $e');
      debugPrint('$st');

      final msg = e.toString().contains('email_address') ||
              e.toString().contains("'NoneType'")
          ? 'Your email is not connected to Hously. Please create an account with this email in Hously first.'
              .tr
          : '${"Error".tr}: $e';

      _showMsg(
        context,
        msg,
        title: 'Warning'.tr,
        type: 'warning',
        isError: true,
        seconds: 5,
      );
      return false;
    } finally {
      state = state.copyWith(isSending: false);
    }
  }
}

final emailComposeProvider = StateNotifierProvider.autoDispose
    .family<EmailComposeNotifier, EmailComposeState, String>(
  (ref, overlayId) {
    ref.keepAlive();
    return EmailComposeNotifier(ref);
  },
);

final emailOverlayExpandedProvider =
    StateProvider.autoDispose.family<bool, String>(
  (ref, overlayId) => false,
);