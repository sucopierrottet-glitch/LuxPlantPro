import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luxplantpro/calculators/light_calculator.dart';
import 'package:luxplantpro/l10n/app_strings.dart';
import 'package:luxplantpro/main.dart';
import 'package:luxplantpro/services/sensor_service.dart';

void main() {
  group('LightCalculator Unit Tests', () {
    test('Lux to Foot-Candles and inverse conversion are accurate', () {
      final fc = LightCalculator.luxToFootCandles(1000.0);
      expect(fc, closeTo(92.903, 0.01));
      final luxBack = LightCalculator.footCandlesToLux(fc);
      expect(luxBack, closeTo(1000.0, 0.01));
    });

    test('PPFD and DLI calculations match photosynthetic physics', () {
      // 5000 Lux under Full-Spectrum Grow Light (0.0165 factor) = 82.5 umol/m2/s
      final ppfd = LightCalculator.calculatePpfd(
        5000.0,
        LightSpectrum.growLightFull,
      );
      expect(ppfd, closeTo(82.5, 0.05));

      // DLI for 82.5 PPFD over 12 hours = 82.5 * 12 * 0.0036 = 3.564 mol/m2/day
      final dli = LightCalculator.calculateDli(ppfd, 12.0);
      expect(dli, closeTo(3.564, 0.01));
    });

    test('Built-in plant catalog has 16 species and evaluates health status', () {
      expect(LightCalculator.plantCatalog.length, greaterThanOrEqualTo(15));
      final monstera = LightCalculator.plantCatalog.firstWhere(
        (p) => p.id == 'monstera',
      );

      final lowEval = LightCalculator.evaluatePlant(
        lux: 300.0,
        spectrum: LightSpectrum.sunlight,
        photoperiodHours: 10.0,
        plant: monstera,
      );
      expect(lowEval.status, PlantHealthStatus.low);

      final optEval = LightCalculator.evaluatePlant(
        lux: 4500.0,
        spectrum: LightSpectrum.sunlight,
        photoperiodHours: 12.0,
        plant: monstera,
      );
      expect(optEval.status, PlantHealthStatus.optimal);
      expect(optEval.healthScore, greaterThanOrEqualTo(88.0));
    });

    test('Photography EV and Workspace EN 12464 compliance calculations', () {
      // At 2500 Lux, EV100 = log2(2500/2.5) = log2(1000) ~ 9.9658
      final photo = LightCalculator.calculatePhotoExposure(
        lux: 2500.0,
        iso: 100,
        apertureF: 2.8,
      );
      expect(photo.ev100, closeTo(9.965, 0.05));
      expect(photo.formattedShutter, contains('1/125'));

      final officeZone = LightCalculator.workspaceZones.first; // 500 lx min
      final compliant =
          LightCalculator.evaluateWorkspaceCompliance(650.0, officeZone);
      expect(compliant.isCompliant, isTrue);

      final nonCompliant =
          LightCalculator.evaluateWorkspaceCompliance(320.0, officeZone);
      expect(nonCompliant.isCompliant, isFalse);
      expect(nonCompliant.deficitLux, closeTo(180.0, 0.1));
    });
  });

  group('LuxPlantPro Widget & Navigation Tests', () {
    testWidgets('Welcome screen enters HomeNavigationScreen and switches tabs/locales',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final localeController = AppLocaleController();
      final sensorService = SensorService();

      await tester.pumpWidget(
        LuxPlantProApp(
          localeController: localeController,
          sensorService: sensorService,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Welcome Screen
      expect(find.text('LuxPlant Pro'), findsOneWidget);
      final enterBtn = find.byKey(const Key('btnWelcomeEnter'));
      expect(enterBtn, findsOneWidget);

      await tester.ensureVisible(enterBtn);
      await tester.tap(enterBtn);
      await tester.pumpAndSettle();

      // Verify Tab 0 (Botany & Lux)
      expect(find.byKey(const Key('sliderManualLux')), findsOneWidget);

      // Navigate to Tab 1 (EV & Standards)
      await tester.tap(find.byIcon(Icons.camera_rounded));
      await tester.pumpAndSettle();
      expect(find.textContaining('EV'), findsWidgets);

      // Navigate to Tab 2 (Saved Audits)
      await tester.tap(find.byIcon(Icons.picture_as_pdf_rounded));
      await tester.pumpAndSettle();
      expect(find.textContaining('LP-2401'), findsOneWidget);

      // Navigate to Tab 3 (Settings) and switch language to English & Portuguese
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('lang_en')));
      await tester.pumpAndSettle();
      expect(localeController.langCode, 'en');
      expect(find.text('Settings'), findsWidgets);

      await tester.tap(find.byKey(const Key('lang_pt')));
      await tester.pumpAndSettle();
      expect(localeController.langCode, 'pt');
      expect(find.text('Ajustes'), findsWidgets);
    });
  });
}
