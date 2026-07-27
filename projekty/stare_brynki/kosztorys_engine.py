"""
Silnik automatycznego kosztorysu dla projektu Stare Brynki (EXTERA).
Wejście: projekt.json
Wyjście: lista pozycji kosztorysu wg KNR z ilościami, cenami jednostkowymi i wartościami.

Ceny jednostkowe: rynek zachodniopomorski, lipiec 2025 (netto PLN).
"""
from __future__ import annotations
import json
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Optional

PROJEKT_PATH = Path(__file__).parent / "projekt.json"


@dataclass
class PozycjaKosztorysu:
    lp: int
    dzial: str
    opis: str
    knr: str
    jednostka: str
    ilosc: float
    cena_jedn_netto: float
    uwagi: str = ""

    @property
    def wartosc_netto(self) -> float:
        return round(self.ilosc * self.cena_jedn_netto, 2)

    def to_dict(self) -> dict:
        d = asdict(self)
        d["wartosc_netto"] = self.wartosc_netto
        return d


def _projekt() -> dict:
    with open(PROJEKT_PATH, encoding="utf-8") as f:
        return json.load(f)


def _pomieszczenia_all(p: dict) -> list[dict]:
    result = []
    for k in p.get("kondygnacje", []):
        for pom in k.get("pomieszczenia", []):
            pom = dict(pom)
            pom["_kondygnacja"] = k["id"]
            result.append(pom)
    return result


def generuj_kosztorys(projekt: Optional[dict] = None) -> list[PozycjaKosztorysu]:
    p = projekt or _projekt()
    geo = p["geometria_budynku"]
    konstr = p["elementy_konstrukcyjne"]
    inst = p["instalacje"]
    stol = p["stolarka"]
    poz: list[PozycjaKosztorysu] = []
    lp = 0

    def add(dzial, opis, knr, jednostka, ilosc, cena, uwagi=""):
        nonlocal lp
        lp += 1
        poz.append(PozycjaKosztorysu(lp, dzial, opis, knr, jednostka, round(ilosc, 2), cena, uwagi))

    # =========================================================
    # DZIAŁ 01 – ROBOTY ZIEMNE I FUNDAMENTOWE
    # =========================================================
    fund = konstr["fundament"]
    dl_funda = fund["dlugosc_calkowita_m"]
    szer_lawicy = fund["szerokosc_lawicy_cm"] / 100
    wys_lawicy = fund["wysokosc_lawicy_cm"] / 100
    gl_posadownienia = fund["glebokos_posadowienia_m"]
    pow_zabudowy = geo["powierzchnia_zabudowy_m2"]

    # Zdjęcie humusu
    add("01 Roboty ziemne", "Zdjęcie warstwy humusu gr. 20cm",
        "KNR 2-01 0111-01", "m2", pow_zabudowy * 1.3, 8.0,
        "Pow. zabudowy +30% pod chodniki i taras")

    # Wykop pod fundamenty (ławy + ściana fundamentowa)
    obj_wykopu = dl_funda * szer_lawicy * (gl_posadownienia + wys_lawicy + 0.5)
    add("01 Roboty ziemne", "Wykop ręczno-mechaniczny pod ławy fundamentowe",
        "KNR 2-01 0213-01", "m3", obj_wykopu, 42.0)

    # Podsypka piaskowa pod fundamenty
    add("01 Roboty ziemne", "Podsypka piaskowa gr. 10cm pod ławy i ścianę fund.",
        "KNR 2-01 0411-01", "m2", dl_funda * szer_lawicy, 12.0)

    # Ławy fundamentowe betonowe
    obj_law = dl_funda * szer_lawicy * wys_lawicy
    add("01 Roboty ziemne", "Beton ław fundamentowych C16/20",
        "KNR 2-01 0502-01", "m3", obj_law, 340.0)

    # Zbrojenie ław
    add("01 Roboty ziemne", "Zbrojenie ław fundamentowych (stal A-IIIN)",
        "KNR 2-01 0502-04", "kg", obj_law * 60, 5.8,
        "Szacunek: 60 kg/m3 betonu")

    # Ściana fundamentowa
    sc_fund = konstr["fundament"]["sciana_fundamentowa"]
    obj_sc_fund = dl_funda * (sc_fund["grubosc_cm"] / 100) * sc_fund["wysokosc_m"]
    add("01 Roboty ziemne", "Ściana fundamentowa z betonu C16/20",
        "KNR 2-01 0504-01", "m3", obj_sc_fund, 360.0)

    # Izolacja przeciwwilgociowa fundamentów
    pow_izol_fund = dl_funda * (sc_fund["wysokosc_m"] + wys_lawicy) * 2
    add("01 Roboty ziemne", "Izolacja p/wilgoci fundamentów (papa termozgrzewalna 2x)",
        "KNR 2-02 1402-01", "m2", pow_izol_fund, 28.0)

    # Izolacja termiczna fundamentów
    add("01 Roboty ziemne", "Styrodur XPS 10cm na ścianie fundamentowej",
        "KNR 2-02 1410-01", "m2", pow_izol_fund, 65.0)

    # Zasypka i zagęszczenie
    add("01 Roboty ziemne", "Zasypanie wykopów z zagęszczeniem mechanicznym",
        "KNR 2-01 0311-01", "m3", obj_wykopu * 0.7, 18.0)

    # =========================================================
    # DZIAŁ 02 – ŚCIANY MUROWANE
    # =========================================================
    sciany_zew = konstr["sciany_zewnetrzne"]["warianty"][0]
    pow_scian_netto = sciany_zew["powierzchnia_netto_m2"]
    pow_scian_brutto = sciany_zew["powierzchnia_brutto_m2"]

    # Ściany zewnętrzne POROTHERM 25
    add("02 Ściany", "Mury z bloczków ceramicznych POROTHERM 25 P+W – ściany zew.",
        "KNR 2-02 0214-01", "m2", pow_scian_netto, 145.0,
        "Cena zawiera zaprawę i spoinowanie")

    # Wieniec żelbetowy
    wieniec = konstr["wieniec"]
    obj_wieniec = dl_funda * (wieniec["szerokosc_cm"] / 100) * (wieniec["wysokosc_cm"] / 100) * 2
    add("02 Ściany", "Wieniec żelbetowy C20/25 – obwód budynku",
        "KNR 2-02 0603-01", "m3", obj_wieniec, 520.0)

    zbrojenie_wieniec = obj_wieniec * 90
    add("02 Ściany", "Zbrojenie wieńców (4Ø12 + strz. Ø6 co 20cm)",
        "KNR 2-02 0603-04", "kg", zbrojenie_wieniec, 5.8)

    # Ściany nośne wewnętrzne
    sc_nosna = next(s for s in konstr["sciany_wewnetrzne"] if s["id"] == "sciana_nosna_wew")
    add("02 Ściany", "Mury z bloczków ceramicznych POROTHERM 25 – ściany nośne wew.",
        "KNR 2-02 0214-02", "m2", sc_nosna["powierzchnia_m2"], 132.0)

    # Ściany działowe
    sc_dzial = next(s for s in konstr["sciany_wewnetrzne"] if s["id"] == "dzialowa_12")
    add("02 Ściany", "Mury z bloczków gazobetonowych B2 gr. 12cm – ściany działowe",
        "KNR 2-02 0412-01", "m2", sc_dzial["powierzchnia_m2"], 78.0)

    # Ścianki karton-gips
    sc_gk = next(s for s in konstr["sciany_wewnetrzne"] if s["id"] == "plyta_gk")
    add("02 Ściany", "Ścianki z płyt GK na ruszcie stalowym gr. 10cm",
        "KNR 2-02 1501-01", "m2", sc_gk["powierzchnia_m2"], 95.0)

    # =========================================================
    # DZIAŁ 03 – STROPY I SCHODY
    # =========================================================
    strop = konstr["stropy"][0]
    add("03 Stropy", "Strop gęstożebrowy TERIVA 4.0/1 wys. 24cm",
        "KNR 2-02 0712-01", "m2", strop["powierzchnia_m2"], 168.0,
        "Cena z belkami, pustakami, zbrojeniem rozdzielczym")

    add("03 Stropy", "Wylewka betonowa gr. 4cm na stropie (C20/25 zbrojona siatką)",
        "KNR 2-02 0801-01", "m2", strop["powierzchnia_m2"], 45.0)

    schody = konstr["schody"]
    add("03 Stropy", "Schody drewniane dywanowe, stopnice dębowe, balustrada stalowa",
        "KNR 4-01 0521-01", "szt", 1, 8_500.0,
        f"Zakres: {schody['liczba_stopni']} stopni + balustrada {schody['balustrada']}")

    # =========================================================
    # DZIAŁ 04 – DACH I POKRYCIE
    # =========================================================
    dach = konstr["dach"]
    pow_polaci = geo["dach"]["powierzchnia_polaci_m2"]

    add("04 Dach", "Konstrukcja drewniana dachu (krokwiowo-płatwiowa, drewno C24)",
        "KNR 2-10 0211-01", "m3",
        pow_polaci * 0.032,
        920.0,
        "Szacunek: 32 dm³/m² połaci; cena zawiera impregnację")

    add("04 Dach", "Membrana wiatroizolacyjna dachowa (Sd≤0.15 m)",
        "KNR 2-10 0412-01", "m2", pow_polaci * 1.05, 12.0)

    add("04 Dach", "Kontrłaty i łaty drewniane",
        "KNR 2-10 0421-01", "m2", pow_polaci, 18.0)

    add("04 Dach", "Pokrycie dachówką ceramiczną (karpiówka / mnich-mniszka)",
        "KNR 2-10 0511-01", "m2", pow_polaci, 145.0)

    add("04 Dach", "Izolacja termiczna dachu – wełna mineralna miedzy krokwiami (18cm)",
        "KNR 2-10 0631-01", "m2", pow_polaci, 68.0)

    add("04 Dach", "Izolacja termiczna dachu – wełna mineralna pod krokwiami (10cm)",
        "KNR 2-10 0631-02", "m2", pow_polaci, 38.0)

    add("04 Dach", "Płyta GK wilgocioodporna 12.5mm – sufit poddasza użytkowego",
        "KNR 2-02 1502-01", "m2", pow_polaci * 0.75, 62.0)

    add("04 Dach", "Rynny PVC fi125mm z uchwytami",
        "KNR 2-10 0811-01", "mb", 44.0, 28.0)

    add("04 Dach", "Rury spustowe PVC fi90mm",
        "KNR 2-10 0821-01", "mb", 4 * 5.0, 22.0,
        "4 sztuki po ~5m")

    add("04 Dach", "Okna dachowe VELUX lub równoważne 78x118cm – z kołnierzem",
        "KNR 2-10 0904-01", "szt", 2, 2_200.0)

    # =========================================================
    # DZIAŁ 05 – TYNKI I OKŁADZINY
    # =========================================================
    pow_tynk_wew = (pow_scian_netto + sc_nosna["powierzchnia_m2"] +
                    sc_dzial["powierzchnia_m2"]) * 1.1

    add("05 Tynki", "Tynk cementowo-wapienny maszynowy kat. III wewnętrzny",
        "KNR 2-02 1201-01", "m2", pow_tynk_wew, 38.0)

    add("05 Tynki", "Gładź gipsowa 1-warstwowa szlifowana",
        "KNR 2-02 1211-01", "m2", pow_tynk_wew * 0.85, 22.0)

    # Malowanie
    add("05 Tynki", "Malowanie ścian i sufitów farbą lateksową 2x",
        "KNR 4-01 0211-01", "m2", pow_tynk_wew * 0.85, 18.0)

    # Plytkowanie łazienki i WC
    pow_plytek = 7.5 * 4 * 2.2 + 2.5 * 4 * 2.2
    add("05 Tynki", "Plytkowanie ścian łazienek i WC (gres rektyfikowany)",
        "KNR 4-01 0411-01", "m2", pow_plytek, 85.0)

    # Plytkowanie kuchni (fartuch)
    add("05 Tynki", "Plytkowanie fartuch kuchenny 60x60cm",
        "KNR 4-01 0411-02", "m2", 10.5 * 0.6, 75.0)

    # Posadzki
    pom_all = _pomieszczenia_all(p)
    pow_gres = sum(pm["powierzchnia_m2"] for pm in pom_all
                   if pm.get("material_podlogi", "").startswith("gres"))
    pow_panel = sum(pm["powierzchnia_m2"] for pm in pom_all
                    if pm.get("material_podlogi", "").startswith("panel"))

    add("05 Tynki", "Posadzki z gresu mat/antypoślizgowego (wraz z klejeniem)",
        "KNR 4-01 0511-01", "m2", pow_gres, 95.0)

    add("05 Tynki", "Posadzki z paneli podłogowych AC5 (wraz z listwami)",
        "KNR 4-01 0521-01", "m2", pow_panel, 58.0)

    add("05 Tynki", "Posadzka betonowa zacierana w garażu i kotłowni",
        "KNR 2-02 0831-01", "m2", 19.0 + 8.0, 42.0)

    # Elewacja
    pow_elewacji = p["wykonczenie"]["elewacja"]["tynk_silikonowy"]["powierzchnia_m2"]
    add("05 Tynki", "Tynk silikonowy cienkowarstwowy elewacja – gr. 1.5mm (ETICS)",
        "KNR 2-02 1231-01", "m2", pow_elewacji, 32.0)

    add("05 Tynki", "Styropian EPS 100 lambda 0.032 – izolacja elewacji 15cm",
        "KNR 2-02 1402-02", "m2", pow_scian_brutto, 98.0)

    add("05 Tynki", "Cokolnik – płytki klinkierowe 40cm ht.",
        "KNR 4-01 0411-03", "mb", dl_funda * 0.9, 85.0)

    # =========================================================
    # DZIAŁ 06 – STOLARKA OKIENNA I DRZWIOWA
    # =========================================================
    okna = stol["okna"]
    add("06 Stolarka", "Okna PCV 6-komorowe trzyszybowe Ug=0.6 – dostawa i montaż",
        "KNR 4-01 0611-01", "m2", okna["powierzchnia_calkowita_m2"], 520.0,
        f"Profil: {okna['typ_profilu']}, kolor: {okna['kolor']}")

    add("06 Stolarka", "Drzwi zewnętrzne stalowe antywłamaniowe RC2 900x2100mm",
        "KNR 4-01 0621-01", "szt", 1, 4_800.0)

    add("06 Stolarka", "Drzwi HST przesuwno-uchylne tarasowe 2400x2200mm",
        "KNR 4-01 0621-02", "szt", 1, 9_500.0)

    add("06 Stolarka", "Brama garażowa segmentowa z napędem 2500x2200mm",
        "KNR 4-01 0625-01", "szt", 1, 5_200.0)

    drzwi = stol["drzwi_wewnetrzne"]
    add("06 Stolarka", "Drzwi wewnętrzne płytowe HDF 900x2000mm z ościeżnicą regulowaną",
        "KNR 4-01 0631-01", "szt", drzwi["liczba_sztuk"], 950.0)

    add("06 Stolarka", "Parapety zewnętrzne blacha stalowa powlekana szer. 25cm",
        "KNR 4-01 0641-01", "mb", okna["powierzchnia_calkowita_m2"] / 1.2 * 1.0, 48.0,
        "Szacunek: 1mb parapetu na 1.2m2 okna")

    # =========================================================
    # DZIAŁ 07 – INSTALACJE SANITARNE
    # =========================================================
    ogrz = inst["sanitarna"]["ogrzewanie"]
    woda = inst["sanitarna"]["woda"]
    went = inst["sanitarna"]["wentylacja"]

    add("07 Instalacje sanitarne", "Pompa ciepła powietrzna monoblok 8kW – dostawa i uruchomienie",
        "KNR 3-01 0711-01", "kpl", 1, 28_000.0,
        f"Parametry: {ogrz['pompa_ciepla']['moc_grzewcza_kW']}kW, COP={ogrz['pompa_ciepla']['cop']}")

    add("07 Instalacje sanitarne", "Zasobnik CWU pionowy 200L – dostawa i montaż",
        "KNR 3-01 0721-01", "szt", 1, 4_200.0)

    add("07 Instalacje sanitarne", "Rozdzielacze ogrzewania podłogowego (6 obwodów) z siłownikami",
        "KNR 3-01 0731-01", "kpl", 1, 3_800.0)

    add("07 Instalacje sanitarne", "Ogrzewanie podłogowe – rura PEX 16x2mm, rozst. 15cm",
        "KNR 3-01 0741-01", "m2", geo["powierzchnia_uzytkowa_m2"] * 0.9, 78.0)

    add("07 Instalacje sanitarne", "Instalacja wody zimnej i ciepłej PP-RC STABI",
        "KNR 3-01 0811-01", "kpl", 1, 8_500.0,
        "Rura PP-RC stabilizowana fi20-32mm, trasy ~85mb")

    add("07 Instalacje sanitarne", "Instalacja kanalizacyjna PVC fi75-160mm (wewnętrzna)",
        "KNR 3-01 0911-01", "kpl", 1, 6_200.0,
        "Piony PVC fi110, poziomy fi110-160mm")

    add("07 Instalacje sanitarne", "Wentylacja mechaniczna HRV – centralka + sieć kanałów",
        "KNR 3-01 1011-01", "kpl", 1, 18_500.0,
        f"Sprawność odzysku {went['sprawnosc_odzysku_procent']}%, {went['wydajnosc_m3h']}m³/h")

    add("07 Instalacje sanitarne", "Armatura sanitarna – łazienka piętro (wanna, prysznic, WC, umyw.)",
        "KNR 3-01 1111-01", "kpl", 1, 8_400.0)

    add("07 Instalacje sanitarne", "Armatura sanitarna – WC parter",
        "KNR 3-01 1111-02", "kpl", 1, 2_200.0)

    add("07 Instalacje sanitarne", "Przyłącze wodociągowe DN32 – wykonanie i podłączenie",
        "KNR 3-01 0801-01", "mb", 15.0, 280.0,
        "Szacunek 15mb od wodociągu do WW")

    # =========================================================
    # DZIAŁ 08 – INSTALACJE ELEKTRYCZNE
    # =========================================================
    el = inst["elektryczna"]

    add("08 Instalacje elektryczne", "Przyłącze kablowe zasilające YKY 4x16mm² dl.32m",
        "KNR 5-01 0211-01", "mb", el["zasilanie"]["dlugosc_kabla_m"], 38.0,
        f"Kabel: {el['zasilanie']['kabel_zasilajacy']}")

    add("08 Instalacje elektryczne", "Rozdzielnica główna RG z wyposażeniem – dostawa i montaż",
        "KNR 5-01 0311-01", "kpl", 1, 4_800.0,
        f"P={el['moc_zamowiona_kW']}kW, cosφ={el['tablice'][0]['cos_phi']}")

    add("08 Instalacje elektryczne", "Instalacja elektryczna wewnętrzna (trasy, gniazda, łączniki)",
        "KNR 5-01 0411-01", "kpl", 1, 12_500.0,
        "Szacunek: ok. 85 obwodów, kable YDYp 3x1.5 i 3x2.5mm²")

    add("08 Instalacje elektryczne", "Kabel zasilania bramy garażowej YKYżo 5x2.5mm²",
        "KNR 5-01 0421-01", "mb", 25.0, 18.0)

    add("08 Instalacje elektryczne", "Kabel zasilania pompy ciepła YKYżo 5x6mm²",
        "KNR 5-01 0421-02", "mb", 20.0, 28.0)

    add("08 Instalacje elektryczne", "Kabel FTPw 4x2x0.5 (domofon/interkom) + panel zewnętrzny",
        "KNR 5-01 0431-01", "kpl", 1, 1_800.0)

    add("08 Instalacje elektryczne", "Instalacja odgromowa – zwody, przewody odprowadzające, uziom",
        "KNR 5-01 0511-01", "kpl", 1, 3_200.0)

    add("08 Instalacje elektryczne", "Oprawy oświetleniowe LED (kompleksowo – dostawa i montaż)",
        "KNR 5-01 0611-01", "kpl", 1, 4_500.0,
        "Szacunek 35 opraw LED panelowych + kinkiety")

    # =========================================================
    # DZIAŁ 09 – ZAGOSPODAROWANIE TERENU
    # =========================================================
    teren = p["wykonczenie"]

    add("09 Zagospodarowanie terenu", "Taras ogrodowy – deska kompozytowa na konstr. stalowej",
        "KNR 4-01 0721-01", "m2",
        teren["tarasy"][0]["powierzchnia_m2"], 320.0)

    add("09 Zagospodarowanie terenu", "Kostka betonowa 6cm na podsypce – podjazd i chodnik",
        "KNR 2-31 0211-01", "m2",
        teren["wjazd_chodnik"]["powierzchnia_m2"], 145.0,
        "Kolor: grafitowy, wzór: pospolity")

    add("09 Zagospodarowanie terenu", "Ogrodzenie działki (siatka na słupach stalowych)",
        "KNR 2-31 0411-01", "mb", 80.0, 220.0,
        "Szacunek obwodu działki")

    add("09 Zagospodarowanie terenu", "Brama wjazdowa stalowa dwuskrzydłowa z napędem",
        "KNR 2-31 0421-01", "szt", 1, 6_500.0)

    add("09 Zagospodarowanie terenu", "Humusowanie i wysiew trawy",
        "KNR 2-31 0511-01", "m2", pow_zabudowy * 2, 18.0)

    return poz


def podsumowanie(poz: list[PozycjaKosztorysu]) -> dict:
    dzialy: dict[str, float] = {}
    for p in poz:
        dzialy[p.dzial] = dzialy.get(p.dzial, 0.0) + p.wartosc_netto

    suma_netto = sum(dzialy.values())
    vat_23 = suma_netto * 0.23
    brutto = suma_netto + vat_23

    return {
        "dzialy": {k: round(v, 2) for k, v in dzialy.items()},
        "suma_netto": round(suma_netto, 2),
        "vat_23_procent": round(vat_23, 2),
        "brutto": round(brutto, 2),
        "uwaga": "Ceny orientacyjne. Wymagają weryfikacji z ofertami podwykonawców i aktualnym cennikiem BIM/SEKOCENBUD.",
    }


def export_json(output_path: str | None = None) -> str:
    poz = generuj_kosztorys()
    summ = podsumowanie(poz)
    result = {
        "projekt_id": "stare-brynki-2024",
        "data_generacji": "2026-07-27",
        "wersja_cennikowa": "SEKOCENBUD_2025Q2_zachodnioPomorskie",
        "pozycje": [p.to_dict() for p in poz],
        "podsumowanie": summ,
    }
    out = output_path or str(Path(__file__).parent / "kosztorys_output.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    return out


if __name__ == "__main__":
    poz = generuj_kosztorys()
    summ = podsumowanie(poz)
    print(f"\n{'='*70}")
    print(f"KOSZTORYS – Stare Brynki / EXTERA  ({len(poz)} pozycji)")
    print(f"{'='*70}")
    dzial_prev = ""
    for p in poz:
        if p.dzial != dzial_prev:
            print(f"\n  {p.dzial.upper()}")
            print(f"  {'─'*62}")
            dzial_prev = p.dzial
        print(f"  {p.lp:>3}. {p.opis[:45]:<45} {p.ilosc:>7.1f} {p.jednostka:<5} "
              f"x {p.cena_jedn_netto:>8.2f} = {p.wartosc_netto:>10.2f} PLN")
    print(f"\n{'='*70}")
    print(f"  PODSUMOWANIE DZIAŁÓW:")
    for dzial, wart in summ["dzialy"].items():
        print(f"    {dzial:<35} {wart:>12,.2f} PLN")
    print(f"  {'─'*54}")
    print(f"  SUMA NETTO:           {summ['suma_netto']:>12,.2f} PLN")
    print(f"  VAT 23%:              {summ['vat_23_procent']:>12,.2f} PLN")
    print(f"  SUMA BRUTTO:          {summ['brutto']:>12,.2f} PLN")
    print(f"\n  * {summ['uwaga']}")
    print(f"{'='*70}\n")
    out = export_json()
    print(f"Eksport JSON: {out}")
