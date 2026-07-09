# Company Cat — animacja Rive

Kot renderuje się przez **Rive** (`CatVisual`), z **fallbackiem na emoji** dopóki
nie ma pliku `.riv`. Silnik ruchu (wchodzenie/łażenie/skoki) jest osobno i działa
niezależnie od grafiki.

## Co musisz dostarczyć: `assets/cat.riv`

Plik `.riv` zaprojektowany w edytorze Rive (rive.app) — albo darmowy kot z
**Rive Community** (rive.app → Community → szukaj „cat"), albo zlecony pod spec.

### Kontrakt state machine (MUSI się zgadzać z kodem)
Artboard ze **state machine o nazwie `Cat`** i inputami:

| input | typ | znaczenie |
|---|---|---|
| `Sleep` | Bool (SMIBool) | true → kot śpi/zwinięty |
| `Walk`  | Bool (SMIBool) | true → kot idzie (podczas ruchu) |
| `Pet`   | Trigger (SMITrigger) | odpalany przy głaskaniu |
| `Happy` | Trigger (SMITrigger) | odpalany przy celebracji wygranej |

Stany animacji (idle / walk / sleep / pet-react / happy) przełącza state machine
na podstawie tych inputów. Jeśli twój `.riv` ma inne nazwy — powiedz, dopasuję
kod (`cat_visual.dart`, funkcja `_onRiveInit`).

## Jak podpiąć plik
1. Wrzuć plik do `modules/company_cat/assets/cat.riv`.
2. Odkomentuj/dodaj w `modules/company_cat/pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/cat.riv
   ```
3. `flutter pub get` + rebuild. `CatVisual` sam wykryje asset i przełączy się z
   emoji na Rive (patrz `_checkAsset`).

## Stan
- ✅ Slot Rive + fallback emoji + mapowanie stanów (Sleep/Walk/Pet/Happy) — gotowe.
- ⏳ Silnik ruchu (wchodzi z krawędzi, łazi, skacze po ekranie) — następny krok.
- ⏳ Sam plik `.riv` — do dostarczenia (community albo projekt).
