import os
from PIL import Image, ImageDraw, ImageFont

def generate_store_assets():
    out_dir = "store_assets"
    os.makedirs(out_dir, exist_ok=True)

    font_bold_path = "C:/Windows/Fonts/segoeuib.ttf"
    font_reg_path = "C:/Windows/Fonts/segoeui.ttf"

    base_icon_path = "assets/icon/app_icon.png"
    if os.path.exists(base_icon_path):
        base_icon = Image.open(base_icon_path).convert("RGBA")
        icon_512 = base_icon.resize((512, 512), Image.Resampling.LANCZOS)
        icon_512.save(os.path.join(out_dir, "icon_512.png"), "PNG")
        print("Generated icon_512.png")

    # Feature Graphic 1024x500
    w_feat, h_feat = 1024, 500
    feat_img = Image.new("RGBA", (w_feat, h_feat), (11, 15, 25, 255))
    feat_draw = ImageDraw.Draw(feat_img)

    for x in range(w_feat):
        ratio = x / w_feat
        r = int(11 + (22 - 11) * ratio)
        g = int(15 + (31 - 15) * ratio)
        b = int(25 + (48 - 25) * ratio)
        feat_draw.line([(x, 0), (x, h_feat)], fill=(r, g, b, 255))

    if os.path.exists(base_icon_path):
        icon_for_feat = Image.open(base_icon_path).convert("RGBA").resize(
            (310, 310), Image.Resampling.LANCZOS
        )
        feat_img.paste(icon_for_feat, (85, 95), icon_for_feat)

    f_badge = ImageFont.truetype(font_bold_path, 16)
    f_title = ImageFont.truetype(font_bold_path, 48)
    f_sub = ImageFont.truetype(font_reg_path, 22)
    f_tag = ImageFont.truetype(font_bold_path, 14)

    tx = 440
    feat_draw.rounded_rectangle(
        [tx, 92, tx + 420, 128],
        radius=18,
        fill=(16, 185, 129, 40),
        outline=(16, 185, 129, 200),
        width=2,
    )
    feat_draw.text(
        (tx + 16, 100),
        "FOTOMETRÍA BOTÁNICA • PPFD / DLI & EV",
        font=f_badge,
        fill=(16, 185, 129, 255),
    )
    feat_draw.text((tx, 145), "LUXPLANT PRO", font=f_title, fill=(248, 250, 252, 255))
    feat_draw.text(
        (tx, 212),
        "Luxómetro en Vivo • PPFD & DLI para 16+ Plantas",
        font=f_sub,
        fill=(203, 213, 225, 255),
    )
    feat_draw.text(
        (tx, 244),
        "Exposímetro EV • Auditoría EN 12464-1 & Reportes PDF",
        font=f_sub,
        fill=(245, 158, 11, 255),
    )

    chips = ["PPFD & DLI", "16+ PLANTAS", "PHOTO EV/ISO", "EN 12464-1 / OSHA", "PDF FIRMADO"]
    cx_chip = tx
    cy_chip = 310
    for c in chips:
        bbox = f_tag.getbbox(c)
        tw = bbox[2] - bbox[0] + 24
        feat_draw.rounded_rectangle(
            [cx_chip, cy_chip, cx_chip + tw, cy_chip + 34],
            radius=8,
            fill=(22, 31, 48, 255),
            outline=(45, 60, 82, 255),
            width=1,
        )
        feat_draw.text(
            (cx_chip + 12, cy_chip + 8), c, font=f_tag, fill=(148, 163, 184, 255)
        )
        cx_chip += tw + 10
        if cx_chip > 930:
            cx_chip = tx
            cy_chip += 44

    feat_img.save(os.path.join(out_dir, "feature_graphic_1024x500.png"), "PNG")
    print("Generated feature_graphic_1024x500.png")

    def create_mockup(filename, tag, title, subtitle, accent, body_lines):
        w, h = 1080, 1920
        img = Image.new("RGBA", (w, h), (11, 15, 25, 255))
        draw = ImageDraw.Draw(img)

        f_top_tag = ImageFont.truetype(font_bold_path, 28)
        f_top_title = ImageFont.truetype(font_bold_path, 58)
        f_top_sub = ImageFont.truetype(font_reg_path, 32)
        f_card_h = ImageFont.truetype(font_bold_path, 36)
        f_card_b = ImageFont.truetype(font_reg_path, 26)

        draw.text((70, 85), tag.upper(), font=f_top_tag, fill=accent)
        draw.text((70, 130), title, font=f_top_title, fill=(248, 250, 252, 255))
        draw.text((70, 210), subtitle, font=f_top_sub, fill=(148, 163, 184, 255))

        p_left, p_top, p_right, p_bottom = 80, 300, 1000, 1850
        draw.rounded_rectangle(
            [p_left, p_top, p_right, p_bottom],
            radius=52,
            fill=(22, 31, 48, 255),
            outline=accent,
            width=4,
        )
        y_cursor = p_top + 80
        for heading, desc in body_lines:
            draw.rounded_rectangle(
                [p_left + 40, y_cursor, p_right - 40, y_cursor + 260],
                radius=24,
                fill=(11, 15, 25, 255),
                outline=(45, 60, 82, 255),
                width=2,
            )
            draw.text(
                (p_left + 75, y_cursor + 40),
                heading,
                font=f_card_h,
                fill=accent,
            )
            draw.text(
                (p_left + 75, y_cursor + 115),
                desc,
                font=f_card_b,
                fill=(203, 213, 225, 255),
            )
            y_cursor += 300

        img.save(os.path.join(out_dir, filename), "PNG")
        print(f"Generated {filename}")

    create_mockup(
        "1_pantalla_bienvenida.png",
        "100% Pro Desbloqueado",
        "Laboratorio Lumínico & Botánico",
        "Interfaz Obsidian Dark para invernaderos y estudios",
        (16, 185, 129, 255),
        [
            ("LUXPLANT PRO v1.0", "Fotometría en vivo (Lux / Foot-Candles)"),
            ("CATÁLOGO DE 16+ PLANTAS", "Monstera, Ficus, Orquídea, Suculentas, Pothos"),
            ("MODO OFFLINE-FIRST", "Cero suscripciones • Cero telemetría externa"),
            ("TRILINGÜE INSTANTÁNEO", "Cambio 1-Tap entre Español, Inglés y Portugués"),
        ],
    )

    create_mockup(
        "2_botanica_ppfd_dli.png",
        "Cálculo PAR Fotosintético",
        "Medidor PPFD & DLI en Vivo",
        "Ajuste por espectro solar, LED blanco o Grow Light",
        (16, 185, 129, 255),
        [
            ("4,200 LUX  |  390.2 FC", "Sensor óptico activo + Slider manual 0–50,000 lx"),
            ("PPFD: 69.3 µmol/m²/s", "Espectro LED Hortícola Full-Spectrum"),
            ("DLI: 2.99 mol/m²/día", "Fotoperíodo configurado: 12.0 horas/día"),
            ("MONSTERA DELICIOSA: ÓPTIMO", "Rango ideal: 2,000 a 10,000 Lux (Salud 96%)"),
        ],
    )

    create_mockup(
        "3_fotografia_ev_normativa.png",
        "Cine & Seguridad Industrial",
        "Exposímetro EV & Norma EN 12464",
        "Velocidad de obturación y cumplimiento OSHA",
        (245, 158, 11, 255),
        [
            ("EXPOSÍMETRO EV100: 10.7 EV", "ISO 100 • f/2.8 -> Obturación rec: 1/250 s"),
            ("OFICINA & CAD (500 LX)", "Cumple EN 12464-1 §5.26.2 (+64.0% sobre norma)"),
            ("LABORATORIO FINO (1000 LX)", "Verificación UGR <= 16 y CRI Ra >= 90"),
            ("8 ZONAS NORMATIVAS", "Aulas, Hospitales, Almacenes y Talleres"),
        ],
    )

    create_mockup(
        "4_reporte_pdf_firmado.png",
        "Memorias Técnicas A4",
        "Reportes PDF con Firma Digital",
        "Exportación formal lista para clientes e inspectores",
        (16, 185, 129, 255),
        [
            ("AUDITORÍA #LP-2401", "Tabla completa de Lux, FC, PPFD, DLI y EV100"),
            ("DIAGNÓSTICO BOTÁNICO", "Especie evaluada, fotoperíodo y estado de salud"),
            ("VEREDICTO EN 12464-1 / OSHA", "Certificación de iluminancia en puesto de trabajo"),
            ("FIRMA MANUSCRITA EN PANTALLA", "Lienzo táctil integrado con exportación directa PDF"),
        ],
    )

if __name__ == "__main__":
    generate_store_assets()
