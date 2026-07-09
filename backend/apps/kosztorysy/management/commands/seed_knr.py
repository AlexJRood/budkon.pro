"""
Management command: seed KNR catalog with common Polish construction positions.

Usage:
    python manage.py seed_knr
    python manage.py seed_knr --clear   (usuwa istniejące przed seedem)

Zawiera ~120 pozycji z najczęściej używanych katalogów:
  KNR 2-02 — Roboty ogólnobudowlane
  KNR 4-01 — Roboty instalacyjne wod-kan
  KNR 5-01 — Instalacje elektryczne
  KNR 2-25 — Roboty wykończeniowe
  KNNR 2   — Roboty murarskie
"""

from decimal import Decimal
from django.core.management.base import BaseCommand
from apps.kosztorysy.models import KnrKatalog, KnrPozycja


# ── Dane katalogów ─────────────────────────────────────────────────────────────

KATALOGI = [
    {"kod": "KNR 2-02", "nazwa": "Roboty ogólnobudowlane kubaturowe"},
    {"kod": "KNR 4-01", "nazwa": "Instalacje sanitarne wewnętrzne"},
    {"kod": "KNR 5-01", "nazwa": "Instalacje elektryczne wewnętrzne"},
    {"kod": "KNR 2-25", "nazwa": "Roboty wykończeniowe"},
    {"kod": "KNNR 2",   "nazwa": "Roboty murarskie i betonowe"},
    {"kod": "KNR 2-01", "nazwa": "Roboty ziemne i fundamentowe"},
]

# (katalog_kod, numer, opis, jm, naklad_r, naklad_m, naklad_s)
POZYCJE = [
    # ── KNR 2-01 Roboty ziemne ────────────────────────────────────────────────
    ("KNR 2-01", "0101-01", "Ręczne wykopy z transportem urobku do 3m", "m3",
     Decimal("2.20"), Decimal("0"), Decimal("0")),
    ("KNR 2-01", "0101-02", "Wykopy mechaniczne koparką do 1m³", "m3",
     Decimal("0.10"), Decimal("0"), Decimal("0.35")),
    ("KNR 2-01", "0102-01", "Zasypanie wykopów z zagęszczeniem", "m3",
     Decimal("0.80"), Decimal("0"), Decimal("0.15")),
    ("KNR 2-01", "0105-01", "Wywóz urobku samochodami do 5km", "m3",
     Decimal("0.05"), Decimal("0"), Decimal("0.60")),

    # ── KNR 2-02 Roboty betonowe / żelbetowe ─────────────────────────────────
    ("KNR 2-02", "0111-01", "Ławy fundamentowe betonowe bez zbrojenia", "m3",
     Decimal("1.80"), Decimal("0"), Decimal("0.20")),
    ("KNR 2-02", "0111-03", "Ławy fundamentowe żelbetowe", "m3",
     Decimal("4.50"), Decimal("0"), Decimal("0.40")),
    ("KNR 2-02", "0113-01", "Stopy fundamentowe żelbetowe", "m3",
     Decimal("5.20"), Decimal("0"), Decimal("0.45")),
    ("KNR 2-02", "0201-01", "Słupy żelbetowe monolityczne", "m3",
     Decimal("8.00"), Decimal("0"), Decimal("0.60")),
    ("KNR 2-02", "0211-01", "Ściany żelbetowe monolityczne gr. do 20cm", "m3",
     Decimal("9.50"), Decimal("0"), Decimal("0.80")),
    ("KNR 2-02", "0301-01", "Stropy płytowe żelbetowe monolityczne", "m3",
     Decimal("7.80"), Decimal("0"), Decimal("0.70")),
    ("KNR 2-02", "0302-01", "Stropy TERIVA", "m2",
     Decimal("0.80"), Decimal("0"), Decimal("0.10")),
    ("KNR 2-02", "0401-01", "Szalunki płytowe tradycyjne ścian", "m2",
     Decimal("1.20"), Decimal("0"), Decimal("0.05")),
    ("KNR 2-02", "0501-01", "Zbrojenie prętami gładkimi", "kg",
     Decimal("0.04"), Decimal("0"), Decimal("0.002")),
    ("KNR 2-02", "0501-02", "Zbrojenie prętami żebrowanymi", "kg",
     Decimal("0.035"), Decimal("0"), Decimal("0.002")),
    ("KNR 2-02", "0601-01", "Chudziak (podkład betonowy) gr. 10cm", "m2",
     Decimal("0.40"), Decimal("0"), Decimal("0.08")),

    # ── KNNR 2 Roboty murarskie ───────────────────────────────────────────────
    ("KNNR 2", "0101-01", "Mury zewnętrzne z bloczków gazobetonowych gr.24cm", "m2",
     Decimal("0.60"), Decimal("0"), Decimal("0")),
    ("KNNR 2", "0101-02", "Mury zewnętrzne z bloczków gazobetonowych gr.36cm", "m2",
     Decimal("0.80"), Decimal("0"), Decimal("0")),
    ("KNNR 2", "0102-01", "Mury wewnętrzne z pustaka ceramicznego gr.12cm", "m2",
     Decimal("0.42"), Decimal("0"), Decimal("0")),
    ("KNNR 2", "0102-02", "Mury wewnętrzne z pustaka ceramicznego gr.18cm", "m2",
     Decimal("0.55"), Decimal("0"), Decimal("0")),
    ("KNNR 2", "0103-01", "Mury z silikatów gr. 18cm", "m2",
     Decimal("0.50"), Decimal("0"), Decimal("0")),
    ("KNNR 2", "0104-01", "Nadproża prefabrykowane L-19 montaż", "szt",
     Decimal("0.30"), Decimal("0"), Decimal("0")),
    ("KNNR 2", "0105-01", "Wieniec żelbetowy", "m",
     Decimal("0.45"), Decimal("0"), Decimal("0.02")),
    ("KNNR 2", "0106-01", "Cegła pełna mur gr.25cm", "m2",
     Decimal("0.85"), Decimal("0"), Decimal("0")),
    ("KNNR 2", "0107-01", "Ścianki działowe z płyt G-K na ruszcie", "m2",
     Decimal("0.55"), Decimal("0"), Decimal("0")),

    # ── KNR 2-02 Więźba dachowa / pokrycie ───────────────────────────────────
    ("KNR 2-02", "1001-01", "Więźba dachowa drewniana", "m3",
     Decimal("3.80"), Decimal("0"), Decimal("0.10")),
    ("KNR 2-02", "1002-01", "Łacenie dachu łatami drewnianymi 40x50", "m2",
     Decimal("0.25"), Decimal("0"), Decimal("0")),
    ("KNR 2-02", "1003-01", "Pokrycie dachówką ceramiczną", "m2",
     Decimal("0.50"), Decimal("0"), Decimal("0")),
    ("KNR 2-02", "1003-02", "Pokrycie dachówką betonową", "m2",
     Decimal("0.45"), Decimal("0"), Decimal("0")),
    ("KNR 2-02", "1004-01", "Pokrycie blachą trapezową", "m2",
     Decimal("0.35"), Decimal("0"), Decimal("0")),
    ("KNR 2-02", "1004-02", "Pokrycie blachą powlekaną na rąbek stojący", "m2",
     Decimal("0.55"), Decimal("0"), Decimal("0")),
    ("KNR 2-02", "1005-01", "Membrany wstępnego krycia MWK układanie", "m2",
     Decimal("0.08"), Decimal("0"), Decimal("0")),
    ("KNR 2-02", "1006-01", "Rynny PVC dn125 montaż", "m",
     Decimal("0.35"), Decimal("0"), Decimal("0")),
    ("KNR 2-02", "1006-02", "Rury spustowe PVC dn90 montaż", "m",
     Decimal("0.30"), Decimal("0"), Decimal("0")),
    ("KNR 2-02", "1007-01", "Ocieplenie dachu wełną mineralną gr.20cm", "m2",
     Decimal("0.45"), Decimal("0"), Decimal("0")),

    # ── KNR 2-25 Tynki / wylewki / posadzki ──────────────────────────────────
    ("KNR 2-25", "0101-01", "Tynki gipsowe maszynowe kat. III", "m2",
     Decimal("0.30"), Decimal("0"), Decimal("0.05")),
    ("KNR 2-25", "0101-02", "Tynki cem-wap kat. III ręczne", "m2",
     Decimal("0.55"), Decimal("0"), Decimal("0")),
    ("KNR 2-25", "0102-01", "Tynk cienkow. silikonowy fasadowy z siatką", "m2",
     Decimal("0.60"), Decimal("0"), Decimal("0")),
    ("KNR 2-25", "0103-01", "Wylewka cementowa samopoziomująca gr.5cm", "m2",
     Decimal("0.35"), Decimal("0"), Decimal("0.05")),
    ("KNR 2-25", "0103-02", "Wylewka anhydrytowa gr.5cm", "m2",
     Decimal("0.28"), Decimal("0"), Decimal("0.05")),
    ("KNR 2-25", "0104-01", "Ocieplenie ścian styropianem EPS 100 gr.15cm", "m2",
     Decimal("0.55"), Decimal("0"), Decimal("0")),
    ("KNR 2-25", "0104-02", "Ocieplenie ścian wełną mineralną fasadową gr.15cm", "m2",
     Decimal("0.60"), Decimal("0"), Decimal("0")),
    ("KNR 2-25", "0105-01", "Układanie płytek ceramicznych podłogowych do 600×600", "m2",
     Decimal("0.85"), Decimal("0"), Decimal("0")),
    ("KNR 2-25", "0105-02", "Układanie płytek ceramicznych ściennych do 300×600", "m2",
     Decimal("0.90"), Decimal("0"), Decimal("0")),
    ("KNR 2-25", "0105-03", "Układanie płytek wielkoformatowych pow.600×600", "m2",
     Decimal("1.20"), Decimal("0"), Decimal("0")),
    ("KNR 2-25", "0106-01", "Parkiet dębowy układanie na kleju", "m2",
     Decimal("0.90"), Decimal("0"), Decimal("0")),
    ("KNR 2-25", "0106-02", "Panele podłogowe laminowane układanie", "m2",
     Decimal("0.45"), Decimal("0"), Decimal("0")),
    ("KNR 2-25", "0107-01", "Listwy przypodłogowe MDF montaż", "m",
     Decimal("0.12"), Decimal("0"), Decimal("0")),
    ("KNR 2-25", "0108-01", "Malowanie ścian farbą emulsyjną 2×", "m2",
     Decimal("0.12"), Decimal("0"), Decimal("0")),
    ("KNR 2-25", "0108-02", "Gruntowanie ścian i sufitów", "m2",
     Decimal("0.06"), Decimal("0"), Decimal("0")),
    ("KNR 2-25", "0109-01", "Sufity podwieszane G-K jednowarstwowe", "m2",
     Decimal("0.65"), Decimal("0"), Decimal("0")),
    ("KNR 2-25", "0110-01", "Parapety wewnętrzne PVC montaż", "m",
     Decimal("0.25"), Decimal("0"), Decimal("0")),
    ("KNR 2-25", "0110-02", "Parapety zewnętrzne blaszane montaż", "m",
     Decimal("0.30"), Decimal("0"), Decimal("0")),

    # ── Stolarka okienna / drzwiowa ───────────────────────────────────────────
    ("KNR 2-02", "1101-01", "Montaż okien PVC w murze z otwarciem", "szt",
     Decimal("2.50"), Decimal("0"), Decimal("0")),
    ("KNR 2-02", "1101-02", "Montaż okien drewnianych energooszczędnych", "szt",
     Decimal("3.00"), Decimal("0"), Decimal("0")),
    ("KNR 2-02", "1102-01", "Montaż drzwi zewnętrznych stalowych antywłamaniowych", "szt",
     Decimal("4.00"), Decimal("0"), Decimal("0")),
    ("KNR 2-02", "1102-02", "Montaż drzwi wewnętrznych w ościeżnicy stalowej", "szt",
     Decimal("2.00"), Decimal("0"), Decimal("0")),
    ("KNR 2-02", "1103-01", "Bramy garażowe segmentowe automatyczne montaż", "szt",
     Decimal("8.00"), Decimal("0"), Decimal("0.50")),

    # ── KNR 4-01 Instalacje sanitarne ─────────────────────────────────────────
    ("KNR 4-01", "0101-01", "Rurociągi PEX w instalacji zimnej wody do dn20", "m",
     Decimal("0.25"), Decimal("0"), Decimal("0")),
    ("KNR 4-01", "0101-02", "Rurociągi PEX w instalacji ciepłej wody do dn20", "m",
     Decimal("0.28"), Decimal("0"), Decimal("0")),
    ("KNR 4-01", "0102-01", "Rurociągi PP w instalacji CO dn20", "m",
     Decimal("0.30"), Decimal("0"), Decimal("0")),
    ("KNR 4-01", "0102-02", "Rurociągi stalowe ocynkowane dn25", "m",
     Decimal("0.55"), Decimal("0"), Decimal("0")),
    ("KNR 4-01", "0103-01", "Kanalizacja PVC dn50 montaż", "m",
     Decimal("0.35"), Decimal("0"), Decimal("0")),
    ("KNR 4-01", "0103-02", "Kanalizacja PVC dn110 montaż", "m",
     Decimal("0.45"), Decimal("0"), Decimal("0")),
    ("KNR 4-01", "0104-01", "Montaż grzejnika panelowego z zaworami", "szt",
     Decimal("2.00"), Decimal("0"), Decimal("0")),
    ("KNR 4-01", "0104-02", "Montaż kotła gazowego kondensacyjnego do 25kW", "kpl",
     Decimal("16.00"), Decimal("0"), Decimal("0")),
    ("KNR 4-01", "0105-01", "Montaż baterii umywalkowej stojącej", "szt",
     Decimal("1.00"), Decimal("0"), Decimal("0")),
    ("KNR 4-01", "0105-02", "Montaż baterii wannowej z deszczownicą", "kpl",
     Decimal("2.50"), Decimal("0"), Decimal("0")),
    ("KNR 4-01", "0106-01", "Montaż umywalki z syfonem i baterią", "kpl",
     Decimal("3.50"), Decimal("0"), Decimal("0")),
    ("KNR 4-01", "0106-02", "Montaż misy WC kompakt z deską", "kpl",
     Decimal("3.00"), Decimal("0"), Decimal("0")),
    ("KNR 4-01", "0106-03", "Montaż wanny akrylowej z baterią", "kpl",
     Decimal("6.00"), Decimal("0"), Decimal("0")),
    ("KNR 4-01", "0106-04", "Montaż kabiny prysznicowej 90×90", "kpl",
     Decimal("5.00"), Decimal("0"), Decimal("0")),
    ("KNR 4-01", "0107-01", "Izolacja termiczna rurociągów pianką PE", "m",
     Decimal("0.15"), Decimal("0"), Decimal("0")),
    ("KNR 4-01", "0108-01", "Ogrzewanie podłogowe — pętle PE-RT z rozdzielaczem", "m2",
     Decimal("0.55"), Decimal("0"), Decimal("0")),
    ("KNR 4-01", "0109-01", "Próba ciśnieniowa instalacji CO", "kpl",
     Decimal("4.00"), Decimal("0"), Decimal("0")),

    # ── KNR 5-01 Instalacje elektryczne ───────────────────────────────────────
    ("KNR 5-01", "0101-01", "Kabel YDYp 3×1.5mm² układanie w tynku", "m",
     Decimal("0.08"), Decimal("0"), Decimal("0")),
    ("KNR 5-01", "0101-02", "Kabel YDYp 3×2.5mm² układanie w tynku", "m",
     Decimal("0.10"), Decimal("0"), Decimal("0")),
    ("KNR 5-01", "0101-03", "Kabel YKY 5×10mm² układanie w ziemi", "m",
     Decimal("0.15"), Decimal("0"), Decimal("0")),
    ("KNR 5-01", "0102-01", "Montaż gniazda wtyczkowego z uziemieniem 230V", "szt",
     Decimal("0.50"), Decimal("0"), Decimal("0")),
    ("KNR 5-01", "0102-02", "Montaż łącznika pojedynczego", "szt",
     Decimal("0.40"), Decimal("0"), Decimal("0")),
    ("KNR 5-01", "0102-03", "Montaż oprawy oświetleniowej sufitowej", "szt",
     Decimal("0.45"), Decimal("0"), Decimal("0")),
    ("KNR 5-01", "0103-01", "Montaż tablicy rozdzielczej TK do 24 modułów", "kpl",
     Decimal("8.00"), Decimal("0"), Decimal("0")),
    ("KNR 5-01", "0103-02", "Montaż wyłącznika nadprądowego S301 w tablicy", "szt",
     Decimal("0.30"), Decimal("0"), Decimal("0")),
    ("KNR 5-01", "0104-01", "Rurka instalacyjna PVC 20mm układanie", "m",
     Decimal("0.10"), Decimal("0"), Decimal("0")),
    ("KNR 5-01", "0105-01", "Uziemienie — bednarstwo 25mm² układanie", "m",
     Decimal("0.12"), Decimal("0"), Decimal("0")),
    ("KNR 5-01", "0105-02", "Piorunochron — zwody pionowe i poziome", "m",
     Decimal("0.20"), Decimal("0"), Decimal("0")),
    ("KNR 5-01", "0106-01", "Pomiar i próba kabli — odcinek do 100m", "kpl",
     Decimal("2.00"), Decimal("0"), Decimal("0")),
    ("KNR 5-01", "0107-01", "Montaż domofonu z kamerą IP", "kpl",
     Decimal("4.00"), Decimal("0"), Decimal("0")),

    # ── Rusztowania ───────────────────────────────────────────────────────────
    ("KNR 2-02", "1201-01", "Rusztowanie ramowe zewnętrzne montaż + demontaż", "m2",
     Decimal("0.40"), Decimal("0"), Decimal("0.10")),
    ("KNR 2-02", "1201-02", "Rusztowanie przesuwne wewnętrzne", "m2",
     Decimal("0.20"), Decimal("0"), Decimal("0.05")),

    # ── Izolacje ──────────────────────────────────────────────────────────────
    ("KNR 2-02", "1301-01", "Izolacja przeciwwilgociowa ław i ścian — papa asfaltowa", "m2",
     Decimal("0.30"), Decimal("0"), Decimal("0")),
    ("KNR 2-02", "1301-02", "Izolacja pozioma fundamentów — membrana HDPE", "m2",
     Decimal("0.25"), Decimal("0"), Decimal("0")),
    ("KNR 2-02", "1302-01", "Ocieplenie stropu nad piwnicą wełną mineralną gr.10cm", "m2",
     Decimal("0.35"), Decimal("0"), Decimal("0")),
    ("KNR 2-02", "1302-02", "Ocieplenie podłogi na gruncie styropianem EPS gr.15cm", "m2",
     Decimal("0.28"), Decimal("0"), Decimal("0")),

    # ── Roboty zewnętrzne ─────────────────────────────────────────────────────
    ("KNR 2-02", "1401-01", "Ogrodzenie z siatki stalowej na słupkach", "m",
     Decimal("1.20"), Decimal("0"), Decimal("0.05")),
    ("KNR 2-02", "1401-02", "Brama wjazdowa stalowa dwuskrzydłowa", "szt",
     Decimal("12.00"), Decimal("0"), Decimal("0")),
    ("KNR 2-02", "1402-01", "Utwardzenie terenu kostką brukową betonową 6cm", "m2",
     Decimal("0.65"), Decimal("0"), Decimal("0.10")),
    ("KNR 2-02", "1402-02", "Krawężniki betonowe 15×30cm montaż", "m",
     Decimal("0.40"), Decimal("0"), Decimal("0.05")),
    ("KNR 2-02", "1403-01", "Przyłącze kanalizacyjne PVC dn160 do 10m", "kpl",
     Decimal("8.00"), Decimal("0"), Decimal("1.00")),
    ("KNR 2-02", "1403-02", "Studzienka rewizyjna dn425 betonowa", "szt",
     Decimal("4.00"), Decimal("0"), Decimal("0")),
]


class Command(BaseCommand):
    help = "Seed KNR catalog with common Polish construction positions"

    def add_arguments(self, parser):
        parser.add_argument(
            "--clear",
            action="store_true",
            help="Usuń istniejące dane KNR przed seedowaniem",
        )

    def handle(self, *args, **options):
        if options["clear"]:
            KnrPozycja.objects.all().delete()
            KnrKatalog.objects.all().delete()
            self.stdout.write(self.style.WARNING("Usunięto istniejące dane KNR."))

        # Utwórz katalogi
        katalogi: dict[str, KnrKatalog] = {}
        for kat in KATALOGI:
            obj, created = KnrKatalog.objects.get_or_create(
                kod=kat["kod"],
                defaults={"nazwa": kat["nazwa"]},
            )
            katalogi[kat["kod"]] = obj
            if created:
                self.stdout.write(f"  + Katalog: {kat['kod']}")

        # Utwórz pozycje
        created_count = 0
        for (kat_kod, numer, opis, jm, nr, nm, ns) in POZYCJE:
            kat = katalogi.get(kat_kod)
            if not kat:
                continue
            _, created = KnrPozycja.objects.get_or_create(
                katalog=kat,
                numer=numer,
                defaults={
                    "opis": opis,
                    "jednostka": jm,
                    "naklad_r": nr,
                    "naklad_m": nm,
                    "naklad_s": ns,
                },
            )
            if created:
                created_count += 1

        self.stdout.write(self.style.SUCCESS(
            f"Seed KNR zakończony: {len(katalogi)} katalogów, {created_count} pozycji."
        ))
