import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tms_app/todo/board/provider/board_details_provider.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';
import 'package:flutter/foundation.dart';

import 'package:get/get_utils/get_utils.dart';

final createColumnLoadingProvider = StateProvider<bool>((ref) => false);


class CreateColumnDialogWidget extends ConsumerStatefulWidget {
  final String selectedBoardId;
  const CreateColumnDialogWidget({super.key, required this.selectedBoardId});

  @override
  ConsumerState<CreateColumnDialogWidget> createState() =>
      _CreateColumnDialogWidgetState();
}

class _CreateColumnDialogWidgetState
    extends ConsumerState<CreateColumnDialogWidget> {
  final TextEditingController columnNameController = TextEditingController();

  @override
  void dispose() {
    columnNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(createColumnLoadingProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 500.w,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Create New Column'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: columnNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Column Name'.tr,
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  disabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel'.tr,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            final columnName =
                                columnNameController.text.trim();
                            if (columnName.isNotEmpty) {
                              ref
                                  .read(createColumnLoadingProvider.notifier)
                                  .state = true;
                              try {
                                await ref
                                    .read(taskProvider.notifier)
                                    .addProgressBar(
                                      widget.selectedBoardId,
                                      columnName,
                                    );
                                await ref.read(boardDetailsManagementProvider
                                        .notifier)
                                    .fetchBoardDetails(
                                        widget.selectedBoardId);
                                ref.read(selectedColumnNameProvider.notifier)
                                    .state = columnName;

                             if (!context.mounted) return;
                                Navigator.of(context).pop();
                              } catch (e) {
                                if (kDebugMode) debugPrint('❌ Error: $e');
                              } finally {
                                ref
                                    .read(createColumnLoadingProvider.notifier)
                                    .state = false;
                              }
                            } else {
                              if (kDebugMode) {
                                debugPrint('⚠️ Column name cannot be empty');
                              }
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Save'.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
