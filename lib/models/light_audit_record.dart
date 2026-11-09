import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LightAuditRecord {
  final String id;
  final String title;
  final DateTime timestamp;
  final double lux;
  final double footCandles;
  final double ppfd;
  final double dli;
  final double photoperiodHours;
  final String spectrumName;
  final String plantName;
  final String plantScientificName;
  final String plantStatus;
  final String workspaceZoneName;
  final double workspaceMinLux;
  final bool workspaceCompliant;
  final double ev100;
  final String shutterRecommendation;

  const LightAuditRecord({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.lux,
    required this.footCandles,
    required this.ppfd,
    required this.dli,
    required this.photoperiodHours,
    required this.spectrumName,
    required this.plantName,
    required this.plantScientificName,
    required this.plantStatus,
    required this.workspaceZoneName,
    required this.workspaceMinLux,
    required this.workspaceCompliant,
    required this.ev100,
    required this.shutterRecommendation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'timestamp': timestamp.toIso8601String(),
        'lux': lux,
        'footCandles': footCandles,
        'ppfd': ppfd,
        'dli': dli,
        'photoperiodHours': photoperiodHours,
        'spectrumName': spectrumName,
        'plantName': plantName,
        'plantScientificName': plantScientificName,
        'plantStatus': plantStatus,
        'workspaceZoneName': workspaceZoneName,
        'workspaceMinLux': workspaceMinLux,
        'workspaceCompliant': workspaceCompliant,
        'ev100': ev100,
        'shutterRecommendation': shutterRecommendation,
      };

  factory LightAuditRecord.fromJson(Map<String, dynamic> json) {
    return LightAuditRecord(
      id: json['id'] as String? ?? 'LP-001',
      title: json['title'] as String? ?? 'Invernadero Botánico Sector A',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime(2026, 11, 9, 10, 30),
      lux: (json['lux'] as num?)?.toDouble() ?? 3200.0,
      footCandles: (json['footCandles'] as num?)?.toDouble() ?? 297.3,
      ppfd: (json['ppfd'] as num?)?.toDouble() ?? 59.2,
      dli: (json['dli'] as num?)?.toDouble() ?? 2.56,
      photoperiodHours: (json['photoperiodHours'] as num?)?.toDouble() ?? 12.0,
      spectrumName: json['spectrumName'] as String? ?? 'Full-Spectrum Horticulture',
      plantName: json['plantName'] as String? ?? 'Monstera Deliciosa',
      plantScientificName:
          json['plantScientificName'] as String? ?? 'Monstera deliciosa',
      plantStatus: json['plantStatus'] as String? ?? 'OPTIMAL',
      workspaceZoneName:
          json['workspaceZoneName'] as String? ?? 'Oficina General (500 lx)',
      workspaceMinLux: (json['workspaceMinLux'] as num?)?.toDouble() ?? 500.0,
      workspaceCompliant: json['workspaceCompliant'] as bool? ?? true,
      ev100: (json['ev100'] as num?)?.toDouble() ?? 10.3,
      shutterRecommendation:
          json['shutterRecommendation'] as String? ?? '1/250 s (ISO 100, f/2.8)',
    );
  }
}

class AuditStorageService {
  static const String _storageKey = 'luxplantpro_saved_audits_v1';

  static List<LightAuditRecord> defaultSampleAudits() {
    return [
      LightAuditRecord(
        id: 'LP-2401',
        title: 'Invernadero Tropical — Zona Monstera & Ficus',
        timestamp: DateTime(2026, 11, 9, 9, 45),
        lux: 4200.0,
        footCandles: 390.2,
        ppfd: 69.3,
        dli: 2.99,
        photoperiodHours: 12.0,
        spectrumName: 'Full-Spectrum Horticulture',
        plantName: 'Monstera Deliciosa',
        plantScientificName: 'Monstera deliciosa',
        plantStatus: 'OPTIMAL',
        workspaceZoneName: 'Laboratorio / Ensamblaje (1000 lx)',
        workspaceMinLux: 1000.0,
        workspaceCompliant: true,
        ev100: 10.71,
        shutterRecommendation: '1/250 s (ISO 100, f/2.8)',
      ),
      LightAuditRecord(
        id: 'LP-2402',
        title: 'Estudio Arquitectónico & Mesa Técnica CAD',
        timestamp: DateTime(2026, 11, 8, 16, 15),
        lux: 820.0,
        footCandles: 76.2,
        ppfd: 12.3,
        dli: 0.44,
        photoperiodHours: 10.0,
        spectrumName: '4000K White LED',
        plantName: 'Zamioculcas Zamiifolia (ZZ)',
        plantScientificName: 'Zamioculcas zamiifolia',
        plantStatus: 'OPTIMAL',
        workspaceZoneName: 'Dibujo Técnico / Inspección (750 lx)',
        workspaceMinLux: 750.0,
        workspaceCompliant: true,
        ev100: 8.36,
        shutterRecommendation: '1/60 s (ISO 100, f/2.8)',
      ),
    ];
  }

  static Future<List<LightAuditRecord>> loadAudits() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey);
    if (rawList == null || rawList.isEmpty) {
      final defaults = defaultSampleAudits();
      await saveAudits(defaults);
      return defaults;
    }
    return rawList
        .map((item) =>
            LightAuditRecord.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveAudits(List<LightAuditRecord> audits) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = audits.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_storageKey, encoded);
  }
}
