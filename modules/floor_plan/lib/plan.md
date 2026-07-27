Floor Plan Builder — plan rozwojowy i aktualne problemy
1. Cel modułu

Floor Plan Builder ma być zaawansowanym edytorem planów nieruchomości dla CRM agentów nieruchomości. Moduł ma umożliwiać:

ręczne rysowanie planów lokali,
wymiarowanie ścian, kątów, pomieszczeń i elementów,
tworzenie ścian rzeczywistych oraz fikcyjnych/przerywanych do podziału przestrzeni,
dodawanie drzwi, okien, bram garażowych, mebli i wyposażenia,
automatyczne liczenie powierzchni pomieszczeń,
eksport/import planu jako JSON,
w przyszłości: generowanie planu przez AI na podstawie zdjęcia, rysunku technicznego albo skanu kartki.

Docelowo moduł powinien działać jak prosty CAD-lite dla agentów nieruchomości, bez złożoności profesjonalnych programów architektonicznych.

2. Aktualne bugi i problemy
2.1. Snap wierzchołków podczas rysowania
Problem

Podczas rysowania nowych ścian wierzchołki nie zawsze przyciągają się do istniejących punktów. Czasami nowa ściana wygląda wizualnie jak połączona, ale topologicznie kończy się obok istniejącego punktu.

Efekt uboczny
pomieszczenia nie wykrywają się poprawnie,
ściany nie tworzą zamkniętych polygonów,
powierzchnia pomieszczeń może nie być liczona,
późniejsze AI/eksport może dostać błędny graf ścian.
Plan naprawy
poprawić _nearestExistingCorner,
zwiększyć próg snapowania zależny od zoomu,
dodać tryb “hard snap” dla końca nowej ściany,
wizualnie pokazać, kiedy punkt jest faktycznie połączony,
po puszczeniu myszy automatycznie normalizować punkt do istniejącego wierzchołka, jeśli jest blisko.
2.2. Narzędzia powinny wykrywać intencje użytkownika
Problem

Aktualnie narzędzie działa bardzo literalnie. Jeśli user ma wybrane “przesuwanie”, ale wykonuje gest typowy dla dodania punktu na ścianie, system tego nie rozpoznaje.

Oczekiwane zachowanie

Builder powinien rozpoznawać intencję użytkownika:

podwójny klik na ścianie → dodaj punkt,
przeciągnięcie wierzchołka na ścianę → podziel ścianę,
kliknięcie na label długości → edytuj długość,
kliknięcie na kąt → edytuj kąt,
kliknięcie w pomieszczenie → zaznacz/nazwij pomieszczenie,
prawy klik → kontekstowe menu danego elementu.
Plan naprawy

Dodać warstwę IntentResolver, która przed wykonaniem akcji sprawdza:

1. Czy kliknięto label?
2. Czy kliknięto kąt?
3. Czy kliknięto wierzchołek?
4. Czy kliknięto ścianę?
5. Czy kliknięto obiekt?
6. Czy kliknięto pomieszczenie?
7. Czy gest wygląda jak pan/zoom/draw/drag?

Dopiero potem wybiera właściwą akcję.

2.3. Obiekty wyglądają zbyt symbolicznie
Problem

Aktualne assety/meble są bardziej prostokątami z tekstem niż realnymi symbolami planu.

Do poprawy

Obiekty powinny bardziej przypominać to, czym są:

sofa powinna mieć siedzisko i oparcie,
łóżko powinno mieć poduszkę,
auto powinno mieć kształt auta,
wanna powinna mieć zaokrąglony kształt,
WC, umywalka, prysznic powinny mieć czytelne ikony,
stół i krzesła powinny wyglądać architektonicznie,
kuchnia powinna mieć ciąg szafek / blat.
Plan

Dodać osobny FloorPlanAssetPainter, który będzie rysował każdy typ obiektu osobno, zamiast używać ogólnego prostokąta.

2.4. Brak pełnego theme na canvasie
Problem

Canvas ma dużo kolorów wpisanych na sztywno:

Colors.white
Color(0xFF...)

To nie będzie dobrze działało z dark mode, personalizacją i Twoim themeColorsProvider.

Plan

Dodać model stylu:

class FloorPlanCanvasTheme {
  final Color background;
  final Color gridMinor;
  final Color gridMajor;
  final Color wall;
  final Color selectedWall;
  final Color virtualWall;
  final Color roomFill;
  final Color roomBorder;
  final Color labelBackground;
  final Color text;
  final Color accent;
}

Następnie FloorPlanPainter powinien przyjmować:

final FloorPlanCanvasTheme canvasTheme;

i rysować wszystko zgodnie z theme.

2.5. Kolory obiektów, ścian i pomieszczeń
Problem

Brakuje możliwości ustawiania kolorów elementów.

Wymagane

User powinien móc ustawić:

kolor ściany,
kolor ściany fikcyjnej,
kolor pomieszczenia,
kolor obiektu,
kolor etykiet,
style eksportu/marketingowe.
Domyślne zachowanie

Ściany powinny domyślnie korzystać z kolorów aplikacji/theme, np.:

normal wall → theme.textColor / neutral dark
selected wall → theme.themeColor
virtual wall → theme.themeColor z opacity / dashed
rooms → theme.themeColor z niskim opacity
Model docelowy
class FloorWall {
  final String? colorHex;
}

class FloorRoom {
  final String? colorHex;
}

class FloorPlanAsset {
  final String? colorHex;
}
2.6. UX dodawania rzeczy do canvasu
Problem

Dodawanie elementów jest obecnie techniczne. User musi dokładnie znać narzędzia i sposób użycia.

Docelowy UX

Powinien być bardziej “agent-friendly”:

boczny panel “Dodaj element”,
kategorie: Ściany, Otwory, Pomieszczenia, Meble, Garaż, Łazienka, Kuchnia,
drag & drop elementu na canvas,
podpowiedzi typu: “Kliknij ścianę, aby dodać drzwi”,
szybkie akcje w pie menu,
lista ostatnio używanych elementów,
gotowe presety: “Salon”, “Łazienka”, “Garaż”, “Kuchnia”.
2.7. API
Problem

Aktualnie edytor działa głównie lokalnie po stronie frontendu. Potrzebne jest API do zapisu, odczytu, wersjonowania i generowania planów.

Wymagane endpointy
GET    /api/floor-plans/
POST   /api/floor-plans/
GET    /api/floor-plans/{id}/
PATCH  /api/floor-plans/{id}/
DELETE /api/floor-plans/{id}/

POST   /api/floor-plans/{id}/duplicate/
POST   /api/floor-plans/{id}/export/pdf/
POST   /api/floor-plans/{id}/export/png/
POST   /api/floor-plans/{id}/generate-from-image/
POST   /api/floor-plans/{id}/analyze/
Powiązania

Plan powinien móc być przypisany do:

ogłoszenia,
nieruchomości,
transakcji,
klienta,
folderu w storage,
wygenerowanego PDF oferty.
2.8. Zmiana szerokości okien/drzwi przez przeciąganie
Problem

Szerokość drzwi/okien można zmieniać tylko w inspectorze.

Docelowe zachowanie

Na zaznaczonym oknie/drzwiach powinny pojawić się uchwyty:

[ lewy uchwyt ] ----- okno ----- [ prawy uchwyt ]

Przeciąganie uchwytu:

zmienia width_m,
zachowuje pozycję środka albo przesuwa jeden koniec zależnie od trybu,
snapuje do siatki i typowych szerokości.
Typowe presety
Drzwi: 70 cm, 80 cm, 90 cm, 100 cm
Okna: 90 cm, 120 cm, 150 cm, 180 cm
Brama: 250 cm, 300 cm, 500 cm
3. Roadmapa rozwojowa
Wersja 0.1 — Stabilizacja edytora ścian
Cel

Doprowadzić podstawowe rysowanie ścian do stabilnego, przewidywalnego działania.

Zakres
poprawić snapowanie wierzchołków,
naprawić przyciąganie nowej ściany do istniejącej ściany,
poprawić dzielenie ściany po double clicku,
poprawić dzielenie ściany po przeciągnięciu narożnika,
dodać wizualny feedback “punkt połączony”,
dodać testy dla topologii ścian.
Priorytet

Bardzo wysoki.

Wersja 0.2 — Intent Resolver i UX gestów
Cel

Edytor ma zachowywać się inteligentnie, nawet jeśli user nie wybrał idealnego narzędzia.

Zakres
stworzyć FloorPlanIntentResolver,
rozpoznawać kliknięcie w label długości,
rozpoznawać kliknięcie w kąt,
rozpoznawać kliknięcie w ścianę,
rozpoznawać kliknięcie w pomieszczenie,
rozpoznawać double click jako dodanie punktu,
dodać fallback akcji w zależności od gestu.
Priorytet

Wysoki.

Wersja 0.3 — Theme i stylowanie
Cel

Canvas powinien wyglądać spójnie z resztą aplikacji.

Zakres
dodać FloorPlanCanvasTheme,
podłączyć themeColorsProvider,
usunąć hardcoded colors z paintera,
dodać dark mode,
dodać default style dla ścian, pokoi, assetów,
dodać ustawianie kolorów elementów.
Priorytet

Wysoki.

Wersja 0.4 — Pomieszczenia
Cel

Pomieszczenia mają być pełnoprawną częścią planu.

Zakres
poprawić wykrywanie zamkniętych pomieszczeń,
obsłużyć wirtualne ściany jako granice pomieszczeń,
edycja nazwy pomieszczenia inline,
wyświetlanie powierzchni,
możliwość ukrycia nazwy/powierzchni,
kolor pomieszczenia,
inspector pomieszczenia,
ręczne tworzenie pokoju przez wskazanie punktów.
Priorytet

Wysoki.

Wersja 0.5 — Drzwi, okna, bramy
Cel

Otwory w ścianach powinny być wygodne do dodawania i edycji.

Zakres
przeciąganie drzwi/okien po ścianie,
zmiana szerokości przez uchwyty,
obracanie kierunku otwierania drzwi,
presety szerokości,
brama garażowa jako pełnoprawny typ,
lepsze symbole drzwi/okien/bram,
blokada, żeby okno/drzwi nie wychodziły poza ścianę.
Priorytet

Wysoki.

Wersja 0.6 — Meble i wyposażenie
Cel

Obiekty na planie mają wyglądać czytelnie i być łatwe do użycia.

Zakres
dedykowany painter dla każdego typu assetu,
obracanie assetu uchwytem,
zmiana rozmiaru assetu przez przeciąganie,
kolor assetu,
biblioteka obiektów,
wyszukiwarka assetów,
drag & drop z panelu bocznego,
grupowanie assetów w kategorie.
Przykładowe assety
Salon:
- sofa
- fotel
- stolik
- TV
- regał

Sypialnia:
- łóżko
- szafa
- biurko

Kuchnia:
- blat
- wyspa
- lodówka
- zlew
- kuchenka

Łazienka:
- WC
- umywalka
- prysznic
- wanna
- pralka

Garaż:
- auto
- brama garażowa
- regał
- rower
Priorytet

Średni/wysoki.

Wersja 0.7 — API i zapis planów
Cel

Plan ma być zapisywany i powiązany z CRM.

Zakres backend

Modele Django:

FloorPlan
FloorPlanVersion
FloorPlanExport
FloorPlanAiJob

Przykładowy model:

FloorPlan:
- id
- user
- company
- advertisement
- property
- name
- status
- data_json
- preview_image
- created_at
- updated_at

Endpointy:

list/create/update/delete
duplicate
export PNG/PDF
version history
AI import
Priorytet

Bardzo wysoki przed produkcją.

Wersja 0.8 — Eksport i prezentacja
Cel

Plan ma być możliwy do użycia w ofertach, PDF-ach i portalach.

Zakres
eksport PNG,
eksport PDF,
eksport SVG,
tryb marketingowy,
tryb techniczny,
ukrywanie ścian fikcyjnych,
ukrywanie assetów,
legenda pomieszczeń,
tabela powierzchni,
branding agenta,
logo biura,
kolory zgodne z theme.
Priorytet

Średni/wysoki.

Wersja 0.9 — AI import z rysunku/skanu
Cel

User wrzuca plan techniczny, skan kartki albo zdjęcie planu, a AI tworzy edytowalny plan.

Zakres
upload pliku,
OCR / vision analiza,
wykrycie ścian,
wykrycie drzwi i okien,
wykrycie wymiarów,
kalibracja skali,
wygenerowanie FloorPlanDocument,
tryb review: user zatwierdza znalezione ściany,
poprawki ręczne.
Priorytet

Wysoki, ale po stabilizacji ręcznego edytora.

Wersja 1.0 — AI generowanie planu ze zdjęć nieruchomości
Cel

User wrzuca zdjęcia nieruchomości, a Emma generuje przybliżony plan do dalszej edycji.

Zakres
upload wielu zdjęć,
wykrycie pomieszczeń,
analiza kolejności zdjęć,
rozpoznanie drzwi, okien, przejść,
oszacowanie wymiarów,
generowanie layoutu,
dialog z Emmą: “czy kuchnia jest po lewej od salonu?”,
user poprawia plan na canvasie.
Priorytet

Strategiczny, późniejszy etap.

4. Dodatkowe funkcje, które warto dodać
4.1. Warstwy
- ściany
- ściany fikcyjne
- pomieszczenia
- meble
- wymiary
- opisy
- AI suggestions

Możliwość ukrywania/pokazywania warstw.

4.2. Historia zmian
- undo/redo
- historia wersji
- autosave
- przywróć poprzednią wersję
4.3. Tryby widoku
Tryb techniczny:
- wszystkie wymiary
- kąty
- grubości
- ściany fikcyjne

Tryb marketingowy:
- nazwy pomieszczeń
- powierzchnie
- ładniejsze kolory
- bez technicznych labeli

Tryb edycji:
- wszystkie uchwyty
- snapy
- guides
4.4. Walidacja planu

System powinien ostrzegać, gdy:

pomieszczenie nie jest zamknięte,
ściany wyglądają na połączone, ale nie są topologicznie połączone,
drzwi/okno wychodzi poza ścianę,
ściana ma długość 0,
pokój ma zbyt małą powierzchnię,
nakładają się assety,
ściany krzyżują się bez punktu przecięcia.
4.5. Automatyczne poprawki

Przycisk:

Napraw plan

Powinien robić:

dociągnięcie bliskich punktów,
scalanie duplikatów wierzchołków,
dodanie punktów na przecięciach ścian,
domykanie małych szczelin,
przeliczenie pomieszczeń.
4.6. Presety
- kawalerka
- mieszkanie 2-pokojowe
- mieszkanie 3-pokojowe
- dom parterowy
- garaż
- lokal usługowy
4.7. Skróty klawiszowe
V / S — zaznaczanie
W — ściana
F — ściana fikcyjna
R — pomieszczenie
D — drzwi
O — okno
G — brama garażowa
A — asset
Space / middle mouse — pan
Delete — usuń
Ctrl+Z — undo
Ctrl+Y — redo
Esc — anuluj rysowanie
Alt — tymczasowo wyłącz snap
Shift — multi select
5. Priorytety na najbliższy etap
Must-have teraz
1. Naprawić snap wierzchołków.
2. Naprawić topologię ścian po dzieleniu.
3. Dodać intencje użytkownika.
4. Uporządkować theme canvasu.
5. Poprawić wygląd assetów.
6. Dodać API zapisu planu.
Should-have zaraz potem
1. Uchwyty zmiany szerokości okien/drzwi.
2. Drag & drop assetów.
3. Kolory elementów.
4. Tryb marketingowy/techniczny.
5. Walidacja planu.
Later
1. AI import z planu technicznego.
2. AI generowanie planu ze zdjęć.
3. Eksport PDF/SVG.
4. Presety mieszkań.
5. Automatyczna naprawa planu.
6. Proponowany podział tasków dla programisty
Task 1 — Fix snap wierzchołków

Cel: końce ścian mają zawsze poprawnie łączyć się z istniejącymi punktami.

Zakres:

poprawić _nearestExistingCorner,
dodać mocniejszy snap na PointerUp,
wizualnie oznaczać aktywny snap,
dodać testy dla bliskich punktów.
Task 2 — Intent Resolver

Cel: canvas ma rozpoznawać intencję usera niezależnie od aktywnego narzędzia.

Zakres:

dodać FloorPlanIntentResolver,
obsłużyć double click,
obsłużyć klik w label długości/kąta/pokoju,
obsłużyć klik w ścianę/pokój/asset,
uporządkować kolejność hit-testów.
Task 3 — Canvas Theme

Cel: usunąć hardcoded colors i podpiąć theme aplikacji.

Zakres:

dodać FloorPlanCanvasTheme,
mapować themeColorsProvider na canvas theme,
przekazać theme do FloorPlanPainter,
dodać dark mode.
Task 4 — Asset Painter

Cel: obiekty mają wyglądać jak realne symbole na planie.

Zakres:

wydzielić FloorPlanAssetPainter,
narysować osobne symbole dla każdego assetu,
dodać kolor assetu,
dodać zaznaczenie i uchwyty.
Task 5 — Resize okien/drzwi na canvasie

Cel: user może zmienić szerokość otworu przez przeciągnięcie uchwytu.

Zakres:

dodać hit-test uchwytów otworów,
dodać drag lewego/prawego końca,
przeliczać width_m,
ograniczyć szerokość do długości ściany,
dodać presety.
Task 6 — Floor Plan API

Cel: zapisywanie i odczyt planów z backendu.

Zakres:

model Django,
serializer,
endpointy CRUD,
version history,
powiązanie z ogłoszeniem,
frontend service/provider.




obiekty:
-tv
-kuchenka
-lodówka
- 