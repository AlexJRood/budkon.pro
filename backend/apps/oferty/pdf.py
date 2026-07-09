"""
Generowanie PDF oferty przez reportlab.
Fallback: jeśli reportlab nie zainstalowany — zwraca None i frontend pokazuje podgląd HTML.
"""
from __future__ import annotations
import io
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .models import Oferta

try:
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import cm
    from reportlab.platypus import (
        SimpleDocTemplate, Table, TableStyle, Paragraph,
        Spacer, HRFlowable,
    )
    REPORTLAB_OK = True
    _KOLOR_NAGLOWEK = colors.HexColor('#1B2B3A')
    _KOLOR_AKCENT = colors.HexColor('#FF9800')
    _KOLOR_LINIA = colors.HexColor('#E0E0E0')
    _SZARY = colors.HexColor('#757575')
except ImportError:
    REPORTLAB_OK = False
    _KOLOR_NAGLOWEK = _KOLOR_AKCENT = _KOLOR_LINIA = _SZARY = None


def generuj_pdf(oferta: 'Oferta') -> bytes | None:
    if not REPORTLAB_OK:
        return None

    buf = io.BytesIO()
    doc = SimpleDocTemplate(
        buf,
        pagesize=A4,
        leftMargin=2 * cm,
        rightMargin=2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
        title=oferta.tytul,
        author=oferta.wystawca_nazwa,
    )

    styles = getSampleStyleSheet()
    bold = ParagraphStyle('bold', parent=styles['Normal'],
                          fontName='Helvetica-Bold')
    small = ParagraphStyle('small', parent=styles['Normal'],
                           fontSize=8, textColor=_SZARY)
    heading = ParagraphStyle('heading', parent=styles['Heading1'],
                             textColor=_KOLOR_NAGLOWEK, fontSize=18)
    sub = ParagraphStyle('sub', parent=styles['Normal'],
                         textColor=_SZARY, fontSize=9)

    story = []

    # ── Nagłówek z numerem ──────────────────────────────────────────────────
    story.append(Paragraph(f'OFERTA {oferta.numer}', heading))
    story.append(HRFlowable(width='100%', color=_KOLOR_AKCENT, thickness=2))
    story.append(Spacer(1, 0.4 * cm))

    # ── Dwie kolumny: Wystawca | Klient ─────────────────────────────────────
    wystawca = [
        [Paragraph('WYSTAWCA', sub)],
        [Paragraph(oferta.wystawca_nazwa or '—', bold)],
        [Paragraph(oferta.wystawca_adres.replace('\n', '<br/>'), styles['Normal'])],
    ]
    if oferta.wystawca_nip:
        wystawca.append([Paragraph(f'NIP: {oferta.wystawca_nip}', small)])
    if oferta.wystawca_email:
        wystawca.append([Paragraph(oferta.wystawca_email, small)])
    if oferta.wystawca_telefon:
        wystawca.append([Paragraph(oferta.wystawca_telefon, small)])

    klient = [
        [Paragraph('KLIENT', sub)],
        [Paragraph(oferta.klient_nazwa or '—', bold)],
        [Paragraph(oferta.klient_adres.replace('\n', '<br/>'), styles['Normal'])],
    ]
    if oferta.klient_nip:
        klient.append([Paragraph(f'NIP: {oferta.klient_nip}', small)])
    if oferta.klient_email:
        klient.append([Paragraph(oferta.klient_email, small)])
    if oferta.klient_telefon:
        klient.append([Paragraph(oferta.klient_telefon, small)])

    header_data = [[
        Table(wystawca, colWidths=['100%']),
        Table(klient, colWidths=['100%']),
    ]]
    header_table = Table(header_data, colWidths=[8.5 * cm, 8.5 * cm])
    header_table.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 0),
        ('RIGHTPADDING', (0, 0), (-1, -1), 0),
    ]))
    story.append(header_table)
    story.append(Spacer(1, 0.4 * cm))

    # Daty
    meta_rows = [
        ['Data wystawienia:', str(oferta.data_wystawienia)],
    ]
    if oferta.wazna_do:
        meta_rows.append(['Ważna do:', str(oferta.wazna_do)])
    meta_t = Table(meta_rows, colWidths=[4 * cm, 6 * cm])
    meta_t.setStyle(TableStyle([
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('TEXTCOLOR', (0, 0), (-1, -1), _SZARY),
        ('LEFTPADDING', (0, 0), (-1, -1), 0),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
    ]))
    story.append(meta_t)

    if oferta.wstep:
        story.append(Spacer(1, 0.4 * cm))
        story.append(Paragraph(oferta.wstep, styles['Normal']))

    story.append(Spacer(1, 0.6 * cm))

    # ── Pozycje ─────────────────────────────────────────────────────────────
    for dzial_data in oferta.pozycje:
        dzial_nazwa = dzial_data.get('dzial', '')
        pozycje = dzial_data.get('pozycje', [])

        if dzial_nazwa:
            story.append(Paragraph(dzial_nazwa, bold))
            story.append(Spacer(1, 0.15 * cm))

        # Tabela pozycji
        naglowek = ['Lp.', 'Opis', 'Jedn.', 'Ilość', 'Cena j.', 'Wartość']
        rows = [naglowek]
        for i, p in enumerate(pozycje, 1):
            rows.append([
                str(i),
                Paragraph(p.get('opis', ''), styles['Normal']),
                p.get('jednostka', ''),
                f"{p.get('ilosc', 0):.2f}",
                f"{p.get('cena_jednostkowa', 0):.2f}",
                f"{p.get('wartosc', 0):.2f}",
            ])

        col_w = [0.8 * cm, 8.2 * cm, 1.5 * cm, 1.5 * cm, 2 * cm, 2.5 * cm]
        t = Table(rows, colWidths=col_w)
        t.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), _KOLOR_NAGLOWEK),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 8),
            ('ALIGN', (3, 0), (-1, -1), 'RIGHT'),
            ('GRID', (0, 0), (-1, -1), 0.3, _KOLOR_LINIA),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#FAFAFA')]),
            ('LEFTPADDING', (0, 0), (-1, -1), 4),
            ('RIGHTPADDING', (0, 0), (-1, -1), 4),
            ('TOPPADDING', (0, 0), (-1, -1), 3),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ]))
        story.append(t)
        story.append(Spacer(1, 0.4 * cm))

    # ── Podsumowanie ────────────────────────────────────────────────────────
    story.append(HRFlowable(width='100%', color=_KOLOR_LINIA))
    story.append(Spacer(1, 0.2 * cm))

    suma_rows = [
        ['Wartość netto:', f'{float(oferta.wartosc_netto):.2f} PLN'],
    ]
    if float(oferta.rabat_procent) > 0:
        suma_rows.append([
            f'Rabat ({oferta.rabat_procent}%):',
            f'-{float(oferta.wartosc_netto) * float(oferta.rabat_procent) / 100:.2f} PLN',
        ])
    suma_rows.append([f'VAT ({oferta.vat_procent}%):', f'{float(oferta.wartosc_vat):.2f} PLN'])
    suma_rows.append(['Wartość brutto:', f'{float(oferta.wartosc_brutto):.2f} PLN'])

    suma_t = Table(suma_rows, colWidths=[4 * cm, 4 * cm],
                   hAlign='RIGHT')
    suma_t.setStyle(TableStyle([
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
        ('TEXTCOLOR', (0, -1), (-1, -1), _KOLOR_AKCENT),
        ('FONTSIZE', (0, -1), (-1, -1), 11),
        ('TOPPADDING', (0, -1), (-1, -1), 6),
        ('LINEABOVE', (0, -1), (-1, -1), 1, _KOLOR_AKCENT),
    ]))
    story.append(suma_t)

    # ── Warunki / uwagi ─────────────────────────────────────────────────────
    if oferta.warunki or oferta.uwagi:
        story.append(Spacer(1, 0.8 * cm))
        if oferta.warunki:
            story.append(Paragraph('Warunki oferty', bold))
            story.append(Paragraph(oferta.warunki, styles['Normal']))
        if oferta.uwagi:
            story.append(Spacer(1, 0.3 * cm))
            story.append(Paragraph('Uwagi', bold))
            story.append(Paragraph(oferta.uwagi, styles['Normal']))

    # Stopka — podpis
    story.append(Spacer(1, 1.5 * cm))
    podpis_t = Table(
        [['', ''], ['', ''], ['_' * 30, ''], ['Podpis wystawcy', '']],
        colWidths=[9 * cm, 8 * cm],
    )
    podpis_t.setStyle(TableStyle([
        ('FONTSIZE', (0, 0), (-1, -1), 8),
        ('TEXTCOLOR', (0, 0), (-1, -1), _SZARY),
    ]))
    story.append(podpis_t)

    doc.build(story)
    return buf.getvalue()
