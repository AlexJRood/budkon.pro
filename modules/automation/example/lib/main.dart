// import 'package:automation_studio/automation_studio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// void main() {
//   runApp(const ProviderScope(child: ExampleApp()));
// }

// class ExampleApp extends StatelessWidget {
//   const ExampleApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final config = AutomationStudioConfig(
//       baseUrl: 'https://www.superbee.cloud',
//       tokenProvider: () async => null,
//       translate: (context, key) => automationTranslationKeysEn[key] ?? key,
//     );

//     return AutomationStudioConfigScope(
//       config: config,
//       child: MaterialApp(
//         theme: ThemeData.dark(useMaterial3: true),
//         home: ProviderScope(
//           overrides: [
//             automationStudioConfigProvider.overrideWithValue(config),
//           ],
//           child: const AutomationWorkflowListScreen(),
//         ),
//       ),
//     );
//   }
// }
