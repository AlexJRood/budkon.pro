import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud/utils/encrypt.dart';

// void _generateCloudKey(BuildContext context) async {
//   final keyService = SecureCloudKeyService();
//   final keyBase64 = await keyService.generateAndSaveKeyReturnBase64();
//
//   // Pokaż dialog:
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (context) => AlertDialog(
//       title: const Text('Twój klucz szyfrujący'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           SelectableText(keyBase64, style: const TextStyle(fontFamily: "monospace")),
//           const SizedBox(height: 16),
//           const Text(
//             "Zapisz ten klucz w bezpiecznym miejscu!\n"
//             "Nie będziesz mógł go później zobaczyć. Utrata klucza = utrata dostępu do dokumentów.",
//             style: TextStyle(color: Colors.red),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           child: const Text('Skopiuj'),
//           onPressed: () {
//             Clipboard.setData(ClipboardData(text: keyBase64));
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Skopiowano do schowka!')),
//             );
//           },
//         ),
//         TextButton(
//           child: const Text('OK, zapisałem'),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//       ],
//     ),
//   );
// }
