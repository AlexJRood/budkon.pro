
I w `_MessageWithActions` zmień:

```dart
MessageBubble(
  content: message.content,
```

na:

```dart
MessageBubble(
  content: sanitizeFlutterTextForUi(message.content),
```

To powinno zatrzymać oba problemy: czerwone odpowiedzi AI i crash `string is not well-formed UTF-16`.


I'm programing chat ai, which works on local device! :D 