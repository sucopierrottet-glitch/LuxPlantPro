# 🌿 LuxPlant Pro (`com.simpleappspg.luxplantpro`)

**Fotometría Botánica PPFD/DLI, Exposímetro EV Fotográfico y Auditoría Normativa EN 12464-1 / OSHA**

Desarrollado bajo el estándar industrial **SimpleAppsPG Obsidian Dark Theme** (`#0B0F19` / `#161F30` / Esmeralda Botánico `#10B981` / Oro Cálido `#F59E0B`), 100% Offline-First, Trilingüe (`ES` / `EN` / `PT`) y **100% Pro Desbloqueado (Camino 1)**.

## ✨ Características Principales

1. **Medidor en Vivo de Lux, Foot-Candles, PPFD y DLI:**
   - Integración nativa con `MethodChannel('com.simpleappspg.sensors/data')` (`getSensorSnapshot` -> `lightLux`) y modo de simulación manual de 0 a 50,000 Lux.
   - Conversión espectral configurable: Luz Solar Natural (6500K), LED Blanco (4000K), LED Hortícola Full-Spectrum, LED PAR Rojo/Azul y Sodio de Alta Presión (HPS).
   - Dial fotométrico radial renderizado con `CustomPainter`.
2. **Catálogo Botánico de 16 Especies de Interior:**
   - Monstera Deliciosa, Ficus Lyrata, Orquídea Phalaenopsis, Pothos Dorado, Sansevieria, Suculenta Echeveria, Calathea Orbifolia, Planta ZZ, Ave del Paraíso (Strelitzia), Filodendro Birkin, Cuna de Moisés (Peace Lily), Aloe Vera, Helecho de Boston, Anturio Rojo, Árbol de Jade y Albahaca Gourmet Indoor.
3. **Calculadora Fotográfica EV & Auditoría Laboral EN 12464-1 / OSHA:**
   - Cálculo de $\text{EV}_{100}$, $\text{EV}_{\text{ISO}}$, ISO (50–6400), apertura ($f/1.4$–$f/16$) y velocidad de obturación.
   - Evaluación de cumplimiento normativo en 8 recintos laborales (Oficina General 500 lx, Dibujo Técnico 750 lx, Laboratorio Electrónico 1000 lx, Aula 300 lx, Taller 300 lx, Almacén 150 lx, Consultorio Médico 500 lx, Pasillo 100 lx).
4. **Auditorías Lumínicas Guardadas y Reportes PDF Firmados:**
   - Persistencia local en `SharedPreferences`, captura de firma manuscrita con `signature` y generación de documentos técnicos A4 con `pdf` y `printing`.
5. **Soporte Trilingüe Instantáneo (1-Tap):**
   - Español (`es`), Inglés (`en`) y Portugués (`pt`) en `lib/l10n/app_strings.dart`.
