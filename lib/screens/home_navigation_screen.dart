import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../calculators/light_calculator.dart';
import '../l10n/app_strings.dart';
import '../models/light_audit_record.dart';
import '../services/pdf_report_service.dart';
import '../services/sensor_service.dart';

class HomeNavigationScreen extends StatefulWidget {
  final AppLocaleController localeController;
  final SensorService sensorService;

  const HomeNavigationScreen({
    super.key,
    required this.localeController,
    required this.sensorService,
  });

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int _selectedTabIndex = 0;

  LightSpectrum _selectedSpectrum = LightSpectrum.growLightFull;
  double _photoperiodHours = 12.0;
  PlantSpecies _selectedPlant = LightCalculator.plantCatalog.first;

  int _selectedIso = 100;
  double _selectedAperture = 2.8;
  WorkspaceNormZone _selectedWorkspaceZone =
      LightCalculator.workspaceZones.first;

  List<LightAuditRecord> _savedAudits = [];

  static const List<int> _isoValues = [50, 100, 200, 400, 800, 1600, 3200, 6400];
  static const List<double> _apertureValues = [
    1.4,
    2.0,
    2.8,
    4.0,
    5.6,
    8.0,
    11.0,
    16.0
  ];

  @override
  void initState() {
    super.initState();
    widget.sensorService.pollOnce();
    _loadSavedAudits();
  }

  Future<void> _loadSavedAudits() async {
    final loaded = await AuditStorageService.loadAudits();
    if (mounted) {
      setState(() {
        _savedAudits = loaded;
      });
    }
  }

  Future<void> _saveCurrentAudit() async {
    final lang = widget.localeController.langCode;
    final lux = widget.sensorService.effectiveLux;
    final fc = LightCalculator.luxToFootCandles(lux);
    final plantEval = LightCalculator.evaluatePlant(
      lux: lux,
      spectrum: _selectedSpectrum,
      photoperiodHours: _photoperiodHours,
      plant: _selectedPlant,
    );
    final normEval = LightCalculator.evaluateWorkspaceCompliance(
      lux,
      _selectedWorkspaceZone,
    );
    final photoEval = LightCalculator.calculatePhotoExposure(
      lux: lux,
      iso: _selectedIso,
      apertureF: _selectedAperture,
    );

    final idNum = 2400 + _savedAudits.length + 1;
    final record = LightAuditRecord(
      id: 'LP-$idNum',
      title: '${_selectedPlant.nameFor(lang)} • ${lux.toStringAsFixed(0)} lx',
      timestamp: DateTime.now(),
      lux: lux,
      footCandles: fc,
      ppfd: plantEval.ppfd,
      dli: plantEval.dli,
      photoperiodHours: _photoperiodHours,
      spectrumName: _selectedSpectrum.technicalCode,
      plantName: _selectedPlant.nameFor(lang),
      plantScientificName: _selectedPlant.scientificName,
      plantStatus: plantEval.status.name.toUpperCase(),
      workspaceZoneName: _selectedWorkspaceZone.nameFor(lang),
      workspaceMinLux: _selectedWorkspaceZone.minLux,
      workspaceCompliant: normEval.isCompliant,
      ev100: photoEval.ev100,
      shutterRecommendation:
          '${photoEval.formattedShutter} (ISO $_selectedIso, f/${_selectedAperture.toStringAsFixed(1)})',
    );

    final updated = [record, ..._savedAudits];
    setState(() {
      _savedAudits = updated;
    });
    await AuditStorageService.saveAudits(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text(
            widget.localeController.tr('auditSavedMsg'),
            style: const TextStyle(
              color: Color(0xFF0B0F19),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteAudit(String id) async {
    final updated = _savedAudits.where((a) => a.id != id).toList();
    setState(() {
      _savedAudits = updated;
    });
    await AuditStorageService.saveAudits(updated);
  }

  Future<void> _openSignatureAndPdfDialog(LightAuditRecord audit) async {
    final tr = widget.localeController.tr;
    final nameCtrl =
        TextEditingController(text: 'Ing. Agrónomo / Especialista Lumínico');
    final locCtrl = TextEditingController(text: audit.title);
    final sigController = SignatureController(
      penStrokeWidth: 2.8,
      penColor: const Color(0xFF0B0F19),
      exportBackgroundColor: Colors.white,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161F30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('sigDialogTitle'),
                  style: const TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: tr('sigInspectorName'),
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF0B0F19),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: tr('sigLocationName'),
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF0B0F19),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFF10B981), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Signature(
                      controller: sigController,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => sigController.clear(),
                      icon: const Icon(Icons.refresh, color: Color(0xFFF59E0B)),
                      label: Text(
                        tr('sigClear'),
                        style: const TextStyle(color: Color(0xFFF59E0B)),
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            tr('sigCancel'),
                            style: const TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: const Color(0xFF0B0F19),
                          ),
                          onPressed: () async {
                            final sigBytes = await sigController.toPngBytes();
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            await PdfReportService.previewAndSharePdf(
                              audit: audit,
                              inspectorName: nameCtrl.text.trim(),
                              projectLocation: locCtrl.text.trim(),
                              signaturePngBytes: sigBytes,
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded,
                              size: 18),
                          label: Text(
                            tr('sigGeneratePdf'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable:
          Listenable.merge([widget.localeController, widget.sensorService]),
      builder: (context, _) {
        final tr = widget.localeController.tr;
        return Scaffold(
          backgroundColor: const Color(0xFF0B0F19),
          appBar: AppBar(
            backgroundColor: const Color(0xFF161F30),
            elevation: 0,
            title: Row(
              children: [
                const Icon(Icons.eco_rounded,
                    color: Color(0xFF10B981), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr('appTitle'),
                    style: const TextStyle(
                      color: Color(0xFFF8FAFC),
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '${widget.sensorService.effectiveLux.toStringAsFixed(0)} lx',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: IndexedStack(
            index: _selectedTabIndex,
            children: [
              _buildBotanyTab(),
              _buildPhotoAndNormTab(),
              _buildAuditsTab(),
              _buildSettingsTab(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedTabIndex,
            onTap: (idx) => setState(() => _selectedTabIndex = idx),
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF161F30),
            selectedItemColor: const Color(0xFF10B981),
            unselectedItemColor: const Color(0xFF94A3B8),
            selectedFontSize: 12,
            unselectedFontSize: 11,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.eco_rounded),
                label: tr('tabBotany'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.camera_rounded),
                label: tr('tabPhotoNorm'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: tr('tabAudits'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.tune_rounded),
                label: tr('tabSettings'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 0: LIVE LUX / PPFD / DLI DIAL & PLANT HEALTH MATCH
  // ---------------------------------------------------------------------------
  Widget _buildBotanyTab() {
    final tr = widget.localeController.tr;
    final lang = widget.localeController.langCode;
    final lux = widget.sensorService.effectiveLux;
    final fc = LightCalculator.luxToFootCandles(lux);
    final eval = LightCalculator.evaluatePlant(
      lux: lux,
      spectrum: _selectedSpectrum,
      photoperiodHours: _photoperiodHours,
      plant: _selectedPlant,
    );

    Color statusColor;
    String statusText;
    if (eval.status == PlantHealthStatus.low) {
      statusColor = const Color(0xFFF59E0B);
      statusText = tr('statusLow');
    } else if (eval.status == PlantHealthStatus.optimal) {
      statusColor = const Color(0xFF10B981);
      statusText = tr('statusOptimal');
    } else {
      statusColor = const Color(0xFFEF4444);
      statusText = tr('statusHigh');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Radial Photometer Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF161F30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2D3C52)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0F19),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.sensorService.useManualOverride
                                ? Icons.tune_rounded
                                : Icons.sensors_rounded,
                            size: 15,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.sensorService.useManualOverride
                                ? tr('sensorManual')
                                : tr('sensorLive'),
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          tr('toggleManual'),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                        Switch(
                          value: widget.sensorService.useManualOverride,
                          activeThumbColor: const Color(0xFF10B981),
                          onChanged: (val) =>
                              widget.sensorService.setUseManualOverride(val),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // CustomPainter Radial Gauge
                SizedBox(
                  height: 190,
                  width: 240,
                  child: CustomPaint(
                    painter: LuxDialPainter(
                      currentLux: lux,
                      optimalMinLux: _selectedPlant.optimalMinLux,
                      optimalMaxLux: _selectedPlant.optimalMaxLux,
                      statusColor: statusColor,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lux.toStringAsFixed(0),
                              style: const TextStyle(
                                color: Color(0xFFF8FAFC),
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'LUX (lm/m²)',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Manual Lux Slider (0 to 50,000 Lux)
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF10B981),
                    inactiveTrackColor: const Color(0xFF0B0F19),
                    thumbColor: const Color(0xFFF59E0B),
                  ),
                  child: Slider(
                    key: const Key('sliderManualLux'),
                    value: lux.clamp(0.0, 50000.0),
                    min: 0.0,
                    max: 50000.0,
                    divisions: 500,
                    label: '${lux.toStringAsFixed(0)} lx',
                    onChanged: (val) => widget.sensorService.setManualLux(val),
                  ),
                ),

                // Quick Lux Presets
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [150.0, 500.0, 1500.0, 4500.0, 12000.0, 30000.0]
                      .map((preset) {
                    return ActionChip(
                      backgroundColor: const Color(0xFF0B0F19),
                      side: const BorderSide(color: Color(0xFF2D3C52)),
                      label: Text(
                        '${preset.toInt()} lx',
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontSize: 11,
                        ),
                      ),
                      onPressed: () =>
                          widget.sensorService.setManualLux(preset),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // 3-Metric Summary Row: Foot-Candles, PPFD, DLI
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        tr('fcLabel'),
                        '${fc.toStringAsFixed(1)} fc',
                        const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricCard(
                        tr('ppfdLabel'),
                        eval.ppfd.toStringAsFixed(1),
                        const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricCard(
                        tr('dliLabel'),
                        eval.dli.toStringAsFixed(2),
                        const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Spectrum & Photoperiod Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161F30),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2D3C52)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('spectrumTitle'),
                  style: const TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<LightSpectrum>(
                  initialValue: _selectedSpectrum,
                  dropdownColor: const Color(0xFF161F30),
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0B0F19),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: LightSpectrum.values.map((spec) {
                    return DropdownMenuItem(
                      value: spec,
                      child: Text(tr(spec.labelKey)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedSpectrum = val);
                    }
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('photoperiodTitle'),
                      style: const TextStyle(
                        color: Color(0xFFF8FAFC),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${_photoperiodHours.toStringAsFixed(1)} h / día',
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _photoperiodHours,
                  min: 4.0,
                  max: 20.0,
                  divisions: 32,
                  activeColor: const Color(0xFFF59E0B),
                  onChanged: (val) => setState(() => _photoperiodHours = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Botanical Species Match Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161F30),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: statusColor.withValues(alpha: 0.7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('plantSelectorTitle'),
                  style: const TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<PlantSpecies>(
                  initialValue: _selectedPlant,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF161F30),
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0B0F19),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: LightCalculator.plantCatalog.map((plant) {
                    return DropdownMenuItem(
                      value: plant,
                      child: Text(
                        plant.nameFor(lang),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedPlant = val);
                    }
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        eval.status == PlantHealthStatus.optimal
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        color: statusColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '${eval.healthScore.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _plantThresholdCol(tr('minRequired'),
                        '${_selectedPlant.minLux.toInt()} lx'),
                    _plantThresholdCol(
                        tr('optimalRange'),
                        '${_selectedPlant.optimalMinLux.toInt()}–${_selectedPlant.optimalMaxLux.toInt()} lx'),
                    _plantThresholdCol(tr('maxTolerable'),
                        '${_selectedPlant.maxLux.toInt()} lx'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '💡 ${_selectedPlant.tipFor(lang)}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: const Color(0xFF0B0F19),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _saveCurrentAudit,
                    icon: const Icon(Icons.bookmark_add_rounded),
                    label: Text(
                      tr('saveCurrentAudit'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _plantThresholdCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFF8FAFC),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: PHOTOGRAPHY EV & WORKSPACE NORMATIVE COMPLIANCE CHECKER
  // ---------------------------------------------------------------------------
  Widget _buildPhotoAndNormTab() {
    final tr = widget.localeController.tr;
    final lang = widget.localeController.langCode;
    final lux = widget.sensorService.effectiveLux;

    final photo = LightCalculator.calculatePhotoExposure(
      lux: lux,
      iso: _selectedIso,
      apertureF: _selectedAperture,
    );
    final sceneText = LightCalculator.describeScene(lux, lang);
    final norm = LightCalculator.evaluateWorkspaceCompliance(
      lux,
      _selectedWorkspaceZone,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photography EV Calculator Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF161F30),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2D3C52)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.camera_rounded,
                        color: Color(0xFFF59E0B), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr('photoSectionTitle'),
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        tr('ev100Label'),
                        '${photo.ev100.toStringAsFixed(1)} EV',
                        const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _metricCard(
                        tr('evIsoLabel'),
                        '${photo.evAtIso.toStringAsFixed(1)} EV',
                        const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _metricCard(
                        tr('shutterRecLabel'),
                        photo.formattedShutter,
                        const Color(0xFFF8FAFC),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '${tr('isoLabel')}: ISO $_selectedIso',
                  style: const TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _isoValues.map((isoVal) {
                    final sel = _selectedIso == isoVal;
                    return ChoiceChip(
                      label: Text('ISO $isoVal'),
                      selected: sel,
                      selectedColor: const Color(0xFFF59E0B),
                      backgroundColor: const Color(0xFF0B0F19),
                      labelStyle: TextStyle(
                        color: sel ? const Color(0xFF0B0F19) : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                      onSelected: (_) => setState(() => _selectedIso = isoVal),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  '${tr('apertureLabel')}: f/${_selectedAperture.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _apertureValues.map((apVal) {
                    final sel = _selectedAperture == apVal;
                    return ChoiceChip(
                      label: Text('f/${apVal.toStringAsFixed(1)}'),
                      selected: sel,
                      selectedColor: const Color(0xFF10B981),
                      backgroundColor: const Color(0xFF0B0F19),
                      labelStyle: TextStyle(
                        color: sel ? const Color(0xFF0B0F19) : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedAperture = apVal),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0F19),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tr('sceneTypeLabel')}: $sceneText',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Workspace Normative Compliance Card (EN 12464-1 / OSHA)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF161F30),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: norm.isCompliant
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        color: Color(0xFF10B981), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr('normSectionTitle'),
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  tr('selectZoneLabel'),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<WorkspaceNormZone>(
                  initialValue: _selectedWorkspaceZone,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF161F30),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0B0F19),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: LightCalculator.workspaceZones.map((z) {
                    return DropdownMenuItem(
                      value: z,
                      child: Text(
                        z.nameFor(lang),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedWorkspaceZone = val);
                    }
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        tr('targetLuxLabel'),
                        '${_selectedWorkspaceZone.minLux.toInt()} lx',
                        const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _metricCard(
                        tr('measuredLuxLabel'),
                        '${lux.toInt()} lx',
                        norm.isCompliant
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (norm.isCompliant
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        norm.isCompliant
                            ? '✓ ${tr('normCompliant')}'
                            : '✗ ${tr('normNonCompliant')}',
                        style: TextStyle(
                          color: norm.isCompliant
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${norm.marginPercent >= 0 ? "+" : ""}${norm.marginPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: norm.isCompliant
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Norma: ${_selectedWorkspaceZone.standardRef} • UGR máx: ${_selectedWorkspaceZone.ugrLimit.toInt()} • CRI Ra ≥ ${_selectedWorkspaceZone.minCriRa}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: SAVED LIGHT AUDITS & SIGNED PDF REPORTS
  // ---------------------------------------------------------------------------
  Widget _buildAuditsTab() {
    final tr = widget.localeController.tr;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('auditsTitle'),
                      style: const TextStyle(
                        color: Color(0xFFF8FAFC),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr('auditsSubtitle'),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: const Color(0xFF0B0F19),
                ),
                onPressed: _saveCurrentAudit,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  tr('btnNewAudit'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _savedAudits.isEmpty
                ? Center(
                    child: Text(
                      tr('emptyAudits'),
                      style: const TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.separated(
                    itemCount: _savedAudits.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final item = _savedAudits[idx];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161F30),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2D3C52)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Color(0xFFF8FAFC),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0B0F19),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.id,
                                    style: const TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'Lux: ${item.lux.toStringAsFixed(0)} lx (${item.footCandles.toStringAsFixed(1)} fc)',
                                  style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'PPFD: ${item.ppfd.toStringAsFixed(1)} µmol/m²/s',
                                  style: const TextStyle(
                                      color: Color(0xFFF8FAFC), fontSize: 12.5),
                                ),
                                Text(
                                  'DLI: ${item.dli.toStringAsFixed(2)} mol/m²/d',
                                  style: const TextStyle(
                                      color: Color(0xFFF59E0B), fontSize: 12.5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${item.workspaceZoneName} • EV₁₀₀ ${item.ev100.toStringAsFixed(1)} • ${item.shutterRecommendation}',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _deleteAudit(item.id),
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      size: 18, color: Color(0xFFEF4444)),
                                  label: Text(
                                    tr('btnDeleteAudit'),
                                    style: const TextStyle(
                                        color: Color(0xFFEF4444), fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    foregroundColor: const Color(0xFF0B0F19),
                                  ),
                                  onPressed: () =>
                                      _openSignatureAndPdfDialog(item),
                                  icon: const Icon(Icons.draw_rounded, size: 17),
                                  label: Text(
                                    tr('btnExportPdf'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: SETTINGS & 1-TAP TRILINGUAL SWITCHER
  // ---------------------------------------------------------------------------
  Widget _buildSettingsTab() {
    final tr = widget.localeController.tr;
    final currentLang = widget.localeController.langCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1-Tap Language Switcher Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF161F30),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2D3C52)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('langSection'),
                  style: const TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _langButton('es', 'Español (ES)', currentLang == 'es'),
                    const SizedBox(width: 8),
                    _langButton('en', 'English (EN)', currentLang == 'en'),
                    const SizedBox(width: 8),
                    _langButton('pt', 'Português (PT)', currentLang == 'pt'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sensor Calibration Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF161F30),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2D3C52)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tr('calSection'),
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.sensorService.calibrationFactor.toStringAsFixed(2)}x',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tr('calDesc'),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12.5,
                  ),
                ),
                Slider(
                  value: widget.sensorService.calibrationFactor,
                  min: 0.5,
                  max: 2.0,
                  divisions: 30,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (v) =>
                      widget.sensorService.setCalibrationFactor(v),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        widget.sensorService.setCalibrationFactor(1.0),
                    child: Text(
                      tr('resetCal'),
                      style: const TextStyle(color: Color(0xFFF59E0B)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Camino 1 100% Pro Unlocked Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF161F30),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFF10B981),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('proBadgeTitle'),
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('proBadgeDesc'),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _langButton(String code, String label, bool selected) {
    return Expanded(
      child: InkWell(
        key: Key('lang_$code'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => widget.localeController.setLocale(code),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF10B981) : const Color(0xFF0B0F19),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  selected ? const Color(0xFF10B981) : const Color(0xFF2D3C52),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF0B0F19) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter for the radial botanical & photometric Lux gauge.
class LuxDialPainter extends CustomPainter {
  final double currentLux;
  final double optimalMinLux;
  final double optimalMaxLux;
  final Color statusColor;

  LuxDialPainter({
    required this.currentLux,
    required this.optimalMinLux,
    required this.optimalMaxLux,
    required this.statusColor,
  });

  double _luxToNormalized(double lux) {
    // Non-linear perceptual scale up to 50,000 Lux
    if (lux <= 0) return 0.0;
    final logMax = math.log(50001.0);
    return (math.log(lux + 1.0) / logMax).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.62);
    final radius = math.min(size.width, size.height) * 0.56;
    const startAngle = math.pi * 0.8;
    const sweepAngle = math.pi * 1.4;

    final trackPaint = Paint()
      ..color = const Color(0xFF0B0F19)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Optimal botanical range arc highlight
    final optStartNorm = _luxToNormalized(optimalMinLux);
    final optEndNorm = _luxToNormalized(optimalMaxLux);
    final optPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + sweepAngle * optStartNorm,
      sweepAngle * (optEndNorm - optStartNorm).clamp(0.02, 1.0),
      false,
      optPaint,
    );

    // Current Lux value arc
    final valNorm = _luxToNormalized(currentLux);
    final activePaint = Paint()
      ..color = statusColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * valNorm,
      false,
      activePaint,
    );

    // Indicator dot on rim
    final indicatorAngle = startAngle + sweepAngle * valNorm;
    final dotOffset = Offset(
      center.dx + radius * math.cos(indicatorAngle),
      center.dy + radius * math.sin(indicatorAngle),
    );
    canvas.drawCircle(
      dotOffset,
      8,
      Paint()..color = const Color(0xFFF59E0B),
    );
    canvas.drawCircle(
      dotOffset,
      4,
      Paint()..color = const Color(0xFF0B0F19),
    );
  }

  @override
  bool shouldRepaint(covariant LuxDialPainter oldDelegate) {
    return oldDelegate.currentLux != currentLux ||
        oldDelegate.optimalMinLux != optimalMinLux ||
        oldDelegate.optimalMaxLux != optimalMaxLux ||
        oldDelegate.statusColor != statusColor;
  }
}
