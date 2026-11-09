# 🚀 Guía Maestra de Publicación en Tiendas: LuxPlant Pro (Google Play & Apple App Store)

Esta guía documenta todos los recursos, activos gráficos y comandos necesarios para publicar **LuxPlant Pro** (`com.simpleappspg.luxplantpro`) bajo el modelo **Camino 1 (Paid App — 100% Pro Desbloqueado)**.

---

## 📦 1. Recursos Generados en el Proyecto

| Recurso | Ubicación | Descripción |
| :--- | :--- | :--- |
| **Generador de Ícono 1024x1024** | `generate_icon.py` | Script Python (Pillow) con diseño Obsidian Dark, hoja esmeralda y dial fotométrico. |
| **Ícono Maestro** | `assets/icon/app_icon.png` | Arte 1024x1024px listo para tiendas y launcher nativo. |
| **Activos de Tienda (Screenshots & Banner)** | `store_assets/` | `icon_512.png`, `feature_graphic_1024x500.png` y 4 capturas promocionales 1080x1920. |
| **Política de Privacidad** | `privacy_policy.html` | Documento HTML autocontenido con arquitectura Offline-First y Zero Data Collection. |

---

## 🤖 2. Ficha de Google Play Store

- **Nombre de la aplicación:** `LuxPlant Pro: Medidor PPFD, DLI & Lux`
- **ID del paquete:** `com.simpleappspg.luxplantpro`
- **Modelo de monetización:** Aplicación de Pago Único (Camino 1 — 100% Pro Desbloqueado, sin anuncios ni suscripciones).
- **Descripción corta (hasta 80 caracteres):**
  > *Luxómetro profesional, PPFD/DLI para 16+ plantas, EV fotográfico y PDF firmado.*
- **Descripción completa:**
  > *LuxPlant Pro es la herramienta de precisión definitiva para agrónomos, viveristas, diseñadores de iluminación, fotógrafos e inspectores de seguridad industrial.*
  >
  > *Características Principales:*
  > • **Fotometría en Vivo y Simulación Manual (0 a 50,000 Lux):** Lectura en tiempo real del sensor óptico nativo con conversión instantánea a Foot-Candles (fc) y calibración de ganancia (0.5x a 2.0x).
  > • **Cálculo Fotosintético PPFD y DLI:** Estimación de flujo de fotones fotosintéticos (µmol/m²/s) e Integral de Luz Diaria (mol/m²/día) según el espectro lumínico (Luz Solar 6500K, LED Blanco 4000K, LED Hortícola Full-Spectrum, PAR Rojo/Azul y HPS).
  > • **Catálogo Botánico de 16 Especies de Interior:** Diagnóstico en vivo para Monstera Deliciosa, Ficus Lyrata, Orquídea Phalaenopsis, Pothos, Sansevieria, Suculentas Echeveria, Calathea, Planta ZZ, Strelitzia, Filodendro, Espatifilo, Aloe Vera, Helecho de Boston, Anturio, Árbol de Jade y Albahaca Indoor.
  > • **Exposímetro Fotográfico y de Cine (EV):** Cálculo de EV₁₀₀, EV efectivo por sensibilidad ISO (50 a 6400) y velocidad de obturación recomendada según apertura de diafragma (f/1.4 a f/16).
  > • **Auditoría Normativa Laboral (EN 12464-1 / OSHA):** Verificación instantánea de niveles mínimos de iluminancia en oficinas, estaciones CAD, laboratorios electrónicos, aulas, consultorios médicos y almacenes.
  > • **Reportes Técnicos en PDF con Firma Digital:** Generación y exportación de memorias A4 firmadas en pantalla, 100% offline.

---

## 🛠️ 3. Comandos de Verificación y Compilación

```bash
# Regenerar ícono y capturas de tienda
python generate_icon.py
dart run flutter_launcher_icons
python generate_store_assets.py

# Ejecutar análisis estático y pruebas
flutter analyze
flutter test

# Compilar Android App Bundle (.aab) de producción
flutter build appbundle --release
```
