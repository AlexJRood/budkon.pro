# Projekt Stare Brynki – API i struktura danych

**Typ:** Adaptacja projektu typowego EXTERA  
**Inwestor:** Hubert Sobieraj  
**Lokalizacja:** dz. 213/6, Czepino, gmina Gryfino  
**Nr projektu:** AB/01/2024  

---

## Pliki

| Plik | Rola |
|---|---|
| `projekt.json` | Master data – wszystkie parametry projektu |
| `room_scene.json` | Scena 3D w formacie RoomScene v2 (dla Flutter room_3d) |
| `kosztorys_engine.py` | Silnik generowania kosztorysu z KNR |
| `kosztorys_output.json` | Wygenerowany kosztorys (auto, nie edytować ręcznie) |
| `llm_tools.py` | Narzędzia dla Emmy/Superbee – 13 tool definitions + dispatcher |

---

## Schemat projekt.json

### `meta`
- `id` – unikalny slug projektu  
- `nazwa` – pełna nazwa  
- `projekt_typowy` – katalogowy typ budynku (`EXTERA`)  
- `nr_projektu` – numer nadany przez biuro projektowe  
- `inwestor.nazwa / adres` – dane inwestora  
- `dzialka.nr_ewidencyjny / obreb / gmina` – dane ewidencyjne działki  
- `biuro_projektowe`, `glowny_architekt` – projektanci  

### `geometria_budynku`
- `powierzchnia_zabudowy_m2` – odcisk budynku na działce  
- `powierzchnia_uzytkowa_m2` – PUM (bez ścian, z garażem)  
- `kubatura_m3` – objętość bryły  
- `liczba_kondygnacji` – ilość kondygnacji nadziemnych  
- `dach.typ / nachylenie_deg / material_pokrycia / powierzchnia_polaci_m2`  

### `kondygnacje[i]`
- `id` – `parter` | `pietro`  
- `index` – 0 = parter, 1 = piętro (zgodny z RoomScene floor.index)  
- `wysokosc_kondygnacji_m` – kondygnacja + strop  
- `wysokosc_w_swietle_m` – wolna wysokość pomieszczenia  
- `pomieszczenia[]` – lista pomieszczeń (patrz niżej)  

### `kondygnacje[i].pomieszczenia[j]`
- `id` – slug (np. `salon`, `lazienka_pietro`)  
- `nazwa` – czytelna nazwa  
- `typ` – `dzienny | sypialnia | kuchnia | lazienka | techniczny | komunikacja | garaz`  
- `powierzchnia_m2` – powierzchnia użytkowa  
- `wymiary_m.a / .b` – przybliżone wymiary (do weryfikacji z rysunkami)  
- `material_podlogi / material_sufitu / sciany_wykonczenie` – materiały wykończenia  
- `drzwi[]` – lista drzwi z `id, typ, szerokosc_m, wysokosc_m`  
- `okna[]` – lista okien z `id, typ, szerokosc_m, wysokosc_m, parapet_m`  
- `wyposazenie[]` – lista sanitariatów/sprzętu  
- `instalacje[]` – lista instalacji w pomieszczeniu  

### `elementy_konstrukcyjne`
- `fundament.typ / szerokosc_lawicy_cm / glebokos_posadowienia_m / dlugosc_calkowita_m`  
- `sciany_zewnetrzne.warianty[].warstwy[]` – układ warstw ze grubościami i lambda  
- `sciany_zewnetrzne.warianty[].wspolczynnik_U` – wartość U ściany  
- `stropy[].typ / rozpietos_m / powierzchnia_m2`  
- `dach.krokiew.przekroj_cm / rozstaw_cm`, `pokrycie`, `izolacja_termiczna[]`  

### `instalacje`
- `elektryczna.moc_zamowiona_kW` = 14  
- `elektryczna.zasilanie.kabel_zasilajacy` = `YKY 4x16mm²`  
- `elektryczna.zasilanie.dlugosc_kabla_m` = 32  
- `sanitarna.ogrzewanie.pompa_ciepla.moc_grzewcza_kW` = 8  
- `sanitarna.ogrzewanie.pompa_ciepla.cop` = 4.2  
- `sanitarna.wentylacja.sprawnosc_odzysku_procent` = 90  

---

## room_scene.json – schemat RoomScene v2

Zgodny z `modules/room_3d/lib/model/room_scene.dart` w hously.pro.

```
RoomScene {
  version: 2
  source_kind: "projekt_budowlany"
  source_id:   "stare-brynki-2024"
  units:       "meters"
  floors: [
    {
      id, index, label, story_height_m
      walls:    [ { id, start:[x,y], end:[x,y], height_m, thickness_m, is_virtual? } ]
      rooms:    [ { id, name, points:[[x,y]...], floor_material_id } ]
      openings: [ { id, wall_id, kind, position(0-1), width_m, sill_height_m, height_m } ]
      stairs:   [ { id, start:[x,y], end:[x,y], width_m } ]
      wall_surface_materials: { room_id: material_id }
    }
  ]
}
```

**Układ współrzędnych:** X = prawo (wschód), Y = dół (południe), Z = góra. Jednostka: metry.  
**position w opening:** 0.0 = początek ściany (start), 1.0 = koniec ściany (end).

### Ładowanie w Flutter (room_3d)

```dart
final scene = RoomScene.fromJson(json);
// lub z pliku via API:
final scene = await RoomSceneBuilder.loadFromFloorPlanProject(ref: ref, floorPlanProjectId: 'stare-brynki-2024');
```

---

## kosztorys_engine.py – kluczowe zmienne

| Zmienna | Znaczenie |
|---|---|
| `PozycjaKosztorysu.dzial` | Dział wg KNR (01–09) |
| `PozycjaKosztorysu.knr` | Numer normy katalogowej |
| `PozycjaKosztorysu.jednostka` | m2, m3, mb, szt, kpl, kg |
| `PozycjaKosztorysu.ilosc` | Obliczona ilość (z geometrii projektu) |
| `PozycjaKosztorysu.cena_jedn_netto` | Cena jednostkowa netto PLN (rynek zach-pom 2025) |
| `PozycjaKosztorysu.wartosc_netto` | `ilosc × cena_jedn_netto` (property) |

**Uruchomienie:**
```bash
python kosztorys_engine.py         # print + eksport JSON
# lub z kodu:
from kosztorys_engine import generuj_kosztorys, podsumowanie
poz = generuj_kosztorys()
print(podsumowanie(poz))
```

**Wynik (lipiec 2025):**
- 68 pozycji KNR
- Suma netto: ~441 000 PLN
- VAT 23%:   ~101 000 PLN  
- Brutto:    ~542 000 PLN

> Ceny orientacyjne. Wymagają weryfikacji ofertami podwykonawców / SEKOCENBUD.

---

## llm_tools.py – 13 narzędzi LLM

| Narzędzie | Opis |
|---|---|
| `get_project_summary()` | Streszczenie projektu (inwestor, lokalizacja, geometria) |
| `get_room_list(kondygnacja?)` | Lista pomieszczeń z powierzchnią |
| `get_room_detail(room_id)` | Pełne dane pomieszczenia (okna, drzwi, materiały) |
| `get_installation_summary(system)` | Dane instalacji (elektryczna/sanitarna/ogrzewanie...) |
| `get_construction_element(element)` | Parametry elementu konstrukcyjnego |
| `calculate_area(typ_powierzchni)` | Zestawienie powierzchni wg kryterium |
| `get_kosztorys_summary()` | Podsumowanie kosztorysu (działy + suma brutto) |
| `get_kosztorys_dzial(dzial)` | Pozycje kosztorysu z danego działu |
| `search_kosztorys(query)` | Wyszukiwanie po opisie pozycji |
| `get_scene_json(floor_index?)` | Scena 3D do renderowania w room_3d |
| `get_joinery_summary()` | Zestawienie stolarki (okna, drzwi, brama) |
| `get_verification_checklist()` | Lista do weryfikacji z rysunkami |
| `update_room_area(room_id, m2)` | Korekta powierzchni po weryfikacji z rysunkami |

**Dispatcher:**
```python
from llm_tools import dispatch_tool, TOOLS

# Wywołanie przez Superbee/Emma:
result = dispatch_tool("get_kosztorys_summary", {})
result = dispatch_tool("get_room_list", {"kondygnacja": "parter"})

# Definicje dla Anthropic tool_use:
tools_for_api = TOOLS  # lista 13 dicts ze schema
```

---

## Do weryfikacji

Po odczycie rysunków technicznych (`Adaptacja - rysunki.pdf`, `Projekt - oryginalny.pdf`) należy:

1. Zweryfikować wymiary każdego pomieszczenia (pola `wymiary_m` i `powierzchnia_m2`)
2. Zaktualizować przez `update_room_area()` lub bezpośrednio w `projekt.json`
3. Sprawdzić rozmieszczenie okien i drzwi (pola `openings` w `room_scene.json`)
4. Ustalić typ kanalizacji: gminny vs. szambo
5. Zregenerować `kosztorys_output.json` przez `python kosztorys_engine.py`
