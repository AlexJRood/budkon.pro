# company_cat assets

Wrzuć tu `cat.riv` (animowany kot z Rive) i zadeklaruj go w `../pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/cat.riv
```

Kontrakt state machine `.riv` (nazwa `Cat`, inputy Sleep/Walk/Pet/Happy) —
patrz `../RIVE.md`. Bez tego pliku kot renderuje się jako emoji (fallback).
