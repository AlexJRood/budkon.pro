import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud/models/file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:cloud/widgets/file_viewer.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';

class CloudFilesTable extends ConsumerWidget {
  final List<CloudFile> files;
  final ThemeColors theme;
  final BuildContext parentContext;

  const CloudFilesTable({
    super.key,
    required this.files,
    required this.theme,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(64.0),
          child: Text("No files".tr),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                theme.textColor.withAlpha(23),
              ),
              columns: [
                DataColumn(
                  label: Text(
                    "File name".tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Date uploaded".tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
                DataColumn(
                  label: Text("Size".tr, style: TextStyle(color: theme.textColor)),
                ),
              ],
              rows:
                  files
                      .map(
                        (file) => DataRow(
                          cells: [
                            DataCell(
                              PieMenu(
                                theme: PieTheme.of(context).copyWith(
                                  overlayColor:
                                      (() {
                                        final theme = ref.watch(
                                          themeColorsProvider,
                                        );
                                        final bool uiIsDark =
                                            theme.textColor.computeLuminance() >
                                            0.5;

                                        final base =
                                            uiIsDark
                                                ? Colors.black
                                                : Colors.white;
                                        return base.withValues(alpha: 0.70);
                                      })(),
                                ),
                                onPressedWithDevice: (kind) {
                                  if (kind == PointerDeviceKind.mouse ||
                                      kind == PointerDeviceKind.touch) {
                                    showDialog(
                                      context: parentContext,
                                      builder:
                                          (ctx) => FileViewerDialog(file: file),
                                    );
                                  }
                                },
                                child: DndSender(
                                  payload: DndPayload(
                                    type:
                                        file.extension.isEmpty
                                            ? DndPayloadType.cloudFolder
                                            : DndPayloadType.cloudFile,
                                    id: file.id,
                                    data: file.toJson(),
                                  ),
                                  feedbackBuilder:
                                      (context) => Material(
                                        color: Colors.transparent,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.dashboardContainer
                                                .withAlpha(240),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: theme.themeColor,
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.2,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                file.extension.isEmpty
                                                    ? Icons.folder
                                                    : Icons
                                                        .insert_drive_file_outlined,
                                                color: theme.themeColor,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                file.name,
                                                style: TextStyle(
                                                  color: theme.textColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.insert_drive_file_outlined,
                                        color: Colors.blueAccent,
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          file.name,
                                          style: TextStyle(
                                            color: theme.textColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                file.createdAt.toString(),
                                style: TextStyle(color: theme.textColor),
                              ),
                            ),
                            DataCell(
                              Text(
                                file.sizeString ?? "",
                                style: TextStyle(color: theme.textColor),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
            ),
          ),
        );
      },
    );
  }
}
