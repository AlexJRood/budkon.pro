import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
class MailVerticalBar extends ConsumerWidget {
  final VoidCallback onPressed;
  final bool showActionList;
  const MailVerticalBar({super.key, required this.onPressed, required this.showActionList});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return  Column(
            spacing: 5,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [ 
              Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: theme.adPopBackground,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  child:
               ElevatedButton(
                style: elevatedButtonStyleRounded10,
               onPressed: () async {
                    try {
                 
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('✅ Synchronization completed'.tr)),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${'❌ Sync error:'.tr} $e'.tr)),
                      );
                    }
                  },
               child: AppIcons.refresh(color: theme.textColor)
               ),
             ),
              Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: theme.adPopBackground,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  child: ElevatedButton(
                    style: elevatedButtonStyleRounded10,
                    onPressed: (){
                    
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: theme.dashboardContainer,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      builder: (context) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          spacing: 5,
                            children: [
                              
                            ],
                          ),
                      ),
                       );
                     },
                  child: AppIcons.filterAlt(color: theme.textColor),
                  ),
               ),
               Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: theme.adPopBackground,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                child: ElevatedButton(
                  style: elevatedButtonStyleRounded10,
                  onPressed: () {
                  }, 
                  child: AppIcons.newChat(color: theme.textColor),
                ),
              ),
            ],
    );
  }
}
