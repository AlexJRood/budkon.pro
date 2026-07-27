"""
Narzędzia LLM dla projektu Stare Brynki.
Każda funkcja to tool dostępny dla Emmy / Superbee.

Rejestracja w Django:
    from projekty.stare_brynki.llm_tools import TOOLS
    # TOOLS to lista definicji zgodna z OpenAI/Anthropic tool-use schema
"""
from __future__ import annotations
import json
from pathlib import Path
from typing import Any

_BASE = Path(__file__).parent
_projekt_cache: dict | None = None
_kosztorys_cache: list | None = None


# =========================================================
# Ładowanie danych
# =========================================================

def _load_projekt() -> dict:
    global _projekt_cache
    if _projekt_cache is None:
        with open(_BASE / "projekt.json", encoding="utf-8") as f:
            _projekt_cache = json.load(f)
    return _projekt_cache


def _load_kosztorys() -> list:
    global _kosztorys_cache
    if _kosztorys_cache is None:
        output = _BASE / "kosztorys_output.json"
        if not output.exists():
            from .kosztorys_engine import generuj_kosztorys, export_json
            export_json()
        with open(output, encoding="utf-8") as f:
            data = json.load(f)
        _kosztorys_cache = data["pozycje"]
    return _kosztorys_cache


def _load_scene() -> dict:
    with open(_BASE / "room_scene.json", encoding="utf-8") as f:
        return json.load(f)


# =========================================================
# Implementacje narzędzi
# =========================================================

def get_project_summary() -> dict:
    """
    Zwraca streszczenie projektu budowlanego: inwestor, lokalizacja,
    biuro projektowe, podstawowe parametry geometryczne.
    """
    p = _load_projekt()
    meta = p["meta"]
    geo = p["geometria_budynku"]
    return {
        "projekt_id": meta["id"],
        "nazwa": meta["nazwa"],
        "projekt_typowy": meta["projekt_typowy"],
        "nr_projektu": meta["nr_projektu"],
        "inwestor": meta["inwestor"],
        "lokalizacja": meta["dzialka"],
        "biuro_projektowe": meta["biuro_projektowe"],
        "glowny_architekt": meta["glowny_architekt"],
        "okres_budowy": {
            "od": meta["okres_budowy_od"],
            "do": meta["okres_budowy_do"],
        },
        "geometria": {
            "powierzchnia_uzytkowa_m2": geo["powierzchnia_uzytkowa_m2"],
            "powierzchnia_zabudowy_m2": geo["powierzchnia_zabudowy_m2"],
            "kubatura_m3": geo["kubatura_m3"],
            "liczba_kondygnacji": geo["liczba_kondygnacji"],
            "wysokosc_m": geo["wysokosc_budynku_m"],
        },
    }


def get_room_list(kondygnacja: str | None = None) -> list[dict]:
    """
    Zwraca listę pomieszczeń z powierzchnią i typem.
    kondygnacja: 'parter' | 'pietro' | None (wszystkie)
    """
    p = _load_projekt()
    result = []
    for k in p["kondygnacje"]:
        if kondygnacja and k["id"] != kondygnacja:
            continue
        for pom in k["pomieszczenia"]:
            result.append({
                "id": pom["id"],
                "kondygnacja": k["id"],
                "kondygnacja_label": k["label"],
                "nazwa": pom["nazwa"],
                "typ": pom["typ"],
                "powierzchnia_m2": pom["powierzchnia_m2"],
                "wymiary_m": pom.get("wymiary_m"),
                "material_podlogi": pom.get("material_podlogi"),
                "liczba_drzwi": len(pom.get("drzwi", [])),
                "liczba_okien": len(pom.get("okna", [])),
            })
    return result


def get_room_detail(room_id: str) -> dict | None:
    """
    Zwraca pełne dane pomieszczenia (okna, drzwi, materiały, instalacje).
    room_id: np. 'salon', 'lazienka_pietro', 'garaz'
    """
    p = _load_projekt()
    for k in p["kondygnacje"]:
        for pom in k["pomieszczenia"]:
            if pom["id"] == room_id:
                return {"kondygnacja": k["id"], **pom}
    return None


def get_installation_summary(system: str) -> dict:
    """
    Zwraca szczegóły danego systemu instalacyjnego.
    system: 'elektryczna' | 'sanitarna' | 'ogrzewanie' | 'wentylacja' | 'woda' | 'kanalizacja'
    """
    p = _load_projekt()
    inst = p["instalacje"]
    if system == "elektryczna":
        return inst["elektryczna"]
    if system in ("sanitarna", "ogrzewanie", "wentylacja", "woda", "kanalizacja"):
        san = inst["sanitarna"]
        if system == "sanitarna":
            return san
        return san.get(system, {})
    return {"error": f"Nieznany system: {system}. Dostępne: elektryczna, sanitarna, ogrzewanie, wentylacja, woda, kanalizacja"}


def get_construction_element(element: str) -> dict | None:
    """
    Zwraca dane elementu konstrukcyjnego.
    element: 'fundament' | 'sciany_zewnetrzne' | 'sciany_wewnetrzne' | 'stropy' | 'schody' | 'dach' | 'wieniec'
    """
    p = _load_projekt()
    konstr = p["elementy_konstrukcyjne"]
    return konstr.get(element)


def calculate_area(typ_powierzchni: str) -> dict:
    """
    Oblicza i zwraca zestawienie powierzchni wg podanego kryterium.
    typ_powierzchni: 'wszystkie' | 'mieszkalne' | 'mokre' | 'techniczne' | 'komunikacja' | 'parter' | 'pietro'
    """
    p = _load_projekt()
    typy_map = {
        "mieszkalne": ["dzienny", "sypialnia"],
        "mokre": ["lazienka"],
        "techniczne": ["techniczny", "garaz"],
        "komunikacja": ["komunikacja"],
    }

    wynik: dict[str, float] = {}
    total = 0.0

    for k in p["kondygnacje"]:
        skip_kondyg = typ_powierzchni in ("parter", "pietro") and k["id"] != typ_powierzchni
        if skip_kondyg:
            continue
        for pom in k["pomieszczenia"]:
            typ = pom["typ"]
            if typ_powierzchni not in ("wszystkie", "parter", "pietro"):
                typy_filtr = typy_map.get(typ_powierzchni, [])
                if typ not in typy_filtr:
                    continue
            wynik[pom["id"]] = pom["powierzchnia_m2"]
            total += pom["powierzchnia_m2"]

    return {
        "filtr": typ_powierzchni,
        "pomieszczenia": wynik,
        "suma_m2": round(total, 2),
        "liczba_pomieszczen": len(wynik),
    }


def get_kosztorys_summary() -> dict:
    """
    Zwraca podsumowanie kosztorysu wg działów z wartościami netto i brutto.
    """
    output = _BASE / "kosztorys_output.json"
    if not output.exists():
        from .kosztorys_engine import export_json
        export_json()
    with open(output, encoding="utf-8") as f:
        data = json.load(f)
    return data["podsumowanie"]


def get_kosztorys_dzial(dzial: str) -> list[dict]:
    """
    Zwraca pozycje kosztorysu z określonego działu.
    dzial: np. '01 Roboty ziemne', '02 Ściany', '03 Stropy', '04 Dach',
           '05 Tynki', '06 Stolarka', '07 Instalacje sanitarne',
           '08 Instalacje elektryczne', '09 Zagospodarowanie terenu'
    """
    poz = _load_kosztorys()
    return [p for p in poz if p["dzial"] == dzial]


def search_kosztorys(query: str) -> list[dict]:
    """
    Przeszukuje opis pozycji kosztorysu. Zwraca pasujące pozycje.
    """
    poz = _load_kosztorys()
    q = query.lower()
    return [p for p in poz if q in p["opis"].lower() or q in p["dzial"].lower()]


def get_scene_json(floor_index: int | None = None) -> dict:
    """
    Zwraca pełną definicję sceny 3D (RoomScene format) gotową do renderowania.
    floor_index: 0 (parter) | 1 (piętro) | None (cała budowla)
    """
    scene = _load_scene()
    if floor_index is not None:
        floors = [f for f in scene["floors"] if f["index"] == floor_index]
        scene = {**scene, "floors": floors}
    return scene


def get_joinery_summary() -> dict:
    """
    Zwraca zestawienie stolarki: okna, drzwi zewnętrzne, drzwi wewnętrzne, brama.
    """
    p = _load_projekt()
    stol = p["stolarka"]

    okna_detail = []
    for k in p["kondygnacje"]:
        for pom in k["pomieszczenia"]:
            for okno in pom.get("okna", []):
                okna_detail.append({
                    "pomieszczenie": pom["nazwa"],
                    "kondygnacja": k["id"],
                    **okno,
                })

    return {
        "okna": {
            "typ_profilu": stol["okna"]["typ_profilu"],
            "szyby": stol["okna"]["szyby"],
            "wspolczynnik_U": stol["okna"]["wspolczynnik_U_okna"],
            "powierzchnia_calkowita_m2": stol["okna"]["powierzchnia_calkowita_m2"],
            "zestawienie": okna_detail,
        },
        "drzwi_zewnetrzne": stol["drzwi_zewnetrzne"],
        "brama_garazowa": stol["brama_garazowa"],
        "drzwi_wewnetrzne": stol["drzwi_wewnetrzne"],
    }


def get_verification_checklist() -> list[str]:
    """
    Zwraca listę rzeczy do weryfikacji (np. po odczycie rysunków).
    """
    p = _load_projekt()
    return p.get("uwagi_do_weryfikacji", [])


def update_room_area(room_id: str, powierzchnia_m2: float) -> dict:
    """
    Aktualizuje powierzchnię pomieszczenia (po weryfikacji z rysunkami).
    Zapisuje zmiany do projekt.json.
    """
    p = _load_projekt()
    for k in p["kondygnacje"]:
        for pom in k["pomieszczenia"]:
            if pom["id"] == room_id:
                old = pom["powierzchnia_m2"]
                pom["powierzchnia_m2"] = powierzchnia_m2
                k["suma_powierzchni_m2"] = sum(r["powierzchnia_m2"] for r in k["pomieszczenia"])
                with open(_BASE / "projekt.json", "w", encoding="utf-8") as f:
                    json.dump(p, f, ensure_ascii=False, indent=2)
                global _projekt_cache, _kosztorys_cache
                _projekt_cache = None
                _kosztorys_cache = None
                return {"updated": room_id, "stara_wartosc_m2": old, "nowa_wartosc_m2": powierzchnia_m2}
    return {"error": f"Nie znaleziono pomieszczenia: {room_id}"}


# =========================================================
# Definicje narzędzi w schemacie Anthropic/OpenAI
# =========================================================

TOOLS: list[dict[str, Any]] = [
    {
        "name": "get_project_summary",
        "description": "Zwraca streszczenie projektu Stare Brynki: inwestor, lokalizacja, parametry geometryczne, biuro projektowe.",
        "input_schema": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "get_room_list",
        "description": "Zwraca listę pomieszczeń z powierzchnią i typem. Można filtrować wg kondygnacji.",
        "input_schema": {
            "type": "object",
            "properties": {
                "kondygnacja": {
                    "type": "string",
                    "enum": ["parter", "pietro"],
                    "description": "Filtruj wg kondygnacji. Pomiń aby pobrać wszystkie.",
                }
            },
            "required": [],
        },
    },
    {
        "name": "get_room_detail",
        "description": "Zwraca pełne dane pomieszczenia (okna, drzwi, materiały, instalacje).",
        "input_schema": {
            "type": "object",
            "properties": {
                "room_id": {
                    "type": "string",
                    "description": "ID pomieszczenia: wiatrolap, salon, kuchnia, wc_parter, kotlownia, korytarz_parter, garaz, sypialnia_glowna, sypialnia_2, sypialnia_3, lazienka_pietro, korytarz_pietro",
                }
            },
            "required": ["room_id"],
        },
    },
    {
        "name": "get_installation_summary",
        "description": "Zwraca szczegóły systemu instalacyjnego budynku.",
        "input_schema": {
            "type": "object",
            "properties": {
                "system": {
                    "type": "string",
                    "enum": ["elektryczna", "sanitarna", "ogrzewanie", "wentylacja", "woda", "kanalizacja"],
                    "description": "Nazwa systemu instalacyjnego",
                }
            },
            "required": ["system"],
        },
    },
    {
        "name": "get_construction_element",
        "description": "Zwraca parametry elementu konstrukcyjnego (fundament, ściany, strop, dach itp.).",
        "input_schema": {
            "type": "object",
            "properties": {
                "element": {
                    "type": "string",
                    "enum": ["fundament", "sciany_zewnetrzne", "sciany_wewnetrzne", "stropy", "schody", "dach", "wieniec"],
                }
            },
            "required": ["element"],
        },
    },
    {
        "name": "calculate_area",
        "description": "Zestawienie powierzchni pomieszczeń wg zadanego kryterium (typ, kondygnacja).",
        "input_schema": {
            "type": "object",
            "properties": {
                "typ_powierzchni": {
                    "type": "string",
                    "enum": ["wszystkie", "mieszkalne", "mokre", "techniczne", "komunikacja", "parter", "pietro"],
                }
            },
            "required": ["typ_powierzchni"],
        },
    },
    {
        "name": "get_kosztorys_summary",
        "description": "Zwraca podsumowanie kosztorysu wg działów (netto / VAT / brutto).",
        "input_schema": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "get_kosztorys_dzial",
        "description": "Zwraca szczegółowe pozycje kosztorysu z danego działu robót.",
        "input_schema": {
            "type": "object",
            "properties": {
                "dzial": {
                    "type": "string",
                    "enum": [
                        "01 Roboty ziemne",
                        "02 Ściany",
                        "03 Stropy",
                        "04 Dach",
                        "05 Tynki",
                        "06 Stolarka",
                        "07 Instalacje sanitarne",
                        "08 Instalacje elektryczne",
                        "09 Zagospodarowanie terenu",
                    ],
                }
            },
            "required": ["dzial"],
        },
    },
    {
        "name": "search_kosztorys",
        "description": "Wyszukuje pozycje kosztorysu po słowie kluczowym w opisie.",
        "input_schema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Fraza do wyszukania, np. 'dachówka', 'pompa ciepła', 'okna'"}
            },
            "required": ["query"],
        },
    },
    {
        "name": "get_scene_json",
        "description": "Zwraca definicję sceny 3D (RoomScene v2) gotową do renderowania w room_3d. Zawiera ściany, pomieszczenia, otwory i schody.",
        "input_schema": {
            "type": "object",
            "properties": {
                "floor_index": {
                    "type": "integer",
                    "enum": [0, 1],
                    "description": "0=parter, 1=piętro. Pomiń aby pobrać całą budowlę.",
                }
            },
            "required": [],
        },
    },
    {
        "name": "get_joinery_summary",
        "description": "Zestawienie stolarki: okna (typ, U, powierzchnia), drzwi zewnętrzne, brama garażowa, drzwi wewnętrzne.",
        "input_schema": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "get_verification_checklist",
        "description": "Zwraca listę elementów projektu wymagających weryfikacji z rysunkami technicznymi.",
        "input_schema": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "update_room_area",
        "description": "Aktualizuje powierzchnię pomieszczenia po weryfikacji z rysunkami. Zapisuje do projekt.json i resetuje cache kosztorysu.",
        "input_schema": {
            "type": "object",
            "properties": {
                "room_id": {"type": "string", "description": "ID pomieszczenia do aktualizacji"},
                "powierzchnia_m2": {"type": "number", "description": "Nowa powierzchnia w m²"},
            },
            "required": ["room_id", "powierzchnia_m2"],
        },
    },
]

# Mapa name -> callable, do dispatchu przez Superbee/Emma
TOOL_HANDLERS: dict[str, Any] = {
    "get_project_summary": lambda args: get_project_summary(),
    "get_room_list": lambda args: get_room_list(**args),
    "get_room_detail": lambda args: get_room_detail(**args),
    "get_installation_summary": lambda args: get_installation_summary(**args),
    "get_construction_element": lambda args: get_construction_element(**args),
    "calculate_area": lambda args: calculate_area(**args),
    "get_kosztorys_summary": lambda args: get_kosztorys_summary(),
    "get_kosztorys_dzial": lambda args: get_kosztorys_dzial(**args),
    "search_kosztorys": lambda args: search_kosztorys(**args),
    "get_scene_json": lambda args: get_scene_json(**args),
    "get_joinery_summary": lambda args: get_joinery_summary(),
    "get_verification_checklist": lambda args: get_verification_checklist(),
    "update_room_area": lambda args: update_room_area(**args),
}


def dispatch_tool(name: str, args: dict) -> Any:
    """Wywołanie narzędzia po nazwie. Używane przez integrator Superbee."""
    handler = TOOL_HANDLERS.get(name)
    if handler is None:
        raise ValueError(f"Nieznane narzędzie: {name}")
    return handler(args)
