import 'dart:math' as math;

enum LightSpectrum {
  sunlight('specSunlight', 0.0185, '6500K Daylight'),
  ledWhite('specLedWhite', 0.0150, '4000K White LED'),
  growLightFull('specGrowFull', 0.0165, 'Full-Spectrum Horticulture'),
  growLightRedBlue('specGrowRedBlue', 0.0220, 'PAR Red/Blue 450/660nm'),
  hps('specHps', 0.0122, '2100K High Pressure Sodium');

  final String labelKey;
  final double ppfdFactorPerLux;
  final String technicalCode;

  const LightSpectrum(
      this.labelKey, this.ppfdFactorPerLux, this.technicalCode);
}

enum PlantHealthStatus { low, optimal, high }

class PlantSpecies {
  final String id;
  final Map<String, String> commonNames;
  final String scientificName;
  final double minLux;
  final double optimalMinLux;
  final double optimalMaxLux;
  final double maxLux;
  final double minPpfd;
  final double optimalPpfd;
  final double optimalDliMin;
  final double optimalDliMax;
  final Map<String, String> careTip;

  const PlantSpecies({
    required this.id,
    required this.commonNames,
    required this.scientificName,
    required this.minLux,
    required this.optimalMinLux,
    required this.optimalMaxLux,
    required this.maxLux,
    required this.minPpfd,
    required this.optimalPpfd,
    required this.optimalDliMin,
    required this.optimalDliMax,
    required this.careTip,
  });

  String nameFor(String lang) =>
      commonNames[lang] ?? commonNames['es'] ?? scientificName;

  String tipFor(String lang) => careTip[lang] ?? careTip['es'] ?? '';
}

class PlantEvaluationResult {
  final PlantSpecies plant;
  final double measuredLux;
  final double ppfd;
  final double dli;
  final PlantHealthStatus status;
  final double healthScore;

  const PlantEvaluationResult({
    required this.plant,
    required this.measuredLux,
    required this.ppfd,
    required this.dli,
    required this.status,
    required this.healthScore,
  });
}

class WorkspaceNormZone {
  final String id;
  final Map<String, String> names;
  final double minLux;
  final double optimalLux;
  final String standardRef;
  final double ugrLimit;
  final int minCriRa;

  const WorkspaceNormZone({
    required this.id,
    required this.names,
    required this.minLux,
    required this.optimalLux,
    required this.standardRef,
    required this.ugrLimit,
    required this.minCriRa,
  });

  String nameFor(String lang) => names[lang] ?? names['es'] ?? id;
}

class WorkspaceComplianceResult {
  final WorkspaceNormZone zone;
  final double measuredLux;
  final bool isCompliant;
  final bool isOptimal;
  final double marginPercent;
  final double deficitLux;

  const WorkspaceComplianceResult({
    required this.zone,
    required this.measuredLux,
    required this.isCompliant,
    required this.isOptimal,
    required this.marginPercent,
    required this.deficitLux,
  });
}

class PhotoExposureResult {
  final double lux;
  final double ev100;
  final double evAtIso;
  final int iso;
  final double apertureF;
  final double shutterSeconds;
  final String formattedShutter;

  const PhotoExposureResult({
    required this.lux,
    required this.ev100,
    required this.evAtIso,
    required this.iso,
    required this.apertureF,
    required this.shutterSeconds,
    required this.formattedShutter,
  });
}

class LightCalculator {
  static const double _luxToFcFactor = 0.09290304;

  /// Converts Illuminance in Lux (lm/m²) to Foot-Candles (lm/ft²).
  static double luxToFootCandles(double lux) {
    if (lux <= 0) return 0.0;
    return lux * _luxToFcFactor;
  }

  /// Converts Foot-Candles to Illuminance in Lux.
  static double footCandlesToLux(double fc) {
    if (fc <= 0) return 0.0;
    return fc / _luxToFcFactor;
  }

  /// Calculates Photosynthetic Photon Flux Density (PPFD) in µmol/m²/s.
  static double calculatePpfd(double lux, LightSpectrum spectrum) {
    if (lux <= 0) return 0.0;
    return lux * spectrum.ppfdFactorPerLux;
  }

  /// Calculates Daily Light Integral (DLI) in mol/m²/day.
  /// Formula: PPFD (µmol/m²/s) * photoperiod (h) * 3600 (s/h) / 1,000,000 (µmol/mol)
  static double calculateDli(double ppfd, double photoperiodHours) {
    if (ppfd <= 0 || photoperiodHours <= 0) return 0.0;
    final clampedHours = photoperiodHours.clamp(0.0, 24.0);
    return ppfd * clampedHours * 0.0036;
  }

  /// Evaluates plant health match against species thresholds.
  static PlantEvaluationResult evaluatePlant({
    required double lux,
    required LightSpectrum spectrum,
    required double photoperiodHours,
    required PlantSpecies plant,
  }) {
    final ppfd = calculatePpfd(lux, spectrum);
    final dli = calculateDli(ppfd, photoperiodHours);

    PlantHealthStatus status;
    double score;

    if (lux < plant.minLux) {
      status = PlantHealthStatus.low;
      score = plant.minLux > 0 ? (lux / plant.minLux * 55.0).clamp(5.0, 55.0) : 0.0;
    } else if (lux > plant.maxLux) {
      status = PlantHealthStatus.high;
      final excessRatio = (lux - plant.maxLux) / plant.maxLux;
      score = (70.0 - excessRatio * 50.0).clamp(15.0, 70.0);
    } else if (lux >= plant.optimalMinLux && lux <= plant.optimalMaxLux) {
      status = PlantHealthStatus.optimal;
      final mid = (plant.optimalMinLux + plant.optimalMaxLux) / 2.0;
      final halfSpan = (plant.optimalMaxLux - plant.optimalMinLux) / 2.0;
      final dist = halfSpan > 0 ? ((lux - mid).abs() / halfSpan) : 0.0;
      score = (100.0 - dist * 12.0).clamp(88.0, 100.0);
    } else {
      status = PlantHealthStatus.optimal;
      score = 78.0;
    }

    return PlantEvaluationResult(
      plant: plant,
      measuredLux: lux,
      ppfd: ppfd,
      dli: dli,
      status: status,
      healthScore: score,
    );
  }

  /// Calculates Exposure Value at ISO 100 (EV100) from incident illuminance in Lux.
  /// Standard calibration equation: E = 2.5 * 2^(EV100) => EV100 = log2(Lux / 2.5)
  static double calculateEv100(double lux) {
    final safeLux = math.max(lux, 0.25);
    return math.log(safeLux / 2.5) / math.ln2;
  }

  /// Calculates effective Exposure Value at a given ISO sensitivity.
  static double calculateEvAtIso(double lux, int iso) {
    final safeIso = math.max(iso, 25);
    final ev100 = calculateEv100(lux);
    return ev100 + (math.log(safeIso / 100.0) / math.ln2);
  }

  /// Calculates full photographic exposure parameters.
  static PhotoExposureResult calculatePhotoExposure({
    required double lux,
    required int iso,
    required double apertureF,
  }) {
    final ev100 = calculateEv100(lux);
    final evIso = calculateEvAtIso(lux, iso);
    // N^2 / t = 2^EV => t = N^2 / 2^EV
    final shutterSeconds = (apertureF * apertureF) / math.pow(2.0, evIso);
    return PhotoExposureResult(
      lux: lux,
      ev100: ev100,
      evAtIso: evIso,
      iso: iso,
      apertureF: apertureF,
      shutterSeconds: shutterSeconds,
      formattedShutter: formatShutterSpeed(shutterSeconds),
    );
  }

  /// Formats shutter speed in standard fractional or decimal seconds.
  static String formatShutterSpeed(double seconds) {
    if (seconds >= 1.0) {
      return '${seconds.toStringAsFixed(1)} s';
    }
    if (seconds >= 0.3) {
      return '${seconds.toStringAsFixed(2)} s';
    }
    final reciprocal = (1.0 / seconds).round();
    const standardDenominators = [
      4,
      8,
      15,
      30,
      60,
      125,
      250,
      500,
      1000,
      2000,
      4000,
      8000
    ];
    int closest = standardDenominators.first;
    int minDiff = (reciprocal - closest).abs();
    for (final d in standardDenominators) {
      final diff = (reciprocal - d).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = d;
      }
    }
    return '1/$closest s';
  }

  /// Returns a localized description of the photographic scene brightness.
  static String describeScene(double lux, String lang) {
    if (lux < 20) {
      return lang == 'en'
          ? 'Night / Dim Ambient (Tripod Required)'
          : lang == 'pt'
              ? 'Noite / Penumbra (Requer Tripé)'
              : 'Noche / Penumbra (Requiere Trípode)';
    } else if (lux < 250) {
      return lang == 'en'
          ? 'Domestic Indoor / Moody Studio'
          : lang == 'pt'
              ? 'Interior Residencial / Estúdio Suave'
              : 'Interior Residencial / Estudio Suave';
    } else if (lux < 1200) {
      return lang == 'en'
          ? 'Bright Office / Commercial Studio Lighting'
          : lang == 'pt'
              ? 'Escritório Iluminado / Estúdio Comercial'
              : 'Oficina Iluminada / Estudio Comercial';
    } else if (lux < 10000) {
      return lang == 'en'
          ? 'Overcast Daylight / Bright Greenhouse'
          : lang == 'pt'
              ? 'Dia Nublado / Estufa Iluminada'
              : 'Día Nublado / Invernadero Luminoso';
    } else {
      return lang == 'en'
          ? 'Direct Sunlight / High Exterior EV'
          : lang == 'pt'
              ? 'Luz Solar Direta / Exterior Alto EV'
              : 'Luz Solar Directa / Exterior Alto EV';
    }
  }

  /// Evaluates workplace illuminance against EN 12464-1 / OSHA thresholds.
  static WorkspaceComplianceResult evaluateWorkspaceCompliance(
    double measuredLux,
    WorkspaceNormZone zone,
  ) {
    final isCompliant = measuredLux >= zone.minLux;
    final isOptimal = measuredLux >= zone.optimalLux;
    final marginPercent = zone.minLux > 0
        ? ((measuredLux - zone.minLux) / zone.minLux) * 100.0
        : 0.0;
    final deficitLux =
        measuredLux < zone.minLux ? (zone.minLux - measuredLux) : 0.0;

    return WorkspaceComplianceResult(
      zone: zone,
      measuredLux: measuredLux,
      isCompliant: isCompliant,
      isOptimal: isOptimal,
      marginPercent: marginPercent,
      deficitLux: deficitLux,
    );
  }

  /// Built-in normative workspace zones (EN 12464-1 & OSHA 1910/1926).
  static const List<WorkspaceNormZone> workspaceZones = [
    WorkspaceNormZone(
      id: 'office_desk',
      names: {
        'es': 'Oficina General / Escritorio CAD & PC (500 lx)',
        'en': 'General Office / PC & Desk Work (500 lx)',
        'pt': 'Escritório Geral / Estação PC & Leitura (500 lx)',
      },
      minLux: 500,
      optimalLux: 750,
      standardRef: 'EN 12464-1 §5.26.2 / ISO 8995-1',
      ugrLimit: 19,
      minCriRa: 80,
    ),
    WorkspaceNormZone(
      id: 'technical_drawing',
      names: {
        'es': 'Dibujo Técnico / Inspección de Color (750 lx)',
        'en': 'Technical Drawing / Architecture Station (750 lx)',
        'pt': 'Desenho Técnico / Mesa de Projeto (750 lx)',
      },
      minLux: 750,
      optimalLux: 1000,
      standardRef: 'EN 12464-1 §5.26.3',
      ugrLimit: 16,
      minCriRa: 90,
    ),
    WorkspaceNormZone(
      id: 'electronics_lab',
      names: {
        'es': 'Laboratorio / Ensamblaje Electrónico Fino (1000 lx)',
        'en': 'Precision Electronics / Lab Assembly (1000 lx)',
        'pt': 'Laboratório / Montagem Eletrônica Fina (1000 lx)',
      },
      minLux: 1000,
      optimalLux: 1500,
      standardRef: 'EN 12464-1 §5.10 / OSHA 1910',
      ugrLimit: 16,
      minCriRa: 90,
    ),
    WorkspaceNormZone(
      id: 'classroom_study',
      names: {
        'es': 'Aula Educativa / Sala de Capacitación (300 lx)',
        'en': 'Classroom / Training & Study Room (300 lx)',
        'pt': 'Sala de Aula / Treinamento (300 lx)',
      },
      minLux: 300,
      optimalLux: 500,
      standardRef: 'EN 12464-1 §5.36.1',
      ugrLimit: 19,
      minCriRa: 80,
    ),
    WorkspaceNormZone(
      id: 'workshop_mech',
      names: {
        'es': 'Taller Mecánico / Maquinado Medio (300 lx)',
        'en': 'Mechanical Workshop / Bench Work (300 lx)',
        'pt': 'Oficina Mecânica / Bancada Industrial (300 lx)',
      },
      minLux: 300,
      optimalLux: 500,
      standardRef: 'EN 12464-1 §5.18 / OSHA 1926.56',
      ugrLimit: 22,
      minCriRa: 80,
    ),
    WorkspaceNormZone(
      id: 'warehouse_aisle',
      names: {
        'es': 'Almacén Logístico / Pasillo de Picking (150 lx)',
        'en': 'Warehouse Logistics / Picking Aisle (150 lx)',
        'pt': 'Armazém Logístico / Corredor de Picking (150 lx)',
      },
      minLux: 150,
      optimalLux: 250,
      standardRef: 'EN 12464-1 §5.31 / OSHA 1926.56',
      ugrLimit: 25,
      minCriRa: 60,
    ),
    WorkspaceNormZone(
      id: 'hospital_exam',
      names: {
        'es': 'Consultorio Médico / Sala de Examen (500 lx)',
        'en': 'Medical Examination / Clinic Room (500 lx)',
        'pt': 'Consultório Médico / Sala de Exame (500 lx)',
      },
      minLux: 500,
      optimalLux: 1000,
      standardRef: 'EN 12464-1 §5.41',
      ugrLimit: 19,
      minCriRa: 90,
    ),
    WorkspaceNormZone(
      id: 'corridor_ circulation',
      names: {
        'es': 'Pasillo de Circulación / Escalera (100 lx)',
        'en': 'Circulation Corridor / Stairway (100 lx)',
        'pt': 'Corredor de Circulação / Escadaria (100 lx)',
      },
      minLux: 100,
      optimalLux: 150,
      standardRef: 'EN 12464-1 §5.1.1 / OSHA 1926.56',
      ugrLimit: 28,
      minCriRa: 40,
    ),
  ];

  /// Built-in catalog of 16 indoor plants with scientific Lux, PPFD and DLI thresholds.
  static const List<PlantSpecies> plantCatalog = [
    PlantSpecies(
      id: 'monstera',
      commonNames: {
        'es': 'Monstera Deliciosa (Costilla de Adán)',
        'en': 'Monstera Deliciosa (Swiss Cheese Plant)',
        'pt': 'Monstera Deliciosa (Costela-de-Adão)',
      },
      scientificName: 'Monstera deliciosa',
      minLux: 800,
      optimalMinLux: 2000,
      optimalMaxLux: 10000,
      maxLux: 18000,
      minPpfd: 15,
      optimalPpfd: 90,
      optimalDliMin: 4.0,
      optimalDliMax: 12.0,
      careTip: {
        'es': 'Requiere luz brillante indirecta para desarrollar fenestraciones en las hojas.',
        'en': 'Requires bright indirect light to develop leaf fenestrations.',
        'pt': 'Requer luz brilhante indireta para desenvolver fenestrações nas folhas.',
      },
    ),
    PlantSpecies(
      id: 'ficus_lyrata',
      commonNames: {
        'es': 'Ficus Lyrata (Higuera Hoja de Violín)',
        'en': 'Fiddle Leaf Fig (Ficus Lyrata)',
        'pt': 'Ficus Lyrata (Figueira-Lira)',
      },
      scientificName: 'Ficus lyrata',
      minLux: 1500,
      optimalMinLux: 3500,
      optimalMaxLux: 15000,
      maxLux: 25000,
      minPpfd: 30,
      optimalPpfd: 140,
      optimalDliMin: 6.0,
      optimalDliMax: 16.0,
      careTip: {
        'es': 'Ubicar junto a ventana luminosa; girar 90° cada 2 semanas para crecimiento simétrico.',
        'en': 'Place near a bright window; rotate 90° every 2 weeks for even canopy growth.',
        'pt': 'Posicionar próximo a janela iluminada; girar 90° a cada 2 semanas.',
      },
    ),
    PlantSpecies(
      id: 'orchid_phalaenopsis',
      commonNames: {
        'es': 'Orquídea Mariposa (Phalaenopsis)',
        'en': 'Moth Orchid (Phalaenopsis)',
        'pt': 'Orquídea Borboleta (Phalaenopsis)',
      },
      scientificName: 'Phalaenopsis Blume',
      minLux: 1000,
      optimalMinLux: 2200,
      optimalMaxLux: 8500,
      maxLux: 14000,
      minPpfd: 20,
      optimalPpfd: 85,
      optimalDliMin: 4.5,
      optimalDliMax: 10.0,
      careTip: {
        'es': 'Luz filtrada constante fomenta la floración sin quemar las hojas carnosas.',
        'en': 'Consistent filtered light promotes blooming without scorching fleshy leaves.',
        'pt': 'Luz filtrada constante estimula a floração sem queimar as folhas.',
      },
    ),
    PlantSpecies(
      id: 'pothos',
      commonNames: {
        'es': 'Pothos Dorado (Epipremnum Aureum)',
        'en': 'Golden Pothos (Devil\'s Ivy)',
        'pt': 'Jiboia Dourada (Epipremnum Aureum)',
      },
      scientificName: 'Epipremnum aureum',
      minLux: 400,
      optimalMinLux: 1200,
      optimalMaxLux: 6500,
      maxLux: 12000,
      minPpfd: 8,
      optimalPpfd: 55,
      optimalDliMin: 2.0,
      optimalDliMax: 8.0,
      careTip: {
        'es': 'Tolera sombra media, pero mantiene su variegación dorada por encima de 1,200 Lux.',
        'en': 'Tolerates low light, but keeps golden variegation above 1,200 Lux.',
        'pt': 'Tolera meia-sombra, mas mantém a variegação dourada acima de 1.200 Lux.',
      },
    ),
    PlantSpecies(
      id: 'sansevieria',
      commonNames: {
        'es': 'Sansevieria (Lengua de Suegra)',
        'en': 'Snake Plant (Dracaena Trifasciata)',
        'pt': 'Espada-de-São-Jorge (Sansevieria)',
      },
      scientificName: 'Dracaena trifasciata',
      minLux: 300,
      optimalMinLux: 1000,
      optimalMaxLux: 8000,
      maxLux: 20000,
      minPpfd: 6,
      optimalPpfd: 60,
      optimalDliMin: 2.0,
      optimalDliMax: 10.0,
      careTip: {
        'es': 'Metabolismo CAM ultra resistente; evita riego excesivo en ambientes de baja luz.',
        'en': 'Resilient CAM metabolism; avoid overwatering in low-light rooms.',
        'pt': 'Metabolismo CAM ultra resistente; evite rega excessiva em baixa luz.',
      },
    ),
    PlantSpecies(
      id: 'succulent_echeveria',
      commonNames: {
        'es': 'Suculenta Roseta (Echeveria Elegans)',
        'en': 'Echeveria Succulent (Mexican Snowball)',
        'pt': 'Suculenta Echeveria (Rosa-de-Pedra)',
      },
      scientificName: 'Echeveria elegans',
      minLux: 2500,
      optimalMinLux: 6000,
      optimalMaxLux: 25000,
      maxLux: 45000,
      minPpfd: 50,
      optimalPpfd: 250,
      optimalDliMin: 10.0,
      optimalDliMax: 22.0,
      careTip: {
        'es': 'Exige alto DLI diario para evitar el estiramiento (etiolación) del tallo.',
        'en': 'Requires high daily DLI to prevent stem stretching (etiolation).',
        'pt': 'Exige alto DLI diário para evitar o estiolamento do caule.',
      },
    ),
    PlantSpecies(
      id: 'calathea',
      commonNames: {
        'es': 'Calathea Orbifolia (Planta de Oración)',
        'en': 'Calathea Orbifolia (Prayer Plant)',
        'pt': 'Calathea Orbifolia (Maranta)',
      },
      scientificName: 'Goeppertia orbifolia',
      minLux: 600,
      optimalMinLux: 1200,
      optimalMaxLux: 4500,
      maxLux: 8000,
      minPpfd: 12,
      optimalPpfd: 45,
      optimalDliMin: 2.5,
      optimalDliMax: 6.5,
      careTip: {
        'es': 'Sensible al sol directo; superar 5,000 Lux decolora sus franjas plateadas.',
        'en': 'Sensitive to direct sun; exceeding 5,000 Lux fades its silver stripes.',
        'pt': 'Sensível ao sol direto; ultrapassar 5.000 Lux desbota suas listras.',
      },
    ),
    PlantSpecies(
      id: 'zz_plant',
      commonNames: {
        'es': 'Planta ZZ (Zamioculcas Zamiifolia)',
        'en': 'ZZ Plant (Zamioculcas Zamiifolia)',
        'pt': 'Zamioculca (Planta da Fortuna)',
      },
      scientificName: 'Zamioculcas zamiifolia',
      minLux: 250,
      optimalMinLux: 800,
      optimalMaxLux: 5000,
      maxLux: 10000,
      minPpfd: 5,
      optimalPpfd: 40,
      optimalDliMin: 1.5,
      optimalDliMax: 7.0,
      careTip: {
        'es': 'Ideal para oficinas con iluminación LED artificial entre 500 y 2,500 Lux.',
        'en': 'Ideal for offices with artificial LED lighting between 500 and 2,500 Lux.',
        'pt': 'Ideal para escritórios com iluminação LED entre 500 e 2.500 Lux.',
      },
    ),
    PlantSpecies(
      id: 'strelitzia',
      commonNames: {
        'es': 'Ave del Paraíso (Strelitzia Nicolai)',
        'en': 'Bird of Paradise (Strelitzia Nicolai)',
        'pt': 'Ave-do-Paraíso (Strelitzia Nicolai)',
      },
      scientificName: 'Strelitzia nicolai',
      minLux: 2000,
      optimalMinLux: 5000,
      optimalMaxLux: 22000,
      maxLux: 40000,
      minPpfd: 40,
      optimalPpfd: 200,
      optimalDliMin: 8.0,
      optimalDliMax: 20.0,
      careTip: {
        'es': 'Planta heliófila tropical; prospera con alta radiación fotosintética.',
        'en': 'Sun-loving tropical species; thrives under high photosynthetic radiation.',
        'pt': 'Planta tropical heliófila; prospera sob alta radiação fotossintética.',
      },
    ),
    PlantSpecies(
      id: 'philodendron',
      commonNames: {
        'es': 'Filodendro Birkin (Philodendron)',
        'en': 'Philodendron Birkin',
        'pt': 'Filodendro Birkin',
      },
      scientificName: 'Philodendron \'Birkin\'',
      minLux: 700,
      optimalMinLux: 1800,
      optimalMaxLux: 7500,
      maxLux: 13000,
      minPpfd: 14,
      optimalPpfd: 70,
      optimalDliMin: 3.5,
      optimalDliMax: 9.5,
      careTip: {
        'es': 'Luz media-alta preserva las líneas blancas de las hojas nuevas.',
        'en': 'Medium-bright indirect light preserves white pinstripes on new leaves.',
        'pt': 'Luz média-alta preserva as linhas brancas nas folhas novas.',
      },
    ),
    PlantSpecies(
      id: 'peace_lily',
      commonNames: {
        'es': 'Cuna de Moisés / Espatifilo (Peace Lily)',
        'en': 'Peace Lily (Spathiphyllum)',
        'pt': 'Lírio-da-Paz (Spathiphyllum)',
      },
      scientificName: 'Spathiphyllum wallisii',
      minLux: 450,
      optimalMinLux: 1200,
      optimalMaxLux: 5500,
      maxLux: 9500,
      minPpfd: 9,
      optimalPpfd: 50,
      optimalDliMin: 2.0,
      optimalDliMax: 7.5,
      careTip: {
        'es': 'Para inducir espatas blancas florales, mantén al menos 1,500 Lux por 10h.',
        'en': 'To induce white floral spathes, maintain at least 1,500 Lux for 10h.',
        'pt': 'Para induzir flores brancas, mantenha pelo menos 1.500 Lux por 10h.',
      },
    ),
    PlantSpecies(
      id: 'aloe_vera',
      commonNames: {
        'es': 'Aloe Vera (Sábila Medicinal)',
        'en': 'Aloe Vera (Medicinal Aloe)',
        'pt': 'Aloe Vera (Babosa)',
      },
      scientificName: 'Aloe barbadensis miller',
      minLux: 2000,
      optimalMinLux: 4500,
      optimalMaxLux: 18000,
      maxLux: 35000,
      minPpfd: 38,
      optimalPpfd: 170,
      optimalDliMin: 7.0,
      optimalDliMax: 18.0,
      careTip: {
        'es': 'Necesita abundante luz solar indirecta o directa suave de mañana.',
        'en': 'Needs abundant indirect sunlight or gentle morning direct sun.',
        'pt': 'Necessita de bastante luz solar indireta ou sol suave da manhã.',
      },
    ),
    PlantSpecies(
      id: 'boston_fern',
      commonNames: {
        'es': 'Helecho de Boston (Nephrolepis Exaltata)',
        'en': 'Boston Fern (Nephrolepis Exaltata)',
        'pt': 'Samambaia-Americana (Nephrolepis)',
      },
      scientificName: 'Nephrolepis exaltata',
      minLux: 600,
      optimalMinLux: 1500,
      optimalMaxLux: 6000,
      maxLux: 10000,
      minPpfd: 12,
      optimalPpfd: 55,
      optimalDliMin: 3.0,
      optimalDliMax: 8.0,
      careTip: {
        'es': 'Prefiere luz tamizada de sotobosque y humedad ambiental superior al 50%.',
        'en': 'Prefers dappled understory light and ambient humidity above 50%.',
        'pt': 'Prefere luz filtrada de sub-bosque e umidade acima de 50%.',
      },
    ),
    PlantSpecies(
      id: 'anthurium',
      commonNames: {
        'es': 'Anturio Rojo (Anthurium Andraeanum)',
        'en': 'Flamingo Flower (Anthurium Andraeanum)',
        'pt': 'Antúrio Vermelho (Anthurium)',
      },
      scientificName: 'Anthurium andraeanum',
      minLux: 900,
      optimalMinLux: 2000,
      optimalMaxLux: 7000,
      maxLux: 12000,
      minPpfd: 18,
      optimalPpfd: 68,
      optimalDliMin: 3.5,
      optimalDliMax: 9.0,
      careTip: {
        'es': 'Luz cálida e indirecta sostiene brácteas rojas brillantes todo el año.',
        'en': 'Warm indirect light sustains glossy red spathes year-round.',
        'pt': 'Luz indireta sustenta brácteas vermelhas brilhantes o ano todo.',
      },
    ),
    PlantSpecies(
      id: 'jade_plant',
      commonNames: {
        'es': 'Árbol de Jade (Crassula Ovata)',
        'en': 'Jade Plant (Crassula Ovata)',
        'pt': 'Planta-Jade (Crassula Ovata)',
      },
      scientificName: 'Crassula ovata',
      minLux: 2000,
      optimalMinLux: 4500,
      optimalMaxLux: 20000,
      maxLux: 38000,
      minPpfd: 38,
      optimalPpfd: 180,
      optimalDliMin: 8.0,
      optimalDliMax: 18.0,
      careTip: {
        'es': 'Con >8,000 Lux los bordes de las hojas adquieren un atractivo tono rojizo.',
        'en': 'Above 8,000 Lux, leaf margins develop an attractive ruby-red tint.',
        'pt': 'Acima de 8.000 Lux, as bordas das folhas ganham um tom avermelhado.',
      },
    ),
    PlantSpecies(
      id: 'indoor_basil',
      commonNames: {
        'es': 'Albahaca Gourmet Indoor (Ocimum Basilicum)',
        'en': 'Indoor Culinary Basil (Ocimum Basilicum)',
        'pt': 'Manjericão Gourmet Indoor (Ocimum Basilicum)',
      },
      scientificName: 'Ocimum basilicum',
      minLux: 3500,
      optimalMinLux: 8000,
      optimalMaxLux: 28000,
      maxLux: 45000,
      minPpfd: 70,
      optimalPpfd: 280,
      optimalDliMin: 12.0,
      optimalDliMax: 24.0,
      careTip: {
        'es': 'Cultivo aromático exigente; requiere lámpara Grow LED (14-16h) o sol directo.',
        'en': 'High-energy herb; requires Grow LED (14-16h photoperiod) or direct sun.',
        'pt': 'Erva aromática exigente; requer Grow LED (14-16h) ou sol direto.',
      },
    ),
  ];
}
