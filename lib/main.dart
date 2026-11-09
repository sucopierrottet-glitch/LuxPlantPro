import 'package:flutter/material.dart';
import 'l10n/app_strings.dart';
import 'screens/welcome_landing_screen.dart';
import 'services/sensor_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeController = AppLocaleController();
  await localeController.loadSavedLocale();
  final sensorService = SensorService();

  runApp(
    LuxPlantProApp(
      localeController: localeController,
      sensorService: sensorService,
    ),
  );
}

class LuxPlantProApp extends StatelessWidget {
  final AppLocaleController localeController;
  final SensorService sensorService;

  const LuxPlantProApp({
    super.key,
    required this.localeController,
    required this.sensorService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'LuxPlant Pro',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0B0F19),
            cardColor: const Color(0xFF161F30),
            primaryColor: const Color(0xFF10B981),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              secondary: Color(0xFFF59E0B),
              surface: Color(0xFF161F30),
              error: Color(0xFFEF4444),
            ),
            useMaterial3: true,
          ),
          home: WelcomeLandingScreen(
            localeController: localeController,
            sensorService: sensorService,
          ),
        );
      },
    );
  }
}
